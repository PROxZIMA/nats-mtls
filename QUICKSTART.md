# Quick Start Guide

## Prerequisites Checklist

- [ ] Two Ubuntu VMs ready (VM A: 1.1.1.1, VM B: 2.2.2.2)
- [ ] SSH access to both VMs
- [ ] VMs can reach each other
- [ ] User: ubuntu with sudo privileges

## Quick Setup Commands

### 1. Generate Certificates (Local Machine)

```bash
cd NATS-mTLS
chmod +x shared/generate-certificates.sh
./shared/generate-certificates.sh
```

### 2. Deploy to VM A (Broker)

```bash
# Copy files
scp -r vm-a-broker shared manifests ubuntu@1.1.1.1:/home/ubuntu/
ssh ubuntu@1.1.1.1 "mkdir -p /home/ubuntu/vm-a-broker/certs"
scp certs/ca.crt certs/cluster-a-issuer.* ubuntu@1.1.1.1:/home/ubuntu/vm-a-broker/certs/

# Setup VM A
ssh ubuntu@1.1.1.1
cd /home/ubuntu/vm-a-broker
chmod +x setup.sh install-linkerd.sh deploy-nats-broker.sh deploy-publisher.sh ../shared/*.sh
./setup.sh
```

### 3. Deploy to VM B (Leaf)

```bash
# Copy files
scp -r vm-b-leaf shared manifests ubuntu@2.2.2.2:/home/ubuntu/
ssh ubuntu@2.2.2.2 "mkdir -p /home/ubuntu/vm-b-leaf/certs"
scp certs/ca.crt certs/cluster-b-issuer.* ubuntu@2.2.2.2:/home/ubuntu/vm-b-leaf/certs/

# Setup VM B
ssh ubuntu@2.2.2.2
cd /home/ubuntu/vm-b-leaf
chmod +x setup.sh install-linkerd.sh deploy-nats-leaf.sh deploy-subscriber.sh ../shared/*.sh
BROKER_IP=1.1.1.1 ./setup.sh
```

### 4. Verify

On VM B:
```bash
kubectl logs -n nats-system -l app=nats-subscriber -f
```

You should see messages arriving from VM A!

## Expected Timeline

- Certificate generation: ~1 minute
- VM A setup: ~10-15 minutes
- VM B setup: ~10-15 minutes
- **Total**: ~25-30 minutes

## Verification Commands

### VM A (Broker)
```bash
# Check everything is running
kubectl get pods -n nats-system

# Watch publisher sending messages
kubectl logs -n nats-system -l app=nats-publisher -f

# Check Linkerd mTLS
linkerd check
```

### VM B (Leaf)
```bash
# Check everything is running
kubectl get pods -n nats-system

# Watch subscriber receiving messages
kubectl logs -n nats-system -l app=nats-subscriber -f

# Check Linkerd mTLS
linkerd check
```

## Troubleshooting Quick Fixes

### Subscriber not receiving messages?

```bash
# On VM B - check leaf connection
kubectl logs -n nats-system -l app=nats-leaf | grep -i connect

# On VM A - check if leafnode port is open
sudo ufw allow 30722/tcp
sudo ufw status
```

### Linkerd issues?

```bash
linkerd check
# Follow the recommendations from check output
```

### Need to start over?

```bash
# Uninstall K3S
sudo /usr/local/bin/k3s-uninstall.sh

# Re-run setup
./setup.sh
```
