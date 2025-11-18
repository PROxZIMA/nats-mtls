#!/bin/bash

# Setup Nginx Ingress Controller with TCP Support for NATS
# This script deploys the ingress controller with NATS ports pre-configured

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR="$SCRIPT_DIR/../manifests"

echo "=== Setting up Nginx Ingress Controller for NATS ==="

# Check if Nginx Ingress Controller already exists
if kubectl get namespace ingress-nginx &> /dev/null; then
    echo "Nginx Ingress Controller namespace already exists"
    echo "Checking for existing deployment..."
    if kubectl get deployment ingress-nginx-controller -n ingress-nginx &> /dev/null; then
        echo "WARNING: Ingress controller already deployed"
        echo "To redeploy, first run: kubectl delete namespace ingress-nginx"
        exit 1
    fi
fi

# Deploy Nginx Ingress Controller with TCP configuration
echo "Deploying Nginx Ingress Controller with NATS TCP support..."
kubectl apply -f "$MANIFEST_DIR/nats-ingress.yaml"

# Wait for the admission webhook job to complete
echo "Waiting for admission webhook setup..."
kubectl wait --namespace ingress-nginx \
  --for=condition=complete \
  --timeout=120s \
  job/ingress-nginx-admission-create 2>/dev/null || echo "Admission job already completed or in progress"

# Wait for ingress controller to be ready
echo "Waiting for ingress controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

# Apply HTTP monitoring ingress
echo "Applying HTTP monitoring ingress..."
kubectl apply -f "$MANIFEST_DIR/nats-ingress.yaml"

echo ""
echo "=== Ingress Controller Setup Complete ==="
echo ""
echo "Checking service status..."
kubectl get svc ingress-nginx-controller -n ingress-nginx

echo ""
echo "NATS will be accessible at:"
echo "  Client port: <NODE-IP>:30422"
echo "  Leafnode port: <NODE-IP>:30722"
echo ""
echo "To get the node IP:"
echo "  kubectl get nodes -o wide"
echo ""
echo "HTTP Monitoring (add to /etc/hosts):"
echo "  <NODE-IP> nats-broker.local"
echo "  Access: http://nats-broker.local/"
echo ""
