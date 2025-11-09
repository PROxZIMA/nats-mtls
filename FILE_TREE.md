# Project File Tree

```
NATS-mTLS/
│
├── 📂 vm-a-broker/                         # VM A (Broker) Scripts
│   ├── 🚀 setup.sh                         # Master setup script for VM A
│   ├── 🔧 install-linkerd.sh               # Install Linkerd on VM A
│   ├── 📦 deploy-nats-broker.sh            # Deploy NATS broker
│   ├── 📤 deploy-publisher.sh              # Deploy publisher client
│   └── 📂 certs/                           # Certificates for VM A (to be created)
│       ├── ca.crt                          # Root CA certificate (copy here)
│       ├── cluster-a-issuer.crt            # Cluster A issuer cert (copy here)
│       └── cluster-a-issuer.key            # Cluster A issuer key (copy here)
│
├── 📂 vm-b-leaf/                           # VM B (Leaf) Scripts
│   ├── 🚀 setup.sh                         # Master setup script for VM B
│   ├── 🔧 install-linkerd.sh               # Install Linkerd on VM B
│   ├── 📦 deploy-nats-leaf.sh              # Deploy NATS leaf
│   ├── 📥 deploy-subscriber.sh             # Deploy subscriber client
│   └── 📂 certs/                           # Certificates for VM B (to be created)
│       ├── ca.crt                          # Root CA certificate (copy here)
│       ├── cluster-b-issuer.crt            # Cluster B issuer cert (copy here)
│       └── cluster-b-issuer.key            # Cluster B issuer key (copy here)
│
├── 📂 shared/                              # Shared Utility Scripts
│   ├── 🛠️ install-prerequisites.sh         # Install kubectl, helm, linkerd CLI, etc.
│   ├── ☸️ install-k3s.sh                   # Install K3S
│   ├── 🔐 generate-certificates.sh         # Generate Linkerd certificates
│   └── ✅ verify-setup.sh                  # Verification and troubleshooting
│
├── 📂 manifests/                           # Kubernetes Manifests
│   ├── 🔑 nats-auth-secret.yaml            # NATS authentication credentials
│   ├── 🖥️ nats-broker.yaml                 # NATS broker deployment + service
│   ├── 🌿 nats-leaf.yaml                   # NATS leaf deployment + service
│   ├── 📤 nats-publisher.yaml              # Publisher client deployment
│   └── 📥 nats-subscriber.yaml             # Subscriber client deployment
│
├── 📂 certs/                               # Generated Certificates (local)
│   ├── ca.crt                              # Root CA certificate (generated)
│   ├── ca.key                              # Root CA key (generated)
│   ├── cluster-a-issuer.crt                # Cluster A issuer cert (generated)
│   ├── cluster-a-issuer.key                # Cluster A issuer key (generated)
│   ├── cluster-b-issuer.crt                # Cluster B issuer cert (generated)
│   └── cluster-b-issuer.key                # Cluster B issuer key (generated)
│
├── 🚀 deploy-to-vms.sh                     # Automated deployment helper
│
├── 📄 README.md                            # Complete setup documentation
├── 📄 QUICKSTART.md                        # Quick start guide
├── 📄 CERTIFICATES.md                      # Certificate management guide
├── 📄 ARCHITECTURE.md                      # Detailed architecture diagrams
├── 📄 PROJECT_SUMMARY.md                   # Project overview and checklist
├── 📄 OVERVIEW.md                          # Complete setup overview
├── 📄 FILE_TREE.md                         # This file - project structure
│
└── 📄 .gitignore                           # Git ignore rules

```

## File Descriptions

### VM A (Broker) Scripts
| File | Purpose | When to Run |
|------|---------|-------------|
| `setup.sh` | Master script that runs all other VM A scripts in sequence | Once on VM A |
| `install-linkerd.sh` | Installs Linkerd control plane with cluster-a certificates | Called by setup.sh |
| `deploy-nats-broker.sh` | Deploys NATS broker with leafnode support | Called by setup.sh |
| `deploy-publisher.sh` | Deploys publisher client that sends messages every second | Called by setup.sh |

### VM B (Leaf) Scripts
| File | Purpose | When to Run |
|------|---------|-------------|
| `setup.sh` | Master script that runs all other VM B scripts in sequence | Once on VM B |
| `install-linkerd.sh` | Installs Linkerd control plane with cluster-b certificates | Called by setup.sh |
| `deploy-nats-leaf.sh` | Deploys NATS leaf that connects to broker on VM A | Called by setup.sh |
| `deploy-subscriber.sh` | Deploys subscriber client that receives messages | Called by setup.sh |

### Shared Utility Scripts
| File | Purpose | When to Run |
|------|---------|-------------|
| `install-prerequisites.sh` | Installs kubectl, helm, linkerd CLI, nats CLI, step-cli | Called by setup.sh on both VMs |
| `install-k3s.sh` | Installs K3S Kubernetes cluster | Called by setup.sh on both VMs |
| `generate-certificates.sh` | Generates all Linkerd certificates using step-cli | Once on local machine before VM setup |
| `verify-setup.sh` | Checks installation status and troubleshoots issues | Anytime for verification |

### Kubernetes Manifests
| File | Purpose | Deployed To |
|------|---------|-------------|
| `nats-auth-secret.yaml` | Contains NATS username and password | Both VMs |
| `nats-broker.yaml` | NATS broker with client, leafnode, and monitoring ports | VM A only |
| `nats-leaf.yaml` | NATS leaf configured to connect to broker | VM B only |
| `nats-publisher.yaml` | Publisher pod that sends messages to "test.messages" | VM A only |
| `nats-subscriber.yaml` | Subscriber pod that receives from "test.messages" | VM B only |

### Documentation Files
| File | Content | Audience |
|------|---------|----------|
| `README.md` | Complete setup guide with troubleshooting | Everyone - start here |
| `QUICKSTART.md` | Condensed quick start commands | Experienced users |
| `CERTIFICATES.md` | Certificate generation and management | Security-focused users |
| `ARCHITECTURE.md` | Detailed architecture and data flow | Architects/Engineers |
| `PROJECT_SUMMARY.md` | Project overview and checklist | Project managers |
| `OVERVIEW.md` | Complete setup overview and testing | All users |
| `FILE_TREE.md` | This file - project structure | Reference |

### Helper Scripts
| File | Purpose | When to Run |
|------|---------|-------------|
| `deploy-to-vms.sh` | Automates SCP file transfer to both VMs | Once from local machine |

### Configuration Files
| File | Purpose |
|------|---------|
| `.gitignore` | Specifies files to exclude from Git (e.g., private keys) |

## Execution Flow

### Phase 1: Local Machine (Before VM Setup)
```
1. generate-certificates.sh
   └── Creates: certs/ca.crt, ca.key, cluster-a-issuer.*, cluster-b-issuer.*

2. deploy-to-vms.sh (optional)
   └── Copies files to both VMs via SCP
```

### Phase 2: VM A Setup
```
1. setup.sh (main entry point)
   │
   ├── 2. install-prerequisites.sh
   │   └── Installs: kubectl, helm, linkerd CLI, nats CLI, step-cli
   │
   ├── 3. install-k3s.sh
   │   └── Installs: K3S cluster
   │
   ├── 4. install-linkerd.sh
   │   └── Installs: Linkerd control plane with cluster-a certificates
   │
   ├── 5. deploy-nats-broker.sh
   │   ├── Creates: nats-system namespace
   │   ├── Applies: nats-auth-secret.yaml
   │   └── Applies: nats-broker.yaml
   │
   └── 6. deploy-publisher.sh
       └── Applies: nats-publisher.yaml
```

### Phase 3: VM B Setup
```
1. setup.sh (main entry point)
   │
   ├── 2. install-prerequisites.sh
   │   └── Installs: kubectl, helm, linkerd CLI, nats CLI, step-cli
   │
   ├── 3. install-k3s.sh
   │   └── Installs: K3S cluster
   │
   ├── 4. install-linkerd.sh
   │   └── Installs: Linkerd control plane with cluster-b certificates
   │
   ├── 5. deploy-nats-leaf.sh
   │   ├── Creates: nats-system namespace
   │   ├── Applies: nats-auth-secret.yaml
   │   └── Applies: nats-leaf.yaml (with BROKER_IP substitution)
   │
   └── 6. deploy-subscriber.sh
       └── Applies: nats-subscriber.yaml
```

### Phase 4: Verification (On Either VM)
```
verify-setup.sh
├── Checks: Kubernetes cluster
├── Checks: Linkerd installation
├── Checks: NATS namespace
├── Checks: Pod status and proxy injection
├── Checks: Services
├── Checks: Secrets
├── Checks: Logs
├── Checks: Network connectivity
└── Checks: Linkerd identity
```

## File Dependencies

### Certificate Dependencies
```
generate-certificates.sh (local)
    └── Generates:
        ├── ca.crt ─────────────┬──────────────> VM A: vm-a-broker/certs/ca.crt
        │                       └──────────────> VM B: vm-b-leaf/certs/ca.crt
        ├── cluster-a-issuer.crt ───────────> VM A: vm-a-broker/certs/
        ├── cluster-a-issuer.key ───────────> VM A: vm-a-broker/certs/
        ├── cluster-b-issuer.crt ───────────> VM B: vm-b-leaf/certs/
        └── cluster-b-issuer.key ───────────> VM B: vm-b-leaf/certs/
```

### Script Dependencies (VM A)
```
setup.sh
├── Requires: ../shared/install-prerequisites.sh
├── Requires: ../shared/install-k3s.sh
├── Requires: install-linkerd.sh
├── Requires: deploy-nats-broker.sh
├── Requires: deploy-publisher.sh
└── Requires: certs/ca.crt, cluster-a-issuer.crt, cluster-a-issuer.key

install-linkerd.sh
└── Requires: certs/ca.crt, cluster-a-issuer.crt, cluster-a-issuer.key

deploy-nats-broker.sh
└── Requires: ../manifests/nats-auth-secret.yaml, nats-broker.yaml

deploy-publisher.sh
└── Requires: ../manifests/nats-publisher.yaml
```

### Script Dependencies (VM B)
```
setup.sh
├── Requires: ../shared/install-prerequisites.sh
├── Requires: ../shared/install-k3s.sh
├── Requires: install-linkerd.sh
├── Requires: deploy-nats-leaf.sh
├── Requires: deploy-subscriber.sh
└── Requires: certs/ca.crt, cluster-b-issuer.crt, cluster-b-issuer.key

install-linkerd.sh
└── Requires: certs/ca.crt, cluster-b-issuer.crt, cluster-b-issuer.key

deploy-nats-leaf.sh
├── Requires: ../manifests/nats-auth-secret.yaml, nats-leaf.yaml
└── Requires: BROKER_IP environment variable

deploy-subscriber.sh
└── Requires: ../manifests/nats-subscriber.yaml
```

## File Sizes (Approximate)

| File Type | Count | Total Size |
|-----------|-------|------------|
| Shell Scripts | 13 | ~25 KB |
| YAML Manifests | 5 | ~15 KB |
| Documentation | 7 | ~85 KB |
| Certificates (generated) | 6 | ~15 KB |
| **Total** | **31** | **~140 KB** |

## Permissions Required

### Executable Scripts
All `.sh` files need execute permission:
```bash
chmod +x vm-a-broker/*.sh
chmod +x vm-b-leaf/*.sh
chmod +x shared/*.sh
chmod +x deploy-to-vms.sh
```

### Certificate Files
Private keys should have restricted permissions:
```bash
chmod 600 certs/*.key
chmod 600 vm-a-broker/certs/*.key
chmod 600 vm-b-leaf/certs/*.key
```

### Public Certificates
```bash
chmod 644 certs/*.crt
chmod 644 vm-a-broker/certs/*.crt
chmod 644 vm-b-leaf/certs/*.crt
```

## Quick Reference

### To Get Started
1. Read: `README.md` or `QUICKSTART.md`
2. Run: `shared/generate-certificates.sh`
3. Run: `deploy-to-vms.sh` or manually copy files
4. On VM A: `vm-a-broker/setup.sh`
5. On VM B: `vm-b-leaf/setup.sh`
6. Verify: `shared/verify-setup.sh`

### To Understand Architecture
- Read: `ARCHITECTURE.md`
- Read: `PROJECT_SUMMARY.md`

### To Manage Certificates
- Read: `CERTIFICATES.md`
- Run: `shared/generate-certificates.sh`

### To Troubleshoot
- Read: README.md → Troubleshooting section
- Run: `shared/verify-setup.sh`
- Check logs: `kubectl logs -n nats-system <pod-name>`

---

**This file tree represents the complete NATS-mTLS project structure.**
