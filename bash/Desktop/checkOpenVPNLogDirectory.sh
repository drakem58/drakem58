#!/bin/bash
# Check the openvpn log directories for issues like logs not rolling over.
# SQL to generate the input file:
# select name from tunnel_endpoint;

sites_to_get=$1
user_name=$2

UsageAndExit () {
    echo "Usage: $0 <input_filename> <username>"
    echo "Where input_filename is the name of a file with one hostname on each line. See script for details."
    echo "And username is your username to log in to that system."
    exit 1
}

CheckNullParams () {
    if [ -z "${sites_to_get}" ] ; then
        echo "The sites_to_get parameter must not be null."
        UsageAndExit
    elif [ -z "${user_name}" ] ; then
        echo "The username parameter must not be null."
        UsageAndExit
    fi
}

get_errors() {
    host_name=$1
    CMD="ls -l /var/log/openvpn_tmpfs"
    errors=$(setsid ssh -n \
        -o PreferredAuthentications=password \
        -o PubkeyAuthentication=no \
        -o NumberOfPasswordPrompts=1 \
        -o ConnectTimeout=5 \
        -o StrictHostKeyChecking=no \
        -p 52222 \
        -T ${user_name}@${host_name} "${CMD}" 2>&1)
    echo -e "${user_name}@${host_name}:\n${errors}"
}

CheckNullParams
read -s -p "SSH Password: " password
echo ""
file=$(mktemp)
chmod 700 ${file}
trap "rm '${file}'" EXIT
echo "echo '${password}'" > "${file}"
export DISPLAY=:0.0
export SSH_ASKPASS=${file}
export user_name
export -f get_errors
xargs -a ${sites_to_get} -r -L1 -P 1 bash -c 'get_errors "$0"'
wait
