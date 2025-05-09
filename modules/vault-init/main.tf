resource "kubernetes_job" "vault_init" {
  metadata {
    name      = "vault-init-job"
    namespace = var.vault_namespace
  }

  spec {
    template {
      metadata {
        name = "vault-init"
      }
      
      spec {
        service_account_name = var.vault_service_account
        container {
          name    = "vault-init"
          image   = "hashicorp/vault:latest"
          command = ["/bin/sh", "-c"]
          args    = [templatefile("${path.module}/../../templates/vault-init-job.yaml.tpl", {})]
          
          env {
            name  = "VAULT_ADDR"
            value = "http://vault-0.vault-internal:8200"
          }
          
          env {
            name = "VAULT_SKIP_VERIFY"
            value = "true"
          }
        }
        
        restart_policy = "OnFailure"
      }
    }
    
    backoff_limit = 4
  }
  
  wait_for_completion = true
  
  timeouts {
    create = "5m"
  }
}