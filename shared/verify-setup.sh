#!/bin/bash
# Troubleshooting and verification script
# Can be run on either VM to check the setup

set -euo pipefail

NAMESPACE="nats-system"

echo "=========================================="
echo "NATS-mTLS Setup Verification"
echo "=========================================="
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl first."
    exit 1
fi

export KUBECONFIG=~/.kube/config

echo "1. Checking Kubernetes Cluster..."
echo "-----------------------------------"
if kubectl cluster-info &> /dev/null; then
    echo "✅ Kubernetes cluster is accessible"
    kubectl get nodes
else
    echo "❌ Cannot connect to Kubernetes cluster"
    exit 1
fi
echo ""

echo "2. Checking Linkerd Installation..."
echo "-----------------------------------"
if command -v linkerd &> /dev/null; then
    export PATH=$PATH:$HOME/.linkerd2/bin
    if linkerd check --pre &> /dev/null; then
        echo "✅ Linkerd prerequisites met"
    else
        echo "⚠️  Linkerd prerequisites check failed"
    fi
    
    if kubectl get namespace linkerd &> /dev/null; then
        echo "✅ Linkerd namespace exists"
        if linkerd check &> /dev/null; then
            echo "✅ Linkerd is healthy"
        else
            echo "❌ Linkerd health check failed"
            echo "Run: linkerd check"
        fi
    else
        echo "❌ Linkerd is not installed"
    fi
else
    echo "⚠️  Linkerd CLI not found"
fi
echo ""

echo "3. Checking NATS Namespace..."
echo "-----------------------------------"
if kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo "✅ Namespace $NAMESPACE exists"
    
    # Check namespace annotation
    INJECT_ANNOTATION=$(kubectl get namespace "$NAMESPACE" -o jsonpath='{.metadata.annotations.linkerd\.io/inject}')
    if [ "$INJECT_ANNOTATION" == "enabled" ]; then
        echo "✅ Linkerd injection enabled on namespace"
    else
        echo "⚠️  Linkerd injection not enabled on namespace"
    fi
else
    echo "❌ Namespace $NAMESPACE does not exist"
    exit 1
fi
echo ""

echo "4. Checking NATS Pods..."
echo "-----------------------------------"
PODS=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
if [ "$PODS" -eq 0 ]; then
    echo "❌ No pods found in namespace $NAMESPACE"
else
    echo "✅ Found $PODS pod(s) in namespace $NAMESPACE"
    kubectl get pods -n "$NAMESPACE"
    echo ""
    
    # Check each pod for linkerd proxy
    echo "Checking Linkerd proxy injection..."
    for POD in $(kubectl get pods -n "$NAMESPACE" -o name); do
        POD_NAME=$(basename "$POD")
        CONTAINERS=$(kubectl get "$POD" -n "$NAMESPACE" -o jsonpath='{.spec.containers[*].name}')
        if echo "$CONTAINERS" | grep -q "linkerd-proxy"; then
            echo "  ✅ $POD_NAME has linkerd-proxy"
        else
            echo "  ❌ $POD_NAME missing linkerd-proxy"
        fi
    done
fi
echo ""

echo "5. Checking NATS Services..."
echo "-----------------------------------"
kubectl get services -n "$NAMESPACE"
echo ""

echo "6. Checking NATS Authentication Secret..."
echo "-----------------------------------"
if kubectl get secret nats-auth -n "$NAMESPACE" &> /dev/null; then
    echo "✅ NATS authentication secret exists"
    kubectl get secret nats-auth -n "$NAMESPACE" -o jsonpath='{.data}' | jq 'keys'
else
    echo "❌ NATS authentication secret not found"
fi
echo ""

echo "7. Checking Pod Logs (last 10 lines)..."
echo "-----------------------------------"

# Check NATS Broker
if kubectl get deployment nats-broker -n "$NAMESPACE" &> /dev/null; then
    echo "NATS Broker logs:"
    kubectl logs -n "$NAMESPACE" deployment/nats-broker --tail=10 2>/dev/null || echo "  ⚠️  No logs available"
    echo ""
fi

# Check NATS Leaf
if kubectl get deployment nats-leaf -n "$NAMESPACE" &> /dev/null; then
    echo "NATS Leaf logs:"
    kubectl logs -n "$NAMESPACE" deployment/nats-leaf --tail=10 2>/dev/null || echo "  ⚠️  No logs available"
    echo ""
fi

# Check Publisher
if kubectl get deployment nats-publisher -n "$NAMESPACE" &> /dev/null; then
    echo "Publisher logs:"
    kubectl logs -n "$NAMESPACE" deployment/nats-publisher --tail=10 2>/dev/null || echo "  ⚠️  No logs available"
    echo ""
fi

# Check Subscriber
if kubectl get deployment nats-subscriber -n "$NAMESPACE" &> /dev/null; then
    echo "Subscriber logs:"
    kubectl logs -n "$NAMESPACE" deployment/nats-subscriber --tail=10 2>/dev/null || echo "  ⚠️  No logs available"
    echo ""
fi

echo "8. Network Connectivity Tests..."
echo "-----------------------------------"

# Check if this is broker or leaf by looking for deployments
if kubectl get deployment nats-broker -n "$NAMESPACE" &> /dev/null; then
    echo "This appears to be the BROKER cluster (VM A)"
    echo ""
    echo "Checking leafnode port accessibility..."
    if kubectl get service nats-broker-external -n "$NAMESPACE" &> /dev/null; then
        NODE_IP=$(hostname -I | awk '{print $1}')
        echo "  NodePort service exposed on: $NODE_IP:30722"
        echo "  Test from VM B with: nc -zv $NODE_IP 30722"
    fi
fi

if kubectl get deployment nats-leaf -n "$NAMESPACE" &> /dev/null; then
    echo "This appears to be the LEAF cluster (VM B)"
    echo ""
    echo "Checking connection to broker..."
    BROKER_CONFIG=$(kubectl get configmap nats-leaf-config -n "$NAMESPACE" -o jsonpath='{.data.nats\.conf}' 2>/dev/null || echo "")
    if [ -n "$BROKER_CONFIG" ]; then
        BROKER_IP=$(echo "$BROKER_CONFIG" | grep -oP 'nats-leaf://\K[0-9.]+' || echo "Not found")
        BROKER_PORT=$(echo "$BROKER_CONFIG" | grep -oP ':[0-9]+' | tr -d ':' || echo "30722")
        echo "  Configured broker: $BROKER_IP:$BROKER_PORT"
        echo "  Testing connectivity..."
        if command -v nc &> /dev/null; then
            if nc -zv -w 2 "$BROKER_IP" "$BROKER_PORT" 2>&1 | grep -q succeeded; then
                echo "  ✅ Can reach broker"
            else
                echo "  ❌ Cannot reach broker"
            fi
        else
            echo "  ⚠️  netcat not installed, skipping connectivity test"
        fi
    fi
fi
echo ""

echo "9. Linkerd Identity Check..."
echo "-----------------------------------"
if command -v linkerd &> /dev/null; then
    export PATH=$PATH:$HOME/.linkerd2/bin
    if kubectl get pods -n "$NAMESPACE" --no-headers &> /dev/null; then
        linkerd identity -n "$NAMESPACE" 2>/dev/null || echo "⚠️  Could not check Linkerd identity"
    fi
else
    echo "⚠️  Linkerd CLI not available"
fi
echo ""

echo "=========================================="
echo "Verification Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
kubectl get all -n "$NAMESPACE"
echo ""
echo "To view real-time logs:"
echo "  Publisher:  kubectl logs -n $NAMESPACE -l app=nats-publisher -f"
echo "  Subscriber: kubectl logs -n $NAMESPACE -l app=nats-subscriber -f"
echo "  Broker:     kubectl logs -n $NAMESPACE -l app=nats-broker -f"
echo "  Leaf:       kubectl logs -n $NAMESPACE -l app=nats-leaf -f"
echo ""
echo "To check Linkerd:"
echo "  linkerd check"
echo "  linkerd viz top deployment -n $NAMESPACE"
echo ""
