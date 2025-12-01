# Sharables Monorepo - Quick Reference

## Setup

```bash
# Create repo
_playground/_scripts/setup-sharables-repo.sh sharables your-github-username

# Migrate existing content
_playground/_scripts/migrate-to-sharables.sh ../sharables

# Or dry-run first
_playground/_scripts/migrate-to-sharables.sh ../sharables --dry-run
```

## Common Commands

### Checkout Sections
```bash
# Single section
./scripts/sharables-checkout.sh cursor-rules

# Multiple sections
./scripts/sharables-checkout.sh cursor-rules global-utilities

# Everything
./scripts/sharables-checkout.sh '/*'
```

### View Status
```bash
# What's checked out
git sparse-checkout list

# What files are available
git ls-files
```

### Push/Pull
```bash
# Push changes
./scripts/sharables-push.sh

# Pull updates
./scripts/sharables-pull.sh
```

## Using in Projects

### Initial Setup
```bash
# Clone with sparse checkout
git clone --filter=blob:none --sparse git@github.com:user/sharables.git .sharables
cd .sharables

# Checkout what you need
./scripts/sharables-checkout.sh cursor-rules global-utilities

# Deploy to target paths (uses .sharables-deploy.yaml config)
SHARABLES_DIR=.sharables /root/_playground/_scripts/sharables-deploy.sh deploy
```

### Update
```bash
cd .sharables
./scripts/sharables-pull.sh
```

## Deployment

### Deploy Sections

**Cross-Platform (Python - Recommended):**
```bash
# Deploy according to config
python3 _playground/_scripts/sharables-deploy.py deploy --sharables-dir .sharables

# Create/edit config
python3 _playground/_scripts/sharables-deploy.py config --sharables-dir .sharables
```

**Linux/Debian (Bash):**
```bash
# Deploy according to config
SHARABLES_DIR=.sharables /root/_playground/_scripts/sharables-deploy.sh deploy

# Create/edit config
SHARABLES_DIR=.sharables /root/_playground/_scripts/sharables-deploy.sh config
```

### Git Operations from Deployed Locations

**Cross-Platform (Python - Recommended):**
```bash
# Status
python3 _playground/_scripts/sharables-git-helper.py status --sharables-dir .sharables

# Commit
python3 _playground/_scripts/sharables-git-helper.py commit --message "Update cursor rules" --sharables-dir .sharables

# Push
python3 _playground/_scripts/sharables-git-helper.py push --sharables-dir .sharables

# Sync (commit + push)
python3 _playground/_scripts/sharables-git-helper.py sync --message "Update" --sharables-dir .sharables
```

**Linux/Debian (Bash):**
```bash
# Status
SHARABLES_DIR=.sharables /root/_playground/_scripts/sharables-git-helper.sh status

# Commit
SHARABLES_DIR=.sharables /root/_playground/_scripts/sharables-git-helper.sh commit "Update cursor rules"

# Push
SHARABLES_DIR=.sharables /root/_playground/_scripts/sharables-git-helper.sh push

# Sync (commit + push)
SHARABLES_DIR=.sharables /root/_playground/_scripts/sharables-git-helper.sh sync "Update"
```

**Note:** Python scripts work on both Windows and Linux. Bash scripts are Linux/Debian only.

## Sections

- `cursor-rules/` - Cursor IDE rules
- `global-utilities/` - Shared scripts and helpers
- `shared-configs/` - Configuration files
- `docs/` - Documentation

## Workflow

1. **Edit**: Make changes in checked-out sections
2. **Commit**: `git add . && git commit -m "Update section"`
3. **Push**: `./scripts/sharables-push.sh`
4. **Update Projects**: `cd project/.sharables && ./scripts/sharables-pull.sh`

