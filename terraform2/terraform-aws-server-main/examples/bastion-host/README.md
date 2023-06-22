# Bastion Host Examples

This folder shows an example of how to use the [single-server module](/modules/single-server) to launch a
single EC2 instance that is meant to serve as a bastion host. A bastion host is a security best practice where it is
the *only* server exposed to the public. You must connect to it (e.g. via SSH) before you can connect to any of your
other servers, which are in private subnets. This way, you minimize the surface area you expose to attackers, and can
focus all your efforts on locking down just a single server.

## Quick start

To try these templates out you must have Terraform installed (minimum version: `0.6.11`):

1. Open `variables.tf`, set the environment variables specified at the top of the file, and fill in any other variables that
   don't have a default.
1. Run `terraform get`.
1. Run `terraform plan`.
1. If the plan looks good, run `terraform apply`.

## Why a Bastion Host?

Your team will need the ability to SSH directly to EC2 Instances. Should we then make these EC2 Instances publicly
accessible to the Internet?

No, because then we have multiple servers that represent potential attack vectors into your app. Instead, the best
practice is to have a single server that's exposed to the public -- a "bastion host" -- on which we can focus all our
efforts for locking down. It is a "bastion" or fortress on which we focus all our security resources versus diluting
our efforts across multiple servers.

As a result, we place the bastion host in the public subnet, and all other servers should be located in private subnets.
Once connected to the bastion host, you can then SSH to any other EC2 Instance.

## Bastion AMI

The bastion host can run any reasonably secure Linux distro. In this example, the default `ami` value is set to an
Ubuntu AMI.

It's possible to undertake more aggressive measures for securing the Bastion Host. For example, you could implement
[port knocking](https://www.digitalocean.com/community/tutorials/how-to-use-port-knocking-to-hide-your-ssh-daemon-from-attackers-on-ubuntu),
however there are [downsides](http://bsdly.blogspot.com/2012/04/why-not-use-port-knocking.html) to that approach.

Or we could install [Intrustion Detection Software](https://www.snort.org/), or prevent most SSH users from seeing
common directories like `/etc/`. But each of these has downsides as well because with most features we introduce, we
also add management overhead.

Therefore, we keep our default Bastion Host as simple as possible. 

## SSH access

Once you are logged into the Bastion Host, you are effectively "in the network" and you can then SSH from the Bastion
Host to any other EC2 instance in the account, including those in the private subnets of the VPC.

Since it takes two "hops" to SSH to your servers, the Bastion Host is often called an "SSH Jump Host" or "Jump Box." The
tricky part with jump hosts is that, while you have your SSH keys on your local computer, the bastion host does not. To
avoid copying keys around (which is a huge security risk!), the best way to work with a jump host is to use
**SSH Agent**.

`ssh-agent` runs on your local machine and is responsible for keeping all your private SSH keys in memory. When you SSH
to another instance, if `ssh-agent` is running and you don't explicitly specify a local key file to use for
authentication, your `ssh-agent` will automatically try each of your keys one by one to log into the instance. Don't
worry, your private keys are never transmitted; only used to participate in the SSH authentication process.

A companion tool to `ssh-agent` is `ssh-add`. You can use `ssh-add` to add some or all of your local SSH Keys to local
memory (note: if you add too many keys, you may get an error like "ran out of authentication methods to try" before it
finds your key). Then, when you connect to the jump host with the `-A` option, your SSH keys will also be available on
the jump host.

For example, let's say `bastion-v1.pem` was your Key Pair (AWS's term for SSH key) for the bastion host and
`stg-ec2-instances-v1.pem` was your Key Pair for the EC2 instances in the Stage VPC. Here is how you could use SSH
Agent to connect to an ec2 instance in the Stage VPC:

```
chmod 400 'bastion-v1.pem'            # You only need to do this once after downloading the Key Pair from AWS
chmod 400 'stg-ec2-instances-v1.pem'  # You only need to do this once after downloading the Key Pair from AWS
ssh-add 'stg-ec2-instances-v1.pem'
ssh -A -i 'bastion-v1.pem' ubuntu@<BASTION-IP-ADDRESS>

# Now you're on the bastion host
ssh ec2-user@<EC2-INSTANCE-PRIVATE-IP-ADDRESS>

# Now you're on the EC2 instance
```

Note: If you're using [ssh-iam](https://github.com/gruntwork-io/terraform-aws-security/tree/main/modules/ssh-iam) from the
[Security Package](https://github.com/gruntwork-io/terraform-aws-security), then you'll be able to SSH using your own
public key (instead of a Key Pair file) and your IAM username (instead of a shared account like ec2-user or ubuntu).
This simplifies the above commands to:

```
ssh -A <YOUR-USERNAME>@<BASTION-IP-ADDRESS>
ssh <YOUR-USERNAME>@<EC2-INSTANCE-PRIVATE-IP-ADDRESS>
```

## Known errors

When you run `terraform apply` on these templates the first time, you may see the following error:

```
* aws_iam_instance_profile.bastion: diffs didn't match during apply. This is a bug with Terraform and should be reported as a GitHub Issue.
```

As the error implies, this is a Terraform bug, but fortunately, it's a harmless one related to the fact that AWS is
eventually consistent, and Terraform occasionally tries to use a recently-created resource that isn't yet available.
Just re-run `terraform apply` and the error should go away.

## Using Port Forwarding with Your Bastion Host

#### Local Port Forwarding

When you connect via SSH to your Bastion Host, you may opt to expose certain ports using [SSH Local Port
Forwarding](http://unix.stackexchange.com/a/115906/129208). For example, you could SSH to the Bastion Host with
`ssh -L 8500:vault-instance.com:8500 mylogin@bastion-host.com`, which will open a listener at `localhost:8500` which is
routed to the Bastion Host where it is then further routed to `vault-instance.com:8500` *from the Bastion Host*. As a
result, just by connecting to http://localhost:8500 from your local machine, you could view, for example, the Consul UI
running on port 8500 on the private Vault instance.

#### SOCKS Proxy

What if you want to route all your web browsing through the Bastion Host? This is useful to appear to websites like you're
coming from a different IP address or different country.  It's also useful for ensuring all your web traffic is encrypted
since all requests, even to non-HTTPS sites, are tunneled through the Bastion Host.

To setup the Bastion Host as a SOCKS Proxy, simply run `ssh -D 5000 mylogin@bastion-host.com`. You now have a SOCKS Proxy
running at `localhost:5000`.  Now any app which is written to leverage a SOCKS Proxy can route all its requests through the
SOCKS Proxy instead of your local network connection.

For example, Firefox supports a SOCKS Proxy. See [one
example](http://lifehacker.com/237227/geek-to-live--encrypt-your-web-browsing-session-with-an-ssh-socks-proxy) of how
to configure it.
