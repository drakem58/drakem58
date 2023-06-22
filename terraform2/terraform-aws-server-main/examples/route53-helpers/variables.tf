# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# ---------------------------------------------------------------------------------------------------------------------

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator
# ---------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
}

variable "aws_account_ids" {
  description = "A list of AWS Account IDs. Only these IDs may be operated on by this template. The first account ID in the list will be used to identify where the VPC Peering Connection should be created. This should be the account ID in which all resources are to be created."
  type        = list(string)
}

variable "ami" {
  description = "The ID of an AMI to run on the EC2 instance. It should have add-dns-a-record and the AWS CLI installed. See packer/build.pkr.hcl."
  type        = string
}

variable "keypair_name" {
  description = "The name of the Key Pair that can be used to SSH to this EC2 instance. Leave blank if you don't want to use a Key Pair."
  type        = string
}

variable "vpc_id" {
  description = "The id of the VPC in which this EC2 instance should be deployed"
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet in which this EC2 instance should be deployed"
  type        = string
}

variable "hosted_zone_id" {
  description = "The ID of the Route 53 Hosted Zone where a DNS A Record should be added"
  type        = string
}

variable "hostname" {
  description = "The hostname to add to the Route 53 Hosted Zone in var.hosted_zone_id (e.g. foo.example.com)."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# DEFINE CONSTANTS
# Generally, these values won't need to be changed.
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name used to namespace all resources created by these templates."
  type        = string
  default     = "route53-helpers-example"
}

variable "server_text" {
  description = "The text the HTTP server on the EC2 Instance will return"
  type        = string
  default     = "Hello World"
}

variable "server_port" {
  description = "The port the EC2 Instance will listen on for HTTP requests"
  type        = number
  default     = 8080
}
