#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Setting up Linkerd Multicluster on Cluster A (Broker)"
echo "=========================================="

# Use external kubeconfig if available
if [ -f ~/.kube/config-external ]; then
    export KUBECONFIG=~/.kube/config-external
    echo "Using kubeconfig with external IP: ~/.kube/config-external"
else
    export KUBECONFIG=~/.kube/config
    echo "Using default kubeconfig: ~/.kube/config"
fi

export PATH=$PATH:$HOME/.linkerd2/bin

# Get API server address from kubeconfig
API_SERVER=$(kubectl config view -o jsonpath='{.clusters[0].cluster.server}')
echo "API Server: $API_SERVER"
echo ""

# Install Linkerd Multicluster extension (with default gateway)
echo "Installing Linkerd Multicluster extension..."
linkerd multicluster install | kubectl apply -f -

# Wait for multicluster components to be ready
echo ""
echo "Waiting for multicluster components to be ready..."
sleep 15

# Check multicluster status
linkerd multicluster check

# Wait for gateway to be ready
echo ""
echo "Waiting for gateway to be ready..."
kubectl wait --for=condition=available --timeout=60s deployment/linkerd-gateway -n linkerd-multicluster

# Get gateway service details
echo ""
echo "Gateway Service Details:"
kubectl get svc linkerd-gateway -n linkerd-multicluster

# Generate link credentials using link-gen
echo ""
echo "Generating link credentials for Cluster B..."
linkerd --context default multicluster link \
  --cluster-name cluster-a \
  > "$SCRIPT_DIR/cluster-a-link.yaml"

echo ""
echo "=========================================="
echo "Linkerd Multicluster Setup Complete on Cluster A!"
echo "=========================================="
echo ""
echo "Link credentials saved to: $SCRIPT_DIR/cluster-a-link.yaml"
echo ""
echo "Gateway information:"
kubectl get svc linkerd-gateway -n linkerd-multicluster -o wide
echo ""
echo "Next steps:"
echo "1. Copy cluster-a-link.yaml to VM B"
echo "2. On VM B, apply: kubectl apply -f cluster-a-link.yaml"
echo ""
