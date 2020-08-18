variable "environment_name" {
  default = "multiarch-eks"
}

variable "eks_version" {
  default = "1.17"
}

variable "region" {
  default = "us-west-2"
}

variable "availability_zones" {
  type = list(string)
  default = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "node_pool_instance_type" {
  default = "m6g.medium"
}

variable "tags" {
  default = {}
}