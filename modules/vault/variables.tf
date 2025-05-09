variable "vault_namespace" {
  description = "Kubernetes namespace for Vault"
  type        = string
}

variable "vault_service_account" {
  description = "Kubernetes service account for Vault"
  type        = string
}

variable "vault_helm_chart_version" {
  description = "Version of the Vault Helm chart to deploy"
  type        = string
}

variable "vault_replicas" {
  description = "Number of Vault server replicas"
  type        = number
}

variable "vault_storage_size" {
  description = "Size of the PV for Vault raft storage"
  type        = string
}

variable "kms_key_id" {
  description = "KMS Key ID for auto-unseal"
  type        = string
}

variable "kms_key_region" {
  description = "AWS Region for KMS Key"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the Vault UI ALB"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EKS is deployed"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the ALB"
  type        = list(string)
}