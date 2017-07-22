#
# Global variables
#

name = "hazelcast"

# This MUST be the same as the one in the packer build file
ami_prefix = "anci"

region = "eu-central-1"
vpc_cidr = "10.27.0.0/16"
hc_num = 1

# Common tags
tags = {
  cluster-name = "hermes"
  project      = "hazelcast-cluster"
  creator      = "Andrea Cisternino"
  built-with   = "terraform"
}
