# NATS with Linkerd mTLS - Cross-Cluster Setup

This project sets up a NATS broker-leaf architecture across two separate K3S clusters with Linkerd service mesh for mTLS communication.

## Architecture Overview

```
┌────────────────────────────────────┐         ┌────────────────────────────────────┐
│          VM A (1.1.1.1)            │         │          VM B (2.2.2.2)            │
│         Broker Cluster             │         │          Leaf Cluster              │
│                                    │         │                                    │
│  ┌──────────────────────────────┐  │         │  ┌──────────────────────────────┐  │
│  │      K3S Cluster             │  │         │  │      K3S Cluster             │  │
│  │                              │  │         │  │                              │  │
│  │  ┌────────────────────────┐  │  │         │  │  ┌────────────────────────┐  │  │
│  │  │ Linkerd Control Plane  │  │  │         │  │  │ Linkerd Control Plane  │  │  │
│  │  │  (Same Root CA)        │  │  │         │  │  │  (Same Root CA)        │  │  │
│  │  └────────────────────────┘  │  │         │  │  └────────────────────────┘  │  │
│  │                              │  │         │  │                              │  │
│  │  ┌────────────────────────┐  │  │         │  │  ┌────────────────────────┐  │  │
│  │  │   NATS Broker          │  │  │         │  │  │   NATS Leaf            │  │  │
│  │  │   Port: 4222           │◄─┼──┼─────────┼──┼─►│   Port: 4222           │  │  │
│  │  │   Leafnode: 7422       │  │  │  mTLS   │  │  │   Remote: 1.1.1.1:30722│  │  │
│  │  │   (Linkerd Injected)   │  │  │         │  │  │   (Linkerd Injected)   │  │  │
│  │  └────────────────────────┘  │  │         │  │  └────────────────────────┘  │  │
│  │              ▲               │  │         │  │              ▲               │  │
│  │              │               │  │         │  │              │               │  │
│  │  ┌────────────────────────┐  │  │         │  │  ┌────────────────────────┐  │  │
│  │  │   Publisher            │  │  │         │  │  │   Subscriber           │  │  │
│  │  │   (NATS CLI)           │  │  │         │  │  │   (NATS CLI)           │  │  │
│  │  │   (Linkerd Injected)   │  │  │         │  │  │   (Linkerd Injected)   │  │  │
│  │  └────────────────────────┘  │  │         │  │  └────────────────────────┘  │  │
│  └──────────────────────────────┘  │         │  └──────────────────────────────┘  │
└────────────────────────────────────┘         └────────────────────────────────────┘
```

## Features

- ✅ Two separate K3S clusters (one per VM)
- ✅ Linkerd service mesh with shared root CA for cross-cluster mTLS
- ✅ NATS broker on VM A accepting leaf connections
- ✅ NATS leaf on VM B connecting to broker
- ✅ Username/password authentication for NATS
- ✅ Automatic Linkerd proxy injection via annotations
- ✅ Publisher client (VM A) sending messages every second
- ✅ Subscriber client (VM B) receiving messages
- ✅ Timestamped messages for clarity

## Directory Structure

```
NATS-mTLS/
├── vm-a-broker/                # VM A (Broker) setup scripts
│   ├── setup.sh                # Main setup script for VM A
│   ├── install-linkerd.sh      # Linkerd installation
│   ├── deploy-nats-broker.sh   # NATS broker deployment
│   ├── deploy-publisher.sh     # Publisher client deployment
│   └── certs/                  # Certificates for VM A (to be created)
│
├── vm-b-leaf/                  # VM B (Leaf) setup scripts
│   ├── setup.sh                # Main setup script for VM B
│   ├── install-linkerd.sh      # Linkerd installation
│   ├── deploy-nats-leaf.sh     # NATS leaf deployment
│   ├── deploy-subscriber.sh    # Subscriber client deployment
│   └── certs/                  # Certificates for VM B (to be created)
│
├── shared/                     # Common scripts
│   ├── install-prerequisites.sh # Install kubectl, helm, linkerd CLI, etc.
│   ├── install-k3s.sh          # K3S installation
│   └── generate-certificates.sh # Generate Linkerd certificates
│
├── manifests/                  # Kubernetes manifests
│   ├── nats-auth-secret.yaml   # NATS authentication credentials
│   ├── nats-broker.yaml        # NATS broker deployment
│   ├── nats-leaf.yaml          # NATS leaf deployment
│   ├── nats-publisher.yaml     # Publisher client deployment
│   └── nats-subscriber.yaml    # Subscriber client deployment
│
├── certs/                      # Generated certificates (local)
└── README.md                   # This file
```

## Prerequisites

- Two Ubuntu Linux VMs (fresh installation)
- VM A IP: 1.1.1.1
- VM B IP: 2.2.2.2
- VMs can communicate directly with each other
- User: ubuntu (with sudo privileges)
- Internet connectivity on both VMs

## Installation Steps

### Step 1: Generate Certificates (Run Locally)

On your local machine (or any machine with `step-cli` installed), generate the Linkerd certificates:

```bash
cd NATS-mTLS
chmod +x shared/generate-certificates.sh
./shared/generate-certificates.sh
```

This creates:
- `certs/ca.crt` - Root CA certificate (shared)
- `certs/ca.key` - Root CA key
- `certs/cluster-a-issuer.crt` - Cluster A identity issuer certificate
- `certs/cluster-a-issuer.key` - Cluster A identity issuer key
- `certs/cluster-b-issuer.crt` - Cluster B identity issuer certificate
- `certs/cluster-b-issuer.key` - Cluster B identity issuer key

### Step 2: Copy Files to VM A (Broker)

Copy the required files to VM A:

```bash
# From your local machine
VM_A_IP=129.154.247.85 VM_B_IP=144.24.103.105 ./deploy-to-vms.sh
scp -r vm-a-broker ubuntu@1.1.1.1:/home/ubuntu/
scp -r shared ubuntu@1.1.1.1:/home/ubuntu/
scp -r manifests ubuntu@1.1.1.1:/home/ubuntu/

# Create certs directory and copy certificates
ssh ubuntu@1.1.1.1 "mkdir -p /home/ubuntu/vm-a-broker/certs"
scp certs/ca.crt ubuntu@1.1.1.1:/home/ubuntu/vm-a-broker/certs/
scp certs/cluster-a-issuer.crt ubuntu@1.1.1.1:/home/ubuntu/vm-a-broker/certs/
scp certs/cluster-a-issuer.key ubuntu@1.1.1.1:/home/ubuntu/vm-a-broker/certs/
```

### Step 3: Copy Files to VM B (Leaf)

Copy the required files to VM B:

```bash
# From your local machine
scp -r vm-b-leaf ubuntu@2.2.2.2:/home/ubuntu/
scp -r shared ubuntu@2.2.2.2:/home/ubuntu/
scp -r manifests ubuntu@2.2.2.2:/home/ubuntu/

# Create certs directory and copy certificates
ssh ubuntu@2.2.2.2 "mkdir -p /home/ubuntu/vm-b-leaf/certs"
scp certs/ca.crt ubuntu@2.2.2.2:/home/ubuntu/vm-b-leaf/certs/
scp certs/cluster-b-issuer.crt ubuntu@2.2.2.2:/home/ubuntu/vm-b-leaf/certs/
scp certs/cluster-b-issuer.key ubuntu@2.2.2.2:/home/ubuntu/vm-b-leaf/certs/
```

### Step 4: Setup VM A (Broker)

SSH into VM A and run the setup:

```bash
ssh ubuntu@1.1.1.1

cd /home/ubuntu/vm-a-broker
chmod +x setup.sh
chmod +x install-linkerd.sh
chmod +x deploy-nats-broker.sh
chmod +x deploy-publisher.sh
chmod +x ../shared/*.sh

# Run the setup (this will take 10-15 minutes)
./setup.sh
```

The setup script will:
1. Install prerequisites (kubectl, helm, linkerd CLI, nats CLI, step-cli)
2. Install K3S
3. Install Linkerd with certificates
4. Deploy NATS broker
5. Deploy publisher client

### Step 5: Verify VM A Setup

```bash
# Check cluster status
kubectl get nodes

# Check Linkerd status
linkerd check

# Check NATS broker
kubectl get pods -n nats-system
kubectl logs -n nats-system -l app=nats-broker

# Check publisher (should be publishing messages)
kubectl logs -n nats-system -l app=nats-publisher -f
```

### Step 6: Setup VM B (Leaf)

SSH into VM B and run the setup:

```bash
ssh ubuntu@2.2.2.2

cd /home/ubuntu/vm-b-leaf
chmod +x setup.sh
chmod +x install-linkerd.sh
chmod +x deploy-nats-leaf.sh
chmod +x deploy-subscriber.sh
chmod +x ../shared/*.sh

# Run the setup with broker IP (this will take 10-15 minutes)
BROKER_IP=1.1.1.1 ./setup.sh
```

The setup script will:
1. Install prerequisites
2. Install K3S
3. Install Linkerd with certificates (using same root CA)
4. Deploy NATS leaf (connecting to broker)
5. Deploy subscriber client

### Step 7: Verify VM B Setup and Message Flow

```bash
# Check cluster status
kubectl get nodes

# Check Linkerd status
linkerd check

# Check NATS leaf
kubectl get pods -n nats-system
kubectl logs -n nats-system -l app=nats-leaf

# Check subscriber (should be receiving messages from VM A)
kubectl logs -n nats-system -l app=nats-subscriber -f
```

You should see messages like:
```
[2025-11-08 10:15:23] ✓ Received: Message #42 - Published at 2025-11-08 10:15:23 UTC
[2025-11-08 10:15:24] ✓ Received: Message #43 - Published at 2025-11-08 10:15:24 UTC
```

## Verification

### Check Cross-Cluster mTLS

On VM A:
```bash
# Check Linkerd proxy on broker
kubectl get pods -n nats-system -l app=nats-broker -o jsonpath='{.items[0].spec.containers[*].name}'
# Should show: nats linkerd-proxy

# Check Linkerd certificates
linkerd identity -n nats-system -l app=nats-broker
```

On VM B:
```bash
# Check Linkerd proxy on leaf
kubectl get pods -n nats-system -l app=nats-leaf -o jsonpath='{.items[0].spec.containers[*].name}'
# Should show: nats linkerd-proxy

# Check Linkerd certificates
linkerd identity -n nats-system -l app=nats-leaf
```

Both should show they're using certificates from the same root CA.

### Check NATS Connectivity

On VM A:
```bash
# Check broker leafnode connections
kubectl exec -n nats-system deployment/nats-broker -- nats-server -sl leafz
```

On VM B:
```bash
# Check leaf connection status
kubectl exec -n nats-system deployment/nats-leaf -- nats-server -sl connz
```

## Configuration Details

### NATS Authentication
- **Username**: `natsuser`
- **Password**: `natspass123`
- Stored in: `manifests/nats-auth-secret.yaml`

### NATS Ports
- **Client Port**: 4222 (internal)
- **Monitoring Port**: 8222
- **Leafnode Port**: 7422 (broker), exposed via NodePort 30722

### Message Subject
- **Subject**: `test.messages`
- **Frequency**: 1 message per second
- **Format**: "Message #N - Published at YYYY-MM-DD HH:MM:SS UTC"

## Troubleshooting

### Subscriber not receiving messages

1. Check NATS leaf connection:
```bash
# On VM B
kubectl logs -n nats-system -l app=nats-leaf
```

2. Check connectivity from VM B to VM A:
```bash
# On VM B
nc -zv 1.1.1.1 30722
```

3. Check firewall rules on VM A:
```bash
# On VM A
sudo ufw status
sudo ufw allow 30722/tcp  # If needed
```

### Linkerd mTLS not working

1. Verify both clusters use the same root CA:
```bash
# On VM A
linkerd identity --context cluster-a -n nats-system -l app=nats-broker

# On VM B
linkerd identity --context cluster-b -n nats-system -l app=nats-leaf
```

2. Check certificate validity:
```bash
openssl x509 -in vm-a-broker/certs/ca.crt -noout -text
openssl x509 -in vm-b-leaf/certs/ca.crt -noout -text
```

### K3S issues

1. Check K3S status:
```bash
sudo systemctl status k3s
```

2. Reset K3S if needed:
```bash
sudo /usr/local/bin/k3s-uninstall.sh
# Then re-run setup script
```

### Publisher/Subscriber not starting

1. Check pod status:
```bash
kubectl describe pod -n nats-system -l app=nats-publisher
kubectl describe pod -n nats-system -l app=nats-subscriber
```

2. Check NATS authentication:
```bash
kubectl get secret -n nats-system nats-auth -o yaml
```

## Cleanup

### On VM A:
```bash
sudo /usr/local/bin/k3s-uninstall.sh
rm -rf /home/ubuntu/vm-a-broker
rm -rf /home/ubuntu/shared
rm -rf /home/ubuntu/manifests
```

### On VM B:
```bash
sudo /usr/local/bin/k3s-uninstall.sh
rm -rf /home/ubuntu/vm-b-leaf
rm -rf /home/ubuntu/shared
rm -rf /home/ubuntu/manifests
```

## Security Considerations

This is a POC setup. For production use:

1. ✅ Change default NATS credentials
2. ✅ Use longer certificate validity periods
3. ✅ Store certificates securely (e.g., vault)
4. ✅ Enable firewall rules properly
5. ✅ Use proper network segmentation
6. ✅ Enable NATS JetStream for persistence
7. ✅ Add monitoring and alerting
8. ✅ Implement proper backup strategies

## References

- [NATS Documentation](https://docs.nats.io/)
- [Linkerd Documentation](https://linkerd.io/docs/)
- [K3S Documentation](https://docs.k3s.io/)
- [NATS Leafnodes](https://docs.nats.io/running-a-nats-service/configuration/leafnodes)

## License

This is a POC project for testing purposes.
