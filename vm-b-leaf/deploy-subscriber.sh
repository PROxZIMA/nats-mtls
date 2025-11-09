#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR="$SCRIPT_DIR/../manifests"

echo "=========================================="
echo "Deploying NATS Subscriber"
echo "=========================================="

export KUBECONFIG=~/.kube/config

# Deploy Subscriber
echo "Deploying NATS Subscriber..."
kubectl apply -f "$MANIFEST_DIR/nats-subscriber.yaml"

# Wait for deployment to be created
echo "Waiting for deployment to be created..."
sleep 5

# Wait for subscriber to be ready
echo "Waiting for subscriber to be ready..."
until kubectl get pods -l app=nats-subscriber -n nats-system 2>/dev/null | grep -q nats-subscriber; do
  echo "  Waiting for pods to be created..."
  sleep 2
done
kubectl wait --for=condition=Ready pods -l app=nats-subscriber -n nats-system --timeout=300s

# Get pod status
echo ""
echo "Subscriber Status:"
kubectl get pods -n nats-system -l app=nats-subscriber

echo ""
echo "=========================================="
echo "Subscriber Deployment Complete!"
echo "=========================================="
echo ""
echo "To view subscriber logs:"
echo "  kubectl logs -n nats-system -l app=nats-subscriber -f"
