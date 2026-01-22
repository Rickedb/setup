# Testing Debian Configuration with Vagrant

This guide explains how to test your Debian setup in a virtual machine without physical installation.

## Prerequisites

Install Vagrant and VirtualBox:

```bash
# On Arch Linux (your current system)
sudo pacman -S vagrant virtualbox virtualbox-host-modules-arch

# Load VirtualBox kernel modules
sudo modprobe vboxdrv
```

## Quick Start

### 1. Start the Debian VM

```bash
cd vagrant
vagrant up --provider=virtualbox
```

This will:
- Download Debian 12 (Bookworm) box (~500MB)
- Create a VM with 4GB RAM and 2 CPUs
- Mount your setup folder to `/setup` inside the VM

### 2. Connect to the VM

```bash
vagrant ssh
```

### 3. Test the Installation

Inside the VM:

```bash
cd /setup/linux/debian
sudo ./install.sh
```

Wait for installation to complete (may take 20-30 minutes).

### 4. Run Post-Installation

```bash
sudo ./post-install.sh
```

### 5. Test Desktop Environment

If you want to test GNOME:

```bash
# Exit SSH
exit

# Stop the VM
vagrant halt

# Edit Vagrantfile.debian and uncomment:
# vb.gui = true

# Start with GUI
vagrant up
```

## Using the Custom Vagrantfile

The `Vagrantfile.debian` is specifically configured for testing. To use it:

```bash
# Rename or backup existing Vagrantfile
mv Vagrantfile Vagrantfile.ubuntu.bak

# Use the Debian one
cp Vagrantfile.debian Vagrantfile

# Or specify directly
VAGRANT_VAGRANTFILE=Vagrantfile.debian vagrant up
```

## Testing Scenarios

### Scenario 1: Test Installation Script Only

```bash
vagrant up
vagrant ssh
cd /setup/linux/debian
sudo ./install.sh 2>&1 | tee install.log
```

Check for errors in `install.log`.

### Scenario 2: Test Desktop Environment

1. Enable GUI in `Vagrantfile.debian`:
   ```ruby
   vb.gui = true
   ```

2. Start VM:
   ```bash
   vagrant up
   ```

3. After installation, reboot:
   ```bash
   vagrant ssh
   sudo reboot
   ```

4. Login through GUI and test GNOME.

### Scenario 3: Test Hyprland Build

```bash
vagrant ssh
cd /setup/linux/debian/hyprland
# Follow manual Hyprland installation
```

### Scenario 4: Test Specific Packages

```bash
vagrant ssh

# Test Docker
docker --version
sudo docker run hello-world

# Test development tools
rustc --version
node --version
python3 --version

# Test CLI tools
bat --version
lazygit --version
```

## VM Management

### Start VM
```bash
vagrant up
```

### Connect to VM
```bash
vagrant ssh
```

### Stop VM
```bash
vagrant halt
```

### Restart VM
```bash
vagrant reload
```

### Delete VM (clean slate)
```bash
vagrant destroy
vagrant up  # Start fresh
```

### Check VM Status
```bash
vagrant status
```

## Snapshots (Quick Recovery)

Take snapshots to save VM state:

```bash
# Take snapshot before installation
vagrant snapshot save before-install

# Take snapshot after installation
vagrant snapshot save after-install

# Restore to a snapshot
vagrant snapshot restore before-install

# List snapshots
vagrant snapshot list

# Delete snapshot
vagrant snapshot delete before-install
```

## Testing Workflow Example

```bash
# 1. Start fresh VM
vagrant destroy -f
vagrant up

# 2. Take snapshot before installation
vagrant snapshot save clean-debian

# 3. Test installation
vagrant ssh
cd /setup/linux/debian
sudo ./install.sh

# 4. If something fails, restore and try again
exit
vagrant snapshot restore clean-debian
# Make fixes to install.sh
vagrant ssh
cd /setup/linux/debian
sudo ./install.sh

# 5. Once working, take snapshot
exit
vagrant snapshot save installed

# 6. Test post-installation
vagrant ssh
sudo /setup/linux/debian/post-install.sh
```

## VM Configuration

The test VM has:

- **OS**: Debian 12 (Bookworm)
- **RAM**: 4GB
- **CPUs**: 2 cores
- **Disk**: ~20GB (dynamic)
- **Video RAM**: 128MB (for GUI testing)
- **3D Acceleration**: Enabled

Adjust in `Vagrantfile.debian` if needed:

```ruby
vb.memory = "8192"  # 8GB RAM
vb.cpus = 4         # 4 CPUs
```

## Sharing Files

Your setup folder is automatically synced:

- **Host**: `/home/rickedb/Work/github/setup`
- **VM**: `/setup`

Any changes you make on your host are immediately visible in the VM.

## Testing with Docker Alternative

If you prefer Docker over Vagrant:

```bash
# Create Debian container
docker run -it --name debian-test \
  -v $(pwd):/setup \
  debian:bookworm bash

# Inside container
cd /setup/linux/debian
apt-get update
./install.sh
```

Note: Docker won't let you test desktop environments or systemd services.

## Troubleshooting

### VirtualBox kernel modules not loaded

```bash
sudo modprobe vboxdrv vboxnetadp vboxnetflt
```

### VM won't start

```bash
# Check VirtualBox is working
VBoxManage list vms

# Try with more verbose output
vagrant up --debug
```

### Slow performance

Increase VM resources in `Vagrantfile.debian`:
```ruby
vb.memory = "8192"
vb.cpus = 4
```

### Shared folder not working

```bash
# Install VirtualBox Guest Additions
vagrant plugin install vagrant-vbguest
vagrant vbguest --do install
```

### Can't see GUI

Make sure you uncommented `vb.gui = true` in `Vagrantfile.debian`.

## Remote Testing

You can also test on a remote server using:

- **AWS EC2**: Launch Debian instance
- **DigitalOcean**: Create Debian droplet
- **Local VPS**: Any Debian 12 server

Just copy the scripts and run:

```bash
scp -r linux/debian user@server:~/
ssh user@server
cd ~/debian
sudo ./install.sh
```

## Automated Testing Script

Create `test-install.sh`:

```bash
#!/bin/bash
vagrant destroy -f
vagrant up
vagrant ssh -c "cd /setup/linux/debian && sudo ./install.sh"
if [ $? -eq 0 ]; then
    echo "✓ Installation succeeded"
else
    echo "✗ Installation failed"
    exit 1
fi
```

## Cleanup

When done testing:

```bash
# Remove VM
vagrant destroy

# Remove downloaded box (optional)
vagrant box remove debian/bookworm64

# Clean up snapshots
vagrant snapshot delete --all
```

## Benefits of VM Testing

✓ **Safe**: No risk to your main system
✓ **Fast**: Snapshots let you quickly retry
✓ **Repeatable**: Test the same setup multiple times
✓ **Isolated**: Won't affect your Arch installation
✓ **Complete**: Test the entire installation process
