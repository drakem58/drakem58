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
# LAUNCH THE BASTION HOST
# ---------------------------------------------------------------------------------------------------------------------

module "bastion" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-server.git//modules/single-server?ref=v1.0.8"
  source = "../../modules/single-server"

  name             = var.name
  instance_type    = module.instance_types.recommended_instance_type
  ami              = var.ami
  keypair_name     = var.keypair_name
  user_data_base64 = data.cloudinit_config.cloud_init.rendered
  attach_eip       = var.attach_eip

  vpc_id                   = var.vpc_id
  subnet_id                = var.subnet_id
  allow_ssh_from_cidr_list = ["0.0.0.0/0"]

  tags = {
    Foo = "Bar"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# USE CLOUD-INIT SCRIPT TO INITIALIZE THE BASTION
# The data sources below use a template and a cloud-init config snippet to set up the system on first boot.
# See the provider documentation: https://www.terraform.io/docs/providers/template/d/cloudinit_config.html
# ---------------------------------------------------------------------------------------------------------------------

data "cloudinit_config" "cloud_init" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "bastion-default-cloud-init"
    content_type = "text/x-shellscript"
    content      = local.user_data
  }
}

locals {
  user_data = file("${path.module}/user-data.sh")
}

# ----------------------------------------------------------------------------------------------------------------------
# FIGURE OUT WHAT INSTANCE TYPE IS AVAILABLE IN ALL AZS IN THE CURRENT AWS REGION
# ----------------------------------------------------------------------------------------------------------------------

module "instance_types" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-utilities.git//modules/instance-type?ref=v0.5.1"

  instance_types = var.instance_types
}
