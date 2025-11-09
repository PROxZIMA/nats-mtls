# Cleanup and Uninstallation Guide

This guide explains how to clean up and uninstall the NATS-mTLS setup.

## Cleanup Options

### Option 1: Full Cleanup (Recommended)

Removes everything including K3S, Linkerd, and installed binaries.

#### On VM A (Broker)
```bash
ssh ubuntu@1.1.1.1
cd vm-a-broker
chmod +x cleanup.sh
./cleanup.sh
```

#### On VM B (Leaf)
```bash
ssh ubuntu@2.2.2.2
cd vm-b-leaf
chmod +x cleanup.sh
./cleanup.sh
```

The script will:
1. Delete NATS namespace and all resources
2. Uninstall Linkerd service mesh
3. Delete Gateway API CRDs
4. Uninstall K3S cluster
5. Remove Kubernetes config files
6. (Optional) Remove installed binaries (kubectl, helm, linkerd, nats, step)
7. (Optional) Remove project files

### Option 2: NATS Resources Only

Removes only NATS deployments, keeping K3S and Linkerd intact.

#### On Either VM
```bash
cd shared
chmod +x cleanup-resources-only.sh
./cleanup-resources-only.sh
```

This will:
- Delete NATS broker/leaf deployments
- Delete NATS services
- Delete NATS configmaps
- Delete NATS secrets
- Keep the namespace (you can manually delete it later)

### Option 3: Manual Cleanup

If you prefer to clean up manually:

#### Step 1: Delete NATS Resources
```bash
# Delete all resources in nats-system namespace
kubectl delete namespace nats-system

# Or delete individual resources
kubectl delete deployment nats-broker -n nats-system
kubectl delete deployment nats-leaf -n nats-system
kubectl delete deployment nats-publisher -n nats-system
kubectl delete deployment nats-subscriber -n nats-system
kubectl delete service --all -n nats-system
kubectl delete configmap --all -n nats-system
kubectl delete secret --all -n nats-system
```

#### Step 2: Uninstall Linkerd
```bash
# Uninstall Linkerd viz extension (if installed)
linkerd viz uninstall | kubectl delete -f -

# Uninstall Linkerd control plane
linkerd uninstall | kubectl delete -f -

# Delete Gateway API CRDs
kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/standard-install.yaml
```

#### Step 3: Uninstall K3S
```bash
# On each VM
sudo /usr/local/bin/k3s-uninstall.sh
```

#### Step 4: Remove Binaries (Optional)
```bash
# Remove kubectl
sudo rm -f /usr/local/bin/kubectl

# Remove helm
sudo rm -f /usr/local/bin/helm

# Remove linkerd
sudo rm -f /usr/local/bin/linkerd
rm -rf ~/.linkerd2

# Remove nats CLI
sudo rm -f /usr/local/bin/nats

# Remove step CLI
sudo rm -f /usr/local/bin/step

# Clean up bashrc
sed -i '/linkerd2/d' ~/.bashrc
```

#### Step 5: Remove Project Files (Optional)
```bash
# On VM A
rm -rf ~/vm-a-broker ~/shared ~/manifests

# On VM B
rm -rf ~/vm-b-leaf ~/shared ~/manifests
```

## Selective Cleanup

### Just Restart NATS Pods
```bash
# Restart broker
kubectl rollout restart deployment nats-broker -n nats-system

# Restart leaf
kubectl rollout restart deployment nats-leaf -n nats-system

# Restart publisher
kubectl rollout restart deployment nats-publisher -n nats-system

# Restart subscriber
kubectl rollout restart deployment nats-subscriber -n nats-system
```

### Remove Just Publisher/Subscriber
```bash
# Remove publisher (VM A)
kubectl delete deployment nats-publisher -n nats-system

# Remove subscriber (VM B)
kubectl delete deployment nats-subscriber -n nats-system
```

### Remove Only Linkerd
```bash
linkerd viz uninstall | kubectl delete -f -
linkerd uninstall | kubectl delete -f -
```

### Remove Only K3S
```bash
sudo /usr/local/bin/k3s-uninstall.sh
```

## Verification After Cleanup

### Check No Pods Running
```bash
kubectl get pods -A
# Should show: No resources found or only kube-system pods
```

### Check K3S Removed
```bash
sudo systemctl status k3s
# Should show: Unit k3s.service could not be found
```

### Check Binaries Removed
```bash
which kubectl
which helm
which linkerd
which nats
which step
# All should return: not found
```

### Check Project Files Removed
```bash
ls -la ~/vm-a-broker  # Should not exist
ls -la ~/vm-b-leaf    # Should not exist
```

## Cleanup Local Machine (Windows)

To clean up the local repository on your Windows machine:

### Keep Everything (Recommended for Future Use)
```powershell
# Just keep it - you might want to set up again
```

### Remove Generated Certificates Only
```powershell
# In PowerShell or WSL
cd c:\Users\pr0x2\Documents\Github\NATS-mTLS
rm -rf certs/*
```

### Remove Entire Repository
```powershell
# Remove the whole project
Remove-Item -Recurse -Force c:\Users\pr0x2\Documents\Github\NATS-mTLS
```

## Troubleshooting Cleanup

### Namespace Stuck in "Terminating"
```bash
# Force delete the namespace
kubectl delete namespace nats-system --force --grace-period=0

# If still stuck, remove finalizers
kubectl get namespace nats-system -o json | jq '.spec.finalizers = []' | kubectl replace --raw "/api/v1/namespaces/nats-system/finalize" -f -
```

### K3S Uninstall Fails
```bash
# Kill all K3S processes
sudo pkill -9 k3s

# Remove K3S files manually
sudo rm -rf /etc/rancher/k3s
sudo rm -rf /var/lib/rancher/k3s
sudo rm -f /usr/local/bin/k3s
sudo rm -f /usr/local/bin/k3s-uninstall.sh
```

### Linkerd Uninstall Hangs
```bash
# Force delete linkerd namespace
kubectl delete namespace linkerd --force --grace-period=0

# Remove CRDs manually
kubectl get crd | grep linkerd | awk '{print $1}' | xargs kubectl delete crd
```

### Pods Won't Delete
```bash
# Force delete all pods in namespace
kubectl delete pods --all -n nats-system --force --grace-period=0
```

## Reboot After Cleanup

For a clean slate, reboot the VMs after cleanup:

```bash
sudo reboot
```

## Fresh Start

After cleanup, to start fresh:

1. Ensure VMs are rebooted
2. Re-run certificate generation on local machine
3. Copy files to VMs again
4. Run setup scripts

See `QUICKSTART.md` or `README.md` for setup instructions.

## Cleanup Checklist

- [ ] Backup any important logs or data
- [ ] Run cleanup script on VM A
- [ ] Run cleanup script on VM B
- [ ] Verify no pods running
- [ ] Verify K3S removed
- [ ] (Optional) Verify binaries removed
- [ ] (Optional) Verify project files removed
- [ ] (Optional) Reboot VMs
- [ ] (Optional) Clean up local certificates

## Notes

- The cleanup scripts are interactive and will ask for confirmation
- You can choose to keep installed binaries for future use
- Project files can be kept if you plan to re-deploy later
- Certificates on local machine are not affected by VM cleanup
- Rebooting ensures all processes and network configurations are cleared

---

**Always backup important data before running cleanup scripts!**
