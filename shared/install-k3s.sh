#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "Installing K3S"
echo "=========================================="

# Check if K3S is already installed
if command -v k3s &> /dev/null; then
    echo "K3S is already installed"
    k3s --version
    exit 0
fi

# Install K3S without traefik (we'll use linkerd for service mesh)
echo "Installing K3S..."

# Get node IPs
NODE_INTERNAL_IP="${NODE_INTERNAL_IP:-}"
NODE_EXTERNAL_IP="${NODE_EXTERNAL_IP:-}"

# Build K3S exec args
K3S_ARGS="--disable=traefik"

if [ -n "$NODE_EXTERNAL_IP" ]; then
    echo "Configuring K3S with external IP: $NODE_EXTERNAL_IP"
    K3S_ARGS="$K3S_ARGS --node-external-ip=$NODE_EXTERNAL_IP --tls-san=$NODE_EXTERNAL_IP"
fi

if [ -n "$NODE_INTERNAL_IP" ]; then
    echo "Configuring K3S with internal IP: $NODE_INTERNAL_IP"
    K3S_ARGS="$K3S_ARGS --node-ip=$NODE_INTERNAL_IP"
fi

echo "K3S installation arguments: $K3S_ARGS"
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="$K3S_ARGS" sh -

# Wait for K3S to be ready
echo "Waiting for K3S to be ready..."
sleep 10

# Setup kubeconfig for ubuntu user
sudo cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube-config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube-config
export KUBECONFIG=/home/ubuntu/.kube-config
echo 'export KUBECONFIG=/home/ubuntu/.kube-config' >> ~/.bashrc

# Create .kube directory if it doesn't exist
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown ubuntu:ubuntu ~/.kube/config

# If external IP is provided, create a second kubeconfig with external IP
if [ -n "$NODE_EXTERNAL_IP" ]; then
    echo ""
    echo "Creating kubeconfig with external IP for multicluster..."
    sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config-external
    sudo chown ubuntu:ubuntu ~/.kube/config-external
    
    # Replace 127.0.0.1 with external IP
    sed -i "s|https://127.0.0.1:6443|https://$NODE_EXTERNAL_IP:6443|g" ~/.kube/config-external
    
    echo "✓ Created ~/.kube/config-external (for multicluster)"
    echo "✓ API server accessible at: https://$NODE_EXTERNAL_IP:6443"
fi

# Wait for all system pods to be ready
echo "Waiting for system pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n kube-system --timeout=300s

echo ""
echo "=========================================="
echo "K3S Installation Complete!"
echo "=========================================="
echo ""
kubectl get nodes
