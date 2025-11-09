#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR="$SCRIPT_DIR/../manifests"

# VM A IP address (NATS Broker)
BROKER_IP="${BROKER_IP:-1.1.1.1}"

echo "=========================================="
echo "Deploying NATS Leaf"
echo "=========================================="
echo "Connecting to broker at: $BROKER_IP"
echo ""

export KUBECONFIG=~/.kube/config

# Create namespace
echo "Creating nats-system namespace..."
kubectl create namespace nats-system --dry-run=client -o yaml | kubectl apply -f -

# Annotate namespace for Linkerd injection
echo "Annotating namespace for Linkerd injection..."
kubectl annotate namespace nats-system linkerd.io/inject=enabled --overwrite

# Create NATS authentication secret
echo "Creating NATS authentication secret..."
kubectl apply -f "$MANIFEST_DIR/nats-auth-secret.yaml"

# Create ConfigMap with broker IP
echo "Creating NATS leaf configuration..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: nats-leaf-config
  namespace: nats-system
data:
  BROKER_IP: "$BROKER_IP"
EOF

# Deploy NATS Leaf
echo "Deploying NATS Leaf..."
sed "s/BROKER_IP_PLACEHOLDER/$BROKER_IP/g" "$MANIFEST_DIR/nats-leaf.yaml" | kubectl apply -f -

# Wait for deployment to be created
echo "Waiting for deployment to be created..."
sleep 5

# Wait for NATS leaf to be ready
echo "Waiting for NATS leaf to be ready..."
until kubectl get pods -l app=nats-leaf -n nats-system 2>/dev/null | grep -q nats-leaf; do
  echo "  Waiting for pods to be created..."
  sleep 2
done
kubectl wait --for=condition=Ready pods -l app=nats-leaf -n nats-system --timeout=300s

# Get pod status
echo ""
echo "NATS Leaf Status:"
kubectl get pods -n nats-system -l app=nats-leaf

# Check if Linkerd proxy is injected
echo ""
echo "Verifying Linkerd proxy injection:"
kubectl get pods -n nats-system -l app=nats-leaf -o jsonpath='{.items[0].spec.containers[*].name}'
echo ""

echo ""
echo "=========================================="
echo "NATS Leaf Deployment Complete!"
echo "=========================================="
echo ""
echo "Leaf endpoint: nats-leaf.nats-system.svc.cluster.local:4222"
echo "Connected to broker: $BROKER_IP:7422"
