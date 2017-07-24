/*
 * Simple Hazelcast cluster for development purposes.
 *
 * Hazelcast server instances.
 */

##---- Data -----------------------------------------------

data "aws_ami" "hazelcast_node" {
  most_recent = true

  owners = ["${var.ami_owner}"]

  filter {
    name   = "name"
    values = ["${var.ami_prefix}/hazelcast-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

##---- Hazelcast servers ----------------------------------

resource "aws_instance" "hazelcast" {
  count = "${var.hc_num}"

  ami           = "${data.aws_ami.hazelcast_node.id}"
  instance_type = "${var.hc_type}"
  key_name      = "${var.key_name}"
  subnet_id     = "${aws_subnet.private.id}"

  iam_instance_profile = "${aws_iam_instance_profile.hazelcast.id}"

  # Cluster members get the VPC default security group to
  # communicate with other instances in the VPC
  vpc_security_group_ids = ["${aws_vpc.main.default_security_group_id}"]

  # The "role" tag is extremely important because it is used by Hazelcast
  # for discovering other members of the cluster.
  # The name and value are currently hard-coded.
  tags = "${merge(var.tags, map("Name", "${var.name}-server-${count.index}"), map("role", "hazelcast-node"))}"
}

##---- Instance role --------------------------------------

resource "aws_iam_role" "hazelcast" {
  name        = "hazelcast-server-role"
  description = "Instance role for an Hazelcast instance"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "hazelcast" {
  name = "hazelcast-instance-profile"
  role = "${aws_iam_role.hazelcast.name}"
}

##---- Policies -------------------------------------------

# Add more policies here
resource "aws_iam_role_policy" "hazelcast" {
  name = "hazelcast-policy"
  role = "${aws_iam_role.hazelcast.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:Get*",
        "s3:List*"
      ],
      "Resource": "arn:aws:s3:::*"
    }
  ]
}
EOF
}
