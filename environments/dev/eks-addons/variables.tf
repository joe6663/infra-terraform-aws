variable "cluster_name" {
  type    = string
  default = "eks-cluster"
}

variable "aws_region_2" {
  type    = string
  default = "us-east-1"
}

variable "aws_namespaced_user_name" {
  type = map(string)
  default = {
    dev1 = "dev1"
    dev2 = "dev2"
  }
}

variable "env" {
  type    = string
  default = "dev"
}
