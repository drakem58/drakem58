# EC2 Instance with custom IAM role

This folder shows an example of how to use the [single-server module](/modules/single-server) to launch a
single EC2 instance by passing a preexisting IAM role instead of the one internally created by the module.

IAM roles created programatically (e.g. through terraform) do not automatically create an instance profile,
to pass the role to an EC2 instance. In that case, the instance profile has to be created separately.

Internally, at the [single-server module](/modules/single-server) both an IAM role and an instance profile
are created, which are returned as an output so custom policies can be attached. Sometimes, however, one
might want to use a preexisting IAM role for the EC2 instance, which you can do by setting the `create_iam_role`
variable to `false` and passing the IAM role namee through the `iam_role_name` variable.

If you pass an IAM role created in Terraform externally to our module, it will create an instance profile to
pass this role to the EC2 instance. But IAM roles created at the aws console automatically create an instance
profile with the same name. In that case, the `create_instance_profile` variable must be set to `false`.

## Quick start

To try these templates out you must have Terraform installed (minimum version: `1.1.0`):

1. Open `variables.tf`, set the environment variables specified at the top of the file, and fill in any other variables that
   don't have a default.
1. Run `terraform get`.
1. Run `terraform plan`.
1. If the plan looks good, run `terraform apply`.
