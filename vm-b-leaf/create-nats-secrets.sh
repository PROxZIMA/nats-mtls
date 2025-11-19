#!/bin/bash
# Script to create Kubernetes secrets from generated NATS certificates for VM B (Leaf)
# This should be run after generate-nats-certificates.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NATS_CERT_DIR="$SCRIPT_DIR/../certs/nats"

echo "=========================================="
echo "Creating NATS Certificate Secrets for VM B (Leaf)"
echo "=========================================="

# Check if certificates exist
if [ ! -d "$NATS_CERT_DIR" ]; then
    echo "ERROR: Certificate directory not found: $NATS_CERT_DIR"
    echo "Please run generate-nats-certificates.sh first"
    exit 1
fi

export KUBECONFIG=~/.kube/config

# Create namespace
echo "Creating nats-system namespace..."
kubectl create namespace nats-system --dry-run=client -o yaml | kubectl apply -f -

# ============================================================================
# 1. Create CA Secret (common for all components)
# ============================================================================
echo ""
echo "Creating CA secret..."
kubectl create secret generic nats-ca \
  --from-file=ca.crt="$NATS_CERT_DIR/ca/ca.crt" \
  --namespace=nats-system \
  --dry-run=client -o yaml | kubectl apply -f -

echo "   ✓ nats-ca secret created"

# ============================================================================
# 2. Create Leaf Server Certificate Secret
# ============================================================================
echo ""
echo "Creating leaf server certificate secret..."
kubectl create secret tls nats-leaf-server-tls \
  --cert="$NATS_CERT_DIR/leaf/server.crt" \
  --key="$NATS_CERT_DIR/leaf/server.key" \
  --namespace=nats-system \
  --dry-run=client -o yaml | kubectl apply -f -

echo "   ✓ nats-leaf-server-tls secret created"

# ============================================================================
# 3. Create Leaf Client Certificate Secret (for connecting to broker)
# ============================================================================
echo ""
echo "Creating leaf client certificate secret (for connecting to broker)..."
kubectl create secret tls nats-leaf-client-tls \
  --cert="$NATS_CERT_DIR/clients/leaf-client.crt" \
  --key="$NATS_CERT_DIR/clients/leaf-client.key" \
  --namespace=nats-system \
  --dry-run=client -o yaml | kubectl apply -f -

echo "   ✓ nats-leaf-client-tls secret created"

# ============================================================================
# 4. Create Subscriber Client Certificate Secret
# ============================================================================
echo ""
echo "Creating subscriber client certificate secret..."
kubectl create secret tls nats-subscriber-client-tls \
  --cert="$NATS_CERT_DIR/clients/subscriber-client.crt" \
  --key="$NATS_CERT_DIR/clients/subscriber-client.key" \
  --namespace=nats-system \
  --dry-run=client -o yaml | kubectl apply -f -

echo "   ✓ nats-subscriber-client-tls secret created"

echo ""
echo "=========================================="
echo "VM B (Leaf) Secrets Created Successfully!"
echo "=========================================="
echo ""
echo "Created secrets in namespace 'nats-system':"
echo "  - nats-ca (CA certificate)"
echo "  - nats-leaf-server-tls (leaf server cert/key)"
echo "  - nats-leaf-client-tls (leaf client cert/key for broker connection)"
echo "  - nats-subscriber-client-tls (subscriber client cert/key)"
echo ""
echo "Verify with: kubectl get secrets -n nats-system"
echo ""
