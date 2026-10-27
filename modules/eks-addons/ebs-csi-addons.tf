# These native resources execute AFTER the cluster and IAM modules are fully resolved
resource "aws_eks_addon" "aws_ebs_csi_driver" {
  cluster_name = var.cluster_name # Passed from the root main.tf output
  addon_name   = "aws-ebs-csi-driver"

  //most_recent                 = true
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  configuration_values        = var.ebs_csi_values_json
  service_account_role_arn    = module.ebs_csi_irsa_role.iam_role_arn # Passed from root main.tf

  tags = var.tags
}

resource "aws_eks_addon" "eks_pod_identity_agent" {
  cluster_name = var.cluster_name
  addon_name   = "eks-pod-identity-agent"

  //most_recent                 = true
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}
