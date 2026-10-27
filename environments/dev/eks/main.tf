module "eks_vpc" {
  source = "../../../modules/eks"

  # Environment / General
  env          = var.env
  cluster_name = var.cluster_name

  # VPC Inputs
  name               = "EKS-DEV-VPC"
  cidr               = "172.0.0.0/16"
  azs                = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets    = ["172.0.1.0/24", "172.0.3.0/24", "172.0.5.0/24"]
  public_subnets     = ["172.0.2.0/24", "172.0.4.0/24", "172.0.6.0/24"]
  single_nat_gateway = var.single_nat_gateway



  # EKS Inputs
  kubernetes_version                       = var.kubernetes_version
  system_node_desired_size                 = var.system_node_desired_size
  system_node_min_size                     = var.system_node_min_size
  system_node_max_size                     = var.system_node_max_size
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
  coredns_values_json                      = jsonencode(yamldecode(file("${path.module}/coredns-values.yaml")))
  //ebs_csi_values_json                      = jsonencode(yamldecode(file("${path.module}/ebs-csi-values.yaml")))

  tags = {
    Environment = "DEV"
  }
}