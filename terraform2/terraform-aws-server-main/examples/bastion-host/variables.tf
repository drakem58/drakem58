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

variable "keypair_name" {
  description = "The AWS EC2 Keypair name for root access to the bastion host."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC in which to run the bastion host. If using the standard Gruntwork VPC setup, this should be the id of the Mgmt VPC."
  type        = string
}

variable "subnet_id" {
  description = "The id of the subnet in which to run the bastion host. If using the standard Gruntwork VPC setup, this should be the id of a public subnet in the Mgmt VPC."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# DEFINE CONSTANTS
# Generally, these values won't need to be changed.
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name of the bastion host"
  type        = string
  default     = "bastion-host"
}

variable "ami" {
  description = "The ID of the AMI to run on the Bastion Host Instance."
  type        = string

  # Ubuntu Server 14.04 LTS (HVM), SSD Volume Type in us-east-1
  default = "ami-fce3c696"
}

variable "attach_eip" {
  description = "Determines if an Elastic IP (EIP) will be created for this instance. Must be set to a boolean (not a string!) true or false value."
  type        = bool
  default     = true
}

variable "instance_types" {
  description = "List of instance types (e.g t2.micro) to pick from when creating the EC2 instance."
  type        = list(string)
  default     = ["t2.micro", "t3.micro"]
}
