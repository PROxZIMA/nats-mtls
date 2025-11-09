#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT_DIR="$SCRIPT_DIR/../certs"

echo "=========================================="
echo "VM A - NATS Broker Cluster Setup"
echo "=========================================="

# Check if running as ubuntu user
if [ "$USER" != "ubuntu" ]; then
    echo "Warning: This script should be run as ubuntu user"
fi

# Step 1: Install prerequisites
echo ""
echo "Step 1: Installing prerequisites..."
bash "$SCRIPT_DIR/../shared/install-prerequisites.sh"

# Source bashrc to get updated PATH
export PATH=$PATH:$HOME/.linkerd2/bin

# Step 2: Install K3S
echo ""
echo "Step 2: Installing K3S..."
bash "$SCRIPT_DIR/../shared/install-k3s.sh"

# Set kubeconfig
export KUBECONFIG=~/.kube/config

# Step 3: Verify certificates exist
echo ""
echo "Step 3: Verifying certificates..."
if [ ! -f "$CERT_DIR/ca.crt" ] || [ ! -f "$CERT_DIR/cluster-a-issuer.crt" ] || [ ! -f "$CERT_DIR/cluster-a-issuer.key" ]; then
    echo "ERROR: Certificate files not found in $CERT_DIR"
    echo "Please ensure the following files exist:"
    echo "  - $CERT_DIR/ca.crt"
    echo "  - $CERT_DIR/cluster-a-issuer.crt"
    echo "  - $CERT_DIR/cluster-a-issuer.key"
    exit 1
fi
echo "Certificates found."

# Step 4: Install Linkerd
echo ""
echo "Step 4: Installing Linkerd..."
bash "$SCRIPT_DIR/install-linkerd.sh"

# Step 5: Deploy NATS Broker
echo ""
echo "Step 5: Deploying NATS Broker..."
bash "$SCRIPT_DIR/deploy-nats-broker.sh"

# Step 6: Deploy Publisher Client
echo ""
echo "Step 6: Deploying Publisher Client..."
bash "$SCRIPT_DIR/deploy-publisher.sh"

echo ""
echo "=========================================="
echo "VM A Setup Complete!"
echo "=========================================="
echo ""
echo "Cluster Status:"
kubectl get nodes
echo ""
echo "NATS Broker Status:"
kubectl get pods -n nats-system
echo ""
echo "Publisher Status:"
kubectl get pods -n nats-system -l app=nats-publisher
echo ""
echo "To check publisher logs:"
echo "  kubectl logs -n nats-system -l app=nats-publisher -f"
