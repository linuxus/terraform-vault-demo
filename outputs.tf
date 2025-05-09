output "vault_ui_url" {
  description = "URL for the Vault UI"
  value       = module.vault.vault_ui_url
}

output "kms_key_id" {
  description = "KMS Key ID used for Vault auto-unseal"
  value       = module.aws_resources.kms_key_id
}

output "vault_init_job_status" {
  description = "Status of the Vault initialization job"
  value       = module.vault_init.init_job_status
}