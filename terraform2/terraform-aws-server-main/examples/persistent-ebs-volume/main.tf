# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE AN EC2 INSTANCE WITH TWO PERSISTENT EBS VOLUMES
# This template shows an example of how to create a standalone EC2 Instance with two EBS Volumes that are persisted
# between redeploys.
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
# CREATE AN EC2 INSTANCE
# We are using the single-server module to create this instance, as it takes care of the common details like IAM
# Roles, Security Groups, etc.
# ---------------------------------------------------------------------------------------------------------------------

module "example" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-server.git//modules/single-server?ref=v0.0.40"
  source = "../../modules/single-server"

  name             = var.name
  instance_type    = module.instance_types.recommended_instance_type
  ami              = var.ami
  root_volume_size = var.root_volume_size

  # We don't need an EIP for this example
  attach_eip = false

  # To make this example easy to test, we allow SSH access from any IP. In real-world usage, you should only allow SSH
  # access from known, trusted servers (e.g., a bastion host).
  allow_ssh_from_cidr_list = ["0.0.0.0/0"]

  keypair_name = var.keypair_name

  # To keep this example easy to try, we run it in the default VPC and subnet. In real-world usage, you should
  # typically create a custom VPC and run your code in private subnets.
  vpc_id = data.aws_vpc.default.id

  subnet_id = data.aws_subnet.selected.id

  # The user data script will attach the volume
  user_data = local.user_data

  # We want user_data changes to trigger a replace on change
  user_data_replace_on_change = true
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE EBS VOLUMES
# If you have an EBS Volume Snapshot from which the new EBS Volume should be created, just add a snapshot_id parameter.
# ---------------------------------------------------------------------------------------------------------------------

# We will attach this volume by ID
resource "aws_ebs_volume" "example_1" {
  availability_zone = data.aws_subnet.selected.availability_zone
  type              = "gp2"
  size              = 5
}

# We will attach this volume by Name tag
resource "aws_ebs_volume" "example_2" {
  availability_zone = data.aws_subnet.selected.availability_zone
  type              = "gp2"
  size              = 5

  tags = {
    Name = var.name
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE USER DATA SCRIPT TO RUN ON THE INSTANCE WHEN IT BOOTS
# This script will attach and mount the EBS volume
# ---------------------------------------------------------------------------------------------------------------------

locals {
  user_data = templatefile(
    "${path.module}/user-data/user-data.sh",
    {
      aws_region    = var.aws_region
      volume_1_id   = aws_ebs_volume.example_1.id
      device_1_name = var.device_1_name
      mount_1_point = var.mount_1_point
      volume_2_tag  = "Name"
      device_2_name = var.device_2_name
      mount_2_point = var.mount_2_point
      owner         = var.user
      name          = var.name
    },
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH AN IAM POLICY THAT ALLOWS THE INSTANCE TO ATTACH VOLUMES
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role_policy" "manage_ebs_volume" {
  name   = "manage-ebs-volume"
  role   = module.example.iam_role_id
  policy = data.aws_iam_policy_document.manage_ebs_volume.json
}

data "aws_iam_policy_document" "manage_ebs_volume" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:AttachVolume",
      "ec2:DetachVolume",
    ]

    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:volume/${aws_ebs_volume.example_1.id}",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:volume/${aws_ebs_volume.example_2.id}",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/${module.example.id}",
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeVolumes", "ec2:DescribeTags"]
    resources = ["*"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH AN IAM POLICY THAT ALLOWS THE INSTANCE TO MODIFY THE INSTANCE METADATA SERVICE (IMDS) ENDPOINT
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role_policy" "manage_imds_endpoint" {
  name   = "manage-imds-endpoint"
  role   = module.example.iam_role_id
  policy = data.aws_iam_policy_document.manage_imds_endpoint.json
}

data "aws_iam_policy_document" "manage_imds_endpoint" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:ModifyInstanceMetadataOptions",
    ]

    # Grant instance the ability to manage its own Instance Metadata service endpoint options
    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/${module.example.id}",
    ]
  }
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

# ----------------------------------------------------------------------------------------------------------------------
# FIGURE OUT WHAT INSTANCE TYPE IS AVAILABLE IN ALL AZS IN THE CURRENT AWS REGION
# ----------------------------------------------------------------------------------------------------------------------

module "instance_types" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-utilities.git//modules/instance-type?ref=v0.5.1"

  instance_types = var.instance_types
}
