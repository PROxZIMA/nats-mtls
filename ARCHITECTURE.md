# Architecture Details

## Overview

This document provides detailed architectural information about the NATS-mTLS cross-cluster setup.

## Network Architecture

### Cluster Topology

```
┌──────────────────────────────────────────────────────────────────────────┐
│                          Internet / WAN                                  │
└──────────────────────────────┬───────────────────────────────────────────┘
                               │
                ┌──────────────┴──────────────┐
                │                             │
                │                             │
    ┌───────────▼──────────┐      ┌──────────▼───────────┐
    │   VM A (1.1.1.1)     │      │   VM B (2.2.2.2)     │
    │   Broker Cluster     │      │   Leaf Cluster       │
    └──────────────────────┘      └──────────────────────┘
```

### Port Mappings

#### VM A (Broker)
| Port  | Service             | Type      | Purpose                    |
|-------|---------------------|-----------|----------------------------|
| 4222  | NATS Client         | ClusterIP | Internal client connections|
| 7422  | NATS Leafnode       | ClusterIP | Internal leafnode port     |
| 8222  | NATS Monitoring     | ClusterIP | Health checks & monitoring |
| 30422 | NATS Client         | NodePort  | External client access     |
| 30722 | NATS Leafnode       | NodePort  | External leaf connections  |

#### VM B (Leaf)
| Port  | Service             | Type      | Purpose                    |
|-------|---------------------|-----------|----------------------------|
| 4222  | NATS Client         | ClusterIP | Internal client connections|
| 8222  | NATS Monitoring     | ClusterIP | Health checks & monitoring |

## Component Architecture

### VM A - Broker Cluster

```
┌─────────────────────────────────────────────────────────────────┐
│ K3S Cluster (VM A)                                              │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Namespace: linkerd                                       │   │
│  │                                                          │   │
│  │  ┌──────────────────┐  ┌──────────────────┐              │   │
│  │  │ linkerd-identity │  │ linkerd-proxy    │              │   │
│  │  │                  │  │  injector        │              │   │
│  │  └──────────────────┘  └──────────────────┘              │   │
│  │                                                          │   │
│  │  Trust Anchor: ca.crt (Root CA)                          │   │
│  │  Issuer: cluster-a-issuer.crt                            │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Namespace: nats-system                                   │   │
│  │ Annotation: linkerd.io/inject=enabled                    │   │
│  │                                                          │   │
│  │  ┌─────────────────────────────────────────────────┐     │   │
│  │  │ NATS Broker Pod                                 │     │   │
│  │  │ ┌─────────────────┐  ┌────────────────────────┐ │     │   │
│  │  │ │  nats-server    │  │  linkerd-proxy         │ │     │   │
│  │  │ │                 │  │  (sidecar)             │ │     │   │
│  │  │ │  Port: 4222     │◄─┤  mTLS enabled          │ │     │   │
│  │  │ │  Leafnode: 7422 │  │                        │ │     │   │
│  │  │ │  Monitor: 8222  │  │  Certificate:          │ │     │   │
│  │  │ │                 │  │  CN=nats-broker...     │ │     │   │
│  │  │ └─────────────────┘  └────────────────────────┘ │     │   │
│  │  │                                                 │     │   │
│  │  │ ConfigMap: nats-broker-config                   │     │   │
│  │  │ Secret: nats-auth (username/password)           │     │   │
│  │  └─────────────────────────────────────────────────┘     │   │
│  │                        ▲                                 │   │
│  │  ┌─────────────────────┼─────────────────────────────┐   │   │
│  │  │ Publisher Pod       │                             │   │   │
│  │  │ ┌──────────────────┐│  ┌───────────────────────┐  │   │   │
│  │  │ │  nats pub        ││  │  linkerd-proxy        │  │   │   │
│  │  │ │  (nats-box)      │┘  │  (sidecar)            │  │   │   │
│  │  │ │                  ├───┤  mTLS enabled         │  │   │   │
│  │  │ │  Publishes to:   │   │                       │  │   │   │
│  │  │ │  test.messages   │   │                       │  │   │   │
│  │  │ │  every 1s        │   │                       │  │   │   │
│  │  │ └──────────────────┘   └───────────────────────┘  │   │   │
│  │  └───────────────────────────────────────────────────┘   │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### VM B - Leaf Cluster

```
┌─────────────────────────────────────────────────────────────────┐
│ K3S Cluster (VM B)                                              │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Namespace: linkerd                                       │   │
│  │                                                          │   │
│  │  ┌──────────────────┐  ┌──────────────────┐              │   │
│  │  │ linkerd-identity │  │ linkerd-proxy    │              │   │
│  │  │                  │  │  injector        │              │   │
│  │  └──────────────────┘  └──────────────────┘              │   │
│  │                                                          │   │
│  │  Trust Anchor: ca.crt (Same Root CA as VM A)             │   │
│  │  Issuer: cluster-b-issuer.crt                            │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Namespace: nats-system                                   │   │
│  │ Annotation: linkerd.io/inject=enabled                    │   │
│  │                                                          │   │
│  │  ┌─────────────────────────────────────────────────┐     │   │
│  │  │ NATS Leaf Pod                                   │     │   │
│  │  │ ┌─────────────────┐  ┌────────────────────────┐ │     │   │
│  │  │ │  nats-server    │  │  linkerd-proxy         │ │     │   │
│  │  │ │                 │  │  (sidecar)             │ │     │   │
│  │  │ │  Port: 4222     │◄─┤  mTLS enabled          │ │     │   │
│  │  │ │  Monitor: 8222  │  │                        │ │     │   │
│  │  │ │                 │  │  Certificate:          │ │     │   │
│  │  │ │  Remote:        │  │  CN=nats-leaf...       │ │     │   │
│  │  │ │  1.1.1.1:30722  │  │                        │ │     │   │
│  │  │ └─────────────────┘  └────────────────────────┘ │     │   │
│  │  │                                                 │     │   │
│  │  │ ConfigMap: nats-leaf-config                     │     │   │
│  │  │ Secret: nats-auth (username/password)           │     │   │
│  │  └─────────────────────────────────────────────────┘     │   │
│  │                        ▲                                 │   │
│  │  ┌─────────────────────┼─────────────────────────────┐   │   │
│  │  │ Subscriber Pod      │                             │   │   │
│  │  │ ┌──────────────────┐│  ┌───────────────────────┐  │   │   │
│  │  │ │  nats sub        ││  │  linkerd-proxy        │  │   │   │
│  │  │ │  (nats-box)      │┘  │  (sidecar)            │  │   │   │
│  │  │ │                  ├───┤  mTLS enabled         │  │   │   │
│  │  │ │  Subscribes to:  │   │                       │  │   │   │
│  │  │ │  test.messages   │   │                       │  │   │   │
│  │  │ │                  │   │                       │  │   │   │
│  │  │ └──────────────────┘   └───────────────────────┘  │   │   │
│  │  └───────────────────────────────────────────────────┘   │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Message Flow

### Publishing Flow (VM A to VM B)

```
1. Publisher Pod (VM A)
   │
   ├─► linkerd-proxy (mTLS)
   │   └─► Encrypts traffic
   │
2. NATS Broker Pod (VM A)
   │   ┌─► linkerd-proxy receives encrypted traffic
   │   └─► Decrypts and forwards to nats-server
   │       └─► nats-server receives message
   │           └─► Stores in subject: test.messages
   │
3. NATS Broker Leafnode Port (7422)
   │   └─► Forwards message to connected leafnodes
   │
4. Network (VM A → VM B)
   │   └─► NodePort 30722 forwards to leafnode
   │       └─► Traffic exits VM A via Linkerd proxy (mTLS)
   │           └─► Traffic enters VM B
   │
5. NATS Leaf Pod (VM B)
   │   ┌─► linkerd-proxy receives encrypted traffic
   │   └─► Decrypts and forwards to nats-server
   │       └─► nats-server receives message via leafnode connection
   │           └─► Stores in local subject: test.messages
   │
6. Subscriber Pod (VM B)
   │   ┌─► Subscribed to: test.messages
   │   └─► linkerd-proxy (mTLS)
   │       └─► Fetches message from NATS Leaf
   │           └─► Message delivered to subscriber
   │               └─► Logs: "✓ Received: Message #N..."
```

## Security Architecture

### mTLS Communication Paths

#### Intra-Cluster Communication (within VM A or VM B)

```
┌──────────────┐         mTLS          ┌──────────────┐
│  Publisher   │◄─────────────────────►│  NATS Broker │
│  (+ proxy)   │  Linkerd Proxies      │  (+ proxy)   │
└──────────────┘  verify each other    └──────────────┘
                  using certificates
                  from same cluster
                  issuer
```

#### Cross-Cluster Communication (VM A to VM B)

```
┌──────────────────┐                  ┌──────────────────┐
│   VM A           │                  │   VM B           │
│                  │                  │                  │
│  NATS Broker     │                  │  NATS Leaf       │
│  (+ proxy)       │                  │  (+ proxy)       │
│                  │                  │                  │
│  Certificate:    │    NodePort      │  Certificate:    │
│  Issued by:      │    30722         │  Issued by:      │
│  cluster-a       │◄────────────────►│  cluster-b       │
│  -issuer.crt     │   Plain TCP      │  -issuer.crt     │
│                  │   (NATS proto)   │                  │
│  Trusts:         │                  │  Trusts:         │
│  ca.crt (root)   │                  │  ca.crt (root)   │
└──────────────────┘                  └──────────────────┘
         ▲                                      ▲
         │                                      │
         └──────────────────┬───────────────────┘
                            │
                  Both trust same Root CA
                  Certificates issued by
                  different issuers but
                  signed by same root
```

### Authentication Layers

1. **NATS Authentication** (Username/Password)
   - Username: `natsuser`
   - Password: `natspass123`
   - Applied to: Client connections, Leafnode connections

2. **Linkerd mTLS** (Transport Layer)
   - Automatic certificate issuance
   - Certificate rotation every 24 hours (default)
   - Mutual verification using Root CA

3. **Kubernetes RBAC** (Authorization)
   - Service accounts per deployment
   - Namespace isolation

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│ Timeline: Message Journey from Publisher to Subscriber             │
└─────────────────────────────────────────────────────────────────────┘

T=0ms    Publisher generates message with timestamp
         │
T=1ms    Publisher → Linkerd Proxy (encrypt with mTLS)
         │
T=2ms    Linkerd Proxy → NATS Broker (within VM A cluster)
         │
T=3ms    NATS Broker receives, authenticates via username/password
         │
T=4ms    NATS Broker stores message in subject "test.messages"
         │
T=5ms    NATS Broker identifies connected leafnodes
         │
T=6ms    NATS Broker → Leafnode Port (7422)
         │
T=10ms   Message traverses network VM A → VM B (NodePort 30722)
         │                (unencrypted at network level, but)
         │                (encrypted by NATS protocol + Linkerd previously)
         │
T=20ms   VM B receives on NodePort 30722
         │
T=21ms   Forward to NATS Leaf pod
         │
T=22ms   NATS Leaf authenticates leafnode connection
         │
T=23ms   NATS Leaf stores message in local subject "test.messages"
         │
T=24ms   Subscriber polls for new messages
         │
T=25ms   Subscriber → Linkerd Proxy (request)
         │
T=26ms   Linkerd Proxy → NATS Leaf (mTLS)
         │
T=27ms   NATS Leaf → Linkerd Proxy (response with message)
         │
T=28ms   Linkerd Proxy → Subscriber (decrypt)
         │
T=29ms   Subscriber logs: "✓ Received: Message #N - Published at..."
         │
T=30ms   Subscriber waits for next message

Total latency: ~30ms (with network latency between VMs)
```

## Resource Requirements

### VM A (Broker)

| Component         | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-------------------|-------------|-----------|----------------|--------------|
| NATS Broker       | 100m        | 500m      | 128Mi          | 512Mi        |
| Publisher         | 50m         | 200m      | 64Mi           | 256Mi        |
| Linkerd Proxies   | ~50m/pod    | ~100m/pod | ~64Mi/pod      | ~128Mi/pod   |
| **Total**         | **~250m**   | **~900m** | **~320Mi**     | **~1Gi**     |

### VM B (Leaf)

| Component         | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-------------------|-------------|-----------|----------------|--------------|
| NATS Leaf         | 100m        | 500m      | 128Mi          | 512Mi        |
| Subscriber        | 50m         | 200m      | 64Mi           | 256Mi        |
| Linkerd Proxies   | ~50m/pod    | ~100m/pod | ~64Mi/pod      | ~128Mi/pod   |
| **Total**         | **~250m**   | **~900m** | **~320Mi**     | **~1Gi**     |

### Recommended VM Specifications

- **CPU**: 2 vCPU minimum
- **Memory**: 2GB minimum (4GB recommended)
- **Disk**: 20GB minimum
- **Network**: 1Gbps recommended for low latency

## Scalability Considerations

### Current Setup (POC)
- Single replica for all components
- No high availability
- Ephemeral storage

### Production Recommendations
1. **NATS Cluster**: 3+ broker nodes
2. **JetStream**: Enable for persistence
3. **Multiple Leaf Nodes**: Scale horizontally
4. **Load Balancing**: Use external load balancer
5. **Resource Limits**: Adjust based on message volume
6. **Monitoring**: Add Prometheus + Grafana
7. **Alerting**: Configure alerts for certificate expiry, pod health

## Failure Scenarios

### VM A Down
- ❌ Publisher stops sending
- ❌ Broker unavailable
- ❌ Leaf connection breaks
- ❌ Subscriber receives no new messages
- **Recovery**: Leaf reconnects automatically when broker comes back

### VM B Down
- ✅ Publisher continues sending
- ✅ Broker continues accepting messages
- ❌ Subscriber unavailable
- **Recovery**: Messages are lost unless JetStream is enabled

### Network Partition
- ❌ Leaf disconnects from broker
- ✅ Local operations continue on both sides
- ❌ No cross-cluster message flow
- **Recovery**: Auto-reconnect when network restored

### Certificate Expiry
- ❌ mTLS validation fails
- ❌ All encrypted communication stops
- **Prevention**: Monitor certificate expiry, rotate before expiry
- **Recovery**: Rotate certificates and restart pods

## Monitoring Points

### Health Checks
1. NATS Broker: `http://nats-broker:8222/healthz`
2. NATS Leaf: `http://nats-leaf:8222/healthz`
3. Linkerd: `linkerd check`

### Metrics to Monitor
1. Message publish rate
2. Message receive rate
3. Leafnode connection status
4. Certificate expiry dates
5. Pod resource utilization
6. Network latency between VMs

### Log Locations
1. Publisher: `kubectl logs -n nats-system -l app=nats-publisher`
2. Subscriber: `kubectl logs -n nats-system -l app=nats-subscriber`
3. Broker: `kubectl logs -n nats-system -l app=nats-broker`
4. Leaf: `kubectl logs -n nats-system -l app=nats-leaf`
5. Linkerd: `kubectl logs -n linkerd -l linkerd.io/control-plane-component`
