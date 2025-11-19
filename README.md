# NATS with Dual mTLS - Cross-Cluster Setup

This project sets up a NATS broker-leaf architecture across two separate K3S clusters with **dual-layer mTLS**:
1. **Native NATS mTLS** - Application-layer mutual TLS authentication with certificate-based client verification
2. **Linkerd mTLS** - Service mesh layer encryption and authentication

This provides defense-in-depth security with two independent layers of mutual authentication and encryption.

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
│   ├── install-prerequisites.sh       # Install kubectl, helm, linkerd CLI, etc.
│   ├── install-k3s.sh                 # K3S installation
│   ├── generate-certificates.sh       # Generate Linkerd certificates
│   ├── generate-nats-certificates.sh  # Generate NATS mTLS certificates
│   └── setup-nats-ingress.sh          # Setup ingress controller
│
├── manifests/                  # Kubernetes manifests
│   ├── nats-auth-secret.yaml          # NATS authentication credentials
│   ├── nats-broker.yaml               # NATS broker with mTLS
│   ├── nats-leaf.yaml                 # NATS leaf with mTLS
│   ├── nats-publisher.yaml            # Publisher with client certs
│   ├── nats-subscriber.yaml           # Subscriber with client certs
│   ├── nats-ingress.yaml              # HTTP monitoring ingress
│   └── nginx-ingress-controller.yaml  # Ingress controller for TCP
│
├── certs/                      # Generated certificates (local)
│   ├── ca.crt, ca.key                 # Linkerd root CA
│   ├── cluster-a-issuer.{crt,key}     # Linkerd cluster A issuer
│   ├── cluster-b-issuer.{crt,key}     # Linkerd cluster B issuer
│   └── nats/                          # NATS mTLS certificates
│       ├── ca/                        # NATS root CA
│       ├── broker/                    # Broker server certs
│       ├── leaf/                      # Leaf server certs
│       └── clients/                   # Client certificates
│
├── NATS-MTLS.md                # NATS mTLS architecture documentation
├── NATS-MTLS-QUICKSTART.md     # Quick setup guide for NATS mTLS
├── INGRESS.md                  # Ingress controller documentation
├── ARCHITECTURE.md             # Detailed architecture
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

On your local machine (or any machine with `step-cli` installed), generate both Linkerd and NATS certificates:

```bash
cd NATS-mTLS
chmod +x shared/generate-certificates.sh
chmod +x shared/generate-nats-certificates.sh

# Generate Linkerd certificates
./shared/generate-certificates.sh

# Generate NATS mTLS certificates
./shared/generate-nats-certificates.sh
```

**Linkerd Certificates** (`certs/`):
- `ca.crt, ca.key` - Root CA certificate (shared)
- `cluster-a-issuer.{crt,key}` - Cluster A identity issuer
- `cluster-b-issuer.{crt,key}` - Cluster B identity issuer

**NATS mTLS Certificates** (`certs/nats/`):
- `ca/ca.{crt,key}` - NATS root CA
- `broker/server.{crt,key}` - Broker server certificate
- `leaf/server.{crt,key}` - Leaf server certificate
- `clients/publisher-client.{crt,key}` - Publisher client certificate
- `clients/leaf-client.{crt,key}` - Leaf node client certificate (for broker connection)
- `clients/subscriber-client.{crt,key}` - Subscriber client certificate

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
4. Create NATS mTLS certificate secrets
5. Deploy NATS broker with mTLS enabled
6. Deploy Nginx Ingress Controller for external access
7. Deploy publisher client with mTLS certificates

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
4. Create NATS mTLS certificate secrets
5. Deploy NATS leaf with mTLS enabled (connecting to broker)
6. Deploy subscriber client with mTLS certificates

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
- **Client Port**: 4222 (internal, TLS enabled)
- **Monitoring Port**: 8222
- **Leafnode Port**: 7422 (broker, TLS enabled)
- **External Access**: 30422 (client), 30722 (leafnode) via Ingress Controller

### Message Subject
- **Subject**: `test.messages`
- **Frequency**: 1 message every 5 seconds
- **Format**: "Message #N - Published at YYYY-MM-DD HH:MM:SS UTC"

### Security Layers

**1. Native NATS mTLS**
- All NATS connections require mutual TLS authentication
- Separate client certificates for publisher, leaf node, and subscriber
- Certificate-based user mapping with `verify_and_map`

**2. Linkerd mTLS**
- Service mesh layer encryption between pods
- Automatic certificate rotation
- Zero-trust networking within each cluster

This dual-layer approach provides defense-in-depth with independent authentication and encryption at both application and transport layers.

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
