/*
 * Simple Hazelcast cluster for development purposes.
 *
 * Copyright (c) 2017 Andrea Cisternino
 * Licensed under the Apache License, version 2.0.
 *
 * Instance roles and policies.
 */

##---- Data -----------------------------------------------

# Policy needed for actually using instance roles
data "aws_iam_policy_document" "assume_role" {
  statement {
    sid    = "AssumeRole"
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Policy used by software running on the instances to enumerate
# other members of the cluster
data "aws_iam_policy_document" "describe_instances" {
  statement {
    sid    = "DescribeInstances"
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
    ]

    resources = ["*"]
  }
}

##---- Instance role --------------------------------------

# WARNING! This could be left hanging in case of errors.
# Delete manually!
resource "aws_iam_instance_profile" "hazelcast" {
  name = "hazelcast-instance-profile"
  role = "${aws_iam_role.hazelcast.id}"
}

# The role name is hard-coded in the Hazelcast configuration file embedded
# in the AMI and used for cluster discovery.
# Use the same name if you overwrite the configuration.
resource "aws_iam_role" "hazelcast" {
  name               = "hazelcast-server-role"
  description        = "Instance role for an Hazelcast server instance"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

##---- Policies -------------------------------------------

resource "aws_iam_role_policy" "hazelcast_server" {
  name   = "hazelcast-server-policy"
  role   = "${aws_iam_role.hazelcast.id}"
  policy = "${data.aws_iam_policy_document.describe_instances.json}"
}
