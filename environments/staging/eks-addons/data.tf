data "aws_caller_identity" "current" {}

/*
data "aws_eks_cluster" "this" {
  name       = var.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "this" {
  name       = var.cluster_name
  depends_on = [module.eks]
}

output "cluster_token" {
  sensitive = true
  value     = data.aws_eks_cluster_auth.this.token
}
*/

data aws_ssm_parameter "cluster_access" {
  name = "/eks/eks_cluster/endpoint"
}

data aws_ssm_parameter "oidc_provider" {
  name = "/eks/eks_cluster/oidc_provider"
}

locals {
  cluster_access = jsondecode(data.aws_ssm_parameter.cluster_access.value)
}
