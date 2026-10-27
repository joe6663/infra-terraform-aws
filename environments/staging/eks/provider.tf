terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }

  }
  backend "s3" {
    bucket         = "kuncheria-tf-code-staging"
    key            = "staging/eks/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "kuncheria-terraform-locks"

  }
}

provider "aws" {
  region = var.aws_region_2
  /*
  access_key = var.aws_access_key_2
  secret_key = var.aws_secret_key_2
  */
  /*
  assume_role {
    role_arn = "arn:aws:iam::899042279834:role/dev-terraform-execution-role"
  }
  */
}