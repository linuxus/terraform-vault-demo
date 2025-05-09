# Create Vault namespace
resource "kubernetes_namespace" "vault" {
  metadata {
    name = var.vault_namespace
  }
}

# Create StorageClass for EBS gp3 volumes
resource "kubernetes_storage_class" "vault_storage" {
  metadata {
    name = "vault-storage-gp3"
  }
  
  storage_provisioner = "ebs.csi.aws.com"
  parameters = {
    type = "gp3"
    fsType = "ext4"
  }
  
  reclaim_policy = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"
  allow_volume_expansion = true
}

# Create ServiceAccount for Vault with annotation for IAM role
resource "kubernetes_service_account" "vault" {
  metadata {
    name      = var.vault_service_account
    namespace = kubernetes_namespace.vault.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = var.vault_iam_role_arn
    }
  }
  
  depends_on = [
    kubernetes_namespace.vault
  ]
}