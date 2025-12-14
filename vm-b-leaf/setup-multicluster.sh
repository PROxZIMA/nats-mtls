#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINK_FILE="${1:-$SCRIPT_DIR/cluster-a-link.yaml}"

echo "=========================================="
echo "Setting up Linkerd Multicluster on Cluster B (Leaf)"
echo "=========================================="

if [ ! -f "$LINK_FILE" ]; then
    echo "ERROR: Link file not found: $LINK_FILE"
    echo "Please provide the cluster-a-link.yaml file from Cluster A"
    exit 1
fi

export KUBECONFIG=~/.kube/config
export PATH=$PATH:$HOME/.linkerd2/bin

# Install Linkerd Multicluster extension (no gateway needed on leaf)
echo "Installing Linkerd Multicluster extension..."
linkerd multicluster install | kubectl apply -f -

# Wait for multicluster components to be ready
echo ""
echo "Waiting for multicluster components to be ready..."
sleep 10
linkerd multicluster check

# Apply the link to Cluster A
echo ""
echo "Establishing link to Cluster A..."
kubectl apply -f "$LINK_FILE"

# Wait for link to be established
echo ""
echo "Waiting for link to be established..."
sleep 10
linkerd multicluster check

# Display linked clusters
echo ""
echo "Linked clusters:"
linkerd multicluster gateways

echo ""
echo "=========================================="
echo "Linkerd Multicluster Setup Complete on Cluster B!"
echo "=========================================="
echo ""
echo "To mirror a service from Cluster A:"
echo "  kubectl label svc <service-name> -n <namespace> mirror.linkerd.io/exported=true"
echo ""
echo "Example for NATS broker:"
echo "  kubectl label svc nats-broker -n nats-system mirror.linkerd.io/exported=true"
echo ""
