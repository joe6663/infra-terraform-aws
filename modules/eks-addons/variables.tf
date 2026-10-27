variable "alb_controller_role_arn" { 
    type = string 
    default = "" 
    }
variable "argocd_values_raw" { 
    type = string 
    default = "" 
    }
variable "vpc_id" { type = string }

variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster passed from the dev environment"
}
variable "tags" { 
    type = map(string) 
    default = {} 
    }
variable "ebs_csi_values_json" { 
    type = string 
    default = "" 
    }

variable "env"{
    type = string
    default = ""
    }
variable "oidc_provider_arn" { 
    type = string 
    default = "" 
    }