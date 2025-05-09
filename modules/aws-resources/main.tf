resource "aws_kms_key" "vault_unseal" {
  description             = "KMS key for Vault auto-unseal"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  
  tags = {
    Name = "vault-auto-unseal-key"
  }
}

resource "aws_kms_alias" "vault_unseal" {
  name          = "alias/${var.kms_key_alias}"
  target_key_id = aws_kms_key.vault_unseal.id
}

data "aws_iam_policy_document" "vault_kms_policy" {
  statement {
    sid    = "VaultKMSUnseal"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
    ]
    resources = [
      aws_kms_key.vault_unseal.arn,
    ]
  }
}

# Create IAM policy for Vault to use the KMS key
resource "aws_iam_policy" "vault_kms_policy" {
  name        = "vault-kms-unseal-policy"
  description = "Policy allowing Vault to use KMS for auto-unseal"
  policy      = data.aws_iam_policy_document.vault_kms_policy.json
}

# Create IAM role for Vault ServiceAccount (using IRSA)
data "aws_iam_policy_document" "vault_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_provider}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:sub"
      values   = ["system:serviceaccount:${var.vault_namespace}:${var.vault_service_account}"]
    }
  }
}

resource "aws_iam_role" "vault_role" {
  name               = "vault-kms-role"
  assume_role_policy = data.aws_iam_policy_document.vault_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "vault_kms_policy_attachment" {
  role       = aws_iam_role.vault_role.name
  policy_arn = aws_iam_policy.vault_kms_policy.arn
}

data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_name
}

locals {
  oidc_provider = replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")
}