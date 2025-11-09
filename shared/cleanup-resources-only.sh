#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "Cleanup NATS Resources Only"
echo "=========================================="
echo ""
echo "This script will remove only NATS deployments"
echo "without touching K3S or Linkerd installation."
echo ""
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

export KUBECONFIG=~/.kube/config

echo ""
echo "Deleting NATS resources..."

# Delete deployments
echo "  Deleting deployments..."
kubectl delete deployment nats-broker -n nats-system --ignore-not-found=true
kubectl delete deployment nats-leaf -n nats-system --ignore-not-found=true
kubectl delete deployment nats-publisher -n nats-system --ignore-not-found=true
kubectl delete deployment nats-subscriber -n nats-system --ignore-not-found=true

# Delete services
echo "  Deleting services..."
kubectl delete service nats-broker -n nats-system --ignore-not-found=true
kubectl delete service nats-broker-external -n nats-system --ignore-not-found=true
kubectl delete service nats-leaf -n nats-system --ignore-not-found=true

# Delete configmaps
echo "  Deleting configmaps..."
kubectl delete configmap nats-broker-config -n nats-system --ignore-not-found=true
kubectl delete configmap nats-leaf-config -n nats-system --ignore-not-found=true

# Delete secrets
echo "  Deleting secrets..."
kubectl delete secret nats-auth -n nats-system --ignore-not-found=true

echo ""
echo "✓ NATS resources deleted"
echo ""
echo "The namespace 'nats-system' is still present."
echo "To delete it completely, run:"
echo "  kubectl delete namespace nats-system"
echo ""
echo "K3S and Linkerd are still running."
