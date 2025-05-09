variable "vault_namespace" {
  description = "Kubernetes namespace for Vault"
  type        = string
}

variable "vault_service_account" {
  description = "Kubernetes service account for Vault"
  type        = string
}

variable "vault_iam_role_arn" {
  description = "IAM Role ARN for Vault service account"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EKS is deployed"
  type        = string
}