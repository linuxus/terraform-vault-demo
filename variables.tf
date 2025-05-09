variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_host" {
  description = "The Kubernetes cluster server host"
  type        = string
}

variable "kubernetes_cluster_ca_certificate" {
  description = "The Kubernetes cluster CA certificate (base64 encoded)"
  type        = string
}

variable "kubernetes_token" {
  description = "The Kubernetes token for authentication"
  type        = string
  default     = ""
  sensitive   = true
}

variable "vault_namespace" {
  description = "Kubernetes namespace for Vault"
  type        = string
  default     = "vault"
}

variable "vault_service_account" {
  description = "Kubernetes service account for Vault"
  type        = string
  default     = "vault"
}

variable "vault_helm_chart_version" {
  description = "Version of the Vault Helm chart to deploy"
  type        = string
  default     = "0.25.0" # Update to the latest version as needed
}

variable "vault_replicas" {
  description = "Number of Vault server replicas"
  type        = number
  default     = 3
}

variable "vault_storage_size" {
  description = "Size of the PV for Vault raft storage (in Gi)"
  type        = string
  default     = "10Gi"
}

variable "kms_key_alias" {
  description = "Alias for the KMS key used for auto-unseal"
  type        = string
  default     = "vault-auto-unseal-key"
}

variable "domain_name" {
  description = "Domain name for the Vault UI ALB"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID where EKS is deployed"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the ALB"
  type        = list(string)
}