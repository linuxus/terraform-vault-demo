output "init_job_status" {
  description = "Status of the Vault initialization job"
  value       = kubernetes_job.vault_init.status
}