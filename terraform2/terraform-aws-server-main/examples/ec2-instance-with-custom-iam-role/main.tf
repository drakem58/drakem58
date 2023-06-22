# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# LAUNCH EC2 INSTANCE WITH CUSTOM IAM ROLE
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
# CREATE IAM ROLE
# To exemplify passing a pre-existing IAM role to the single-server module
# ---------------------------------------------------------------------------------------------------------------------


resource "aws_iam_role" "example" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.example.json
}

data "aws_iam_policy_document" "example" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = var.assume_role_principals
    }
  }
}

# Note: Creating an instance profile externally to the single-server module is normally not necessary
# to pass a custom IAM role to it, if the IAM role is created programatically like it is being done
# above (instead of through the AWS console). This is here for test purposes only.
resource "aws_iam_instance_profile" "instance" {
  name = var.name
  role = var.name
}

# ---------------------------------------------------------------------------------------------------------------------
# LAUNCH THE EC2 INSTANCE 
# ---------------------------------------------------------------------------------------------------------------------

module "instance-test" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-server.git//modules/single-server?ref=v1.0.8"
  source = "../../modules/single-server"

  # EC2 Instance Vars
  name          = var.name
  instance_type = var.instance_type
  ami           = data.aws_ami.ubuntu.image_id
  keypair_name  = var.keypair_name
  attach_eip    = var.attach_eip

  create_iam_role = false                   # disables creation of IAM role inside module
  iam_role_name   = aws_iam_role.example.id # passes name of role created externally

  # The creation of an instance profile in the single-server module might need to be disabled or not,
  # depending on how the external IAM role was created. If it was created in the AWS Console, an
  # instance profile was automatically created, so this needs to be set to false. If the IAM role
  # was created programatically (e.g.through terraform) an instance profile still needs to be
  # created separately. That can be the one created inside the module already. In that case, the
  # create_instance_profile variable doesn't need to be set (default is true), and that instance
  # profile will pass your custom IAM role to the EC2 instance.
  #
  # For testing purposes only, an instance profile was created programatically in this example,
  # so we are setting this false.
  create_instance_profile = false

  vpc_id                   = data.aws_vpc.default.id
  subnet_id                = data.aws_subnet.selected.id
  allow_ssh_from_cidr_list = ["0.0.0.0/0"]
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
