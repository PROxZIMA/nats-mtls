#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR="$SCRIPT_DIR/../manifests"

echo "=========================================="
echo "Deploying NATS Broker"
echo "=========================================="

export KUBECONFIG=~/.kube/config

# Create namespace
echo "Creating nats-system namespace..."
kubectl create namespace nats-system --dry-run=client -o yaml | kubectl apply -f -

# Annotate namespace for Linkerd injection
echo "Annotating namespace for Linkerd injection..."
kubectl annotate namespace nats-system linkerd.io/inject=enabled --overwrite

# Deploy Linkerd Server resources for NATS protocol configuration
# echo "Deploying Linkerd Server resources..."
# kubectl apply -f "$MANIFEST_DIR/linkerd-server-nats.yaml"

# Create NATS authentication secret
echo "Creating NATS authentication secret..."
kubectl apply -f "$MANIFEST_DIR/nats-auth-secret.yaml"

# Deploy NATS Broker
echo "Deploying NATS Broker..."
kubectl apply -f "$MANIFEST_DIR/nats-broker.yaml"

# Setup Ingress for NATS
echo "Setting up Ingress for NATS..."
bash "./setup-nats-ingress.sh"

# Wait for deployment to be created
echo "Waiting for deployment to be created..."
sleep 5

# Wait for NATS broker to be ready
echo "Waiting for NATS broker to be ready..."
until kubectl get pods -l app=nats-broker -n nats-system 2>/dev/null | grep -q nats-broker; do
  echo "  Waiting for pods to be created..."
  sleep 2
done
kubectl wait --for=condition=Ready pods -l app=nats-broker -n nats-system --timeout=300s

# Get pod status
echo ""
echo "NATS Broker Status:"
kubectl get pods -n nats-system -l app=nats-broker

# Check if Linkerd proxy is injected
echo ""
echo "Verifying Linkerd proxy injection:"
kubectl get pods -n nats-system -l app=nats-broker -o jsonpath='{.items[0].spec.containers[*].name}'
echo ""

echo ""
echo "=========================================="
echo "NATS Broker Deployment Complete!"
echo "=========================================="
echo ""
echo "Internal endpoint (within cluster):"
echo "  nats-broker.nats-system.svc.cluster.local:4222"
echo ""
echo "External access via Ingress (NodePort):"
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "<NODE-IP>")
echo "  Client endpoint: $NODE_IP:30422"
echo "  Leafnode endpoint: $NODE_IP:30722"
echo ""
echo "To get node IP: kubectl get nodes -o wide"
