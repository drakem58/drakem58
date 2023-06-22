output "dlm_lifecycle_role_arn" {
  description = "The ARN of the IAM role associated with the data lifecycle manager"
  value       = module.ec2-backup.dlm_lifecycle_role_arn
}

output "dlm_lifecycle_role_name" {
  description = "The name of the IAM role associated with the data lifecycle manager"
  value       = module.ec2-backup.dlm_lifecycle_role_name
}

output "dlm_lifecycle_policy_arn" {
  description = "The ARN of the data lifecycle manager policy"
  value       = module.ec2-backup.dlm_lifecycle_policy_arn
}
