# Sharables Repo with Submodules

## Your Proposed Structure

```
sharables/ (main repository)
├── .git/
├── .gitmodules              # Lists all submodules
├── cursor-rules/            # Submodule (its own repo)
│   ├── .git/
│   └── rules/
│       ├── formatting/
│       └── workspace/
├── global-utilities/         # Submodule (its own repo)
│   ├── .git/
│   └── scripts/
└── shared-configs/           # Submodule (its own repo)
    └── .git/
```

## How This Works

### Setup

```bash
# 1. Create sharables main repo
mkdir sharables && cd sharables
git init
git remote add origin git@github.com:user/sharables.git

# 2. Create cursor-rules as separate repo
cd ..
mkdir cursor-rules && cd cursor-rules
git init
# Add cursor rules
git add .
git commit -m "Initial cursor rules"
git remote add origin git@github.com:user/cursor-rules.git
git push -u origin main

# 3. Add cursor-rules as submodule to sharables
cd ../sharables
git submodule add git@github.com:user/cursor-rules.git cursor-rules

# 4. Repeat for other sections
# Create global-utilities repo, then:
git submodule add git@github.com:user/global-utilities.git global-utilities

# 5. Commit submodules
git add .gitmodules
git commit -m "Add submodules"
git push -u origin main
```

### .gitmodules File

```ini
[submodule "cursor-rules"]
    path = cursor-rules
    url = git@github.com:user/cursor-rules.git

[submodule "global-utilities"]
    path = global-utilities
    url = git@github.com:user/global-utilities.git
```

## Usage in Projects

### Clone with Submodules

```bash
# Clone sharables with all submodules
git clone --recurse-submodules git@github.com:user/sharables.git .sharables

# Or if already cloned
cd .sharables
git submodule init
git submodule update
```

### Work with Individual Sections

```bash
# Work with cursor-rules
cd .sharables/cursor-rules
git pull origin main
# Edit files
git add rules/formatting/markdown.mdc
git commit -m "Update markdown rules"
git push origin main

# Update sharables to track new commit
cd ..
git add cursor-rules
git commit -m "Update cursor-rules submodule"
git push
```

### Deploy to Custom Paths

You can still use the deployment system:

```bash
# Deploy cursor-rules to .cursor/rules
cd .sharables
python3 ../_playground/_scripts/sharables-deploy.py deploy
```

With config:
```yaml
deployments:
  - section: cursor-rules
    target: .cursor/rules
    method: symlink
```

## Pros of This Approach

✅ **Fully Git-native** - Uses standard Git submodules  
✅ **Independent repos** - Each section is its own repo  
✅ **Track specific commits** - Sharables tracks exact versions  
✅ **Work independently** - Edit cursor-rules, commit, push directly  
✅ **Can still deploy** - Use deployment scripts for custom paths  
✅ **Standard workflow** - No custom sparse checkout needed  
✅ **Built-in Git** - No special tools required  

## Cons / Considerations

### 1. Multiple Repositories to Manage

You need to create and maintain separate repos:
- `cursor-rules` repo
- `global-utilities` repo
- `shared-configs` repo
- `sharables` main repo

### 2. No Sparse Checkout (But You Don't Need It!)

With submodules, you can't do sparse checkout, but you don't need to:
- Each submodule is already a focused repo
- You get only what's in that submodule
- No need to filter files

### 3. Submodule Updates

When you update a submodule, you need to:
1. Commit in the submodule
2. Update the parent (sharables) to track new commit
3. Push both

```bash
cd cursor-rules
git commit -m "Update"
git push
cd ..
git add cursor-rules
git commit -m "Update cursor-rules"
git push
```

### 4. Cloning Complexity

Users need to remember `--recurse-submodules`:

```bash
# Must use this flag
git clone --recurse-submodules <repo-url>

# Or initialize after clone
git submodule update --init --recursive
```

## Comparison: Submodules vs Sparse Checkout

### With Submodules (Your Approach)

```
sharables/
├── cursor-rules/      # Submodule (separate repo)
├── global-utilities/  # Submodule (separate repo)
└── shared-configs/    # Submodule (separate repo)
```

**Workflow:**
```bash
git clone --recurse-submodules sharables
cd sharables/cursor-rules
git pull  # Update just cursor-rules
```

### With Sparse Checkout (Current Sharables System)

```
sharables/
├── cursor-rules/      # Section in same repo
├── global-utilities/  # Section in same repo
└── shared-configs/    # Section in same repo
```

**Workflow:**
```bash
git clone --sparse sharables
git sparse-checkout set cursor-rules
```

## Your Specific Question

> "Wouldn't I just be able to delete what does not pertain, add it to gitignore, then be able to push pull only the relevant items?"

**With submodules, this works differently:**

1. **Each submodule is its own repo** - So you'd delete from that specific repo
2. **.gitignore in sharables** - Doesn't affect submodule contents (submodules tracked as commits)
3. **Push/pull relevant items** - Each submodule repo only contains what it needs

**Example:**
```bash
# In cursor-rules repo (submodule)
cd sharables/cursor-rules
rm rules/workspace-architecture.mdc  # Delete from cursor-rules repo
git add .
git commit -m "Remove workspace rule"
git push  # Pushes to cursor-rules repo

# This only affects cursor-rules repo, not other submodules!
```

## Deployment with Submodules

You can still use the deployment system:

```yaml
deployments:
  - section: cursor-rules      # Points to submodule directory
    target: .cursor/rules
    method: symlink
    
  - section: global-utilities  # Points to submodule directory
    target: ~/.local/share/sharables
    method: symlink
```

The deployment script would:
1. Find `cursor-rules/` submodule directory
2. Create symlink from `.cursor/rules` to `sharables/cursor-rules`
3. Git tracking maintained (it's the submodule's repo)

## Complete Workflow Example

### Initial Setup

```bash
# 1. Create sharables repo
git init sharables
cd sharables
git remote add origin git@github.com:user/sharables.git

# 2. Add cursor-rules submodule
git submodule add git@github.com:user/cursor-rules.git cursor-rules

# 3. Add global-utilities submodule
git submodule add git@github.com:user/global-utilities.git global-utilities

# 4. Commit and push
git add .gitmodules
git commit -m "Add submodules"
git push -u origin main
```

### In Your Project

```bash
# Clone with submodules
git clone --recurse-submodules git@github.com:user/sharables.git .sharables

# Deploy to custom paths
cd .sharables
python3 ../_playground/_scripts/sharables-deploy.py deploy
```

### Daily Workflow

```bash
# Edit cursor rules
cd .sharables/cursor-rules
vim rules/formatting/markdown.mdc

# Commit in submodule
git add .
git commit -m "Update markdown"
git push origin main

# Update sharables to track new commit
cd ..
git add cursor-rules
git commit -m "Update cursor-rules submodule"
git push origin main
```

## Advantages of This Approach

1. **Each section is independent** - cursor-rules, global-utilities are separate repos
2. **Can work on sections independently** - Edit, commit, push directly in submodule
3. **Sharables tracks versions** - Knows which commit of each submodule
4. **Still can deploy** - Use deployment scripts for custom paths
5. **Fully Git-native** - No custom sparse checkout needed
6. **Can delete from submodule** - Only affects that specific repo

## When This Is Better Than Sparse Checkout

- ✅ You want each section as independent repo
- ✅ You want to work on sections separately
- ✅ You want standard Git workflow
- ✅ You don't mind managing multiple repos
- ✅ You want built-in Git solution

## When Sparse Checkout Is Better

- ✅ You want one repo to manage
- ✅ You want simpler setup
- ✅ You want to add/remove sections easily
- ✅ You don't need independent repos

## Recommendation

**Your approach (Sharables with submodules) is excellent if:**
- You want each section as its own repo
- You want independent versioning
- You want standard Git workflow
- You're okay managing multiple repos

**It combines:**
- ✅ Git submodules (standard, built-in)
- ✅ Deployment system (custom paths)
- ✅ Independent repos (each section separate)
- ✅ Version tracking (sharables tracks commits)

This is actually a really solid hybrid approach!


