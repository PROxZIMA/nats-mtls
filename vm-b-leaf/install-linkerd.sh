#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT_DIR="$SCRIPT_DIR/../certs"

echo "=========================================="
echo "Installing Linkerd on Cluster B (Leaf)"
echo "=========================================="

export KUBECONFIG=~/.kube/config
export PATH=$PATH:$HOME/.linkerd2/bin

# Check Linkerd pre-requisites
echo "Checking Linkerd pre-requisites..."
linkerd check --pre

# Install Gateway API CRDs (required for Linkerd)
echo ""
echo "Installing Gateway API CRDs..."
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/standard-install.yaml

# Install Linkerd CRDs
echo ""
echo "Installing Linkerd CRDs..."
linkerd install --crds | kubectl apply -f -

# Install Linkerd control plane with custom certificates
echo ""
echo "Installing Linkerd control plane..."
linkerd install \
  --identity-trust-anchors-file "$CERT_DIR/ca.crt" \
  --identity-issuer-certificate-file "$CERT_DIR/cluster-b-issuer.crt" \
  --identity-issuer-key-file "$CERT_DIR/cluster-b-issuer.key" \
  | kubectl apply -f -

# Wait for Linkerd to be ready
echo ""
echo "Waiting for Linkerd to be ready..."
linkerd check

echo ""
echo "=========================================="
echo "Linkerd Installation Complete on Cluster B!"
echo "=========================================="
