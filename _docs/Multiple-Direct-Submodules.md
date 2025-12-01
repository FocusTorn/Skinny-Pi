# Multiple Direct Submodules - Each to Its Destination

## Your Approach

Clone each section directly to where you want it:

```
your-project/
├── .git/
├── .gitmodules
├── .cursor/                    # cursor-rules submodule (direct!)
│   ├── .git/
│   └── rules/
├── .local/share/sharables/     # global-utilities submodule (direct!)
│   ├── .git/
│   └── scripts/
└── .config/sharables/          # shared-configs submodule (direct!)
    ├── .git/
    └── configs/
```

## Setup

```bash
# In your project
git submodule add git@github.com:user/cursor-rules.git .cursor
git submodule add git@github.com:user/global-utilities.git .local/share/sharables
git submodule add git@github.com:user/shared-configs.git .config/sharables

# Commit
git add .gitmodules
git commit -m "Add sharables submodules"
git push
```

## .gitmodules File

```ini
[submodule ".cursor"]
    path = .cursor
    url = git@github.com:user/cursor-rules.git

[submodule ".local/share/sharables"]
    path = .local/share/sharables
    url = git@github.com:user/global-utilities.git

[submodule ".config/sharables"]
    path = .config/sharables
    url = git@github.com:user/shared-configs.git
```

## Workflow

### Clone Project with All Submodules

```bash
git clone --recurse-submodules <your-project-url> my-project
cd my-project

# All submodules are already in their destination directories!
# .cursor/ is ready to use
# .local/share/sharables/ is ready to use
# .config/sharables/ is ready to use
```

### Work with Each Section

```bash
# Update cursor rules
cd .cursor
git pull origin main
vim rules/formatting/markdown.mdc
git add .
git commit -m "Update markdown"
git push origin main
cd ..
git add .cursor
git commit -m "Update cursor rules"

# Update utilities
cd .local/share/sharables
git pull origin main
vim scripts/my-script.sh
git add .
git commit -m "Update script"
git push origin main
cd ../..
git add .local/share/sharables
git commit -m "Update utilities"
```

### Delete Unwanted Files

```bash
# In cursor-rules
cd .cursor
rm rules/workspace-architecture.mdc
git add .
git commit -m "Remove workspace rule"
git push  # Only affects cursor-rules repo

# In global-utilities
cd ../.local/share/sharables
rm scripts/old-script.sh
git add .
git commit -m "Remove old script"
git push  # Only affects utilities repo
```

## Advantages

✅ **No wrapper needed** - No `.sharables` directory  
✅ **Direct access** - Each section is where you want it  
✅ **No deployment** - Already in destination  
✅ **Standard Git** - Just submodules  
✅ **Independent repos** - Each section is separate  
✅ **Simple workflow** - Work with each directly  

## Comparison

### Your Approach (Direct Submodules)

```bash
git submodule add <cursor-repo> .cursor
git submodule add <utilities-repo> .local/share/sharables
git submodule add <configs-repo> .config/sharables
```

**Result:**
- ✅ Each section in its destination
- ✅ No wrapper repo
- ✅ No deployment step
- ✅ Simple and direct

### Sharables Wrapper Approach

```bash
git clone --recurse-submodules <sharables-repo> .sharables
python3 deploy.py  # Deploy to destinations
```

**Result:**
- ❌ Extra `.sharables` directory
- ❌ Deployment step needed
- ❌ More complex
- ✅ Unified management (only advantage)

## When to Use Each

### Use Direct Submodules (Your Approach) When:
- ✅ You want simplicity
- ✅ You know where each section should go
- ✅ You don't mind multiple submodule commands
- ✅ You want standard Git workflow

### Use Sharables Wrapper When:
- ✅ You want unified management
- ✅ You want to change destinations easily
- ✅ You want deployment configuration
- ✅ You want single clone command

## Setup Script

Here's a helper script:

```bash
#!/bin/bash
# Add multiple submodules directly to their destinations

git submodule add git@github.com:user/cursor-rules.git .cursor
git submodule add git@github.com:user/global-utilities.git .local/share/sharables
git submodule add git@github.com:user/shared-configs.git .config/sharables

git add .gitmodules
git commit -m "Add sharables submodules"
```

## .gitignore Considerations

You typically **don't** need to add submodules to `.gitignore` - they're tracked as submodules. But you might ignore local-only files:

```gitignore
# Local customizations in submodules
.cursor/rules/local-custom.mdc
.local/share/sharables/.local-settings
.config/sharables/local-config.yaml
```

## Complete Example

### Initial Setup

```bash
# Create your project
git init my-project
cd my-project

# Add submodules directly to destinations
git submodule add git@github.com:user/cursor-rules.git .cursor
git submodule add git@github.com:user/global-utilities.git .local/share/sharables
git submodule add git@github.com:user/shared-configs.git .config/sharables

# Commit
git add .gitmodules
git commit -m "Add sharables submodules"
git remote add origin <your-project-repo>
git push -u origin main
```

### Clone in New Location

```bash
# Clone with all submodules
git clone --recurse-submodules <your-project-repo> new-project
cd new-project

# Everything is already in place!
# .cursor/ is ready
# .local/share/sharables/ is ready
# .config/sharables/ is ready
```

### Daily Workflow

```bash
# Update all submodules
git submodule update --remote

# Or update individually
cd .cursor && git pull && cd ..
cd .local/share/sharables && git pull && cd ../..
cd .config/sharables && git pull && cd ../..

# Edit and commit in each
cd .cursor
vim rules/formatting/markdown.mdc
git add .
git commit -m "Update markdown"
git push
cd ..
git add .cursor
git commit -m "Update cursor rules"
```

## Summary

**Your approach is excellent!**

✅ Multiple sections  
✅ Each cloned directly to destination  
✅ No wrapper repo needed  
✅ No deployment step  
✅ Standard Git submodules  
✅ Simple and direct  

This is actually **simpler** than the sharables wrapper approach for your use case. The only advantage of the wrapper is unified management, but if you know where each section should go, direct submodules are the way to go!


