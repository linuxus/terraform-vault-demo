variable "kms_key_alias" {
  description = "Alias for the KMS key"
  type        = string
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vault_namespace" {
  description = "Kubernetes namespace for Vault"
  type        = string
}

variable "vault_service_account" {
  description = "Kubernetes service account for Vault"
  type        = string
}