output "instance_1_ip" {
  value = module.example_1.instance_ip
}

output "instance_2_ip" {
  value = module.example_2.instance_ip
}

output "instance_1_id" {
  value = module.example_1.id
}

output "instance_2_id" {
  value = module.example_2.id
}

output "eni_1_a_id" {
  value = aws_network_interface.example_1a.id
}

output "eni_1_b_id" {
  value = aws_network_interface.example_1b.id
}

output "eni_2_id" {
  value = aws_network_interface.example_2.id
}

output "instance_test_ip" {
  value = module.example_test.public_ip
}

output "instance_test_id" {
  value = module.example_test.id
}
