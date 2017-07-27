/*
 * Simple Hazelcast cluster for development purposes.
 *
 * Main infrastructure.
 */

##---- Global variables ----------------------------------

variable "name" {
  description = "A common name prefix used when naming the resources."
}

variable "region" {
  description = "The AWS region to use."
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  description = "CIDR of the main VPC."
  default     = "10.27.0.0/16"
}

variable "key_name" {
  description = "Name of the SSH key as registered in AWS."
}

variable "key_file" {
  description = "File name of the private SSH key corresponding to the key_name."
}

variable "source_cidr" {
  description = "Source CIDR used for SSH access."
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = "map"
}

variable "worker_type" {
  description = "EC2 instance type for the work node."
  default     = "t2.medium"
}

##---- Hazelcast ------------------------------------------

variable "ami_prefix" {
  description = "Prefix used when searching the Hazelcast Server AMI."
}

variable "ami_owner" {
  description = "Owner of the Hazelcast Server AMI."
}

variable "hc_type" {
  description = "EC2 instance type for the Hazelcast servers."
  default     = "r4.large"
}

variable "hc_num" {
  description = "Number of Hazelcast servers to launch."
  default     = "4"
}

##---- Data -----------------------------------------------

data "aws_availability_zones" "all" {}

# Ubuntu Linux AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# data "http" "myip" {
#   url = "http://ipinfo.io/ip"
#
#   request_headers {
#     "Accept" = "text/plain"
#   }
# }

##---- Outputs ------------------------------------------

output "worker_ip" {
  description = "Public address of the work node."
  value       = "${aws_instance.worker.public_ip}"
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = "${aws_vpc.main.id}"
}

##---- Providers ------------------------------------------

provider "aws" {
  region = "${var.region}"
}

/**********************************************************
** Main code
**********************************************************/

##---- VPC ------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags = "${merge(var.tags, map("Name", "${var.name}-vpc"))}"
}

##---- Internet Gateway -----------------------------------

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = "${merge(var.tags, map("Name", "${var.name}-igw"))}"
}

##---- Subnets --------------------------------------------

# One public subnet
resource "aws_subnet" "public" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "${cidrsubnet(aws_vpc.main.cidr_block, 4, 0)}"

  tags = "${merge(var.tags, map("Name", "${var.name}-public"))}"
}

# One private subnet
resource "aws_subnet" "private" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "${cidrsubnet(aws_vpc.main.cidr_block, 4, 1)}"

  tags = "${merge(var.tags, map("Name", "${var.name}-private"))}"
}

##---- Route tables ---------------------------------------

# Give a name to the default routing table that comes with the VPC
resource "aws_default_route_table" "default" {
  default_route_table_id = "${aws_vpc.main.default_route_table_id}"

  tags = "${merge(var.tags, map("Name", "${var.name}-main-rt"))}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.main.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.igw.id}"
}

# Route table for the private subnet
resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.main.id}"

  # The default route, mapping the VPC's CIDR block to "local", is created
  # implicitly and cannot be specified.

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat_gw.id}"
  }
  tags = "${merge(var.tags, map("Name", "${var.name}-private-rt"))}"
}

resource "aws_route_table_association" "private-rta" {
  subnet_id      = "${aws_subnet.private.id}"
  route_table_id = "${aws_route_table.private.id}"
}

##---- NAT Gateway ----------------------------------------

resource "aws_nat_gateway" "nat_gw" {
  subnet_id     = "${aws_subnet.public.id}"
  allocation_id = "${aws_eip.nat_ip.id}"

  depends_on = ["aws_eip.nat_ip"]
}

##---- Elastic IP -----------------------------------------

# Public IP for the NAT gateway
resource "aws_eip" "nat_ip" {
  vpc = true
}

##---- Work node ------------------------------------------

resource "aws_instance" "worker" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "${var.worker_type}"
  key_name      = "${var.key_name}"
  subnet_id     = "${aws_subnet.public.id}"
  user_data     = "${file("./scripts/update.sh")}"

  # Same role as servers for allowing auto discovery
  iam_instance_profile = "${aws_iam_instance_profile.hazelcast.name}"

  depends_on = ["aws_internet_gateway.igw"]

  associate_public_ip_address = true

  vpc_security_group_ids = [
    "${aws_security_group.worker.id}",
    "${aws_vpc.main.default_security_group_id}",
  ]

  tags = "${merge(var.tags, map("Name", "${var.name}-work-node"))}"
}

##---- Security groups ------------------------------------

# SSH and HTTP access from the outside world
resource "aws_security_group" "worker" {
  name        = "Restricted SSH and HTTP"
  description = "SSH and HTTP access from local IP"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.source_cidr}"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["${var.source_cidr}"]
  }

  # "ping" support
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["${var.source_cidr}"]
  }

  # Outgoing access open to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(var.tags, map("Name", "${var.name}-ssh-http-sg"))}"
}
