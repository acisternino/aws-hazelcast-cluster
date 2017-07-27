# Simple development Hazelcast cluster

> A [Terraform](https://www.terraform.io/) and [Packer](https://www.packer.io/)
> configuration for creating a simple [Hazelcast](https://hazelcast.org/) cluster
> on AWS.

The cluster is suited for development work and has the following characteristics:

* Runs inside a dedicated VPC.
* Hazelcast instances are located in a private subnet with access to the Internet
  through a NAT Gateway (e.g. for updates.)
* By default 4 `r4.large` instances are created.
* A *Work Instance* is created in a public subnet for deploying user code.
  This instance doubles as bastion host.
* All instances in the VPC can communicate with each other.
* Only one availability zone is used for simplicity.
* A pre-defined tag is assigned to all Hazelcast instances for easy service discovery.

## Table of Contents

- [Requisites](#requisites)
- [Deploying the cluster](#deploying-the-cluster)
    - [Build the Hazelcast AMI](#build-the-hazelcast-ami)
    - [Deploy the Hazelcast cluster](#deploy-the-hazelcast-cluster)
    - [Scale the cluster](#scale-the-cluster)
- [Troubleshooting](#troubleshooting)
    - [Problems creating or deleting the instance profile](#problems-creating-or-deleting-the-instance-profile)

## Requisites

1. An AWS account with the proper rights (see below.)
2. Terraform [installed on your system](https://www.terraform.io/intro/getting-started/install.html).
3. Packer [installed on your system](https://www.packer.io/docs/install/index.html).

AWS authentication is handled by either defining the two `AWS_ACCESS_KEY_ID` and
`AWS_SECRET_ACCESS_KEY` environment variables or by having a properly defined
`credentials` file in the `~/.aws` directory. If you have multiple profiles
defined there, you can instead define the `AWS_DEFAULT_PROFILE` environment
variable.

The rights needed by the user should allow working with IAM roles. The reason is
that the Terraform scripts create an Instance Role that is used by Hazelcast to
discover other members of the cluster. Please note that the _PowerUserAccess_
policy commonly used for development work does **not** contain the needed policies.

The following custom policy document contains the needed permissions and can be
assigned to a user or group (e.g. named _TerraformDeployer_) to allow working
with Terraform.

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
                "iam:PassRole",
                "iam:AddRoleToInstanceProfile",
                "iam:RemoveRoleFromInstanceProfile",
                "iam:CreateInstanceProfile",
                "iam:GetInstanceProfile",
                "iam:DeleteInstanceProfile",
                "iam:ListInstanceProfiles",
                "iam:ListInstanceProfilesForRole",
                "iam:GetRolePolicy",
                "iam:PutRolePolicy",
                "iam:DeleteRolePolicy"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```

You should also have an SSH key defined in your account and the corresponding
`pem` file available on your HD.

## Deploying the cluster

Cluster deployment is divided in two steps:

1. First an Hazelcast Server AMI is built with Packer.
2. The cluster can then be deployed using Terraform.

The [ami](ami/) directory contains the Packer scripts for creating an updated
Ubuntu 16.04 LTS AMI with the Hazelcast server configured and launched automatically
at boot time.

This AMI does not need to be built each time the cluster is deployed. Only before
the first deployment and when critical OS updates or new versions of Hazelcast
are released.

Before proceeding with building the AMI and deploying the cluster, a few resources
and identifiers must be defined and written in some files.

For building the AMI:

* A _prefix_ for the AMI name. This value will be prepended to the name as a
  path component to better identify the AMI. If e.g. you choose the prefix to be
  `foobar`, then the AMI name will be `foobar/hazelcast-server-X.Y.Z-YYYY-MM-DD`
  where `X.Y.Z` is the Hazelcast version and `YYY-MM-DD` the AMI creation date.
  
  The prefix must be specified in the command line when invoking Packer.
* Check the latest available versions of Hazelcast and of the
  [Hazelcast AWS](https://github.com/hazelcast/hazelcast-aws) project.
  
  If a new version has been released, change the values defined at the top of
  [hazelcast.json](ami/hazelcast.json) and submit a pull-request :)

For deploying the cluster:

* In the `cluster` directory, create an empty `private.tfvars` file that will contain
  sensitive information about the deployment. This file is excluded from the
  git repository to avoid sharing private information. The format of the file is
  that of [Terraform variables](https://www.terraform.io/docs/configuration/variables.html).

  Add the following variables to the file:
    * The AMI prefix defined previously when building the AMI. The var name is `ami_prefix`:
      ```
      ami_prefix = "foobar"
      ```
    * The AMI owner as seen in the AWS console. The var name is `ami_owner`:
      ```
      ami_owner = "123456789012"        # fake value :)
      ```
    * Define a CIDR that will be used for SSH access:
      ```
      source_cidr = "299.199.99.9/32"   # or "0.0.0.0/0" for open access
      ```
    * The name of an SSH key already registered with AWS.
      ```
      key_name = "my_ssh_key"
      ```
    * The corresponding private key file name:
      ```
      key_file = "~/path/to/my_ssh_key.pem"
      ```

An example of a `private.tfvars` file is:

```
#
# Private variables
#
source_cidr = "299.199.99.9/32"   # or "0.0.0.0/0" for open access

# AMI data
ami_prefix = "foobar"       # MUST be the same as the one used by Packer
ami_owner = "123456789012"

# SSH key handling
key_name = "my_ssh_key"
key_file = "~/path/to/my_ssh_key.pem"
```

After these configuration steps, we can finally proceed with the deployment.

### Build the Hazelcast AMI

Execute these steps in the `ami` directory.

1. Open the [hazelcast.json](hazelcast.json) file and eventually change the AWS
   region and the Hazelcast version to use.
2. Decide a _prefix_ for the resulting AMI name. This value will be prepended to
   the name as a path component to better identify the AMI.
3. Validate the template (change _myprefix_ to your chosen one!):
   ```
   $ packer validate --var 'ami_prefix=myprefix' hazelcast.json
   ```
4. If validation is successful, run the template:
   ```
   $ packer build --var 'ami_prefix=myprefix' hazelcast.json
   ```
5. If packer terminates correctly an Hazelcast Server AMI will be available in
   your account.
6. Verify that the AMI is available in your AWS console and save the owner account
   number in the `private.tfvars` file as stated above.

### Deploy the Hazelcast cluster

Execute these steps in the `cluster` directory.

1. Verify that the information in the `private.tfvars` file is correct and
   matches the AMI built in the previous step.
2. Check that the resources can be created:
   ```
   $ terraform plan -var-file=private.tfvars
   ```
3. If terraform reports no errors, deploy the cluster:
   ```
   $ terraform apply -var-file=private.tfvars
   ```
4. To destroy the cluster and free all the AWS resources, execute this command
   from the same directory:
   ```
   $ terraform destroy -var-file=private.tfvars
   ```

### Scaling the cluster

The number of Hazelcast instances in the cluster can be controlled using the
`hc_num` variable.

It can be used while creating the cluster or to change the number of instances
of a running cluster.

In both cases we have to tell terraform the new number and _apply_ the changes:
```
$ terraform apply -var-file=private.tfvars -var 'hc_num=6'
```

The previous command can create a 6 instances cluster from scratch or change the
state of an existing one.

Note that in the latter case the command **must** be executed in the same
directory where the terraform state file `terraform.tfstate` is located.

Other parameters can also be changed by setting variables either in the `tfvars`
files or directly on the command line.

## Troubleshooting

### Problems creating or deleting the instance profile

If you get error messages during a `plan` or `apply` phase because of an already existing
[instance profile](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html),
verify if the profile already exists, maybe as a leftover from a previous session:

```bash
$ aws iam list-instance-profiles | jq '.InstanceProfiles[].InstanceProfileName'
"hazelcast-instance-profile"
...
```
If, like above, this is the case, then the profile must be manually deleted
before trying again:

```bash
$ aws iam delete-instance-profile --instance-profile-name hazelcast-instance-profile
```
