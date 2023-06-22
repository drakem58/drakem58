
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

variable "module_server-tag" {
  type    = string
  default = "~>v0.15.2"
}

variable "module_server_branch" {
  type    = string
  default = ""
}

variable "repo_base_url" {
  type    = string
  default = "https://github.com/gruntwork-io"
}

data "amazon-ami" "amazon_ami" {
  filters = {
    architecture                       = "x86_64"
    "block-device-mapping.volume-type" = "gp2"
    name                               = "*amzn-ami-hvm-*"
    root-device-type                   = "ebs"
    virtualization-type                = "hvm"
  }
  most_recent = true
  owners      = ["amazon"]
  region      = "${var.aws_region}"
}

data "amazon-ami" "ubuntu_18_ami" {
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

data "amazon-ami" "ubuntu_20_ami" {
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

data "amazon-ami" "centos_ami" {
  filters = {
    architecture                       = "x86_64"
    "block-device-mapping.volume-type" = "gp2"
    name                               = "CentOS-7*"
    root-device-type                   = "ebs"
    virtualization-type                = "hvm"
    product-code                       = "cvugziknvmxgqna9noibqnnsy"
  }
  most_recent = true
  owners      = ["aws-marketplace"]
  region      = "${var.aws_region}"
}


source "amazon-ebs" "amazon-ami" {
  ami_description = "An example of how to use the persistent-ebs-volume module to attach persistent EBS volumes to an Amazon Linux instance"
  ami_name        = "gruntwork-persistent-ebs-volume-example-amazon-${lower(regex_replace(timestamp(), ":", "-"))}"
  instance_type   = "${var.instance_type}"
  region          = "${var.aws_region}"
  source_ami      = "${data.amazon-ami.amazon_ami.id}"
  ssh_username    = "ec2-user"
}

source "amazon-ebs" "ubuntu-18-ami" {
  ami_description = "An example of how to use the persistent-ebs-volume module to attach persistent EBS volumes to an Ubuntu 18.04 instance"
  ami_name        = "gruntwork-persistent-nvme-ebs-volume-example-ubuntu-18-${lower(regex_replace(timestamp(), ":", "-"))}"
  instance_type   = "${var.instance_type}"
  region          = "${var.aws_region}"
  source_ami      = "${data.amazon-ami.ubuntu_18_ami.id}"
  ssh_username    = "ubuntu"
}

source "amazon-ebs" "ubuntu-20-ami" {
  ami_description = "An example of how to use the persistent-ebs-volume module to attach persistent EBS volumes to an Ubuntu 20.04 instance"
  ami_name        = "gruntwork-persistent-nvme-ebs-volume-example-ubuntu-20-${lower(regex_replace(timestamp(), ":", "-"))}"
  instance_type   = "${var.instance_type}"
  region          = "${var.aws_region}"
  source_ami      = "${data.amazon-ami.ubuntu_20_ami.id}"
  ssh_username    = "ubuntu"
}

source "amazon-ebs" "centos-ami" {
  ami_description = "An example of how to use the persistent-ebs-volume module to attach persistent EBS volumes to a CentOS instance"
  ami_name        = "gruntwork-persistent-nvme-ebs-volume-example-centos-${lower(regex_replace(timestamp(), ":", "-"))}"
  instance_type   = "${var.instance_type}"
  region          = "${var.aws_region}"
  source_ami      = "${data.amazon-ami.centos_ami.id}"
  ssh_username    = "centos"
}

build {
  sources = [
    "source.amazon-ebs.amazon-ami",
    "source.amazon-ebs.ubuntu-18-ami",
    "source.amazon-ebs.ubuntu-20-ami",
    "source.amazon-ebs.centos-ami",
  ]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y curl python3-pip jq nvme-cli unzip",
      "echo 'Installing AWS CLI version 2'",
      "curl -s \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.2.44.zip\" -o \"awscliv2.zip\"",
      "unzip awscliv2.zip",
      "sudo ./aws/install",
      "rm awscliv2.zip",
    ]
    only = [
      "amazon-ebs.ubuntu-20-ami",
      "amazon-ebs.ubuntu-18-ami",
    ]
    pause_before = "30s"
  }

  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo yum install epel-release -y",
      "sudo yum install -y curl python35-pip jq nvme-cli unzip",
      "curl -s \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.2.44.zip\" -o \"awscliv2.zip\"",
      "unzip awscliv2.zip",
      "sudo ./aws/install",
      "rm awscliv2.zip",
    ]
    only         = ["amazon-ebs.amazon-ami"]
    pause_before = "30s"
  }

  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo yum install epel-release -y",
      "sudo yum install -y curl python3-pip jq unzip nvme-cli",
      "echo 'Installing AWS CLI version 2'",
      "curl -s \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.2.44.zip\" -o \"awscliv2.zip\"",
      "unzip awscliv2.zip",
      "sudo ./aws/install",
      "rm awscliv2.zip",
    ]
    only         = ["amazon-ebs.centos-ami"]
    pause_before = "30s"
  }

  provisioner "shell" {
    inline = ["curl -Ls https://raw.githubusercontent.com/gruntwork-io/gruntwork-installer/main/bootstrap-gruntwork-installer.sh | bash /dev/stdin --version v0.0.38"]
  }

  provisioner "shell" {
    environment_vars = ["GITHUB_OAUTH_TOKEN=${var.github_token}"]
    inline = [
      "gruntwork-install --module-name 'bash-commons' --repo 'https://github.com/gruntwork-io/bash-commons' --tag '${var.bash_commons_version}'",
      "gruntwork-install --module-name 'persistent-ebs-volume' --repo '${var.repo_base_url}/terraform-aws-server' --tag '${var.module_server-tag}' --branch '${var.module_server_branch}'",
      "gruntwork-install --module-name 'disable-instance-metadata' --repo 'https://github.com/gruntwork-io/terraform-aws-server' --tag '${var.module_server-tag}' --branch '${var.module_server_branch}'",
      "gruntwork-install --module-name 'require-instance-metadata-service-version' --repo 'https://github.com/gruntwork-io/terraform-aws-server' --tag '${var.module_server-tag}' --branch '${var.module_server_branch}'",
    ]
  }
}
