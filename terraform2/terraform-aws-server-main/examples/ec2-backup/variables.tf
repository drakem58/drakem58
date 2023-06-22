# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# ---------------------------------------------------------------------------------------------------------------------
variable "schedule_name" {
  description = "The name to assign to the data lifecycle manager policy schedule"
  type        = string
  default     = "test-schedule"
}

variable "dlm_role_name" {
  description = "The name to assign to the data lifecycle manager's IAM role"
  type        = string
  default     = "test-dlm-role"
}

variable "aws_region" {
  description = "The AWS region in which to deploy the resources"
  type        = string
  default     = "us-west-1"
}

