# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# ---------------------------------------------------------------------------------------------------------------------

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY

# ----------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables must be passed in by the templates using this module.
# ----------------------------------------------------------------------------------------------------------------------

variable "ami" {
  description = "The ID of an AMI to run on the EC2 instance. It should have mount-ebs-volume and the AWS CLI installed. See packer/build.pkr.hcl."
  type        = string
}

# ----------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These variables may be optionally passed in by the templates using this module to overwite the defaults.
# ----------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "The name used to namespace all resources created by these templates."
  type        = string
  default     = "attach-eni-example"
}

variable "keypair_name" {
  description = "The name of the Key Pair that can be used to SSH to this EC2 instance. Leave blank if you don't want to use a Key Pair."
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "The size of the root volume, in gigabytes."
  type        = number
  default     = 10
}

variable "server_text" {
  description = "The text for the server to return for HTTP requests. This is solely used for automated testing and you do not need to copy it to your real-world apps."
  type        = string
  default     = "Hello, World"
}

variable "server_port" {
  description = "The port the server should listen on for HTTP requests. This is solely used for automated testing and you do not need to copy it to your real-world apps."
  type        = number
  default     = 8080
}
