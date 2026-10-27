data aws_ssm_parameter "cluster_access" {
  name = "/eks/eks_cluster_${var.env}/endpoint"
}

data aws_ssm_parameter "oidc_provider" {
  name = "/eks/eks_cluster_${var.env}/oidc_provider"
}

locals {
  cluster_access = jsondecode(data.aws_ssm_parameter.cluster_access.value)
}

locals {
  oidc_provider  = jsondecode(data.aws_ssm_parameter.oidc_provider.value)
  
}