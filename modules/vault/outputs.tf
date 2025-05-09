output "vault_ui_url" {
  description = "URL for the Vault UI"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : kubernetes_ingress_v1.vault_ui.status[0].load_balancer[0].ingress[0].hostname
}