module "eks_vpc" {
  source = "../../../modules/eks"

  # Environment / General
  env          = var.env
  cluster_name = var.cluster_name

  # VPC Inputs
  name               = "EKS-DEV-VPC"
  cidr               = "172.0.0.0/16"
  azs                = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets    = ["172.0.10.0/24", "172.0.30.0/24", "172.0.50.0/24"]
  public_subnets     = ["172.0.20.0/24", "172.0.40.0/24", "172.0.60.0/24"]
  single_nat_gateway = false



  # EKS Inputs
  kubernetes_version                       = var.kubernetes_version
  system_node_desired_size                 = var.system_node_desired_size
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
  coredns_values_json                      = jsonencode(yamldecode(file("${path.module}/coredns-values.yaml")))

  tags = {
    Environment = "STAGING"
  }
}