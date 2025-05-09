provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Data sources to get EKS cluster info
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

# Create a namespace for Vault
resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
    labels = {
      "app.kubernetes.io/name" = "vault"
    }
  }
}

# Create a service account for Vault
resource "kubernetes_service_account" "vault" {
  metadata {
    name      = "vault"
    namespace = kubernetes_namespace.vault.metadata[0].name
  }
}

# Create Kubernetes storage class for Vault's persistent storage
resource "kubernetes_storage_class" "vault_storage" {
  metadata {
    name = "vault-storage"
  }
  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"
  parameters = {
    type      = "gp3"
    encrypted = "true"
    fsType    = "ext4"
  }
}

# Create a headless service for Vault's internal communication
resource "kubernetes_service" "vault_internal" {
  metadata {
    name      = "vault-internal"
    namespace = kubernetes_namespace.vault.metadata[0].name
    labels = {
      app = "vault"
    }
  }
  
  spec {
    selector = {
      app = "vault"
    }
    
    port {
      name        = "server"
      port        = 8200
      target_port = 8200
    }
    
    port {
      name        = "cluster"
      port        = 8201
      target_port = 8201
    }
    
    cluster_ip = "None"
  }
}

# Create a service for external Vault access
resource "kubernetes_service" "vault" {
  metadata {
    name      = "vault"
    namespace = kubernetes_namespace.vault.metadata[0].name
    labels = {
      app = "vault"
    }
  }
  
  spec {
    selector = {
      app = "vault"
    }
    
    port {
      name        = "http"
      port        = 8200
      target_port = 8200
    }
    
    type = "ClusterIP"
  }
}

# Deploy Vault using a StatefulSet
resource "kubernetes_stateful_set_v1" "vault" {
  metadata {
    name      = "vault"
    namespace = kubernetes_namespace.vault.metadata[0].name
    labels = {
      app = "vault"
    }
  }

  spec {
    service_name = kubernetes_service.vault_internal.metadata[0].name
    replicas     = 0  # Start with 0 replicas for manual initialization
    
    selector {
      match_labels = {
        app = "vault"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "vault"
        }
      }
      
      spec {
        service_account_name = kubernetes_service_account.vault.metadata[0].name
        termination_grace_period_seconds = 10
        
        # Security context for the pod - set fsGroup to ensure volume permissions
        security_context {
          fs_group = 1000  # Vault group ID
        }
        
        container {
          name  = "vault"
          image = "hashicorp/vault:${var.vault_version}"
          
          command = ["/bin/sh", "-c"]
          args = [
            <<-EOT
            # Get private IP using hostname -i 
            export POD_IP=$(hostname -i)
            echo "My POD_IP is: $POD_IP"
            
            # Create a subdirectory inside the main data directory that will be writeable
            mkdir -p /vault/data/vault-storage
            
            # Create vault.hcl in emptyDir volume
            cat > /vault/config/vault.hcl << EOF
            ui = true
            
            listener "tcp" {
              address     = "0.0.0.0:8200"
              tls_disable = 1
            }
            
            storage "raft" {
              path    = "/vault/data/vault-storage"
              node_id = "$HOSTNAME"
              
              retry_join {
                leader_api_addr = "http://vault-0.vault-internal.${kubernetes_namespace.vault.metadata[0].name}.svc.cluster.local:8200"
              }
            }
            
            api_addr    = "http://$POD_IP:8200"
            cluster_addr = "http://$POD_IP:8201"
            disable_mlock = true
            EOF
            
            # Show environment variables
            echo "Environment Variables:"
            echo "HOSTNAME: $HOSTNAME"
            echo "POD_IP: $POD_IP"
            
            # Print config for debugging
            echo "Configuration:"
            cat /vault/config/vault.hcl
            
            # Show directory permissions
            echo "Directory Permissions:"
            ls -la /vault/data
            ls -la /vault/data/vault-storage || echo "Storage directory not yet created"
            id
            
            # Start Vault
            exec vault server -config=/vault/config/vault.hcl
            EOT
          ]
          
          port {
            container_port = 8200
            name           = "http"
          }
          
          port {
            container_port = 8201
            name           = "cluster"
          }
          
          env {
            name  = "VAULT_ADDR"
            value = "http://127.0.0.1:8200"
          }
          
          env {
            name = "HOSTNAME"
            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }
          
          env {
            name  = "SKIP_CHOWN"
            value = "true"
          }
          
          env {
            name  = "SKIP_SETCAP"
            value = "true"
          }
          
          security_context {
            run_as_user  = 100   # Vault user
            run_as_group = 1000  # Vault group
            capabilities {
              add = ["IPC_LOCK"]
            }
          }
          
          volume_mount {
            name       = "vault-data"
            mount_path = "/vault/data"
          }
          
          volume_mount {
            name       = "vault-config"
            mount_path = "/vault/config"
          }
          
          resources {
            requests = {
              memory = "256Mi"
              cpu    = "200m"
            }
            limits = {
              memory = "512Mi"
              cpu    = "500m"
            }
          }
          
          liveness_probe {
            http_get {
              path   = "/v1/sys/health?standbyok=true&uninitcode=200&sealedcode=200"
              port   = 8200
              scheme = "HTTP"
            }
            initial_delay_seconds = 10
            period_seconds        = 30
            timeout_seconds       = 5
            failure_threshold     = 3
            success_threshold     = 1
          }
          
          # Add a readiness probe to check when it's ok to join/unseal
          readiness_probe {
            http_get {
              path   = "/v1/sys/health?standbyok=true&uninitcode=200&sealedcode=200"
              port   = 8200
              scheme = "HTTP"
            }
            initial_delay_seconds = 5
            period_seconds        = 10
            timeout_seconds       = 3
            failure_threshold     = 3
            success_threshold     = 1
          }
        }
        
        volume {
          name = "vault-config"
          empty_dir {}
        }
      }
    }
    
    volume_claim_template {
      metadata {
        name = "vault-data"
      }
      
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = kubernetes_storage_class.vault_storage.metadata[0].name
        
        resources {
          requests = {
            storage = "5Gi"
          }
        }
      }
    }
    
    update_strategy {
      type = "OnDelete"
    }
  }

  # Disable waiting for rollout since we're using OnDelete strategy
  wait_for_rollout = false
}