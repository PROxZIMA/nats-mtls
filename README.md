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
- VM A IP: `1.1.1.1` with `30722/tcp` ingress rule
- VM B IP: `2.2.2.2`
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

### Step 2: Copy Files to VM A & VM B

Copy the required files to VM A:

```bash
# From your local machine
VM_A_IP=129.154.247.85 VM_B_IP=144.24.103.105 ./deploy-to-vms.sh
```

### Step 3: Setup VM A (Broker)

SSH into VM A and run the setup:

```bash
ssh ubuntu@1.1.1.1

cd /home/ubuntu/vm-a-broker
# Run the setup (this will take 10-15 minutes)
./setup.sh
```

The setup script will:
1. Install prerequisites (kubectl, helm, linkerd CLI, nats CLI, step-cli)
2. Install K3S
3. Install Linkerd with certificates
4. Deploy NATS broker
5. Deploy publisher client

### Step 4: Setup VM B (Leaf)

SSH into VM B and run the setup:

```bash
ssh ubuntu@2.2.2.2

cd /home/ubuntu/vm-b-leaf
# Run the setup with broker IP (this will take 10-15 minutes)
BROKER_IP=1.1.1.1 ./setup.sh
```

The setup script will:
1. Install prerequisites
2. Install K3S
3. Install Linkerd with certificates (using same root CA)
4. Deploy NATS leaf (connecting to broker)
5. Deploy subscriber client

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

## Cleanup

### On VM A:
```bash
cd /home/ubuntu/nats/vm-a-broker
./cleanup.sh
rm -rfd /home/ubuntu/nats
```

### On VM B:
```bash
cd /home/ubuntu/nats/vm-a-leaf
./cleanup.sh
rm -rfd /home/ubuntu/nats
```

## References

- [NATS Documentation](https://docs.nats.io/)
- [Linkerd Documentation](https://linkerd.io/docs/)
- [K3S Documentation](https://docs.k3s.io/)
- [NATS Leafnodes](https://docs.nats.io/running-a-nats-service/configuration/leafnodes)

## License

This is a POC project for testing purposes.
