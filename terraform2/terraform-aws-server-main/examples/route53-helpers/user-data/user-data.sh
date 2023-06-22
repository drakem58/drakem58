#!/bin/bash
#
# This script is meant to run in the User Data of an EC2 instance to add a DNS A Record.

set -e

# Send the log output from this script to user-data.log, syslog, and the console
# From: https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

function add_dns_a_record {
  local readonly aws_region="$1"
  local readonly hosted_zone_id="$2"
  local readonly hostname="$3"

  echo "Adding Route 53 DNS A Record for hostname $hostname in Hosted Zone $hosted_zone_id"
  add-dns-a-record --aws-region "$aws_region" --hosted-zone-id "$hosted_zone_id" --hostname "$hostname" --ip-type "public"
}

function run_dummy_http_server {
  local readonly server_text="$1"
  local readonly server_port="$2"

  echo "Running HTTP server on port $server_port that will return the text '$server_text'"
  echo "$server_text" > index.html
  nohup python -m SimpleHTTPServer "$server_port" 2>&1 | logger &
}

function setup_server {
  local readonly aws_region="$1"
  local readonly hosted_zone_id="$2"
  local readonly hostname="$3"
  local readonly server_text="$4"
  local readonly server_port="$5"

  add_dns_a_record "$aws_region" "$hosted_zone_id" "$hostname"
  run_dummy_http_server "$server_text" "$server_port"
}

# These variables are set via Terraform interpolation
setup_server "${aws_region}" "${hosted_zone_id}" "${hostname}" "${server_text}" "${server_port}"

# By way of demonstration, require that all calls to the Instance Metadata Service use the more secure version 2.0. This would typically be done on an instance that is intended to continue making calls to IMDS
require-instance-metadata-service-version --version-2-state 'required'

# Once setup is complete, disable all access to the Instance Metadata service from this instance to prevent privilege escalation
disable-instance-metadata
