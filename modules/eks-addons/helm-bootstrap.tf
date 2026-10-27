terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.0"
    }
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.8.1"

  values = [
    jsonencode({
      clusterName  = var.cluster_name
      replicaCount = 2
      vpcId        = var.vpc_id
      serviceAccount = {
        create = true
        name   = "aws-loadbalancer-controller"
        annotations = {
          "eks.amazonaws.com/role-arn" = module.aws_loadbalacer_controller_irsa_role.iam_role_arn
        }
      }
      nodeSelector = {
        role = "system"
      }
      tolerations = [
        {
          key      = "dedicated"
          operator = "Equal"
          value    = "system_pods"
          effect   = "NoSchedule"
        }
      ]
    })
  ]

  // depends_on = [module.eks]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  chart            = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  version          = "7.8.2"
  namespace        = "argocd"
  create_namespace = true

  values = [
    var.argocd_values_raw
  ]

  //depends_on = [module.eks]
}

resource "kubernetes_ingress_v1" "argocd_alb_ingress" {
  metadata {
    name      = "argocd-server-explicit-ingress"
    namespace = "argocd"
    
    annotations = {
      "alb.ingress.kubernetes.io/scheme"               = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"          = "ip"
      "alb.ingress.kubernetes.io/backend-protocol"     = "HTTP"
      "alb.ingress.kubernetes.io/healthcheck-path"     = "/healthz"
      "alb.ingress.kubernetes.io/healthcheck-protocol" = "HTTP"
      "alb.ingress.kubernetes.io/listen-ports"         = "[{\"HTTP\": 80}]"
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      # Leaving host block out acts as a total wildcard catch-all (*)
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          
          backend {
            service {
              name = "argocd-server"
              port {
                number = 80  # Forces explicit mapping straight to the exposed service port
              }
            }
          }
        }
      }
    }
  }
    # Forces Terraform to wait until both charts are fully running inside EKS before exposing the endpoint
  depends_on = [
    helm_release.aws_load_balancer_controller,
    helm_release.argocd
  ]
}
