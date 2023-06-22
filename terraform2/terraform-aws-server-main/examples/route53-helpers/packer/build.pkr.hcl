
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "bash_commons_version" {
  type    = string
  default = "v0.1.8"
}

variable "github_token" {
  type    = string
  default = "${env("GITHUB_OAUTH_TOKEN")}"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "module_server_branch" {
  type    = string
  default = ""
}

data "amazon-ami" "example_ubuntu2004" {
  filters = {
    architecture                       = "x86_64"
    "block-device-mapping.volume-type" = "gp2"
    name                               = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
    root-device-type                   = "ebs"
    virtualization-type                = "hvm"
  }
  most_recent = true
  owners      = ["099720109477"]
  region      = "${var.aws_region}"
}

data "amazon-ami" "example_ubuntu1804" {
  filters = {
    architecture                       = "x86_64"
    "block-device-mapping.volume-type" = "gp2"
    name                               = "ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"
    root-device-type                   = "ebs"
    virtualization-type                = "hvm"
  }
  most_recent = true
  owners      = ["099720109477"]
  region      = "${var.aws_region}"
}

source "amazon-ebs" "gruntwork-route53-helpers-example-ubuntu2004" {
  ami_description = "An example of how to use the route53-helpers module to add a DNS A Record in Route 53 for an EC2 Instance with Ubuntu 20.04"
  ami_name        = "gruntwork-route53-helpers-example-ubuntu2004-${lower(regex_replace(timestamp(), ":", "-"))}"
  instance_type   = "${var.instance_type}"
  region          = "${var.aws_region}"
  source_ami      = "${data.amazon-ami.example_ubuntu2004.id}"
  ssh_username    = "ubuntu"
}

source "amazon-ebs" "gruntwork-route53-helpers-example-ubuntu1804" {
  ami_description = "An example of how to use the route53-helpers module to add a DNS A Record in Route 53 for an EC2 Instance with Ubuntu 18.04"
  ami_name        = "gruntwork-route53-helpers-example-ubuntu1804-${lower(regex_replace(timestamp(), ":", "-"))}"
  instance_type   = "${var.instance_type}"
  region          = "${var.aws_region}"
  source_ami      = "${data.amazon-ami.example_ubuntu1804.id}"
  ssh_username    = "ubuntu"
}

build {
  sources = ["source.amazon-ebs.gruntwork-route53-helpers-example-ubuntu2004", "source.amazon-ebs.gruntwork-route53-helpers-example-ubuntu1804"]

  provisioner "shell" {
    inline = ["echo 'Sleeping for 30 seconds to give the AMIs enough time to initialize (otherwise, packages may fail to install).'", "sleep 30", "echo 'Installing AWS cli pre-requisites...'", "sudo apt-get update && sudo apt-get install -y jq python unzip"]
  }

  provisioner "shell" {
    inline = ["echo 'Installing AWS CLI version 2'", "curl -s \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.2.44.zip\" -o \"awscliv2.zip\"", "unzip awscliv2.zip", "sudo ./aws/install", "rm awscliv2.zip"]
  }

  provisioner "shell" {
    inline = ["curl -Ls https://raw.githubusercontent.com/gruntwork-io/gruntwork-installer/v0.0.38/bootstrap-gruntwork-installer.sh | bash /dev/stdin --version v0.0.38"]
  }

  provisioner "shell" {
    environment_vars = ["GITHUB_OAUTH_TOKEN=${var.github_token}", "GRUNTWORK_BASH_COMMONS_IMDS_VERSION=2"]
    inline           = [
    "gruntwork-install --module-name 'bash-commons' --repo 'https://github.com/gruntwork-io/bash-commons' --tag '${var.bash_commons_version}'", 
    "gruntwork-install --module-name 'route53-helpers' --repo 'https://github.com/gruntwork-io/terraform-aws-server'  --branch '${var.module_server_branch}'", 
    "gruntwork-install --module-name 'disable-instance-metadata' --repo 'https://github.com/gruntwork-io/terraform-aws-server' --branch '${var.module_server_branch}'", 
    "gruntwork-install --module-name 'require-instance-metadata-service-version' --repo 'https://github.com/gruntwork-io/terraform-aws-server'  --branch '${var.module_server_branch}'",
    ]
  }

}
