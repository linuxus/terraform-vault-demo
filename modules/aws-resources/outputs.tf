output "kms_key_id" {
  description = "KMS Key ID for auto-unseal"
  value       = aws_kms_key.vault_unseal.id
}

output "kms_key_arn" {
  description = "KMS Key ARN for auto-unseal"
  value       = aws_kms_key.vault_unseal.arn
}

output "vault_iam_role_arn" {
  description = "IAM Role ARN for Vault service account"
  value       = aws_iam_role.vault_role.arn
}