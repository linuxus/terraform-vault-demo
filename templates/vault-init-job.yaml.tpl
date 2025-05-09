#!/bin/sh
set -e

# Wait for Vault to be ready
echo "Waiting for Vault to be ready..."
until curl -fs $VAULT_ADDR/v1/sys/health; do
  echo "Vault not ready yet, waiting..."
  sleep 5
done

# Check if Vault is initialized
INIT_STATUS=$(curl -s $VAULT_ADDR/v1/sys/init | jq -r .initialized)

if [ "$INIT_STATUS" = "false" ]; then
  echo "Initializing Vault..."
  
  # Initialize Vault with 1 key share and 1 key threshold
  # In production, you might want to use more shares and higher threshold
  INIT_RESPONSE=$(curl -s -X PUT $VAULT_ADDR/v1/sys/init -d '{"secret_shares": 1, "secret_threshold": 1}')
  
  # Extract root token and unseal key
  ROOT_TOKEN=$(echo $INIT_RESPONSE | jq -r .root_token)
  UNSEAL_KEY=$(echo $INIT_RESPONSE | jq -r .keys[0])
  
  echo "Vault initialized successfully"
  echo "Root Token: $ROOT_TOKEN"
  
  # Store these securely - in production you would use a secret manager
  # For demonstration purposes, we'll create a Kubernetes secret
  kubectl create secret generic vault-init-secrets \
    --from-literal=root-token=$ROOT_TOKEN \
    --from-literal=unseal-key=$UNSEAL_KEY \
    -n $VAULT_NAMESPACE
  
  echo "Secrets stored in Kubernetes secret vault-init-secrets"
else
  echo "Vault is already initialized"
fi

# Vault should auto-unseal using AWS KMS, but we can verify
SEAL_STATUS=$(curl -s $VAULT_ADDR/v1/sys/seal-status | jq -r .sealed)
echo "Vault seal status: $SEAL_STATUS"

if [ "$SEAL_STATUS" = "true" ]; then
  echo "Vault is sealed, checking if we need to manually unseal..."
  # This should not happen with auto-unseal, but just in case
  UNSEAL_KEY=$(kubectl get secret vault-init-secrets -n $VAULT_NAMESPACE -o jsonpath='{.data.unseal-key}' | base64 --decode)
  curl -X PUT $VAULT_ADDR/v1/sys/unseal -d "{\"key\": \"$UNSEAL_KEY\"}"
  echo "Manual unseal attempted"
fi

echo "Vault initialization job completed"