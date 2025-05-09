resource "helm_release" "vault" {
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = var.vault_helm_chart_version
  namespace  = var.vault_namespace
  
  values = [
    templatefile("${path.module}/../../templates/vault-values.yaml.tpl", {
      vault_replicas      = var.vault_replicas
      storage_class_name  = "vault-storage-gp3"
      storage_size        = var.vault_storage_size
      kms_key_id          = var.kms_key_id
      kms_region          = var.kms_key_region
      domain_name         = var.domain_name
      vault_service_account = var.vault_service_account
    })
  ]
  
  depends_on = [
    kubernetes_namespace.vault,
    kubernetes_storage_class.vault_storage
  ]
}

# Create Ingress for Vault UI using ALB
resource "kubernetes_ingress_v1" "vault_ui" {
  metadata {
    name      = "vault-ui-ingress"
    namespace = var.vault_namespace
    
    annotations = {
      "kubernetes.io/ingress.class"               = "alb"
      "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"     = "ip"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/ui/"
      "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
      "alb.ingress.kubernetes.io/success-codes"   = "200,204,301,302,307"
    }
  }
  
  spec {
    rule {
      host = var.domain_name != "" ? var.domain_name : null
      http {
        path {
          path      = "/*"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "vault-ui"
              port {
                number = 8200
              }
            }
          }
        }
      }
    }
  }
  
  depends_on = [
    helm_release.vault
  ]
}

# Create a service for Vault UI specifically
resource "kubernetes_service" "vault_ui" {
  metadata {
    name      = "vault-ui"
    namespace = var.vault_namespace
  }
  
  spec {
    selector = {
      "app.kubernetes.io/name"      = "vault"
      "app.kubernetes.io/instance"  = "vault"
    }
    
    port {
      name        = "http"
      port        = 8200
      target_port = 8200
    }
    
    type = "ClusterIP"
  }
  
  depends_on = [
    helm_release.vault
  ]
}