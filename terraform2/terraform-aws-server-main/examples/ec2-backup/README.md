# EC2 Backup Example

This folder contains an example of how to create an EC2 backup policy that will create snapshots from targeted EBS volumes on a configurable schedule. 

This is useful for quickly and repeatbly configuring backup policies to protect against data loss or to ensure that you always have regular backups to launch instances from.

For ease of use and to help you get up and running quickly, this example will first create an EBS volume of 2GB in size. 

This EBS volume is tagged with the same tag that the backup module is configured to target. This means that the data lifecycle manager that is created will find the created EBS at the configured snapshot time.

## How do you run this example?

1. Install [Terraform](https://www.terraform.io/).
1. You can run this example as written without needing to configure any variables. If you want to change the variables to gain a better understanding of how the module works, you can open [variables.tf](./variables.tf)
1. `terraform init`.
1. `terraform apply`.

Terraform will output the ARN of the data lifecycle manager that was created, along with the ARN of the IAM role that was associated with it and the role's name.
