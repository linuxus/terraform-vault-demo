variable "vault_namespace" {
  description = "Kubernetes namespace for Vault"
  type        = string
}

variable "vault_service_account" {
  description = "Kubernetes service account for Vault"
  type        = string
  default     = "vault"
}