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
  default     = "persistent-ebs-volume-example"
}

variable "instance_types" {
  description = "List of instance types (e.g t2.micro) to pick from when creating the EC2 instance."
  type        = list(string)
  default     = ["t2.micro", "t3.micro"]
}

variable "keypair_name" {
  description = "The name of the Key Pair that can be used to SSH to this EC2 instance. Leave blank if you don't want to use a Key Pair."
  type        = string
  default     = null
}

variable "user" {
  description = "The OS user who should own the EBS Volume mount points. If you use the Ubuntu AMI, this should be ubuntu. If you use the CentOS AMI, this should be CentOS."
  type        = string
  default     = "ubuntu"
}

variable "root_volume_size" {
  description = "The size of the root volume, in gigabytes."
  type        = number
  default     = 10
}

variable "device_1_name" {
  description = "The device name to use for the first EBS volume"
  type        = string
  default     = "/dev/xvdh"
}

variable "mount_1_point" {
  description = "The mount point to use for the first EBS volume"
  type        = string
  default     = "/data_1"
}

variable "device_2_name" {
  description = "The device name to use for the second EBS volume"
  type        = string
  default     = "/dev/xvdi"
}

variable "mount_2_point" {
  description = "The mount point to use for the second EBS volume"
  type        = string
  default     = "/data_2"
}
