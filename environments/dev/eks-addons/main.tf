
/*
output "karpenter_node_role_name" {
  value = module.eks.karpenter_node_role_name
}

output "karpenter_queue_name" {
  value = module.eks.karpenter_queue_name
}
*/

module "eks_addons" {
  source = "../../../modules/eks-addons"
  cluster_name      = local.cluster_access.cluster_name
  argocd_values_raw = file("${path.module}/argocd-values.yaml")
  vpc_id            = local.cluster_access.vpc_id
 // alb_controller_role_arn = module.aws_loadbalacer_controller_irsa_role.iam_role_arn
  ebs_csi_values_json     = jsonencode(yamldecode(file("${path.module}/ebs-csi-values.yaml")))
  //ebs_csi_role_arn        = module.ebs_csi_irsa_role.iam_role_arn
  //tags                =  var.tags

  providers = {
    helm = helm
  }

  # Breaks the loop by forcing Terraform to wait until the cluster controls are completely up
  //depends_on = [module.eks]
}

