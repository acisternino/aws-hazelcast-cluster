/*
 * Simple Hazelcast cluster for development purposes.
 *
 * Copyright (c) 2017 Andrea Cisternino
 * Licensed under the Apache License, version 2.0.
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

  iam_instance_profile = "${aws_iam_instance_profile.hazelcast.name}"

  depends_on = ["aws_route_table.private"]

  # Cluster members get the VPC default security group to
  # communicate with other instances in the VPC
  vpc_security_group_ids = ["${aws_vpc.main.default_security_group_id}"]

  # The "role" tag is extremely important because it is used by Hazelcast
  # for discovering other members of the cluster.
  # The name and value are currently hard-coded.
  tags = "${merge(var.tags, map("Name", "${var.name}-server-${count.index}", "role", "hazelcast-node"))}"
}
