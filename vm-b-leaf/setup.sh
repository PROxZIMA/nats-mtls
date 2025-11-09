#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT_DIR="$SCRIPT_DIR/../certs"

# VM A IP address (NATS Broker)
BROKER_IP="${BROKER_IP:-1.1.1.1}"

echo "=========================================="
echo "VM B - NATS Leaf Cluster Setup"
echo "=========================================="
echo "Broker IP: $BROKER_IP"
echo ""

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
if [ ! -f "$CERT_DIR/ca.crt" ] || [ ! -f "$CERT_DIR/cluster-b-issuer.crt" ] || [ ! -f "$CERT_DIR/cluster-b-issuer.key" ]; then
    echo "ERROR: Certificate files not found in $CERT_DIR"
    echo "Please ensure the following files exist:"
    echo "  - $CERT_DIR/ca.crt"
    echo "  - $CERT_DIR/cluster-b-issuer.crt"
    echo "  - $CERT_DIR/cluster-b-issuer.key"
    exit 1
fi
echo "Certificates found."

# Step 4: Install Linkerd
echo ""
echo "Step 4: Installing Linkerd..."
bash "$SCRIPT_DIR/install-linkerd.sh"

# Step 5: Deploy NATS Leaf
echo ""
echo "Step 5: Deploying NATS Leaf..."
BROKER_IP="$BROKER_IP" bash "$SCRIPT_DIR/deploy-nats-leaf.sh"

# Step 6: Deploy Subscriber Client
echo ""
echo "Step 6: Deploying Subscriber Client..."
bash "$SCRIPT_DIR/deploy-subscriber.sh"

echo ""
echo "=========================================="
echo "VM B Setup Complete!"
echo "=========================================="
echo ""
echo "Cluster Status:"
kubectl get nodes
echo ""
echo "NATS Leaf Status:"
kubectl get pods -n nats-system
echo ""
echo "Subscriber Status:"
kubectl get pods -n nats-system -l app=nats-subscriber
echo ""
echo "To check subscriber logs:"
echo "  kubectl logs -n nats-system -l app=nats-subscriber -f"
