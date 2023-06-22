# EC2 Instance on Dedicated Host Example

This folder shows an example of how to use the [single-server module](/modules/single-server) to launch a
single EC2 instance on a dedicated EC2 host. EC2 Dedicated Hosts are physical servers with EC2 instance
capacity fully dedicated for your use. Dedicated Hosts support different configurations (physical cores,
sockets and VCPUs) which allow you to select and run instances of different families and sizes depending
as well as different architectures such as macOS workloads.

## Quick start

To try these templates out you must have Terraform installed (minimum version: `1.1.0`):

1. Open `variables.tf`, set the environment variables specified at the top of the file, and fill in any other variables that
   don't have a default.
1. Run `terraform get`.
1. Run `terraform plan`.
1. If the plan looks good, run `terraform apply`.
