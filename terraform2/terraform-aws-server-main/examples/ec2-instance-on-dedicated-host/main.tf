# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# LAUNCH THE BASTION HOST
# The bastion host is the sole point of entry to the network. This way, we can make all other servers inaccessible from
# the public Internet and focus our efforts on locking down the bastion host.
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

  # Only these AWS Account IDs may be operated on by this template
  allowed_account_ids = var.aws_account_ids
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

# ---------------------------------------------------------------------------------------------------------------------
# LAUNCH THE EC2 DEDICATED HOST
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_ec2_host" "dedicated_host" {
  instance_family   = "m5"
  availability_zone = data.aws_subnet.selected.availability_zone
  host_recovery     = "on"
  auto_placement    = "on"

  # We want to set the name of the resource with var.name, but all other tags should be settable with var.tags and var.instance_tags.
  tags = merge(
    { "Name" = "${var.name}-dedicated-host-test" }
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# LAUNCH THE EC2 INSTANCE ON DEDICATED HOST
# ---------------------------------------------------------------------------------------------------------------------

module "instance-test" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-server.git//modules/single-server?ref=v1.0.8"
  source = "../../modules/single-server"

  # EC2 Instance Vars
  name              = var.name
  instance_type     = var.instance_type
  dedicated_host_id = aws_ec2_host.dedicated_host.id
  ami               = data.aws_ami.ubuntu.image_id
  keypair_name      = var.keypair_name
  attach_eip        = var.attach_eip
  tenancy           = "host"

  vpc_id                   = data.aws_vpc.default.id
  subnet_id                = data.aws_subnet.selected.id
  allow_ssh_from_cidr_list = ["0.0.0.0/0"]

  tags = {
    Foo = "Bar"
  }
}

# To keep this example simple, we deploy the latest Ubuntu 20.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "image-type"
    values = ["machine"]
  }

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}
