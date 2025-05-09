module "aws_resources" {
  source = "./modules/aws-resources"

  kms_key_alias         = var.kms_key_alias
  eks_cluster_name      = var.eks_cluster_name
  vault_namespace       = var.vault_namespace
  vault_service_account = var.vault_service_account
}

module "kubernetes_resources" {
  source = "./modules/kubernetes-resources"

  vault_namespace       = var.vault_namespace
  vault_service_account = var.vault_service_account
  vpc_id                = var.vpc_id
}

module "vault" {
  source = "./modules/vault"

  vault_namespace          = var.vault_namespace
  vault_service_account    = var.vault_service_account
  vault_helm_chart_version = var.vault_helm_chart_version
  vault_replicas           = var.vault_replicas
  vault_storage_size       = var.vault_storage_size
  kms_key_id               = module.aws_resources.kms_key_id
  kms_key_region           = var.aws_region
  domain_name              = var.domain_name
  vpc_id                   = var.vpc_id
  subnet_ids               = var.subnet_ids

  depends_on = [
    module.kubernetes_resources,
    module.aws_resources
  ]
}

module "vault_init" {
  source = "./modules/vault-init"

  vault_namespace = var.vault_namespace

  depends_on = [
    module.vault
  ]
}