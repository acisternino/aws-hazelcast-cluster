#
# Global variables
#

name = "hazelcast"

region = "eu-central-1"
vpc_cidr = "10.27.0.0/16"
hc_num = 4

# Common tags
tags = {
  cluster-name = "hermes"
  project      = "hazelcast-cluster"
  built-with   = "terraform"
  environment  = "development"
}
