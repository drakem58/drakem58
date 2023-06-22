output "instance_ip" {
  value = module.example.instance_ip
}

output "ebs_volume_id_1" {
  value = aws_ebs_volume.example_1.id
}

output "ebs_volume_id_2" {
  value = aws_ebs_volume.example_2.id
}

output "device_1_name" {
  value = var.device_1_name
}

output "mount_1_point" {
  value = var.mount_1_point
}

output "device_2_name" {
  value = var.device_2_name
}

output "mount_2_point" {
  value = var.mount_2_point
}
