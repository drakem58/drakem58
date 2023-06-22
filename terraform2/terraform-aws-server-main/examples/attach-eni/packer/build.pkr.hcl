
variable "aws_region" {
  type    = string
  default = "us-east-1"
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

data "amazon-ami" "al2" {
  filters = {
    name                = "amzn2-ami-hvm-*-x86_64-gp2"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["amazon"]
  region      = "${var.aws_region}"
}

data "amazon-ami" "amazon_linux" {
  filters = {
    name                = "amzn-ami-hvm-*-x86_64-gp2"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["137112412989"]
  region      = "${var.aws_region}"
}

data "amazon-ami" "ubuntu_1804" {
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

data "amazon-ami" "ubuntu_2004" {
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

data "amazon-ami" "centos" {
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

source "amazon-ebs" "gruntwork-attach-eni-example-al2" {
  ami_description = "An example of how to use the attach-eni script to attach ENIs to an Amazon Linux 2 instance"
  ami_name        = "gruntwork-attach-eni-example-al2-${lower(regex_replace(timestamp(), ":", "-"))}"
  instance_type   = "${var.instance_type}"
  region          = "${var.aws_region}"
  source_ami      = "${data.amazon-ami.al2.id}"
  ssh_username    = "ec2-user"
}

source "amazon-ebs" "gruntwork-attach-eni-example-amazon-linux" {
  ami_description = "An example of how to use the attach-eni script to attach ENIs to an Amazon Linux instance"
  ami_name        = "gruntwork-attach-eni-example-amazon-linux-${lower(regex_replace(timestamp(), ":", "-"))}"
  instance_type   = "${var.instance_type}"
  region          = "${var.aws_region}"
  source_ami      = "${data.amazon-ami.amazon_linux.id}"
  ssh_username    = "ec2-user"
}

source "amazon-ebs" "gruntwork-attach-eni-example-ubuntu1804" {
  ami_description = "An example of how to use the attach-eni script to attach ENIs to an Ubuntu 18.04 instance"
  ami_name        = "gruntwork-attach-eni-example-ubuntu1804-${lower(regex_replace(timestamp(), ":", "-"))}"
  instance_type   = "${var.instance_type}"
  region          = "${var.aws_region}"
  source_ami      = "${data.amazon-ami.ubuntu_1804.id}"
  ssh_username    = "ubuntu"
}

source "amazon-ebs" "gruntwork-attach-eni-example-ubuntu2004" {
  ami_description = "An example of how to use the attach-eni script to attach ENIs to an Ubuntu 20.04 instance"
  ami_name        = "gruntwork-attach-eni-example-ubuntu-${lower(regex_replace(timestamp(), ":", "-"))}"
  instance_type   = "${var.instance_type}"
  region          = "${var.aws_region}"
  source_ami      = "${data.amazon-ami.ubuntu_2004.id}"
  ssh_username    = "ubuntu"
}

source "amazon-ebs" "gruntwork-attach-eni-example-centos" {
  ami_description = "An example of how to use the attach-eni script to attach ENIs to a CentOS instance"
  ami_name        = "gruntwork-attach-eni-example-centos-${lower(regex_replace(timestamp(), ":", "-"))}"
  instance_type   = "${var.instance_type}"
  region          = "${var.aws_region}"
  source_ami      = "${data.amazon-ami.centos.id}"
  ssh_username    = "centos"
}

build {
  sources = [
    "source.amazon-ebs.gruntwork-attach-eni-example-al2",
    "source.amazon-ebs.gruntwork-attach-eni-example-amazon-linux",
    "source.amazon-ebs.gruntwork-attach-eni-example-ubuntu1804",
    "source.amazon-ebs.gruntwork-attach-eni-example-ubuntu2004",
    "source.amazon-ebs.gruntwork-attach-eni-example-centos",
  ]

  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo yum install epel-release -y",
      "sudo yum install -y python3 python3-pip jq",
      "sudo pip3 install awscli",
    ]
    only         = ["amazon-ebs.gruntwork-attach-eni-example-centos"]
    pause_before = "30s"
  }

  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo yum install epel-release -y",
      "sudo yum install -y python3 python35-pip jq",
      "sudo pip install awscli",
    ]
    only         = ["amazon-ebs.gruntwork-attach-eni-example-amazon-linux"]
    pause_before = "30s"
  }

  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install epel",
      "sudo yum install -y python3 python3-pip jq",
      "sudo pip3 install awscli",
    ]
    only         = ["amazon-ebs.gruntwork-attach-eni-example-al2"]
    pause_before = "30s"
  }

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-pip jq",
      "sudo pip3 install awscli",
    ]
    only = [
      "amazon-ebs.gruntwork-attach-eni-example-ubuntu2004",
      "amazon-ebs.gruntwork-attach-eni-example-ubuntu1804",
    ]
    pause_before = "30s"
  }

  provisioner "shell" {
    environment_vars = ["GITHUB_OAUTH_TOKEN=${var.github_token}"]
    inline = [
      "curl -Ls https://raw.githubusercontent.com/gruntwork-io/gruntwork-installer/main/bootstrap-gruntwork-installer.sh | bash /dev/stdin --version v0.0.38",
      "gruntwork-install --module-name 'attach-eni' --repo 'https://github.com/gruntwork-io/terraform-aws-server' --tag '${var.module_server-tag}' --branch '${var.module_server_branch}'",
    ]
  }

}
