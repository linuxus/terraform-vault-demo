output "vault_service_name" {
  description = "The name of the Vault Kubernetes service"
  value       = kubernetes_service.vault.metadata[0].name
}

output "vault_namespace" {
  description = "The namespace where Vault is deployed"
  value       = kubernetes_namespace.vault.metadata[0].name
}

output "vault_internal_service" {
  description = "The name of the Vault internal headless service"
  value       = kubernetes_service.vault_internal.metadata[0].name
}

output "vault_ui_access_command" {
  description = "Command to port-forward to access the Vault UI"
  value       = "kubectl port-forward svc/${kubernetes_service.vault.metadata[0].name} -n ${kubernetes_namespace.vault.metadata[0].name} 8200:8200"
}

output "vault_ui_url" {
  description = "URL to access the Vault UI (after port forwarding)"
  value       = "http://localhost:8200"
}

output "vault_statefulset_name" {
  description = "Name of the Vault StatefulSet"
  value       = "vault"
}

output "vault_root_token_file" {
  description = "Location of the file containing the root token (after initialization)"
  value       = "vault-keys.txt (Extract root token with: grep 'Initial Root Token:' vault-keys.txt | cut -d: -f2 | tr -d ' ')"
}

output "vault_pod_exec_command" {
  description = "Command template to execute Vault commands inside the pod"
  value       = "kubectl exec -n ${kubernetes_namespace.vault.metadata[0].name} vault-0 -- vault <command>"
}

output "vault_status_command" {
  description = "Command to check Vault status"
  value       = "kubectl exec -n ${kubernetes_namespace.vault.metadata[0].name} vault-0 -- vault status"
}

output "vault_client_instructions" {
  description = "Instructions for setting up a Vault client locally"
  value       = <<-EOF
    To use Vault CLI with this deployment:
    
    1. Install Vault CLI locally
    2. Export VAULT_ADDR environment variable:
       export VAULT_ADDR=http://localhost:8200
    3. Run port-forwarding:
       ${local.vault_ui_access_command}
    4. Extract and use the root token:
       export VAULT_TOKEN=$(grep 'Initial Root Token:' vault-keys.txt | cut -d: -f2 | tr -d ' ')
    5. Now you can run Vault commands locally:
       vault status
       vault secrets list
  EOF
}

output "vault_raft_peer_command" {
  description = "Command to list Raft peers"
  value       = "kubectl exec -n ${kubernetes_namespace.vault.metadata[0].name} vault-0 -- vault operator raft list-peers"
}

locals {
  vault_ui_access_command = "kubectl port-forward svc/${kubernetes_service.vault.metadata[0].name} -n ${kubernetes_namespace.vault.metadata[0].name} 8200:8200"
}