terraform {
  # This module is now only being tested with Terraform 1.1.x. However, to make upgrading easier, we are setting 1.0.0 as the minimum version.
  required_version = ">= 1.0.0"
}

# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ---------------------------------------------------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region
}

locals {
  target_tags = {
    Snapshot = "Ec2BackupTest"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN AWS ELASTIC BLOCK STORE (EBS) VOLUME
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_ebs_volume" "test" {
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = 2

  # We tag the EBS volume with the same tag value the data lifecycler manager will use to target volumes for snapshotting
  tags = local.target_tags
}

# ---------------------------------------------------------------------------------------------------------------------
# USE THE EC2-BACKUP MODULE TO CONFIGURE BACKUPS FOR THE EBS VOLUME
# ---------------------------------------------------------------------------------------------------------------------

module "ec2-backup" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-server.git//modules/ec2-backup?ref=v0.8.3"
  source = "../../modules/ec2-backup"

  # You can optionally enable or disable the data lifecycle manager policy
  backup_enabled = true

  # For the purposes of CI / testing, we need unique schedule and role names for each test run
  schedule_name = var.schedule_name
  dlm_role_name = var.dlm_role_name

  # Any volumes that have this tag will be targeted for snapshots by the data lifecycle manager
  # Note that this is the same tag we added to the EBS volume that we created above
  target_tags = local.target_tags

  # This is currently the only interval_unit supported by the data lifecycle manager policy
  interval_unit = "HOURS"

  # How often the lifecycle policy should be evaluated. In this case, we're specifying that the snapshots should be taken every 24 hours
  interval = 24

  # This specifies when the snapshots should be taken: at 11:45 PM each night
  times = ["23:45"]

  # The number of snapshots to retain. Must be an integer between 1 and 1000
  number_of_snapshots_to_retain = 7

  # An optional tag to be appended to the snapshots tags
  tags_to_add = {
    Additional = "AnExtraTag"
  }

  # We don't need to copy tags existing on the target volume to the resulting snapshot
  copy_tags = false
}

# ---------------------------------------------------------------------------------------------------------------------
# USE A DATA SOURCE TO SELECT AN AVAILABILITY ZONE WITHIN THE CONFIGURED REGION
# ---------------------------------------------------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}
