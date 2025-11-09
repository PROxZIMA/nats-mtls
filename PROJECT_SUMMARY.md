# NATS-mTLS Cross-Cluster Setup - Project Summary

## 📁 Project Structure

```
NATS-mTLS/
├── 📂 vm-a-broker/              # VM A (Broker) scripts
│   ├── setup.sh                 # Main setup script
│   ├── install-linkerd.sh       # Linkerd installation
│   ├── deploy-nats-broker.sh    # NATS broker deployment
│   ├── deploy-publisher.sh      # Publisher deployment
│   └── 📂 certs/                # Certificates (to be copied)
│
├── 📂 vm-b-leaf/                # VM B (Leaf) scripts
│   ├── setup.sh                 # Main setup script
│   ├── install-linkerd.sh       # Linkerd installation
│   ├── deploy-nats-leaf.sh      # NATS leaf deployment
│   ├── deploy-subscriber.sh     # Subscriber deployment
│   └── 📂 certs/                # Certificates (to be copied)
│
├── 📂 shared/                   # Shared scripts
│   ├── install-prerequisites.sh # Prerequisites installation
│   ├── install-k3s.sh           # K3S installation
│   └── generate-certificates.sh # Certificate generation
│
├── 📂 manifests/                # Kubernetes manifests
│   ├── nats-auth-secret.yaml    # Authentication credentials
│   ├── nats-broker.yaml         # Broker deployment
│   ├── nats-leaf.yaml           # Leaf deployment
│   ├── nats-publisher.yaml      # Publisher deployment
│   └── nats-subscriber.yaml     # Subscriber deployment
│
├── 📂 certs/                    # Generated certificates (local)
├── 📄 deploy-to-vms.sh          # Automated deployment helper
├── 📄 README.md                 # Comprehensive documentation
├── 📄 QUICKSTART.md             # Quick start guide
├── 📄 CERTIFICATES.md           # Certificate management guide
├── 📄 ARCHITECTURE.md           # Architecture details
└── 📄 PROJECT_SUMMARY.md        # This file
```

## 🎯 What This POC Demonstrates

### Core Capabilities
✅ **Cross-Cluster NATS Communication** - Broker on VM A, Leaf on VM B  
✅ **Linkerd mTLS** - Service mesh with mutual TLS across clusters  
✅ **Shared Root CA** - Both clusters trust the same certificate authority  
✅ **NATS Leafnode Protocol** - Hierarchical NATS topology  
✅ **Automated Setup** - Complete automation from zero to working system  
✅ **Message Flow** - Continuous publishing and subscribing with timestamps  

### Technology Stack
- **Kubernetes**: K3S (lightweight Kubernetes)
- **Service Mesh**: Linkerd 2.x
- **Message Broker**: NATS Server 2.10
- **Container Runtime**: containerd (via K3S)
- **Certificates**: step-cli for certificate generation
- **Clients**: NATS CLI (nats-box)

## 🔧 Key Configuration Details

### Network Configuration
- **VM A IP**: 1.1.1.1 (configurable)
- **VM B IP**: 2.2.2.2 (configurable)
- **NATS Client Port**: 4222
- **NATS Leafnode Port**: 7422 (internal), 30722 (NodePort)
- **NATS Monitor Port**: 8222

### Security Configuration
- **NATS Username**: natsuser
- **NATS Password**: natspass123
- **Certificate Validity**: 365 days
- **mTLS**: Enabled via Linkerd with automatic certificate rotation
- **Root CA**: Shared between both clusters

### Message Configuration
- **Subject**: test.messages
- **Publish Rate**: 1 message per second
- **Message Format**: "Message #N - Published at YYYY-MM-DD HH:MM:SS UTC"

## 🚀 Quick Start

### 1. Generate Certificates
```bash
cd NATS-mTLS
chmod +x shared/generate-certificates.sh
./shared/generate-certificates.sh
```

### 2. Deploy to VMs (Automated)
```bash
chmod +x deploy-to-vms.sh
./deploy-to-vms.sh
```

### 3. Setup VM A
```bash
ssh ubuntu@1.1.1.1
cd vm-a-broker
./setup.sh
```

### 4. Setup VM B
```bash
ssh ubuntu@2.2.2.2
cd vm-b-leaf
BROKER_IP=1.1.1.1 ./setup.sh
```

### 5. Verify
```bash
# On VM B
kubectl logs -n nats-system -l app=nats-subscriber -f
```

## 📊 Expected Outcomes

### Success Indicators

1. **VM A (Broker)**
   - K3S cluster running
   - Linkerd control plane healthy
   - NATS broker pod running with 2 containers (nats + linkerd-proxy)
   - Publisher continuously sending messages
   - Logs show: `✓ Published: Message #N...`

2. **VM B (Leaf)**
   - K3S cluster running
   - Linkerd control plane healthy
   - NATS leaf pod running with 2 containers (nats + linkerd-proxy)
   - Leaf connected to broker on VM A
   - Subscriber continuously receiving messages
   - Logs show: `✓ Received: Message #N...`

3. **mTLS Verification**
   - Both clusters show healthy Linkerd checks
   - Certificates issued by different issuers but same root CA
   - All pods have linkerd-proxy sidecars injected

## 🔍 Verification Commands

### Check Cluster Health
```bash
# On both VMs
kubectl get nodes
kubectl get pods -n kube-system
kubectl get pods -n linkerd
kubectl get pods -n nats-system
```

### Check Linkerd mTLS
```bash
# On both VMs
linkerd check
linkerd identity -n nats-system
```

### Check NATS Status
```bash
# On VM A (Broker)
kubectl exec -n nats-system deployment/nats-broker -- nats-server -sl leafz

# On VM B (Leaf)
kubectl exec -n nats-system deployment/nats-leaf -- nats-server -sl connz
```

### Monitor Message Flow
```bash
# On VM A (Publisher)
kubectl logs -n nats-system -l app=nats-publisher -f

# On VM B (Subscriber)
kubectl logs -n nats-system -l app=nats-subscriber -f
```

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| **README.md** | Complete setup instructions with troubleshooting |
| **QUICKSTART.md** | Condensed setup guide for quick deployment |
| **CERTIFICATES.md** | Certificate management and rotation procedures |
| **ARCHITECTURE.md** | Detailed architecture diagrams and data flow |
| **PROJECT_SUMMARY.md** | This file - overview and reference |

## ⏱️ Time Estimates

- **Certificate Generation**: ~1 minute
- **File Transfer to VMs**: ~2 minutes
- **VM A Setup**: ~10-15 minutes
- **VM B Setup**: ~10-15 minutes
- **Verification**: ~2 minutes
- **Total**: ~25-35 minutes

## 🔧 Maintenance Tasks

### Regular Tasks
- [ ] Monitor certificate expiry (every 90 days)
- [ ] Check pod health (weekly)
- [ ] Review logs for errors (daily)
- [ ] Verify message flow (daily)

### Periodic Tasks
- [ ] Rotate certificates (before 30 days of expiry)
- [ ] Update NATS version (quarterly)
- [ ] Update Linkerd version (quarterly)
- [ ] Update K3S version (quarterly)

## 🐛 Common Issues & Solutions

### Issue: Subscriber not receiving messages
**Solution**: Check firewall on VM A, ensure port 30722 is open
```bash
# On VM A
sudo ufw allow 30722/tcp
```

### Issue: Linkerd check fails
**Solution**: Verify certificates are correctly deployed
```bash
# On both VMs
ls -la certs/
linkerd check --pre
```

### Issue: NATS authentication fails
**Solution**: Verify secret is created
```bash
kubectl get secret -n nats-system nats-auth -o yaml
```

### Issue: Pods stuck in Pending
**Solution**: Check node resources
```bash
kubectl describe node
kubectl top node
```

## 🔄 Extending This POC

### Add More Publishers
```bash
kubectl scale deployment nats-publisher -n nats-system --replicas=3
```

### Add More Subscribers
```bash
kubectl scale deployment nats-subscriber -n nats-system --replicas=3
```

### Add More Leaf Clusters
1. Create VM C with same setup as VM B
2. Point it to the same broker (VM A)
3. Each leaf operates independently

### Enable JetStream (Persistence)
Modify `nats-broker.yaml` to add JetStream configuration:
```yaml
jetstream {
  store_dir: "/data/jetstream"
}
```

### Add Monitoring
Install Prometheus and Grafana:
```bash
# Install Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace

# Install Linkerd viz extension
linkerd viz install | kubectl apply -f -
linkerd viz dashboard
```

## 🎓 Learning Outcomes

After completing this POC, you will understand:

1. **NATS Architecture** - How leafnodes extend NATS clusters
2. **Linkerd mTLS** - How service mesh provides transparent encryption
3. **Certificate Management** - How to create and distribute certificates
4. **K3S** - Lightweight Kubernetes for edge/IoT scenarios
5. **Cross-Cluster Communication** - Patterns for multi-cluster messaging
6. **Kubernetes Operators** - How to deploy and manage applications on K8s

## 📞 Support & Resources

### Documentation
- Full README: `README.md`
- Quick Start: `QUICKSTART.md`
- Certificates: `CERTIFICATES.md`
- Architecture: `ARCHITECTURE.md`

### External Resources
- [NATS Documentation](https://docs.nats.io/)
- [Linkerd Documentation](https://linkerd.io/docs/)
- [K3S Documentation](https://docs.k3s.io/)

## ✅ Checklist

Use this checklist to track your progress:

- [ ] Repository cloned/created
- [ ] Certificates generated
- [ ] Files deployed to VM A
- [ ] Files deployed to VM B
- [ ] VM A setup completed
- [ ] VM B setup completed
- [ ] Publisher sending messages
- [ ] Subscriber receiving messages
- [ ] Linkerd mTLS verified
- [ ] Documentation reviewed

## 🎉 Success Criteria

Your POC is successful when:

✅ Publisher on VM A sends messages every second  
✅ Subscriber on VM B receives those messages  
✅ Messages include accurate timestamps  
✅ Linkerd proxies are injected in all pods  
✅ mTLS is verified between both clusters  
✅ Both clusters trust the same root CA  
✅ Message latency is acceptable (<100ms)  
✅ All health checks pass  

---

**Congratulations!** You now have a working NATS broker-leaf setup with Linkerd mTLS across two separate K3S clusters! 🚀
