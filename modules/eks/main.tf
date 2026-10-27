module "eks-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.cluster_name
  cidr = var.cidr


  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true
  single_nat_gateway = var.single_nat_gateway //  HA

  // one_nat_gateway_per_az = false # Explicitly tell the module to map all private subnets to the single NAT

  public_subnet_tags = {
    "kubernetes.io/role/elb"            = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared" # Added cluster discovery tag
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"   = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared" # Added cluster discovery tag
    "karpenter.sh/discovery"            = var.cluster_name
  }

  tags = {
    Environment = var.env
  }

}


module "eks-cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  //  generate module.eks-cluster.oidc_provider_arn
  enable_irsa = true

  vpc_id     = module.eks-vpc.vpc_id
  subnet_ids = module.eks-vpc.private_subnets

  // enable_cluster_creator_admin_permissions = false
  endpoint_public_access  = true
  endpoint_private_access = true

  authentication_mode = "API"

  // user accessing kube cluster need to be defined first and its accessibilty for enable_cluster_creator_admin_permissions = false
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions // make it false and create roles this is testing

  node_security_group_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }

  access_entries = {
    deployer = {
      principal_arn = aws_iam_role.deployer.arn
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
  encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = aws_kms_key.eks.arn
  }


  eks_managed_node_groups = {
    # sys nodes (ON DEMAND)
    # sys pods nodeAffinity as system
    system_nodes = {
      name         = "${var.env}-system-nodes"
      min_size     = var.system_node_min_size // HA 3 zone
      max_size     = var.system_node_max_size //
      desired_size = var.system_node_desired_size // make it 3


      instance_types = ["m6i.large"] # 2 vCPU, 8 GiB RAM
      capacity_type  = "ON_DEMAND"

      labels = {
        role = "system"
      }
      taints = {
        dedicated = {
          key    = "dedicated"
          value  = "system_pods"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }



  # -----------------------------------------------------------------
  # Map of attribute maps for all enabled EKS cluster addons
  # -----------------------------------------------------------------
  addons = {
    # 1. Networking Plugin
    vpc-cni = {
      most_recent                 = true
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"

      before_compute = true

      # Custom tuning: e.g., enabling prefix delegation for higher pod density
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }

    # 2. Cluster DNS Service
    coredns = {
      most_recent                 = true
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      configuration_values        = var.coredns_values_json
      #        configuration_values = jsonencode(yamldecode(file("${path.module}/system_node_taint-values.yaml")))
    }

    # 3. Network Proxy
    kube-proxy = {
      most_recent                 = true
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
  }

}