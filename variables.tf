variable "region" {
  description = "AWS region where the EKS cluster is deployed"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "Name of the existing EKS cluster"
  type        = string
}

variable "vault_version" {
  description = "Version of HashiCorp Vault to deploy"
  type        = string
  default     = "1.15.2"
}

variable "pod_name" {
  description = "Name of the Vault pod"
  type        = string
  default     = "vault-0"
}