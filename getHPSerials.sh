#!/bin/bash
# Get serial number from HP routers.
# For example, run this on Cedar, and it will run the command on the specified device.
# The file /etc/hpserial.txt is created the first time as follows, executed as root:
# cat /sys/devices/virtual/dmi/id/product_serial > /etc/hpserial.txt
#	This command doesn't need to be executed again unless the server hardware is replaced.

sites_to_get=$1

UsageAndExit () {
    echo "Usage: $0 (filename)"
    echo "Where filename is the name of a file with one hostname on each line."
    exit 1
}

CheckNullParams () {
    if [ -z "${sites_to_get}" ] ; then
        echo "The sites_to_get parameter must not be null."
        UsageAndExit
    fi
}

ExecuteCommand () {
    while read -r device_ip; do
        echo "$device_ip"
        CMD="cat /etc/hpserial.txt"
        ssh -p 52222 -o ConnectTimeout=5 -o StrictHostKeyChecking=no -t $device_ip "$CMD" < /dev/null
    done < $sites_to_get
}

CheckNullParams
ExecuteCommand
