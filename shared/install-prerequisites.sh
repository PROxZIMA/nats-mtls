#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "Installing Prerequisites"
echo "=========================================="

ARCH=$(dpkg --print-architecture)

# Update system
echo "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install basic tools
echo "Installing basic tools..."
sudo apt-get install -y curl wget git jq

# Install kubectl
echo "Installing kubectl..."
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    echo "kubectl installed successfully"
else
    echo "kubectl already installed"
fi

# Install helm
echo "Installing Helm..."
if ! command -v helm &> /dev/null; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    echo "Helm installed successfully"
else
    echo "Helm already installed"
fi

# Install linkerd CLI
echo "Installing Linkerd CLI..."
if ! command -v linkerd &> /dev/null; then
    curl -sL https://run.linkerd.io/install | sh
    export PATH=$PATH:$HOME/.linkerd2/bin
    echo 'export PATH=$PATH:$HOME/.linkerd2/bin' >> ~/.bashrc
    echo "Linkerd CLI installed successfully"
else
    echo "Linkerd CLI already installed"
fi

# Install step-cli for certificate generation
echo "Installing step-cli..."
if ! command -v step &> /dev/null; then
    wget -O step.tar.gz https://dl.smallstep.com/gh-release/cli/gh-release-header/v0.25.0/step_linux_0.25.0_${ARCH}.tar.gz
    tar -xzf step.tar.gz
    sudo mv step_0.25.0/bin/step /usr/local/bin/
    rm -rf step.tar.gz step_0.25.0
    echo "step-cli installed successfully"
else
    echo "step-cli already installed"
fi

# Install NATS CLI
echo "Installing NATS CLI..."
if ! command -v nats &> /dev/null; then
    curl -sf https://binaries.nats.dev/nats-io/natscli/nats@latest | sh
    sudo mv nats /usr/local/bin/
    echo "NATS CLI installed successfully"
else
    echo "NATS CLI already installed"
fi

# Install k9s
echo "Installing k9s..."
if ! command -v k9s &> /dev/null; then
    wget -O k9s.tar.gz "https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_${ARCH}.tar.gz"
    tar -xzf k9s.tar.gz k9s
    sudo mv k9s /usr/local/bin/
    rm -f k9s.tar.gz LICENSE README.md
    echo "k9s installed successfully"
else
    echo "k9s already installed"
fi

echo ""
echo "=========================================="
echo "Prerequisites Installation Complete!"
echo "=========================================="
echo ""
echo "Installed versions:"
kubectl version --client --short 2>/dev/null || kubectl version --client
helm version --short
linkerd version --client --short
step version
nats --version
k9s version --short
