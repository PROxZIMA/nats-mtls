#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT_DIR="$SCRIPT_DIR/../certs"

echo "=========================================="
echo "VM A - NATS Broker Cluster Setup"
echo "=========================================="

# Check if NODE_EXTERNAL_IP is set
if [ -z "${NODE_EXTERNAL_IP:-}" ]; then
    echo "ERROR: NODE_EXTERNAL_IP environment variable is not set"
    echo ""
    echo "Please set the public/external IP address of this VM:"
    echo "  export NODE_EXTERNAL_IP=<vm-a-public-ip>"
    echo "  export NODE_INTERNAL_IP=<vm-a-private-ip>  # Optional"
    echo "  ./setup.sh"
    echo ""
    echo "Example:"
    echo "  export NODE_EXTERNAL_IP=129.154.247.85"
    echo "  export NODE_INTERNAL_IP=10.0.0.37"
    echo "  ./setup.sh"
    exit 1
fi

echo "External IP: $NODE_EXTERNAL_IP"
echo "Internal IP: ${NODE_INTERNAL_IP:-auto-detect}"

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

# Step 6: Setup Linkerd Multicluster
echo ""
echo "Step 6: Setting up Linkerd Multicluster..."
bash "$SCRIPT_DIR/setup-multicluster.sh"

# Step 7: Verify NATS Broker Export (label is in manifest)
echo ""
echo "Step 7: Verifying NATS Broker Service Export..."
echo "Checking for exported services..."
kubectl get svc -n nats-system -l mirror.linkerd.io/exported=true
echo "✓ NATS broker service is configured for export (via manifest)"

# Step 8: Deploy Publisher Client
echo ""
echo "Step 8: Deploying Publisher Client..."
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
echo "Linkerd Gateway Status:"
kubectl get pods -n linkerd-multicluster
echo ""
echo "To check publisher logs:"
echo "  kubectl logs -n nats-system -l app=nats-publisher -f"
echo ""
echo "=========================================="
echo "Next Steps for VM B (Leaf Cluster):"
echo "=========================================="
echo ""
echo "1. Copy cluster-a-link.yaml to VM B:"
echo "   scp -3 -F ./.scp_config src:~/nats/vm-a-broker/cluster-a-link.yaml dest:~/nats/vm-b-leaf/"
echo ""
echo "2. On VM B, run the setup script:"
echo "   cd vm-b-leaf && ./setup.sh"
echo ""
