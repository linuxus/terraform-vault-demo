global:
  enabled: true

server:
  image:
    repository: "hashicorp/vault"
    tag: "latest"
  
  serviceAccount:
    create: false
    name: "${vault_service_account}"
  
  ha:
    enabled: true
    replicas: ${vault_replicas}
    
    raft:
      enabled: true
      setNodeId: true
      
      config: |
        ui = true
        
        listener "tcp" {
          tls_disable = 1
          address = "[::]:8200"
          cluster_address = "[::]:8201"
        }
        
        storage "raft" {
          path = "/vault/data"
          retry_join {
            leader_api_addr = "http://vault-0.vault-internal:8200"
          }
          retry_join {
            leader_api_addr = "http://vault-1.vault-internal:8200"
          }
          retry_join {
            leader_api_addr = "http://vault-2.vault-internal:8200"
          }
        }
        
        service_registration "kubernetes" {}
        
        seal "awskms" {
          region = "${kms_region}"
          kms_key_id = "${kms_key_id}"
        }
  
  dataStorage:
    enabled: true
    size: "${storage_size}"
    storageClass: "${storage_class_name}"
    accessMode: "ReadWriteOnce"
  
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "500m"

ui:
  enabled: true
  serviceType: "ClusterIP"
  externalPort: 8200