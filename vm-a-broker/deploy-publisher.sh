#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR="$SCRIPT_DIR/../manifests"

echo "=========================================="
echo "Deploying NATS Publisher"
echo "=========================================="

export KUBECONFIG=~/.kube/config

# Deploy Publisher
echo "Deploying NATS Publisher..."
kubectl apply -f "$MANIFEST_DIR/nats-publisher.yaml"

# Wait for deployment to be created
echo "Waiting for deployment to be created..."
sleep 5

# Wait for publisher to be ready
echo "Waiting for publisher to be ready..."
until kubectl get pods -l app=nats-publisher -n nats-system 2>/dev/null | grep -q nats-publisher; do
  echo "  Waiting for pods to be created..."
  sleep 2
done
kubectl wait --for=condition=Ready pods -l app=nats-publisher -n nats-system --timeout=300s

# Get pod status
echo ""
echo "Publisher Status:"
kubectl get pods -n nats-system -l app=nats-publisher

echo ""
echo "=========================================="
echo "Publisher Deployment Complete!"
echo "=========================================="
echo ""
echo "To view publisher logs:"
echo "  kubectl logs -n nats-system -l app=nats-publisher -f"
