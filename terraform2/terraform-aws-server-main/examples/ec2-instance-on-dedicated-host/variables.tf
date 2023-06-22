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

variable "aws_account_ids" {
  description = "The AWS Account ID in which resources will be created"
  type        = list(string)
}

variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
}

variable "keypair_name" {
  description = "The AWS EC2 Keypair name for root access to the EC2 instance."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------------------------------------------------
# DEFINE CONSTANTS
# Generally, these values won't need to be changed.
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name of the EC2 instance"
  type        = string
  default     = "ec2-test-instance"
}

variable "attach_eip" {
  description = "Determines if an Elastic IP (EIP) will be created for this instance. Must be set to a boolean (not a string!) true or false value."
  type        = bool
  default     = true
}

variable "instance_type" {
  description = "The EC2 instance type to deploy"
  type        = string
  default     = "m5.large"
}
