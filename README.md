# HashiCorp Vault on EKS

This repository contains Terraform code and scripts for deploying a highly available HashiCorp Vault cluster on Amazon EKS with Raft storage backend.

## Overview

This module deploys a 3-node Vault cluster using Kubernetes StatefulSets with the following components:

- Vault server configured with integrated Raft storage (no Consul required)
- A headless service for internal Vault cluster communication
- A ClusterIP service for external access to the Vault API
- EBS volumes for persistent storage
- Scripts for initialization and automatic unsealing

## Prerequisites

- Existing EKS cluster
- AWS CLI configured
- Terraform 1.0+
- Terraform IAM Role with correct permissions
- kubectl configured to access your EKS cluster

## Architecture

The deployed Vault cluster consists of:

- 3 Vault server pods in a StatefulSet
- Each pod has its own persistent EBS volume
- Integrated Raft storage for HA
- Pods communicate via a headless service

## Deployment

### 1. Update Variables

Edit `terraform.tfvars` to set your EKS cluster name, region, and other variables:

```hcl
region          = "us-west-2"  # Your AWS region
cluster_name    = "my-eks"     # Your EKS cluster name
vault_version   = "1.15.2"     # Vault version to deploy
```

### 2. Apply Terraform Configuration

Deploy the Vault infrastructure:

```bash
terraform init
terraform apply
```

This creates all the necessary Kubernetes resources but starts with 0 replicas.

### 3. Initialize and Unseal

Run the initialization script to set up the Vault cluster:

```bash
chmod +x initialize-vault-existing.sh
./initialize-vault-existing.sh
```

The script will:
1. Scale up to 1 replica
2. Initialize Vault (or use existing initialization)
3. Create a keys file
4. Unseal the first Vault instance
5. Scale up to 2 and 3 replicas
6. Join the other instances to the Raft cluster
7. Unseal all instances
8. Verify the cluster status

## Accessing Vault

After deployment, you can access the Vault UI:

```bash
kubectl port-forward svc/vault -n vault 8200:8200
```

Then open `http://localhost:8200` in your browser and log in with the root token.

## Files

- `main.tf` - Main Terraform configuration for deploying Vault
- `variables.tf` - Variable definitions
- `terraform.tfvars` - Variable values
- `initialize-vault-existing.sh` - Script for initializing and unsealing Vault

## Configuration Details

### Vault Configuration

The Vault server is configured with:

- UI enabled
- TLS disabled (for demo purposes - enable TLS in production)
- Raft storage backend
- 3-node HA cluster
- Default resource limits

### Storage

Each Vault pod uses:
- EBS volumes provisioned by the EBS CSI driver
- 5Gi storage per pod
- gp3 volume type
- Encrypted volumes

### Security Considerations

This deployment includes:
- Non-root user for Vault (UID 100)
- Group ID 1000 for filesystem permissions
- IPC_LOCK capability
- No privileged containers

## Troubleshooting

### Common Issues

1. **Permission Problems**: If you see permission errors in the logs, check that the pod security context is set correctly.

2. **Unsealing Issues**: If a pod won't unseal, verify that you're using the correct keys.

3. **Raft Join Failures**: If pods can't join the Raft cluster, check network connectivity between pods.

### Debugging Commands

```bash
# Check Vault status
kubectl exec -n vault vault-0 -- vault status

# Check logs
kubectl logs vault-0 -n vault

# Check Raft peers
kubectl exec -n vault vault-0 -- vault operator raft list-peers
```

## Production Considerations

For production deployments:

1. **Enable TLS**: Configure TLS for all Vault communications
2. **Auto-unsealing**: Set up auto-unsealing using AWS KMS
3. **Backup Strategy**: Implement regular backups of Vault data
4. **Resource Tuning**: Adjust CPU and memory based on workload
5. **Monitoring**: Set up monitoring and alerting
6. **Access Control**: Implement proper IAM and Vault policies

## Maintenance

### Scaling

To adjust the number of replicas:

```bash
kubectl scale statefulset vault -n vault --replicas=<number>
```

New pods will need to be unsealed using the same script.

### Upgrades

To upgrade Vault:

1. Update the `vault_version` in `terraform.tfvars`
2. Apply the Terraform changes
3. Terminate pods one at a time to allow rolling upgrade
4. Unseal each pod after it restarts
