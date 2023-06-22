# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE TWO EC2 INSTANCES WITH ENIS ATTACHED
# This template shows an example of how to create EC2 Instances that attach ENIs during boot time.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  # This module is now only being tested with Terraform 1.1.x. However, to make upgrading easier, we are setting 1.0.0 as the minimum version.
  required_version = ">= 1.0.0"
}

# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ---------------------------------------------------------------------------------------------------------------------

provider "aws" {
  # The AWS region in which all resources will be created
  region = var.aws_region
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE TWO EC2 INSTANCES
# We are using the single-server module to create this instance, as it takes care of the common details like IAM
# Roles, Security Groups, etc.
# ---------------------------------------------------------------------------------------------------------------------

module "example_1" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-server.git//modules/single-server?ref=v0.0.40"
  source = "../../modules/single-server"

  name             = "${var.name}-1"
  ami              = var.ami
  root_volume_size = var.root_volume_size
  # Intentionally run an m5.large here to enable testing 2 eni attachments. Additionally, Ubuntu mounts ethernet devices 
  # differently on different instance types, and we want to make sure the attach-eni script works on all of them. 
  instance_type = "m5.large"

  metadata_http_endpoint               = "enabled"
  metadata_http_put_response_hop_limit = 1
  metadata_http_tokens                 = "optional"
  metadata_tags                        = "enabled"

  # We don't need an EIP for this example
  attach_eip = false

  # To make this example easy to test, we allow SSH access from any IP. In real-world usage, you should only allow SSH
  # access from known, trusted servers (e.g., a bastion host).
  allow_ssh_from_cidr_list = ["0.0.0.0/0"]
  keypair_name             = var.keypair_name

  # To keep this example easy to try, we run it in the default VPC and subnet. In real-world usage, you should
  # typically create a custom VPC and run your code in private subnets.
  vpc_id    = data.aws_vpc.default.id
  subnet_id = data.aws_subnet.selected.id

  # The user data script will attach the volume
  user_data = local.user_data_1

  # We want user_data changes to trigger a replace on change
  user_data_replace_on_change = true
}

module "example_2" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-server.git//modules/single-server?ref=v0.0.40"
  source = "../../modules/single-server"

  name             = "${var.name}-2"
  ami              = var.ami
  root_volume_size = var.root_volume_size

  instance_type = "t3.micro"

  # We don't need an EIP for this example
  attach_eip = false

  # To make this example easy to test, we allow SSH access from any IP. In real-world usage, you should only allow SSH
  # access from known, trusted servers (e.g., a bastion host).
  allow_ssh_from_cidr_list = ["0.0.0.0/0"]
  keypair_name             = var.keypair_name

  # To keep this example easy to try, we run it in the default VPC and subnet. In real-world usage, you should
  # typically create a custom VPC and run your code in private subnets.
  vpc_id    = data.aws_vpc.default.id
  subnet_id = data.aws_subnet.selected.id

  # The user data script will attach the volume
  user_data = local.user_data_2

  # We want user_data changes to trigger a replace on change
  user_data_replace_on_change = true
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE ENIS
# We will attach one ENI to each EC2 Instance
# ---------------------------------------------------------------------------------------------------------------------

# We will attach this ENI by ID
resource "aws_network_interface" "example_1a" {
  subnet_id       = data.aws_subnet.selected.id
  security_groups = [module.example_1.security_group_id]
}

resource "aws_network_interface" "example_1b" {
  subnet_id       = data.aws_subnet.selected.id
  security_groups = [module.example_1.security_group_id]
}

# We will attach this ENI by Name tag
resource "aws_network_interface" "example_2" {
  subnet_id       = data.aws_subnet.selected.id
  security_groups = [module.example_2.security_group_id]

  tags = {
    Name = module.example_2.name
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE USER DATA SCRIPTS TO RUN ON THE INSTANCES WHEN THEY BOOT
# This script will attach the ENI
# ---------------------------------------------------------------------------------------------------------------------

locals {
  user_data_1 = templatefile(
    "${path.module}/user-data/user-data-1.sh",
    {
      aws_region  = var.aws_region
      eni_id_a    = aws_network_interface.example_1a.id
      eni_id_b    = aws_network_interface.example_1b.id
      server_text = var.server_text
      server_port = var.server_port
    },
  )

  user_data_2 = templatefile(
    "${path.module}/user-data/user-data-2.sh",
    {
      aws_region  = var.aws_region
      eni_tag     = "Name"
      server_text = var.server_text
      server_port = var.server_port
    },
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH AN IAM POLICY THAT ALLOWS THE INSTANCES TO ATTACH ENIS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role_policy" "attach_eni_1" {
  name   = "attach-eni"
  role   = module.example_1.iam_role_id
  policy = data.aws_iam_policy_document.attach_eni.json
}

resource "aws_iam_role_policy" "attach_eni_2" {
  name   = "attach-eni"
  role   = module.example_2.iam_role_id
  policy = data.aws_iam_policy_document.attach_eni.json
}

data "aws_iam_policy_document" "attach_eni" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeNetworkInterfaces", "ec2:DescribeTags", "ec2:AttachNetworkInterface", "ec2:DescribeSubnets"]
    resources = ["*"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# OPEN UP THE HTTP PORT ON EACH SERVER
# This is used solely for automated testing and you do not need to copy it to your real-world apps
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group_rule" "allow_all_http_inbound_1" {
  type              = "ingress"
  from_port         = var.server_port
  to_port           = var.server_port
  protocol          = "tcp"
  security_group_id = module.example_1.security_group_id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_http_inbound_2" {
  type              = "ingress"
  from_port         = var.server_port
  to_port           = var.server_port
  protocol          = "tcp"
  security_group_id = module.example_2.security_group_id
  cidr_blocks       = ["0.0.0.0/0"]
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY ONE MORE INSTANCE THAT HAS A PUBLIC IP
# The automated tests connect to this instance and use it to test that the ENIs on the other servers are working
# correctly.
# ---------------------------------------------------------------------------------------------------------------------

module "example_test" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-server.git//modules/single-server?ref=v0.0.40"
  source = "../../modules/single-server"

  name             = "${var.name}-test"
  ami              = var.ami
  root_volume_size = var.root_volume_size
  instance_type    = "t3.micro"

  # This instance needs a nice public IP so our automated tests can connect to it
  attach_eip = true

  # To make this example easy to test, we allow SSH access from any IP. In real-world usage, you should only allow SSH
  # access from known, trusted servers (e.g., a bastion host).
  allow_ssh_from_cidr_list = ["0.0.0.0/0"]
  keypair_name             = var.keypair_name

  # To keep this example easy to try, we run it in the default VPC and subnet. In real-world usage, you should
  # typically create a custom VPC and run your code in private subnets.
  vpc_id    = data.aws_vpc.default.id
  subnet_id = data.aws_subnet.selected.id
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THIS EXAMPLE IN THE DEFAULT VPC AND SUBNETS
# To keep this example simple, we deploy it in the default VPC and subnets. In real-world usage, you'll probably want
# to use a custom VPC and private subnets.
# ---------------------------------------------------------------------------------------------------------------------

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "selected" {
  id = element(tolist(data.aws_subnets.default.ids), 0)
}

data "aws_caller_identity" "current" {}
