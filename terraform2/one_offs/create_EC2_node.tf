# terraform version stub, this is used to be sure we are running at the very least 1.0

provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.medium"
  key_name      = "mykey"
  subnet_id     = "subnet-0ce05258d952c1cc1"

  tags = {
    Name = "Nessus2"
  }
}
