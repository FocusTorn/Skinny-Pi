# Windows Symlinks Support

## Yes, Windows Supports Symlinks!

Windows **does support symlinks** (since Windows Vista/Server 2008). The sharables system uses native Windows symlinks, which work the same as Linux symlinks once properly configured.

## Windows Symlink Requirements

To create symlinks on Windows, you need **one** of the following:

### Option 1: Developer Mode (Recommended - Easiest)

**Windows 10/11:**
1. Open **Settings** (Win + I)
2. Go to **Update & Security** → **For developers**
3. Enable **Developer Mode**
4. Restart if prompted

**Benefits:**
- ✅ No need to run as Administrator
- ✅ Works for all users
- ✅ One-time setup
- ✅ Recommended by Microsoft

### Option 2: Administrator Privileges

1. Right-click **Command Prompt** or **PowerShell**
2. Select **"Run as administrator"**
3. Run your deployment commands

**Note:** You must run as Administrator each time you create symlinks.

### Option 3: Use Copy Method (Fallback)

If symlinks don't work, use the copy method:

```yaml
deployments:
  - section: cursor-rules
    target: .cursor/rules
    method: copy  # Uses copy instead of symlink
```

**Note:** Copy method doesn't maintain git connection, but works everywhere.

## How Windows Symlinks Work

### Technical Details

Windows supports three types of links:
1. **Symbolic Links** (symlinks) - What we use
2. **Hard Links** - For files only
3. **Junctions** - Legacy directory links

The sharables system uses **symbolic links**, which work identically to Linux symlinks:
- Point to source location
- Maintain git tracking
- Work across drives (unlike junctions)

### Path Handling

Windows symlinks work with:
- Relative paths: `.cursor/rules`
- Absolute paths: `C:\Users\YourName\.cursor\rules`
- UNC paths: `\\server\share\path`
- Both forward slashes `/` and backslashes `\`

## Verification

### Check if Symlinks Work

```cmd
# Try creating a test symlink
mklink /D test-link C:\Users

# If it works, delete it
rmdir test-link
```

### Check Developer Mode

```cmd
# Check registry (Developer Mode)
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowDevelopmentWithoutDevLicense
```

If it returns `0x1`, Developer Mode is enabled.

## Troubleshooting

### Error: "A required privilege is not held by the client"

**Solution:** Enable Developer Mode (Option 1) or run as Administrator (Option 2)

### Error: "The system cannot find the path specified"

**Solution:** Make sure the source path exists and is correct

### Symlinks Created But Don't Work

**Check:**
1. Source path is correct
2. Source exists
3. Target parent directory exists
4. No permission issues

### Using Git Bash on Windows

Git Bash on Windows can create symlinks, but they may not work correctly with Windows applications. Use the Python script instead for better compatibility.

## Comparison: Windows vs Linux

| Feature | Windows | Linux |
|---------|---------|-------|
| Symlink Support | ✅ Yes (Vista+) | ✅ Yes |
| Requires Admin | ❌ No (with Dev Mode) | ❌ No |
| Cross-Drive | ✅ Yes | ✅ Yes |
| Git Tracking | ✅ Yes | ✅ Yes |
| Path Format | `/` or `\` | `/` |

## Best Practice

**Recommended Setup:**
1. Enable Developer Mode (one-time setup)
2. Use Python scripts (cross-platform)
3. Use symlink method in config
4. Enjoy seamless cross-platform experience

## Summary

✅ **Windows DOES support symlinks**  
✅ **Works identically to Linux symlinks**  
✅ **Enable Developer Mode for easiest setup**  
✅ **Python scripts handle Windows correctly**  
✅ **Same functionality on both platforms**  

The sharables system uses native Windows symlinks, so once Developer Mode is enabled (or you run as Admin), everything works exactly like on Linux!

