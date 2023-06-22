# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE AN EC2 INSTANCE WITH A ROUTE 53 DNS A RECORD
# This template shows an example of how to create a standalone EC2 Instance that, when it boots, run a script in User
# Data that associate a Route 53 DNS A Record with the Instance's IP address. The EC2 Instance will also run a dummy
# HTTP server for testing.
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
# CREATE AN EC2 INSTANCE
# We are using the single-server module to create this instance, as it takes care of the common details like IAM
# Roles, Security Groups, etc.
# ---------------------------------------------------------------------------------------------------------------------

module "example" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-server.git//modules/single-server?ref=v0.0.40"
  source = "../../modules/single-server"

  name          = var.name
  instance_type = "t3.micro"
  ami           = var.ami
  keypair_name  = var.keypair_name

  allow_ssh_from_cidr_list = ["0.0.0.0/0"]
  vpc_id                   = var.vpc_id
  subnet_id                = var.subnet_id

  # The user data script will create the DNS A Record
  user_data = local.user_data
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE USER DATA SCRIPT TO RUN ON THE INSTANCE WHEN IT BOOTS
# This script will add the DNS A Record. It will also run a dummy HTTP server on the given port to return the given
# text.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  user_data = templatefile(
    "${path.module}/user-data/user-data.sh",
    {
      aws_region     = var.aws_region
      hosted_zone_id = var.hosted_zone_id
      hostname       = var.hostname
      server_text    = var.server_text
      server_port    = var.server_port
    },
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# ADD A SECURITY GROUP RULE THAT ALLOWS THE EC2 INSTANCE TO RECEIVE HTTP REQUESTS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group_rule" "allow_inbound_http" {
  type              = "ingress"
  from_port         = var.server_port
  to_port           = var.server_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.example.security_group_id
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH AN IAM POLICY THAT ALLOWS THE INSTANCE TO SET DNS RECORDS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_policy" "change_resource_record_sets" {
  name        = "${var.name}-change-resource-record-sets-${var.hosted_zone_id}"
  description = "Allows ${var.name} to change Resource Record Sets in hosted zone ${var.hosted_zone_id}"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Action": "route53:ChangeResourceRecordSets",
      "Effect": "Allow",
      "Resource": "arn:aws:route53:::hostedzone/${var.hosted_zone_id}"
    }
  ]
}
EOF

}

resource "aws_iam_policy_attachment" "attach_change_resource_record_sets" {
  name       = "attach-change-resource-record-sets"
  roles      = [module.example.iam_role_id]
  policy_arn = aws_iam_policy.change_resource_record_sets.arn
}

# -------------------------------------------------------------------------------------------------------------------------
# ATTACH AN IAM POLICY THAT ALLOWS THE INSTANCE TO DISABLE EC2 METADATA ENDPOINT ACCESS
# -------------------------------------------------------------------------------------------------------------------------
resource "aws_iam_policy" "disable_ec2_metadata_access" {
  name        = "${var.name}-disable-ec2-metadata-access"
  description = "Allows ${var.name} to disable access to ec2 instance metadata once it's no longer needed"
  policy      = data.aws_iam_policy_document.disable_ec2_metadata_access.json
}

data "aws_iam_policy_document" "disable_ec2_metadata_access" {
  statement {
    sid = "DisableEc2MetadataAccess"

    actions = [
      "ec2:ModifyInstanceMetadataOptions"
    ]

    resources = [
      # Get the EC2 Instance ARN from the module
      "${module.example.arn}"
    ]
  }
}

resource "aws_iam_policy_attachment" "attach_disable_ec2_metadata_access" {
  name       = "attach-disable-ec2-metadata-access"
  roles      = [module.example.iam_role_id]
  policy_arn = aws_iam_policy.disable_ec2_metadata_access.arn
}
