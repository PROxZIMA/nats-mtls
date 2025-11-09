# Windows User Guide - Using These Scripts

## 🪟 Important for Windows Users

These scripts are designed to run on **Linux Ubuntu VMs**, not directly on Windows. Here's how to use them from your Windows machine.

## 📋 Prerequisites on Windows

### Required Tools
1. **SSH Client** (built-in on Windows 10/11)
2. **WSL2** (Windows Subsystem for Linux) - for running bash scripts locally
3. **Git Bash** (alternative to WSL2)
4. **Text Editor** (VS Code recommended)

### Install WSL2 (Recommended)
```powershell
# Run in PowerShell as Administrator
wsl --install
# Restart your computer
# After restart, open Ubuntu from Start menu
```

### Install Git Bash (Alternative)
Download from: https://git-scm.com/download/win

## 🚀 Workflow from Windows

### Option 1: Using WSL2 (Recommended)

#### Step 1: Open Ubuntu in WSL2
```powershell
wsl
```

#### Step 2: Navigate to your project
```bash
cd /mnt/c/Users/pr0x2/Documents/Github/NATS-mTLS
```

#### Step 3: Generate certificates
```bash
chmod +x shared/generate-certificates.sh
./shared/generate-certificates.sh
```

#### Step 4: Deploy to VMs
```bash
chmod +x deploy-to-vms.sh

# Option A: Use the automated script
VM_A_IP=1.1.1.1 VM_B_IP=2.2.2.2 ./deploy-to-vms.sh

# Option B: Manual deployment (see below)
```

#### Step 5: SSH to VMs and run setup
```bash
# Setup VM A
ssh ubuntu@1.1.1.1
cd vm-a-broker
chmod +x *.sh ../shared/*.sh
./setup.sh
exit

# Setup VM B
ssh ubuntu@2.2.2.2
cd vm-b-leaf
chmod +x *.sh ../shared/*.sh
BROKER_IP=1.1.1.1 ./setup.sh
exit
```

### Option 2: Using Git Bash

Same as WSL2 but:
1. Open Git Bash instead of WSL
2. Paths are already Windows-style (C:\Users\...)
3. SSH commands work the same

### Option 3: Using PowerShell + SSH

#### Step 1: Generate certificates using WSL/Git Bash
(PowerShell doesn't run bash scripts directly)

```powershell
# Open WSL or Git Bash for this step
wsl
cd /mnt/c/Users/pr0x2/Documents/Github/NATS-mTLS
./shared/generate-certificates.sh
exit
```

#### Step 2: Copy files using PowerShell
```powershell
# Copy to VM A
scp -r vm-a-broker ubuntu@1.1.1.1:/home/ubuntu/
scp -r shared ubuntu@1.1.1.1:/home/ubuntu/
scp -r manifests ubuntu@1.1.1.1:/home/ubuntu/
ssh ubuntu@1.1.1.1 "mkdir -p /home/ubuntu/vm-a-broker/certs"
scp certs/ca.crt certs/cluster-a-issuer.crt certs/cluster-a-issuer.key ubuntu@1.1.1.1:/home/ubuntu/vm-a-broker/certs/

# Copy to VM B
scp -r vm-b-leaf ubuntu@2.2.2.2:/home/ubuntu/
scp -r shared ubuntu@2.2.2.2:/home/ubuntu/
scp -r manifests ubuntu@2.2.2.2:/home/ubuntu/
ssh ubuntu@2.2.2.2 "mkdir -p /home/ubuntu/vm-b-leaf/certs"
scp certs/ca.crt certs/cluster-b-issuer.crt certs/cluster-b-issuer.key ubuntu@2.2.2.2:/home/ubuntu/vm-b-leaf/certs/
```

#### Step 3: SSH and run setup
```powershell
# Setup VM A
ssh ubuntu@1.1.1.1
# (now you're on the Linux VM, run bash commands)
cd vm-a-broker
chmod +x *.sh ../shared/*.sh
./setup.sh
exit

# Setup VM B
ssh ubuntu@2.2.2.2
# (now you're on the Linux VM, run bash commands)
cd vm-b-leaf
chmod +x *.sh ../shared/*.sh
BROKER_IP=1.1.1.1 ./setup.sh
exit
```

## 🔑 SSH Key Setup (First Time)

If you haven't set up SSH keys:

### Generate SSH key (PowerShell or WSL)
```powershell
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

### Copy key to VMs
```powershell
# For VM A
type $env:USERPROFILE\.ssh\id_rsa.pub | ssh ubuntu@1.1.1.1 "cat >> .ssh/authorized_keys"

# For VM B
type $env:USERPROFILE\.ssh\id_rsa.pub | ssh ubuntu@2.2.2.2 "cat >> .ssh/authorized_keys"
```

For WSL:
```bash
ssh-copy-id ubuntu@1.1.1.1
ssh-copy-id ubuntu@2.2.2.2
```

## 🛠️ Troubleshooting Windows Issues

### Issue: "bash: command not found"
**Solution**: Use WSL2 or Git Bash, not PowerShell

### Issue: Line ending errors (^M)
**Solution**: Convert line endings using dos2unix
```bash
# In WSL
sudo apt-get install dos2unix
find . -type f -name "*.sh" -exec dos2unix {} \;
```

Or in Git Bash:
```bash
find . -type f -name "*.sh" -exec dos2unix {} \;
```

### Issue: Permission denied on scripts
**Solution**: Make scripts executable
```bash
chmod +x vm-a-broker/*.sh
chmod +x vm-b-leaf/*.sh
chmod +x shared/*.sh
chmod +x deploy-to-vms.sh
```

### Issue: Cannot connect to VMs
**Solution**: Check network connectivity
```powershell
# Test connection
ping 1.1.1.1
ping 2.2.2.2

# Test SSH
ssh -v ubuntu@1.1.1.1
```

### Issue: SCP fails with "No such file or directory"
**Solution**: Create directory first
```bash
ssh ubuntu@1.1.1.1 "mkdir -p /home/ubuntu/vm-a-broker/certs"
ssh ubuntu@2.2.2.2 "mkdir -p /home/ubuntu/vm-b-leaf/certs"
```

## 📝 Editing Files on Windows

### Using VS Code
1. Open folder in VS Code
2. Edit files normally
3. VS Code handles line endings automatically if configured:
   - Settings → Text Editor → Files → EOL → Set to `\n` (LF)
   - Or add to `.vscode/settings.json`:
   ```json
   {
     "files.eol": "\n"
   }
   ```

### Using Notepad++
1. Edit → EOL Conversion → Unix (LF)
2. Make changes
3. Save

### Using Windows Notepad (Not Recommended)
- Windows Notepad uses CRLF which can cause issues
- Use VS Code or Notepad++ instead

## 🖥️ Terminal Options for Windows

### 1. Windows Terminal (Recommended)
- Modern, tabbed interface
- Supports WSL, PowerShell, Command Prompt
- Download from Microsoft Store
- Best for this project

### 2. WSL2 Ubuntu Terminal
- Native Linux environment
- Full bash support
- Integrated with Windows filesystem

### 3. Git Bash
- Lightweight
- Good bash compatibility
- Portable

### 4. PowerShell
- Native Windows shell
- Limited bash script support
- Good for SSH/SCP commands

## 🔄 Complete Workflow Summary

```
┌─────────────────────────────────────────────────────┐
│         Your Windows Machine                        │
│  (c:\Users\pr0x2\Documents\Github\NATS-mTLS)       │
│                                                     │
│  1. Open WSL2/Git Bash                              │
│  2. Run: ./shared/generate-certificates.sh          │
│  3. Run: ./deploy-to-vms.sh                         │
│     (This copies files to both VMs)                 │
└─────────────────┬───────────────────────────────────┘
                  │
                  ├─────────────────┬─────────────────┐
                  │                 │                 │
                  ▼                 ▼                 │
    ┌──────────────────┐  ┌──────────────────┐       │
    │   VM A           │  │   VM B           │       │
    │   1.1.1.1        │  │   2.2.2.2        │       │
    │                  │  │                  │       │
    │  ssh ubuntu@...  │  │  ssh ubuntu@...  │       │
    │  cd vm-a-broker  │  │  cd vm-b-leaf    │       │
    │  ./setup.sh      │  │  BROKER_IP=...   │       │
    │                  │  │  ./setup.sh      │       │
    └──────────────────┘  └──────────────────┘       │
                  │                 │                 │
                  └─────────┬───────┘                 │
                            │                         │
                            ▼                         │
                  ┌───────────────────┐               │
                  │  Verify on VM B   │               │
                  │  kubectl logs...  │               │
                  └───────────────────┘               │
                            │                         │
                            └─────────────────────────┘
                         Back to Windows
                         (Monitor via SSH)
```

## 📊 Monitoring from Windows

### Real-time Logs
```powershell
# Watch publisher (VM A)
ssh ubuntu@1.1.1.1 "kubectl logs -n nats-system -l app=nats-publisher -f"

# Watch subscriber (VM B)
ssh ubuntu@2.2.2.2 "kubectl logs -n nats-system -l app=nats-subscriber -f"
```

### Check Status
```powershell
# VM A status
ssh ubuntu@1.1.1.1 "kubectl get pods -n nats-system"

# VM B status
ssh ubuntu@2.2.2.2 "kubectl get pods -n nats-system"
```

### Run Verification
```powershell
# Verify VM A
ssh ubuntu@1.1.1.1 "cd shared && ./verify-setup.sh"

# Verify VM B
ssh ubuntu@2.2.2.2 "cd shared && ./verify-setup.sh"
```

## 🎯 Recommended Setup

For the best experience on Windows:

1. **Install WSL2** with Ubuntu
2. **Install Windows Terminal** from Microsoft Store
3. **Install VS Code** with "Remote - WSL" extension
4. **Configure Git** for LF line endings:
   ```bash
   git config --global core.autocrlf input
   ```

## 🔐 Security Notes for Windows Users

1. **Certificate Files**: The private keys are in `certs/` directory
   - These are sensitive files
   - Don't share them
   - In production, don't commit to Git

2. **SSH Keys**: Your SSH keys are in `C:\Users\pr0x2\.ssh\`
   - Keep `id_rsa` secure (private key)
   - `id_rsa.pub` is the public key (safe to share)

3. **VM Access**: 
   - Change default passwords on VMs
   - Use SSH keys instead of passwords
   - Consider using SSH config file

## 📁 SSH Config (Optional but Recommended)

Create `C:\Users\pr0x2\.ssh\config` (or `~/.ssh/config` in WSL):

```
Host vm-a
    HostName 1.1.1.1
    User ubuntu
    IdentityFile ~/.ssh/id_rsa

Host vm-b
    HostName 2.2.2.2
    User ubuntu
    IdentityFile ~/.ssh/id_rsa
```

Then you can simply use:
```powershell
ssh vm-a
ssh vm-b
```

## 🎉 Quick Start for Windows Users

```powershell
# 1. Open Windows Terminal (WSL2 tab)
wsl

# 2. Navigate to project
cd /mnt/c/Users/pr0x2/Documents/Github/NATS-mTLS

# 3. Generate certificates
chmod +x shared/generate-certificates.sh
./shared/generate-certificates.sh

# 4. Deploy to VMs
chmod +x deploy-to-vms.sh
./deploy-to-vms.sh

# 5. Setup VM A (open new terminal tab)
ssh ubuntu@1.1.1.1
cd vm-a-broker
chmod +x *.sh ../shared/*.sh
./setup.sh

# 6. Setup VM B (open new terminal tab)
ssh ubuntu@2.2.2.2
cd vm-b-leaf
chmod +x *.sh ../shared/*.sh
BROKER_IP=1.1.1.1 ./setup.sh

# 7. Watch results (open new terminal tab)
ssh ubuntu@2.2.2.2 "kubectl logs -n nats-system -l app=nats-subscriber -f"
```

## ✅ You're All Set!

You now know how to:
- ✅ Run bash scripts from Windows
- ✅ Copy files to Linux VMs
- ✅ SSH into VMs and run commands
- ✅ Monitor the setup from Windows
- ✅ Troubleshoot common Windows issues

**Next Step**: Follow `QUICKSTART.md` or `README.md` to deploy your NATS-mTLS setup!
