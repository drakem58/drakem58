output "bastion_host_public_ip" {
  value = module.bastion.public_ip
}

output "bastion_host_security_group_id" {
  value = module.bastion.security_group_id
}
