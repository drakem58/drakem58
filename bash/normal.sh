#!/bin/bash
# Welcome to lucille2.
# So named for the oedipal paramour of Buster Bluth.
#
# This script is for upgrading old POP HW infrastructure
# to the new puppet6/debian buster setup. The basic
# operation is to split the root raid device into two,
# format one half and write a new system image to it,
# clean things up and copy configs to the new system
# so it will boot to the same state as the old (e.g.,
# networking), then reboot (the reboot is handled by
# the user). The new image should be set as the default
# grub choice, and the system should come up into the new
# image. Once booted, the old raid can be removed and the
# underlying sata device can be reformatted and added to
# the new raid.
#
# The script is split into two commands:
#
#   start: the pre-reboot steps
#   finish: the post-reboot steps
#
# Both commands require the --iamsure option to actually
# modify system state. It is recommended to run them once
# without that option to make sure the commands are going
# act upon the expected device.
#
# The script will log to a file _${0}.log in the same
# directory, and both the log and the script will be copied
# to the new system to preserve the logging after the reboot.

OPTS="-eu -o pipefail -o noclobber"
eval set $OPTS
START_SUBSHELL="bash $OPTS -x"

export START_SUBSHELL

IMAGE_HOST='bunyan.prod.bigleaf.net'
IMAGE_DIR='/opt/bigleaf/lib/pkg-repo/rootfs'


fatal() { echo >&2 $0: fatal: "$@"; exit 1; }

export -f fatal

_node_exec () {
    ROOT=$1; shift
    DEBIAN_FRONTEND=noninteractive exec unshare -impuf chroot $ROOT \
        $START_SUBSHELL -c 'hostname "$(cat ./etc/hostname)" && exec "$@"' -- "$@"
}

export -f _node_exec

node_exec () {
    $START_SUBSHELL -c '_node_exec "$@"' -- "$@"
}

export -f node_exec

_mount_and_chdir () {
    MDIR=$(mktemp -du)
    MOUNTS=()

    MOUNT_OPTS=
    DEVICE=
    while [ -z "$DEVICE" ]; do
        echo $1
        case "$1" in
            --with-dev-mount)
                MOUNTS+=("-o ro,bind /dev $MDIR/dev")
                ;;
            --with-proc-mount)
                MOUNTS+=("-o ro -t proc proc $MDIR/proc")
                ;;
            --with-sys-mount)
                MOUNTS+=("-o ro -t sysfs sys $MDIR/sys")
                ;;
            # for speeding/discarding temp/cache data during install
            --with-tmpfs-mount)
                MOUNTS+=("-o size=$2 -t tmpfs tmpfs $MDIR/$3")
            shift; shift
            ;;
            # for bootstrapping pre-puppet deps, i.e. puppet+pkg-repo
            --with-bind-mount)
                MOUNTS+=("-o ro,bind $2 $MDIR/$3")
                shift; shift;
                ;;
            -o)
                MOUNT_OPTS="${MOUNT_OPTS} $1 $2"
                shift;
                ;;
            *)
                DEVICE="$1";
                ;;
        esac
        shift
    done

    unmount-all() {
        for M in ${MOUNTS[@]+"${MOUNTS[@]}"}; do
            umount "${M##* }"
        done
        umount $MDIR
    }
    trap "set +e; cd /; unmount-all; rmdir $MDIR" EXIT
    mkdir $MDIR
    mount $MOUNT_OPTS $DEVICE $MDIR

    for M in ${MOUNTS[@]+"${MOUNTS[@]}"}; do
        mkdir -p "${M##* }"
        mount $M
    done
    cd $MDIR >/dev/null
    "$@"
}

export -f _mount_and_chdir

mount-and-chdir () {
    unshare -m $START_SUBSHELL -c '_mount_and_chdir "$@"' -- "$@"
}

partition-device () {
    # DEV (raid|root|swap):(+|[0-9][MG])...
    # The plus "+" suffix means to extend to the end of the device.
    # e.g. ./tools/partition-device /dev/ndc3p0 swap:1G root:9G raid:+
    local DEV=$1;shift
    local SECTOR_SIZE=$(blockdev --getss $DEV)
    case $SECTOR_SIZE in
    512|2048|4096) ;;
    *) fatal "unexpected sector size: $SECTOR_SIZE"
    esac

    local SFDISK_INPUT=("\
unit: sectors
")

    # 640K^W2M should be enough for anyone
    local SEC=$((2 * 1024 * 1024 / $SECTOR_SIZE))
    local P=
    ! [[ ${DEV:-1} =~ [0-9] ]] || P=p
    local WIPEFS=

    local PARTNUM=1
    while [ $PARTNUM -le $# ]; do
        local ARG=${!PARTNUM}
        case "$ARG" in
                root:*) local TYPE="83, bootable";;
                swap:*) local TYPE=82;;
                raid:*) local TYPE="fd, bootable";;
                *) fatal "unknown name: ${ARG%:*}";;
        esac
        local ARG=${ARG#*:}
        local SIZE=${ARG%?}
        local SCALE=1024
        case "$ARG" in
                +)
                SCALE=$SECTOR_SIZE
                        SIZE=$(($(blockdev --getsize64 $DEV) / $SECTOR_SIZE - $SEC))
                        [ $PARTNUM -eq $# ] || fatal "expando-partition must be at the end";;
                [0-9]*G) SCALE=$(($SCALE * 1024));&
                [0-9]*M) SCALE=$(($SCALE * 1024));;
                *) fatal "need [0-9][MG] got $ARG";;
        esac

        SIZE=$(($SIZE * $SCALE))
        [ $(($SIZE % $SECTOR_SIZE )) -eq 0 ] ||
                fatal "Partition size must be divisible by sector size " \
                        $ARG $SIZE / $SECTOR_SIZE
        SIZE=$(($SIZE / $SECTOR_SIZE))
        # Could create GPT or extended partitions, but 4 is enough for now
        SFDISK_INPUT+=("$(printf "$DEV$P%-2d: start=%12d, size=%12d, Id=%s" \
                        $PARTNUM $SEC $SIZE "$TYPE")")
        PARTNUM=$(($PARTNUM + 1))
        WIPEFS="$WIPEFS $SEC"
        SEC=$(($SEC + $SIZE))
    done

    local REAL_SIZE=$(blockdev --getsize64 $DEV)
    SIZE=$(($SEC * $SECTOR_SIZE))

    [ $SIZE -le $REAL_SIZE ] ||
        fatal "total partition size $SIZE cannot be more than blockdev size $REAL_SIZE"

    dd if=/dev/zero of=$DEV bs=2M count=1 status=noxfer
    for i in $WIPEFS; do
        dd if=/dev/zero of=$DEV bs=$SECTOR_SIZE seek=$i count=100 status=noxfer
    done
    for i in "${SFDISK_INPUT[@]}"; do
        echo "$i"
    done | tee /tmp/sfdisk.in | sfdisk -q --no-reread $DEV
    partprobe $DEV
}

gen-md-name () {
    local OLD_MD=$1
    # if our old md is 0 then we want 1, else we want 0
    [ "/dev/md0" == "$1" ] && echo "/dev/md1" || echo "/dev/md0"
}

uuid() {
        hexdump -vn 24 -e '/1 "%02x"' < /dev/urandom | (read R;
        echo ${R:0:8}-${R:8:4}-${R:12:4}-${R:16:4}-${R:20:12})
}

export -f uuid

create-raid (){
    local MD=$1; shift
    local PART=$1; shift
    local UUID=$(uuid)
    mdadm -C $MD --uuid=$UUID --homehost=any --metadata=1.2 --level=1 --raid-devices=1 $PART -f
}

install-root () {
    local ROOTFS_TAR=$1; shift
    local HOST=$1; shift
    local ROOT_DEV=$1; shift
    ROOTFS_TAR=$(readlink -m $ROOTFS_TAR)
    local UUID=$1; shift
    wipefs -a $ROOT_DEV
    local LABEL=${HOST}_rootfs
    mkfs.ext4 -U $UUID -T default -L ${LABEL:0:16} $ROOT_DEV
    udevadm trigger $ROOT_DEV

    mount-and-chdir $ROOT_DEV $START_SUBSHELL<<EOF
( gunzip -c<$ROOTFS_TAR || cat $ROOTFS_TAR) | pv | tar x
[ "\$(cat ./etc/hostname)" = unconfigured-base-system ]  || {
        fatal "expected 'unconfigured-base-system' in /etc/hostname, found \$(cat ./etc/hostname)"
}
rm ./etc/hostname
echo $HOST.bigleaf.net > ./etc/hostname
sed -e "s_UUID=[^ ]* */_UUID=$UUID /_g" -i ./etc/fstab
grep -q $UUID ./etc/fstab
EOF

    mount-and-chdir --with-{dev,proc,sys}-mount $ROOT_DEV \
        node_exec . $START_SUBSHELL <<EOF
/opt/bigleaf/lib/system-image/tools/setup-hostname
dpkg-reconfigure openssh-server
EOF
}

install-grub () {
    local ROOT_DEV=$1; shift
    local BOOT_DEV=$1; shift
    mount-and-chdir --with-{dev,proc,sys}-mount $ROOT_DEV \
        node_exec . $START_SUBSHELL -e <<EOF
grub-install $BOOT_DEV
update-grub
EOF
}

install-swap () {
    local ROOT_DEV=$1; shift
    local SWAP_DEV=$1; shift
    mount-and-chdir $ROOT_DEV $START_SUBSHELL<<EOF
UUID=\$(uuid)
mkswap $SWAP_DEV -U \$UUID
echo "UUID=\$UUID none swap sw,pri=1 0 0" >> ./etc/fstab
EOF
}

run-puppet () {
    local DEV=$1; shift
    mount-and-chdir --with-{sys,proc,dev}-mount $DEV \
        node_exec . /bin/bash -s <<EOF
install -m 755 /dev/stdin /usr/local/sbin/ip <<EOC
#!/bin/sh
echo ip "$@"
EOC
puppet</dev/null agent --test --detailed-exitcodes --waitforcert 5 || [ \$? -eq 2 ]
rm -f /usr/local/sbin/ip
EOF
}

get-hostname () {
    local HOST=$(hostname --fqdn | grep -Po "(.*)(?=\.bigleaf\.net)")
    local H1=$(echo $HOST | cut -d '.' -f 1)
    local POP=$(echo $HOST | cut -d '.' -f 2)
    local ENV=$(echo $HOST | cut -d '.' -f 3)
    echo "${H1}.${POP}.${ENV:-retail}"
}

get-image-name () {
    local HOST=$1; shift
    local node=$(echo $HOST | cut -d '.' -f 1 | tr -d '0-9')
    if [ "$node" == "tunnel" ]; then
        echo "tunnel-terra"
    elif [ "$node" == "apricot" -o "$node" == "banana" ]; then
        echo "compute-terra"
    else
        fatal "An appropriate image name cannot not be gleaned from host '${HOST}'"
    fi
}

wait-for-partprobe () {
    i=10
    while [ $i -gt 0 ] && sleep 1; do
        [ -e $1 ] && break
        i=$((i - 1))
    done
}

start-upgrade () {
    # figure out host and image names
    HOST=$(get-hostname)
    IMAGE_NAME=$(get-image-name $HOST)

    # scp image file vars
    IMAGE=/root/${IMAGE_NAME}.tgz
    IMG_SRC=${IMAGE_HOST}:${IMAGE_DIR}/${IMAGE_NAME}/current

    # find raid device names
    OLD_MD=/dev/$(lsblk -n $(findmnt -no source -T /) | awk '{ print $1 }')
    NEW_MD=$(gen-md-name ${OLD_MD})

    # get old raid members
    PARTS=$(mdadm -D ${OLD_MD} | grep -o -E '/dev/sd.*$')
    PART1=$(echo "${PARTS}" | head -n 1)
    PART2=$(echo "${PARTS}" | tail -n 1)
    DEV1=$(echo ${PART1} | tr -d '0-9')
    DEV2=$(echo ${PART2} | tr -d '0-9')

    if [ "$DEV1" == "$DEV2" ]; then
        # only one device in the raid
        # we need to check for other devices
        PART2=
        DEV2=
        for dev in $(ls -d1 /sys/block/sd*); do
            dev=/dev/$(basename $dev)
            [ "$dev" != "$DEV1" ] && DEV2=$dev && break
        done
    fi

    [ "$DEV2" != "" ] || fatal "Could not identify more than one SATA device. Cannot proceed."


    ## ------ EVERYTHING PAST THIS POINT COULD BREAK STUFF ------ ##
    [ "${1:-}" == "--iamsure" ] || {
        set +x
        echo "Run with '--iamsure' to proceed past discovery" >&2
        echo "If you do, this will run on device '${DEV2}'" >&2
        exit
    }


    # scp image over to this host
    [ -f "$IMAGE" ] || \
        scp $SUDO_USER@${IMG_SRC} ${IMAGE}

    # install required packages
    apt-get install -y parted pv os-prober
    TARGET=$(dpkg --compare-versions $(cat /etc/debian_version) lt 8.0 && echo "-t jessie" ||:)
    apt-get install -y ${TARGET} util-linux grub-pc

    # turn swap off
    swapoff $(cat /proc/swaps | grep ${DEV2} | awk '{ print $1 }') ||:

    # remove the partition from our old raid
    if [ "$PART2" != "" ]; then
        mdadm --manage ${OLD_MD} -f ${PART2}
        mdadm --manage ${OLD_MD} -r ${PART2}
        mdadm --grow ${OLD_MD} --raid-devices=1 --force
    elif grep -q $(basename ${NEW_MD}) /proc/mdstat; then
        # stop the new raid
        umount ${NEW_MD} ||:
        mdadm --stop ${NEW_MD}
        mdadm --remove ${NEW_MD}
    fi

    # run "provisioner"
    UUID=$(uuid)
    partition-device ${DEV2} swap:1G raid:48G
    wait-for-partprobe ${DEV2}2
    create-raid ${NEW_MD} ${DEV2}2
    install-root ${IMAGE} ${HOST} ${NEW_MD} ${UUID}
    install-grub ${NEW_MD} ${DEV2}
    install-swap ${NEW_MD} ${DEV2}1
    run-puppet ${NEW_MD}

    # start the raid and mount it
    mdadm --manage ${NEW_MD} -a ${DEV2}2 run ||:
    mount ${NEW_MD} /mnt
    trap "umount /mnt" EXIT

    # copy the network config to the new raid
    cp {,/mnt}/etc/network/interfaces

    # setup MAC to iface mappings
    for ETH in $(ls -d /sys/class/net/eth*); do
        NAME=$(basename $ETH);
        MAC=$(cat ${ETH}/address);
        FILE=/mnt/etc/systemd/network/10-${NAME}.link

        [ -f $FILE ] || cat > $FILE << EOF
[Match]
MACAddress=${MAC}

[Link]
Name=${NAME}
EOF
    done

    # fixup grub settings
    sed -i '/^GRUB_DEFAULT=/d' /etc/default/grub
    echo "GRUB_DEFAULT=osprober-gnulinux-simple-${UUID}" >> /etc/default/grub
    sed -i '/^GRUB_DISABLE_OS_PROBER=/d' /etc/default/grub
    echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub

    # make os-prober work
    sed -i \
        's*OSPROBED="`os-prober | tr '"'"' '"'"' '"'"'^'"'"' | paste -s -d '"'"' '"'"'`"*OSPROBED="'"${NEW_MD}"':linux-4.19.0-20-amd64::linux"*' \
        /etc/grub.d/30_os-prober
    grep -q 'OSPROBED="'"${NEW_MD}"':linux-4.19.0-20-amd64::linux"' /etc/grub.d/30_os-prober \
        || fatal "It looks like the OSPROBER sed hack failed."

    # now we can generate a good grub config
    update-grub
    cp {,/mnt}/boot/grub/grub.cfg

    # copy this script and log to the new raid
    cp {,/mnt}$(this-script)
    cp {,/mnt}$(log-file)

    # cross your fingers and reboot
    echo "If everything looks good, you should reboot now"
}

finish-upgrade () {
    # find raid device names
    ALL_MDS=$(grep -o -E "^md[0-9]+" /proc/mdstat)
    NEW_MD=/dev/$(lsblk -n $(findmnt -no source -T /) | awk '{ print $1 }')
    for md in $ALL_MDS; do
        md=/dev/${md}
        if [ "$md" == "$NEW_MD" ]; then
            continue
        elif [ -z ${OLD_MD:-} ]; then
            OLD_MD=$md
        else
            fatal "More than two MD devices detected. Cannot proceed."
        fi
    done

    # make sure new raid meets expectations and get sata dev
    PARTS=$(mdadm -D ${NEW_MD} | grep -o -E '/dev/sd.*$')
    [ "$(echo "$PARTS" | wc -l)" -eq "1" ] || \
        fatal "It looks like the new raid device has more than one partition, so this script has already been run?"
    PART1=$(echo "${PARTS}" | head -n 1)
    DEV1=$(echo ${PART1} | tr -d '0-9')

    if [ -z ${OLD_MD:-} ]; then
        # we don't have a raid device, so let's see if we can find a bare sata device
        for dev in $(ls -d1 /sys/block/sd*); do
            dev=/dev/$(basename $dev)
            [ "$dev" != "$DEV1" ] && DEV2=$dev && break
        done
    else
        # we have an old raid, let's remove it
        PARTS=$(mdadm -D ${OLD_MD} | grep -o -E '/dev/sd.*$')
        [ "$(echo "$PARTS" | wc -l)" -eq "1" ] || \
            fatal "It looks like the old raid device has more than one partition. I don't know what to do."
        PART2=$(echo "${PARTS}" | head -n 1)
        DEV2=$(echo "${PART2}" | tr -d '0-9')
    fi

    [ "$DEV2" != "" ] || fatal "Could not identify more than one SATA device. Cannot proceed."


    ## ------ EVERYTHING PAST THIS POINT COULD BREAK STUFF ------ ##
    [ "${1:-}" == "--iamsure" ] || {
        set +x
        echo "Run with '--iamsure' to proceed past discovery" >&2
        echo "If you do, this will run on device '${DEV2}'" >&2
        exit
    }


    apt install -y parted

    [ -z ${OLD_MD:-} ] || {
        # stop and remove the raid
        mdadm --stop ${OLD_MD}
        mdadm --remove ${OLD_MD} ||:
    }

    # turn swap off
    swapoff $(cat /proc/swaps | grep ${DEV2} | awk '{ print $1 }') ||:

    partition-device ${DEV2} swap:1G raid:48G
    wait-for-partprobe ${DEV2}1

    # make swap
    UUID=$(uuid)
    mkswap ${DEV2}1 -U $UUID
    echo "UUID=$UUID none swap sw,pri=1 0 0" >> /etc/fstab

    # add device to raid
    mdadm --add $NEW_MD ${DEV2}2
    mdadm --grow $NEW_MD --raid-devices=2
    sleep 3
    rm /etc/mdadm/mdadm.conf
    /usr/share/mdadm/mkconf > /etc/mdadm/mdadm.conf && update-initramfs -u

    grub-install ${DEV1}
    grub-install ${DEV2}
    update-grub
}

main () {
    echo >&2 "BEGIN RUN: $0, args '$@', at $(date)"
    trap "echo >&2 END RUN at $(date)" EXIT
    [ "$UID" -eq "0" ] || fatal "Must run this script as root."
    cmd=${1:?"Must specify command. Valid options are 'start' and 'finish'"}
    case $cmd in
        start)
            shift
            set -x
            start-upgrade "$@"
            ;;
        finish)
            shift
            set -x
            finish-upgrade "$@"
            ;;
        *)
            fatal "Unrecognized command '${cmd}'. Valid options are 'start' and 'finish'."
            ;;
    esac
}

this-script () {
    echo "$(readlink -f ${BASH_SOURCE[0]})"
}

log-file () {
    local SCRIPT="$(this-script)"
    local SCRIPT_NAME="$(basename "$SCRIPT")"
    local SCRIPT_DIR="$(dirname "$SCRIPT")"
    echo "${SCRIPT_DIR}/_${SCRIPT_NAME}.log"
}

main "$@" |& tee -a >(sed -r 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g' >> "$(log-file)")

tunnel10.chi
Personalities : [raid1]
md1 : active raid1 sdb2[0]
      50298752 blocks super 1.2 [1/1] [U]

md0 : active raid1 sda2[0]
      233248320 blocks super 1.2 [1/1] [U]
      bitmap: 1/2 pages [4KB], 65536KB chunk
after first reboot
mdrake@tunnel10.chi.retail(production):~$ cat /proc/mdstat
Personalities : [raid1] [linear] [multipath] [raid0] [raid6] [raid5] [raid4] [raid10]
md0 : active (auto-read-only) raid1 sda2[0]
      233248320 blocks super 1.2 [1/1] [U]
      bitmap: 0/2 pages [0KB], 65536KB chunk

md1 : active raid1 sdb2[0]
      50298752 blocks super 1.2 [1/1] [U]
