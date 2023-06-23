#!/bin/bash
# Get OpenVPN tunnel process status on all tunnel servers.

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
        CMD="/etc/init.d/openvpn status"
        ssh -p 52222 -o ConnectTimeout=5 -o StrictHostKeyChecking=no -t $device_ip "$CMD" < /dev/null
    done < $sites_to_get
}

CheckNullParams
ExecuteCommand
