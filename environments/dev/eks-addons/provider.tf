terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.0"
    }
  }

  backend "s3" {
    bucket         = "kuncheria-terraform-tfstate-bucket"
    key            = "dev/eks-addons/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "kuncheria-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region_2
  /*
  assume_role {
    role_arn = "arn:aws:iam::899042279834:role/dev-terraform-execution-role"
  }
  */
}



provider "kubernetes" {
  host                   = local.cluster_access.endpoint
  cluster_ca_certificate = base64decode(local.cluster_access.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      local.cluster_access.cluster_name,
      "--role-arn",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.cluster_access.cluster_name}-deployer-role"
    ]
  }
}

provider "helm" {
  kubernetes = {
    host                   = local.cluster_access.endpoint
    cluster_ca_certificate = base64decode(local.cluster_access.cluster_certificate_authority_data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        local.cluster_access.cluster_name,
        "--role-arn",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.cluster_access.cluster_name}-deployer-role"
      ]
    }
  }
}