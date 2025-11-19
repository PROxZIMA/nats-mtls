#!/bin/bash
# Script to create Kubernetes secrets from generated NATS certificates
# This should be run after generate-nats-certificates.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NATS_CERT_DIR="$SCRIPT_DIR/../certs/nats"

echo "=========================================="
echo "Creating NATS Certificate Secrets for VM A (Broker)"
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
# 2. Create Broker Server Certificate Secret
# ============================================================================
echo ""
echo "Creating broker server certificate secret..."
kubectl create secret tls nats-broker-server-tls \
  --cert="$NATS_CERT_DIR/broker/server.crt" \
  --key="$NATS_CERT_DIR/broker/server.key" \
  --namespace=nats-system \
  --dry-run=client -o yaml | kubectl apply -f -

echo "   ✓ nats-broker-server-tls secret created"

# ============================================================================
# 3. Create Publisher Client Certificate Secret
# ============================================================================
echo ""
echo "Creating publisher client certificate secret..."
kubectl create secret tls nats-publisher-client-tls \
  --cert="$NATS_CERT_DIR/clients/publisher-client.crt" \
  --key="$NATS_CERT_DIR/clients/publisher-client.key" \
  --namespace=nats-system \
  --dry-run=client -o yaml | kubectl apply -f -

echo "   ✓ nats-publisher-client-tls secret created"

# ============================================================================
# 4. Create Leaf Client Certificate Secret (for broker to verify leaf connections)
# ============================================================================
echo ""
echo "Creating leaf client certificate secret (for broker verification)..."
kubectl create secret tls nats-leaf-client-tls \
  --cert="$NATS_CERT_DIR/clients/leaf-client.crt" \
  --key="$NATS_CERT_DIR/clients/leaf-client.key" \
  --namespace=nats-system \
  --dry-run=client -o yaml | kubectl apply -f -

echo "   ✓ nats-leaf-client-tls secret created"

echo ""
echo "=========================================="
echo "VM A (Broker) Secrets Created Successfully!"
echo "=========================================="
echo ""
echo "Created secrets in namespace 'nats-system':"
echo "  - nats-ca (CA certificate)"
echo "  - nats-broker-server-tls (broker server cert/key)"
echo "  - nats-publisher-client-tls (publisher client cert/key)"
echo "  - nats-leaf-client-tls (leaf node client cert/key)"
echo ""
echo "Verify with: kubectl get secrets -n nats-system"
echo ""
