#!/bin/bash
#
# This script is meant to run in the User Data of an EC2 instance to an ENI by tag

set -e

# Send the log output from this script to user-data.log, syslog, and the console
# From: https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Attach the ENI
/usr/local/bin/attach-eni --eni-with-same-tag "${eni_tag}"

# We start a web server so that we can make an HTTP request to the ENI IP address to validate that it's working correctly
echo "Starting server on port ${server_port} that returns text ${server_text}"
echo "${server_text}" > index.html

nohup python3 -m http.server ${server_port} 2>&1 | logger &
