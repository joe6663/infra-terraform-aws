variable "name" { type = string }
variable "cidr" { type = string }
variable "azs" { type = list(string) }
variable "private_subnets" { type = list(string) }
variable "public_subnets" { type = list(string) }
variable "single_nat_gateway" { 
    type = bool 
    default = false 
    }


#############################################################################
## EKS
#############################################################################

variable "cluster_name" { type = string }
variable "kubernetes_version" { 
    type = string 
    default = "1.33" 
    }
variable "system_node_desired_size" { 
    type = number 
    default = 2 
    }
variable "enable_cluster_creator_admin_permissions" { 
    type = bool 
    default = true 
    }
variable "coredns_values_json" { 
    type = string 
    default = "" 
    }
variable "env"{
    type = string
    default = ""
    }

variable "tags" { 
    type = map(string) 
    default = {} 
    }
variable "system_node_min_size" {
  type    = number
  default = 1
}
variable "system_node_max_size" {
  type    = number
  default = 5
}


