# Route 53 Helpers Example

This folder contains an example of how to create an EC2 Instance that runs the `add-dns-a-record` script on boot to add
a DNS A record pointing to the Instance's IP address.

This example has been updated to leverage Instance Metadata Service Version 2, which includes a number of security enhancements against common threat vectors. [Read more about IMDSv2 here.](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html). In addition to using IMDSv2, this example also demonstrates how the server booting can request the information it needs from IMDSv2 (in this case, the instance ID), and then, once finished, disable instance metadata access entirely, for enhanced security.

See the [add-dns-a-record script](../../modules/route53-helpers/bin/add-dns-a-record) to view the implementation.

## How do you run this example?

To run this example, you need to do the following:

1. Build an AMI using Packer
1. Deploy the AMI using Terraform

These steps are described in detail next.

### Build an AMI using Packer

The code that runs the EC2 instance in this example is an [Amazon Machine Image
(AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) that has been defined in a [Packer
template](https://www.packer.io/) under `packer/build.pkr.hcl`. To build an AMI from this template:

1. Install [Packer](https://www.packer.io/).
1. Set up your [AWS credentials as environment variables](https://www.packer.io/docs/builders/amazon.html).
1. Run `packer build build.pkr.hcl` to create the AMI in your AWS account. Note down the ID of this new AMI.

### Deploy the AMI using Terraform

Now that you have an AMI, use Terraform to deploy it:

1. Install [Terraform](https://www.terraform.io/).
1. Open up `variables.tf` and set secrets at the top of the file as environment variables and fill in any other variables in
   the file that don't have defaults. This includes the `ami` variable which you should fill in with the ID of the
   AMI you just built with Packer.
1. `terraform get`.
1. `terraform plan`.
1. If the plan looks good, run `terraform apply`.

When the templates are applied, Terraform will output the IP address of the EC2 instance.
