variable "cluster_name" {
  type    = string
  default = "eks-cluster-dev"
}

variable "aws_region_2" {
  type    = string
  default = "us-east-1"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "kubernetes_version" {
  type    = string
  default = "1.33"
}

variable "system_node_desired_size" {
  type    = number
  default = 1
}

variable "enable_cluster_creator_admin_permissions" {
  type    = bool
  default = true
}
variable "single_nat_gateway" {
  type    = bool
  default = false
}
variable "system_node_min_size" {
  type    = number
  default = 1 // staging it should be 3, prod should be 3 for HA
}
variable "system_node_max_size" {
  type    = number
  default = 5
}