/*
output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "cluster_arn" { value = module.eks.cluster_arn }
output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data # Ensure 'this' matches your resource label
}
output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the EKS cluster"
  value       = module.eks.cluster_oidc_issuer_url
}

// new outputs 

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider for IRSA configurations"
  value       = module.eks.oidc_provider_arn
}
*/

output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster"
  value       = module.eks-cluster.cluster_endpoint
}

resource "aws_ssm_parameter" "cluster_access" {
  name  = "/eks/eks_cluster_${var.env}/endpoint"
  type  = "SecureString"
  overwrite = true
  value = jsonencode({
    endpoint = module.eks-cluster.cluster_endpoint
    cluster_name      = module.eks-cluster.cluster_name
    cluster_certificate_authority_data = module.eks-cluster.cluster_certificate_authority_data
    cluster_arn = module.eks-cluster.cluster_arn
    vpc_id = module.eks-vpc.vpc_id
  })
}

resource "aws_ssm_parameter" "oidc_provider" {
  name  = "/eks/eks_cluster_${var.env}/oidc_provider"
  type  = "SecureString"
  overwrite = true
  value = jsonencode({
    oidc_provider_arn = module.eks-cluster.oidc_provider_arn
    oidc_provider_url = module.eks-cluster.cluster_oidc_issuer_url
  })
}

