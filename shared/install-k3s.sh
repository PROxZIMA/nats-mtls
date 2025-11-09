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
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik" sh -

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

# Wait for all system pods to be ready
echo "Waiting for system pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n kube-system --timeout=300s

echo ""
echo "=========================================="
echo "K3S Installation Complete!"
echo "=========================================="
echo ""
kubectl get nodes
