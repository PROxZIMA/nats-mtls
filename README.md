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
│  │  │ Linkerd Gateway        │  │  │         │  │  │ Mirrored Service:      │  │  │
│  │  │ Port: 4143 (30143)     │◄─┼──┼─────────┼──┼─►│ nats-broker-cluster-a  │  │  │
│  │  └────────────────────────┘  │  │  Link   │  │  └──────────┬─────────────┘  │  │
│  │                              │  │         │  │             │                │  │
│  │  ┌────────────────────────┐  │  │         │  │  ┌──────────▼─────────────┐  │  │
│  │  │   NATS Broker          │  │  │         │  │  │   NATS Leaf            │  │  │
│  │  │   (Exported Service)   │  │  │         │  │  │   Connects via DNS     │  │  │
│  │  │   Port: 4222, 7422     │  │  │         │  │  │   Port: 4222           │  │  │
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
│   ├── setup-multicluster.sh   # Linkerd multicluster setup
│   ├── create-nats-secrets.sh  # Create NATS mTLS secrets
│   ├── deploy-nats-broker.sh   # NATS broker deployment
│   ├── deploy-publisher.sh     # Publisher client deployment
│   └── certs/                  # Certificates for VM A (to be created)
│
├── vm-b-leaf/                  # VM B (Leaf) setup scripts
│   ├── setup.sh                # Main setup script for VM B
│   ├── install-linkerd.sh      # Linkerd installation
│   ├── setup-multicluster.sh   # Linkerd multicluster setup & link
│   ├── create-nats-secrets.sh  # Create NATS mTLS secrets
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
- **VM A (Broker):**
  - Internal/Private IP: `10.0.0.37` (or similar)
  - External/Public IP: `129.154.247.85`
  - Firewall rules allowing inbound from VM B to:
    - `6443/tcp` (Kubernetes API server - on external IP)
    - `4143` Gateway port (automatically assigned LoadBalancer or use NodePort)
    - `4191` Probe port
- **VM B (Leaf):**
  - Must be able to reach VM A's external IP
- User: ubuntu (with sudo privileges)
- Internet connectivity on both VMs

**Network Connectivity Requirements:**
- VM B → VM A external IP:6443 (Kubernetes API access)
- VM B → VM A gateway port (Linkerd multicluster traffic)

**Key Configuration:**
- K3s is installed with `--node-external-ip` to expose API server on external IP
- Linkerd multicluster uses default gateway configuration (LoadBalancer)
- Link file is generated using `linkerd multicluster link-gen` (no manual IP specification needed)

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

# Set the node IP addresses (required for multicluster)
export NODE_EXTERNAL_IP=129.154.247.85  # VM A's public IP
export NODE_INTERNAL_IP=10.0.0.37       # VM A's private IP (optional)

# Run the setup (this will take 10-15 minutes)
./setup.sh
```

**Important:** The setup will:
- Install K3s with `--node-external-ip` and `--tls-san` flags
- Create two kubeconfig files:
  - `~/.kube/config` - Uses 127.0.0.1 (local access)
  - `~/.kube/config-external` - Uses external IP (for multicluster)
- Configure Linkerd multicluster to use the external IP automatically

The setup script will:
1. Install prerequisites (kubectl, helm, linkerd CLI, nats CLI, step-cli)
2. Install K3S
3. Install Linkerd with certificates
4. Create NATS mTLS certificate secrets
5. Deploy NATS broker with mTLS enabled
6. Setup Linkerd multicluster with gateway (port 4143/30143)
7. Export NATS broker service for cross-cluster discovery
8. Generate cluster link credentials (cluster-a-link.yaml)
9. Deploy Nginx Ingress Controller for external access
10. Deploy publisher client with mTLS certificates

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
5. Setup Linkerd multicluster and establish link to cluster-a
6. Wait for mirrored service (nats-broker-cluster-a) to appear
7. Deploy NATS leaf with mTLS enabled (connecting to mirrored broker)
8. Deploy subscriber client with mTLS certificates

### Step 5: Verify Linkerd Multicluster Setup

On VM A (Broker):
```bash
# Check gateway status
linkerd multicluster gateways

# Verify NATS broker is exported
kubectl get svc -n nats-system -l mirror.linkerd.io/exported=true
```

On VM B (Leaf):
```bash
# Check cluster link status
linkerd multicluster check

# Verify mirrored service exists
kubectl get svc -n nats-system nats-broker-cluster-a

# View service details
kubectl describe svc -n nats-system nats-broker-cluster-a
```

### Step 6: Check NATS Connectivity

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

### Linkerd Multicluster Ports
- **Gateway Port**: 4143 (internal)
- **Gateway NodePort**: 30143 (external, for cross-cluster communication)
- **Required Firewall Rule**: Allow TCP port 30143 on VM A for VM B access

### Service Discovery
- **Leaf Connection Method**: DNS-based via mirrored service
- **Mirrored Service Name**: `nats-broker-cluster-a.nats-system.svc.cluster.local`
- **Original Service**: `nats-broker.nats-system.svc.cluster.local` (on VM A)
- **Benefit**: No hardcoded IP addresses, automatic service discovery

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

### Mirrored Service Not Appearing

1. Check Linkerd gateway on VM A:
```bash
# On VM A
linkerd multicluster gateways
kubectl get svc -n linkerd-multicluster linkerd-gateway
```

2. Verify service is exported:
```bash
# On VM A
kubectl get svc -n nats-system nats-broker -o jsonpath='{.metadata.labels.mirror\.linkerd\.io/exported}'
```

3. Check cluster link on VM B:
```bash
# On VM B
linkerd multicluster check
kubectl get links -n linkerd-multicluster
```

4. Verify network connectivity to gateway:
```bash
# On VM B
nc -zv <VM-A-IP> 4143
```

### Subscriber not receiving messages

1. Check mirrored service exists:
```bash
# On VM B
kubectl get svc -n nats-system nats-broker-cluster-a
```

2. Check NATS leaf connection:
```bash
# On VM B
kubectl logs -n nats-system -l app=nats-leaf
```

3. Check connectivity from VM B to VM A gateway:
```bash
# On VM B
nc -zv <VM-A-IP> 4143
```

4. Check firewall rules on VM A:
```bash
# On VM A
sudo ufw status
sudo ufw allow 30143/tcp  # Linkerd gateway
sudo ufw allow 30722/tcp  # NATS leafnode (legacy, if still using direct connection)
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
- [Linkerd Multicluster](https://linkerd.io/2/features/multicluster/)
- [K3S Documentation](https://docs.k3s.io/)
- [NATS Leafnodes](https://docs.nats.io/running-a-nats-service/configuration/leafnodes)
- [NATS TLS Configuration](https://docs.nats.io/running-a-nats-service/configuration/securing_nats/tls)

## License

This is a POC project for testing purposes.
