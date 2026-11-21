module "karpenter" {
  source  = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git//modules/karpenter?ref=5858b0f9652f6c7bdc8f6639a4885ce9221189ef"


  cluster_name         = local.cluster_access.cluster_name
  enable_inline_policy = true


  // enable_pod_identity_association = true
  create_pod_identity_association = true

  create_node_iam_role          = true
  node_iam_role_use_name_prefix = false
  node_iam_role_name            = "${var.cluster_name}-karpenter-node"
  create_access_entry           = true

  enable_spot_termination = true

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = var.tags
}
