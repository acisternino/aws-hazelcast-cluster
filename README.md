# Simple development Hazelcast cluster

A [Terraform](https://www.terraform.io/) and [Packer](https://www.packer.io/)
configuration for creating a simple [Hazelcast](https://hazelcast.org/) cluster
on AWS.

The cluster is suited for developement work and has the following characteristics:

* Created in a custom VPC.
* Hazelcast instances are located in a private subnet with access to the internet
  through a NAT Gateway (e.g. for updates.)
* By default 4 `r4.large` instances will be created.
* A bastion host for public access located in a public subnet.
* All instances in the VPC can communicate with each other.

## Requisites

1. An AWS account with enough rights (see below.)
2. Terraform [installed on your system](https://www.terraform.io/intro/getting-started/install.html).
3. Packer [installed on your system](https://www.packer.io/docs/install/index.html).

## Deploying the cluster

In order to speed-up cluster deployment, the [ami](ami/) directory contains a
Packer script to create an updated Ubuntu Xenial AMI with the Hazelcast server
configured and launched automatically.

This AMI must be built once before the first deployment and when critical OS
updates or new versions of Hazelcast are released.

### Build the Hazelcast AMI

Execute these steps in the `ami` directory.

1. Check the [hazelcast.json](hazelcast.json) file and eventually change the AWS
   region and the Hazelcast version to use.
2. Decide a _prefix_ for the resulting AMI name. This value will be prepended to
   the name as a path component to better identify the AMI.
3. Validate the template (change _myprefix_ to your chosen one!):
   ```
   packer validate --var 'ami_prefix=myprefix' hazelcast.json 
   ```
4. If validation is sucessful, run the template:
   ```
   packer build --var 'ami_prefix=myprefix' hazelcast.json 
   ```
5. If packer terminates correctly an Hazelcast Server AMI will be available in
   your account.

## AWS credentials

The script can be run only if the AWS user has the following permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateRole",
                "iam:GetRole",
                "iam:DeleteRole",
                "iam:CreateInstanceProfile",
                "iam:GetInstanceProfile",
                "iam:ListInstanceProfilesForRole",
                "iam:GetRolePolicy",
                "iam:PutRolePolicy",
                "iam:DeleteRolePolicy"
            ],
            "Resource": [
                "arn:aws:iam::*:*"
            ]
        }
    ]
}
```

The above policy document can be used to create a custom Role and attach it
to a group or user.

These permissions are needed because the Terraform script tries to create an
instance role for the Hazelcast instances.
