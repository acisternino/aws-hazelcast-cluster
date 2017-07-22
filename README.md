# Simple development Hazelcast cluster

A [Terraform](https://www.terraform.io/) configuration for creating a simple
[Hazelcast](https://hazelcast.org/) cluster on AWS suited for development.

## Prerequisites

1. An AWS account with enough rights (see below.)
2. Terraform installed on your system.
3. [Packer](https://www.packer.io/) installed on your system.

### Needed policies

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
