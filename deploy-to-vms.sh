#!/bin/bash
set -euo pipefail

# This script helps deploy the project to both VMs from your local machine
# Usage: VM_A_IP=129.154.247.85 VM_A_SSH_KEY=~/.ssh/a_ssh.key VM_B_IP=144.24.103.105 VM_B_SSH_KEY=~/.ssh/b_ssh.key ./deploy-to-vms.sh

VM_A_IP="${VM_A_IP:-1.1.1.1}"
VM_A_SSH_KEY="${VM_A_SSH_KEY:-~/.ssh/a_ssh.key}"
VM_B_IP="${VM_B_IP:-2.2.2.2}"
VM_B_SSH_KEY="${VM_B_SSH_KEY:-~/.ssh/b_ssh.key}"
SSH_USER="${SSH_USER:-ubuntu}"
WORKING_DIR="/home/$SSH_USER/nats"

echo "=========================================="
echo "Deploying NATS-mTLS Setup to VMs"
echo "=========================================="
echo "VM A (Broker): $VM_A_IP"
echo "VM A SSH Key:  $VM_A_SSH_KEY"
echo "VM B (Leaf):   $VM_B_IP"
echo "VM B SSH Key:  $VM_B_SSH_KEY"
echo "SSH User:      $SSH_USER"
echo ""

# Check if certificates exist
if [ ! -f "certs/ca.crt" ]; then
    echo "ERROR: Certificates not found!"
    echo "Please run './shared/generate-certificates.sh' first"
    exit 1
fi

echo "Certificates found ✓"
echo ""

# Deploy to VM A
echo "=========================================="
echo "Deploying to VM A (Broker) - $VM_A_IP"
echo "=========================================="

echo "Creating working directory on VM A..."
ssh -i "$VM_A_SSH_KEY" "$SSH_USER@$VM_A_IP" "mkdir -p $WORKING_DIR" || { echo "Failed to create working dir"; exit 1; }

echo "Copying files to VM A..."
scp -i "$VM_A_SSH_KEY" -r vm-a-broker "$SSH_USER@$VM_A_IP:$WORKING_DIR/" || { echo "Failed to copy vm-a-broker"; exit 1; }
scp -i "$VM_A_SSH_KEY" -r shared "$SSH_USER@$VM_A_IP:$WORKING_DIR/" || { echo "Failed to copy shared"; exit 1; }
scp -i "$VM_A_SSH_KEY" -r manifests "$SSH_USER@$VM_A_IP:$WORKING_DIR/" || { echo "Failed to copy manifests"; exit 1; }

echo "Creating certs directory on VM A..."
ssh -i "$VM_A_SSH_KEY" "$SSH_USER@$VM_A_IP" "mkdir -p $WORKING_DIR/certs" || { echo "Failed to create certs dir"; exit 1; }
ssh -i "$VM_A_SSH_KEY" "$SSH_USER@$VM_A_IP" "mkdir -p $WORKING_DIR/certs/nats" || { echo "Failed to create nats certs dir"; exit 1; }

echo "Copying certificates to VM A..."
scp -i "$VM_A_SSH_KEY" certs/ca.crt "$SSH_USER@$VM_A_IP:$WORKING_DIR/certs/" || { echo "Failed to copy ca.crt"; exit 1; }
scp -i "$VM_A_SSH_KEY" certs/cluster-a-issuer.crt "$SSH_USER@$VM_A_IP:$WORKING_DIR/certs/" || { echo "Failed to copy cluster-a-issuer.crt"; exit 1; }
scp -i "$VM_A_SSH_KEY" certs/cluster-a-issuer.key "$SSH_USER@$VM_A_IP:$WORKING_DIR/certs/" || { echo "Failed to copy cluster-a-issuer.key"; exit 1; }

echo "Copying nats certificates to VM A..."
scp -i "$VM_A_SSH_KEY" -r certs/nats/* "$SSH_USER@$VM_A_IP:$WORKING_DIR/certs/nats/" || { echo "Failed to copy nats certificates"; exit 1; }


echo "Setting permissions on VM A..."
ssh -i "$VM_A_SSH_KEY" "$SSH_USER@$VM_A_IP" "chmod +x $WORKING_DIR/**/*.sh" || { echo "Failed to set permissions"; exit 1; }
ssh -i "$VM_A_SSH_KEY" "$SSH_USER@$VM_A_IP" "find $WORKING_DIR -name '*.sh' -type f -exec sed -i 's/\r$//' {} +" || { echo "Failed to convert line endings on VM A"; exit 1; }

echo "VM A deployment complete ✓"
echo ""

# Deploy to VM B
echo "=========================================="
echo "Deploying to VM B (Leaf) - $VM_B_IP"
echo "=========================================="

echo "Creating working directory on VM B..."
ssh -i "$VM_B_SSH_KEY" "$SSH_USER@$VM_B_IP" "mkdir -p $WORKING_DIR" || { echo "Failed to create working dir"; exit 1; }

echo "Copying files to VM B..."
scp -i "$VM_B_SSH_KEY" -r vm-b-leaf "$SSH_USER@$VM_B_IP:$WORKING_DIR/" || { echo "Failed to copy vm-b-leaf"; exit 1; }
scp -i "$VM_B_SSH_KEY" -r shared "$SSH_USER@$VM_B_IP:$WORKING_DIR/" || { echo "Failed to copy shared"; exit 1; }
scp -i "$VM_B_SSH_KEY" -r manifests "$SSH_USER@$VM_B_IP:$WORKING_DIR/" || { echo "Failed to copy manifests"; exit 1; }

echo "Creating certs directory on VM B..."
ssh -i "$VM_B_SSH_KEY" "$SSH_USER@$VM_B_IP" "mkdir -p $WORKING_DIR/certs" || { echo "Failed to create certs dir"; exit 1; }
ssh -i "$VM_B_SSH_KEY" "$SSH_USER@$VM_B_IP" "mkdir -p $WORKING_DIR/certs/nats" || { echo "Failed to create nats certs dir"; exit 1; }

echo "Copying certificates to VM B..."
scp -i "$VM_B_SSH_KEY" certs/ca.crt "$SSH_USER@$VM_B_IP:$WORKING_DIR/certs/" || { echo "Failed to copy ca.crt"; exit 1; }
scp -i "$VM_B_SSH_KEY" certs/cluster-b-issuer.crt "$SSH_USER@$VM_B_IP:$WORKING_DIR/certs/" || { echo "Failed to copy cluster-b-issuer.crt"; exit 1; }
scp -i "$VM_B_SSH_KEY" certs/cluster-b-issuer.key "$SSH_USER@$VM_B_IP:$WORKING_DIR/certs/" || { echo "Failed to copy cluster-b-issuer.key"; exit 1; }

echo "Copying nats certificates to VM B..."
scp -i "$VM_B_SSH_KEY" -r certs/nats/* "$SSH_USER@$VM_B_IP:$WORKING_DIR/certs/nats/" || { echo "Failed to copy nats certificates"; exit 1; }

echo "Setting permissions on VM B..."
ssh -i "$VM_B_SSH_KEY" "$SSH_USER@$VM_B_IP" "chmod +x $WORKING_DIR/**/*.sh" || { echo "Failed to set permissions"; exit 1; }
ssh -i "$VM_B_SSH_KEY" "$SSH_USER@$VM_B_IP" "find $WORKING_DIR -name '*.sh' -type f -exec sed -i 's/\r$//' {} +" || { echo "Failed to convert line endings on VM B"; exit 1; }

echo "VM B deployment complete ✓"
echo ""

echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Setup VM A (Broker):"
echo "   ssh $SSH_USER@$VM_A_IP"
echo "   cd $WORKING_DIR/vm-a-broker"
echo "   ./setup.sh"
echo ""
echo "2. Setup VM B (Leaf):"
echo "   ssh $SSH_USER@$VM_B_IP"
echo "   cd $WORKING_DIR/vm-b-leaf"
echo "   BROKER_IP=$VM_A_IP ./setup.sh"
echo ""
echo "3. Verify on VM B:"
echo "   kubectl logs -n nats-system -l app=nats-subscriber -f"
echo ""
