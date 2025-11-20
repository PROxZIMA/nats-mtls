#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "VM A - Cleanup Script"
echo "=========================================="
echo ""
echo "WARNING: This will remove:"
echo "  - All NATS deployments and resources"
echo "  - Linkerd service mesh"
echo "  - K3S cluster"
echo "  - Installed binaries (kubectl, helm, linkerd, etc.)"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Starting cleanup..."
echo ""

# Step 1: Delete NATS resources 
echo "1. Deleting NATS resources..."
if kubectl get namespace nats-system &> /dev/null; then
    kubectl delete namespace nats-system --timeout=60s || true
    echo "   ✓ NATS namespace deleted"
else
    echo "   ⚠ NATS namespace not found"
fi

# Step 2: Uninstall Linkerd
echo ""
echo "2. Uninstalling Linkerd..."
if command -v linkerd &> /dev/null; then
    if kubectl get namespace linkerd &> /dev/null; then
        linkerd viz uninstall | kubectl delete -f - || true
        linkerd multicluster uninstall | kubectl delete -f - || true
        linkerd uninstall | kubectl delete -f - || true
        echo "   ✓ Linkerd uninstalled"
    else
        echo "   ⚠ Linkerd not found"
    fi
else
    echo "   ⚠ Linkerd CLI not found"
fi

# Step 3: Delete Gateway API CRDs
echo ""
echo "3. Deleting Gateway API CRDs..."
kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/standard-install.yaml --ignore-not-found=true || true
echo "   ✓ Gateway API CRDs deleted"

# Step 4: Uninstall K3S
echo ""
echo "4. Uninstalling K3S..."
if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
    sudo /usr/local/bin/k3s-uninstall.sh
    echo "   ✓ K3S uninstalled"
else
    echo "   ⚠ K3S not installed"
fi

# Step 5: Remove configuration files
echo ""
echo "5. Removing configuration files..."
rm -rf ~/.kube/config
rm -rf ~/.kube/config-external
rm -rf ~/.kube-config
echo "   ✓ Kubernetes config removed"

# Step 6: Remove installed binaries (optional)
echo ""
read -p "Do you want to remove installed binaries (kubectl, helm, linkerd, nats, step)? (yes/no): " remove_bins

if [ "$remove_bins" == "yes" ]; then
    echo "6. Removing installed binaries..."
    
    sudo rm -f /usr/local/bin/kubectl
    echo "   ✓ kubectl removed"
    
    sudo rm -f /usr/local/bin/helm
    echo "   ✓ helm removed"
    
    rm -rf ~/.linkerd2
    sudo rm -f /usr/local/bin/linkerd
    echo "   ✓ linkerd removed"
    
    sudo rm -f /usr/local/bin/nats
    echo "   ✓ nats removed"
    
    sudo rm -f /usr/local/bin/step
    echo "   ✓ step removed"
else
    echo "6. Skipping binary removal"
fi

# Step 7: Remove project files (optional)
echo ""
read -p "Do you want to remove project files from ~/nats? (yes/no): " remove_files

if [ "$remove_files" == "yes" ]; then
    echo "7. Removing project files..."
    cd ~
    rm -rfd ~/nats
    echo "   ✓ Project files removed"
else
    echo "7. Keeping project files"
fi

echo ""
echo "=========================================="
echo "VM A Cleanup Complete!"
echo "=========================================="
echo ""
echo "Cleaned up:"
echo "  ✓ NATS resources"
echo "  ✓ Linkerd service mesh"
echo "  ✓ Gateway API CRDs"
echo "  ✓ K3S cluster"
if [ "$remove_bins" == "yes" ]; then
    echo "  ✓ Installed binaries"
fi
if [ "$remove_files" == "yes" ]; then
    echo "  ✓ Project files"
fi
echo ""
echo "Note: You may want to reboot the system to ensure all processes are stopped."
