# Swap Configuration Guide

## What is Swap?

**Swap** is disk space used as virtual memory when physical RAM is full. It allows the system to:

- **Prevent crashes** when RAM is exhausted
- **Handle memory spikes** from applications
- **Give the OOM (Out of Memory) killer time** to work before system freezes

## Why Your Pi Needs Swap

### Current Status
- **RAM:** 3.8GB total
- **Swap:** 0B (none configured) ⚠️
- **Services Running:**
  - Home Assistant (memory-intensive)
  - MariaDB (database)
  - Node-RED
  - Mosquitto MQTT broker
  - Other services

### The Problem

Without swap, if your system runs out of RAM:
- The OOM killer should trigger, but...
- If the system freezes **before** OOM can log/act, you get a hard lockup
- This may have contributed to your system lockup

## Swap Size Recommendations

For Raspberry Pi with 4GB RAM:

| RAM | Recommended Swap | Use Case |
|-----|------------------|----------|
| 4GB | 1GB | Standard services (Home Assistant, etc.) ⭐ **Recommended** |
| 4GB | 2GB | Heavy workloads, many services |
| 4GB | 512MB | Minimal (if disk space is limited) |

**Recommendation for your system: 1GB swap (1024 MiB)**

### DietPi Auto-Size Option

DietPi's swap function also supports auto-sizing:
- Use `1` for auto-size (ensures minimum 2048 MiB total memory)
- Or specify exact size in MiB (e.g., `1024` for 1GB)

### DietPi Swappiness Setting

Your system uses **swappiness=1** (very conservative):
- Minimizes swap usage (swap only when absolutely necessary)
- Optimized for SD card longevity
- This is DietPi's recommended setting

## Configuration Methods

### Method 1: Using DietPi's Built-in Swap System (RECOMMENDED for DietPi)

**This is the proper DietPi way** - uses DietPi's optimized swap management that integrates with the system.

```bash
# Edit DietPi configuration
sudo nano /boot/dietpi.txt
# Find and change:
# AUTO_SETUP_SWAPFILE_SIZE=0
# To:
AUTO_SETUP_SWAPFILE_SIZE=1024

# Run DietPi's swap setup function
sudo /boot/dietpi/func/dietpi-set_swapfile

# Verify swap is active
free -h
swapon --show
```

**What this does:**
- Uses DietPi's optimized swap management
- Creates swap at `/var/swap` (DietPi's standard location)
- Maintains DietPi's optimized swappiness=1 setting
- Integrates with DietPi's configuration system
- Persists across reboots

### Method 2: Direct Function Call (Alternative)

You can also call the function directly without editing config:

```bash
# Create 1GB swap at DietPi's standard location
sudo /boot/dietpi/func/dietpi-set_swapfile 1024 /var/swap

# Or use auto-size (ensures min 2048 MiB total memory)
sudo /boot/dietpi/func/dietpi-set_swapfile 1 /var/swap
```

### Method 3: Manual Swap File (Not Recommended - Use DietPi's method instead)

If dphys-swapfile doesn't work:

```bash
# Create 1GB swap file
sudo fallocate -l 1G /swapfile
# OR if fallocate doesn't work:
sudo dd if=/dev/zero of=/swapfile bs=1M count=1024

# Set permissions
sudo chmod 600 /swapfile

# Make it swap
sudo mkswap /swapfile

# Enable swap
sudo swapon /swapfile

# Make it permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Verify
free -h
```

## Verification

After setup, verify swap is working:

```bash
# Check swap status
free -h

# Should show something like:
#               total        used        free      shared  buff/cache   available
# Mem:           3.8Gi       1.4Gi       1.4Gi        11Mi       1.1Gi       2.4Gi
# Swap:          1.0Gi          0B       1.0Gi    <-- This line should show swap now

# Check swap details
swapon --show

# Monitor swap usage
watch -n 1 'free -h && echo "---" && swapon --show'
```

## Performance Considerations

### Swap on SD Card
- **Slower** than RAM (SD card is much slower)
- Can cause wear on SD card with heavy swapping
- But better than system crashes/freezes

### Swap on USB SSD
- If you have a USB SSD, put swap there instead
- Much faster and reduces SD card wear

## Monitoring Swap Usage

```bash
# Watch swap usage in real-time
watch -n 1 free -h

# Check which processes are using swap
sudo smem --swap

# System load and swap
vmstat 1
```

## Troubleshooting

### Swap not activating
```bash
# Check dmesg for errors
dmesg | grep -i swap

# Check fstab
cat /etc/fstab | grep swap

# Check systemd service
systemctl status dphys-swapfile
```

### Remove Swap (if needed)
```bash
# Disable swap
sudo swapoff -a

# Remove from fstab
sudo nano /etc/fstab  # Remove swap line

# Delete swap file
sudo rm /swapfile

# Or if using dphys-swapfile
sudo dphys-swapfile swapoff
sudo rm /var/swap
```

## Auto-Setup Script

See the bootstrap script for automated swap setup.

