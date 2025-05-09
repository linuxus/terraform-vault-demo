output "vault_namespace" {
  description = "The Vault Kubernetes namespace"
  value       = kubernetes_namespace.vault.metadata[0].name
}

output "vault_storage_class" {
  description = "The name of the storage class created for Vault"
  value       = kubernetes_storage_class.vault_storage.metadata[0].name
}