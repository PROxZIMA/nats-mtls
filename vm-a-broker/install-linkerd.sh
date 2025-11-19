#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT_DIR="$SCRIPT_DIR/../certs"

echo "=========================================="
echo "Installing Linkerd on Cluster A (Broker)"
echo "=========================================="

export KUBECONFIG=~/.kube/config
export PATH=$PATH:$HOME/.linkerd2/bin

# Check if Linkerd is already installed
echo "Checking for existing Linkerd installation..."
if kubectl get namespace linkerd > /dev/null 2>&1; then
    echo "Linkerd namespace found. Checking installation status..."
    if linkerd check > /dev/null 2>&1; then
        echo "Linkerd is already installed and healthy!"
        echo "Skipping installation..."
        echo ""
        echo "=========================================="
        echo "Linkerd Already Installed on Cluster A!"
        echo "=========================================="
        exit 0
    else
        echo "Linkerd installation found but not healthy. Reinstalling..."
        echo "Removing existing Linkerd installation..."
        linkerd uninstall | kubectl delete -f - || true
        kubectl delete namespace linkerd --timeout=60s || true
    fi
else
    echo "No existing Linkerd installation found."
fi

# Check Linkerd pre-requisites
echo ""
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
  --identity-issuer-certificate-file "$CERT_DIR/cluster-a-issuer.crt" \
  --identity-issuer-key-file "$CERT_DIR/cluster-a-issuer.key" \
  | kubectl apply -f -

# Wait for Linkerd to be ready
echo ""
echo "Waiting for Linkerd to be ready..."
linkerd check

echo ""
echo "=========================================="
echo "Linkerd Installation Complete on Cluster A!"
echo "=========================================="
