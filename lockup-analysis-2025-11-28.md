# Raspberry Pi Lockup Analysis
**Date:** November 28, 2025  
**Boot Session:** Started 06:00:32, Last Activity 06:36:53

## Summary

The system experienced a **hard lockup/freeze** that required manual power down. The system was running normally for approximately 36 minutes before becoming completely unresponsive.

## Timeline

- **06:00:32** - System booted
- **06:00:35** - Mosquitto MQTT broker started
- **06:00:39** - ESP32 device (`esp32-s3-led-controller`) connected to MQTT
- **06:32:06** - All services started (Home Assistant, MariaDB, Node-RED, etc.)
- **06:36:53** - Last Home Assistant log entry (Bluetooth scanner error - normal)
- **06:36:57** - Last system log entry (MQTT PING/PUBLISH from ESP32 device - normal traffic)
- **After 06:36:57** - Complete lockup, no further logs

## Key Evidence

### Filesystem Recovery Required
```
[    2.819394] EXT4-fs (mmcblk0p2): INFO: recovery required on readonly filesystem
```
This confirms the previous shutdown was **unclean** - the system did not shut down gracefully.

### Logs Stop Abruptly
- No shutdown sequence
- No error messages
- No kernel panic
- No OOM killer activity
- No I/O errors

### Home Assistant Database
```
WARNING: The system could not validate that the sqlite3 database at 
//mnt/dietpi_userdata/homeassistant/home-assistant_v2.db was shutdown cleanly
```
Previous session from November 25 also ended uncleanly, suggesting recurring issues.

## What DIDN'T Cause It

❌ **Not Out of Memory:**
- 3.8GB total RAM
- 2.5GB available at current boot
- But: **NO SWAP configured** - could be problematic under memory pressure

❌ **Not Disk Full:**
- 21GB free on root filesystem

❌ **Not Thermal:**
- Current temperature: 34.5°C (normal)

❌ **Not Software Crash:**
- No kernel panic
- No OOM killer
- No application crashes logged

❌ **Not SD Card I/O Errors (visible):**
- No I/O errors in kernel messages
- Filesystem error count: 0

❌ **Not MQTT Broker or Data Stream Issue:**
- Mosquitto broker functioning normally
- Only 1 client connected: `esp32-s3-led-controller` (192.168.1.168)
- Traffic pattern: Regular keepalive (PING every 15s, PUBLISH every 30s)
- Message size: 120 bytes per status update
- Volume: ~3 messages/minute (very low)
- Memory usage: 3.9MB (lightweight)
- No connection errors, disconnects, or warnings
- Traffic was normal right up until lockup at 06:36:57
- Last message processed successfully before system froze

## Likely Causes

### 1. Hardware-Level Lockup (Most Likely)
- **SD Card Issue:** Intermittent SD card problems can cause complete freezes
  - Card may be failing or have connection issues
  - SD card recovery message suggests filesystem corruption from unexpected power loss
  
- **Power Supply:** Insufficient or unstable power
  - Voltage drops can cause lockups without logging errors
  - Pi 4 requires quality 5V/3A power supply

- **Kernel Bug/Driver Issue:**
  - Hardware-specific driver may have hit a bug
  - Bluetooth errors were occurring (though likely not the cause)

### 2. Memory Pressure Without Swap
- No swap configured means if memory is exhausted, OOM killer should trigger
- But if system freezes before OOM can log, it might appear as a lockup
- Home Assistant + MariaDB + Node-RED + other services can consume significant memory

### 3. Process Deadlock
- A process may have deadlocked the kernel
- System becomes completely unresponsive
- No logs because logging subsystem is also frozen

## Recommendations

### Immediate Actions

1. **Check SD Card Health:**
   ```bash
   # Check for bad blocks
   sudo badblocks -v /dev/mmcblk0
   
   # Check SD card status
   dmesg | grep -i mmc
   
   # Consider replacing SD card if issues found
   ```

2. **Configure Swap:**
   ```bash
   # Add swap to prevent OOM issues
   sudo dphys-swapfile swapoff
   sudo nano /etc/dphys-swapfile
   # Set CONF_SWAPSIZE=1024 (or appropriate size)
   sudo dphys-swapfile setup
   sudo dphys-swapfile swapon
   ```

3. **Enable Watchdog:**
   ```bash
   # Enable hardware watchdog to auto-reboot on lockups
   sudo apt-get install watchdog
   sudo systemctl enable watchdog
   sudo systemctl start watchdog
   ```

4. **Monitor Memory Usage:**
   ```bash
   # Check memory usage patterns
   free -h
   # Monitor for leaks
   ps aux --sort=-%mem | head -20
   ```

### Diagnostic Commands

```bash
# Check filesystem errors
sudo fsck -n /dev/mmcblk0p2

# Monitor system resources
htop
iotop

# Check for hardware issues
vcgencmd get_throttled
dmesg | grep -i error

# Monitor temperature
watch -n 1 vcgencmd measure_temp
```

### Long-Term Solutions

1. **Replace SD Card:**
   - Use high-quality, high-endurance SD card (SanDisk Extreme, Samsung EVO Plus)
   - Consider using SSD via USB 3.0 instead

2. **Power Supply:**
   - Ensure official Raspberry Pi power supply or equivalent quality
   - Check for voltage drops with: `vcgencmd get_throttled`
   - Should show `throttled=0x0` when not throttling

3. **Add System Monitoring:**
   - Set up monitoring for temperature, memory, and system health
   - Configure alerts for high memory usage or temperature

4. **Enable Kernel Logging to Network:**
   - Set up remote syslog to capture logs even if local logging fails
   - Or use kernel ring buffer export over network

## System Configuration Notes

- **Kernel:** 6.12.47+rpt-rpi-v8
- **OS:** DietPi (Debian-based)
- **Filesystem:** EXT4
- **Swap:** None configured
- **Watchdog:** Hardware present but not configured as service

## Filesystem Recovery Status

The system successfully recovered the filesystem on boot:
```
[    5.958460] EXT4-fs (mmcblk0p2): recovery complete
```

No filesystem errors detected in current boot, but the recovery requirement indicates the lockup was severe enough to prevent proper filesystem unmounting.

## MQTT Broker Analysis

### Traffic Pattern
- **Client:** Single ESP32 device (`esp32-s3-led-controller`) at 192.168.1.168
- **Connection:** Connected at 06:00:39, remained connected until lockup
- **Message Pattern:**
  - PINGREQ (keepalive): Every 15 seconds
  - PUBLISH (status): Every 30 seconds
  - Message size: 120 bytes
  - Total volume: ~3 messages/minute (~294 messages in 59 minutes)
- **Broker Status:**
  - Memory: 3.9MB (very lightweight)
  - Persistence database: 47 bytes
  - No connection errors, disconnects, or warnings
  - Last message processed successfully at 06:36:57

### Conclusion
**MQTT broker and data stream are NOT the issue.** Traffic was completely normal, low-volume, and regular. The broker was functioning perfectly when the system locked up. The lockup occurred AFTER successful MQTT message processing, indicating it's unrelated to MQTT activity.

The regular, predictable traffic pattern suggests no message bursts, connection storms, or data corruption that could cause a lockup.

---

**Next Steps:** Monitor the system after implementing swap and watchdog. If lockups continue, replace SD card and/or power supply.

