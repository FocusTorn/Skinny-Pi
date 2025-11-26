# Skinny-Pi

Raspberry Pi system configuration and automation repository.

## Overview

This repository contains the complete setup and configuration for a Raspberry Pi running DietPi, including:

- MQTT broker setup and management
- System bootstrap scripts
- Development tools and configurations
- Automation scripts

## Structure

```
_playground/
├── _scripts/          # System scripts and utilities
│   └── mqtt/         # MQTT helper scripts
├── rust/             # Rust development projects
│   └── dev/
│       └── bootstrapper/  # Bootstrap scripts
├── zsh/              # Zsh configuration
└── _docs/            # Documentation
```

## Quick Start

### Bootstrap Scripts

Run bootstrap scripts in order:

1. **Mosquitto MQTT Broker:**
   ```bash
   sudo _playground/rust/dev/bootstrapper/bootstraps/bootstrap-mosquitto.sh
   ```

2. **GitHub SSH Setup:**
   ```bash
   _playground/rust/dev/bootstrapper/bootstraps/bootstrap-github-ssh.sh
   ```

### MQTT Management

Use the `mqtt` helper command:

```bash
mqtt status          # Check broker status
mqtt list            # List broker contents
mqtt setup-universal # Set up universal authentication
mqtt monitor "sensors/#"  # Monitor topics
```

## Secrets Management

Secrets are stored in `~/.secrets` (excluded from git). The file format:

```
MQTT_PASSWORD=your_password
MQTT_USERNAME=mqtt
```

## License

[Add your license here]



