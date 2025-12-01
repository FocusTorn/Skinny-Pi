#!/usr/bin/env python3
"""
Sharables Deployment Script - Cross-platform
Deploys sharables sections to target paths while maintaining git tracking
Works on both Windows and Linux/Debian
"""

import os
import sys
import shutil
import subprocess
from pathlib import Path
from typing import List, Dict, Optional
import argparse
from datetime import datetime

# Try to import yaml, provide helpful error if not available
try:
    import yaml
except ImportError:
    print("Error: PyYAML not installed. Install with: pip install pyyaml")
    sys.exit(1)

# Colors for terminal output (cross-platform)
class Colors:
    GREEN = '\033[0;32m'
    BLUE = '\033[0;34m'
    YELLOW = '\033[1;33m'
    RED = '\033[0;31m'
    NC = '\033[0m'  # No Color
    
    @staticmethod
    def disable():
        """Disable colors on Windows if not supported"""
        if sys.platform == 'win32':
            try:
                import ctypes
                kernel32 = ctypes.windll.kernel32
                # Enable ANSI escape sequences on Windows 10+
                kernel32.SetConsoleMode(kernel32.GetStdHandle(-11), 7)
            except:
                Colors.GREEN = Colors.BLUE = Colors.YELLOW = Colors.RED = Colors.NC = ''

Colors.disable()

def find_sharables_dir(start_path: Path = None) -> Optional[Path]:
    """Find sharables directory by looking for .git folder"""
    if start_path is None:
        start_path = Path.cwd()
    
    current = start_path.resolve()
    while current != current.parent:
        for name in ['.sharables', 'sharables']:
            sharables = current / name
            if sharables.exists() and (sharables / '.git').exists():
                return sharables
        current = current.parent
    
    return None

def expand_path(path_str: str) -> Path:
    """Expand ~ and resolve path"""
    expanded = os.path.expanduser(path_str)
    return Path(expanded).resolve()

def create_symlink(source: Path, target: Path, is_dir: bool = True) -> bool:
    """
    Create symlink (cross-platform)
    Windows: Requires Administrator privileges OR Developer Mode enabled
    Linux: Works without special permissions
    """
    try:
        # Remove target if it exists
        if target.exists() or target.is_symlink():
            if target.is_symlink():
                target.unlink()
            else:
                # Backup existing
                backup = target.with_name(f"{target.name}.backup.{int(datetime.now().timestamp())}")
                if target.is_dir():
                    shutil.move(str(target), str(backup))
                else:
                    target.rename(backup)
                print(f"{Colors.YELLOW}Backed up existing: {backup}{Colors.NC}")
        
        # Create parent directory
        target.parent.mkdir(parents=True, exist_ok=True)
        
        # Create symlink
        # Windows DOES support symlinks (since Vista/Server 2008)
        # But requires either Administrator privileges OR Developer Mode
        if sys.platform == 'win32':
            # Windows symlink creation
            # Path.symlink_to() handles Windows correctly
            if is_dir:
                target.symlink_to(source, target_is_directory=True)
            else:
                target.symlink_to(source)
        else:
            # Unix-like systems (Linux, macOS)
            target.symlink_to(source)
        
        return True
    except OSError as e:
        error_code = getattr(e, 'winerror', None)
        if sys.platform == 'win32':
            if error_code == 1314:  # ERROR_PRIVILEGE_NOT_HELD
                print(f"{Colors.RED}Error: Insufficient privileges to create symlink{Colors.NC}")
                print(f"{Colors.YELLOW}Windows symlink options:{Colors.NC}")
                print(f"  1. Enable Developer Mode: Settings → Update & Security → For developers")
                print(f"  2. Run as Administrator: Right-click → Run as administrator")
                print(f"  3. Use copy method: Set method: copy in config file")
            else:
                print(f"{Colors.RED}Error creating symlink: {e}{Colors.NC}")
                print(f"{Colors.YELLOW}Windows symlinks require Administrator OR Developer Mode{Colors.NC}")
        else:
            print(f"{Colors.RED}Error creating symlink: {e}{Colors.NC}")
        return False

def copy_directory(source: Path, target: Path) -> bool:
    """Copy directory (fallback if symlinks don't work)"""
    try:
        if target.exists():
            backup = target.with_name(f"{target.name}.backup.{int(datetime.now().timestamp())}")
            if target.is_dir():
                shutil.move(str(target), str(backup))
            else:
                target.rename(backup)
        
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(str(source), str(target), dirs_exist_ok=True)
        return True
    except Exception as e:
        print(f"{Colors.RED}Error copying: {e}{Colors.NC}")
        return False

def create_example_config(config_path: Path):
    """Create example deployment configuration"""
    config_content = """# Sharables Deployment Configuration
# Maps sections to target paths (works on Windows and Linux)

deployments:
  # Deploy cursor-rules to .cursor/rules (relative to project root)
  - section: cursor-rules
    target: .cursor/rules
    method: symlink  # symlink, copy, or git-worktree
    
  # Deploy global-utilities to home directory
  - section: global-utilities
    target: ~/.local/share/sharables
    method: symlink
    
  # Example: Windows path
  # - section: shared-configs
  #   target: C:/Users/YourName/.config/sharables
  #   method: symlink
"""
    config_path.write_text(config_content)
    print(f"{Colors.GREEN}Created example config at: {config_path}{Colors.NC}")

def load_config(config_path: Path) -> List[Dict]:
    """Load and parse deployment configuration"""
    if not config_path.exists():
        return []
    
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            config = yaml.safe_load(f)
        
        deployments = config.get('deployments', [])
        return deployments
    except Exception as e:
        print(f"{Colors.RED}Error loading config: {e}{Colors.NC}")
        return []

def deploy_section(section: str, target_str: str, method: str, sharables_dir: Path, project_root: Path):
    """Deploy a single section"""
    section_path = sharables_dir / section
    
    if not section_path.exists():
        print(f"{Colors.YELLOW}Section not found: {section} (skipping){Colors.NC}")
        return False
    
    # Expand and resolve target path
    target = expand_path(target_str)
    
    # If relative path, make it relative to project root
    if not target.is_absolute() and not target_str.startswith('~'):
        target = (project_root / target_str).resolve()
    
    # Check if already deployed correctly
    if target.exists() and target.is_symlink():
        try:
            link_target = Path(os.readlink(str(target)))
            if link_target.resolve() == section_path.resolve():
                print(f"{Colors.GREEN}✓ Already deployed: {section} -> {target}{Colors.NC}")
                return True
        except:
            pass
    
    # Deploy based on method
    if method == 'symlink':
        is_dir = section_path.is_dir()
        if create_symlink(section_path, target, is_dir):
            print(f"{Colors.GREEN}✓ Deployed (symlink): {section} -> {target}{Colors.NC}")
            return True
        else:
            print(f"{Colors.YELLOW}Symlink failed, trying copy method...{Colors.NC}")
            method = 'copy'
    
    if method == 'copy':
        if section_path.is_dir():
            if copy_directory(section_path, target):
                print(f"{Colors.GREEN}✓ Deployed (copy): {section} -> {target}{Colors.NC}")
                print(f"{Colors.YELLOW}  Note: Copy method doesn't maintain git connection{Colors.NC}")
                return True
        else:
            shutil.copy2(str(section_path), str(target))
            print(f"{Colors.GREEN}✓ Deployed (copy): {section} -> {target}{Colors.NC}")
            return True
    
    return False

def undeploy_section(target_str: str, project_root: Path):
    """Remove deployed section"""
    target = expand_path(target_str)
    
    if not target.is_absolute() and not target_str.startswith('~'):
        target = (project_root / target_str).resolve()
    
    if target.is_symlink():
        target.unlink()
        print(f"{Colors.GREEN}✓ Removed: {target}{Colors.NC}")
        return True
    elif target.exists():
        response = input(f"Target exists but is not a symlink: {target}\nRemove anyway? (y/n): ")
        if response.lower() == 'y':
            if target.is_dir():
                shutil.rmtree(str(target))
            else:
                target.unlink()
            print(f"{Colors.GREEN}✓ Removed: {target}{Colors.NC}")
            return True
    else:
        print(f"{Colors.YELLOW}Target not found: {target}{Colors.NC}")
        return False

def main():
    parser = argparse.ArgumentParser(description='Deploy sharables sections to target paths')
    parser.add_argument('action', choices=['deploy', 'undeploy', 'config'], 
                       default='deploy', nargs='?',
                       help='Action to perform')
    parser.add_argument('--sharables-dir', type=str, default=None,
                       help='Path to sharables directory (auto-detected if not specified)')
    parser.add_argument('--project-root', type=str, default=None,
                       help='Project root directory (default: parent of sharables)')
    
    args = parser.parse_args()
    
    # Find sharables directory
    if args.sharables_dir:
        sharables_dir = Path(args.sharables_dir).resolve()
    else:
        sharables_dir = find_sharables_dir()
        if not sharables_dir:
            sharables_dir = Path('.sharables').resolve()
    
    if not sharables_dir.exists():
        print(f"{Colors.RED}Sharables directory not found: {sharables_dir}{Colors.NC}")
        print("Clone the sharables repo first:")
        print(f"  git clone --filter=blob:none --sparse <repo-url> {sharables_dir.name}")
        sys.exit(1)
    
    if not (sharables_dir / '.git').exists():
        print(f"{Colors.RED}Not a git repository: {sharables_dir}{Colors.NC}")
        sys.exit(1)
    
    # Determine project root
    if args.project_root:
        project_root = Path(args.project_root).resolve()
    else:
        project_root = sharables_dir.parent
    
    config_path = sharables_dir / '.sharables-deploy.yaml'
    
    # Handle config action
    if args.action == 'config':
        create_example_config(config_path)
        return
    
    # Load configuration
    if not config_path.exists():
        print(f"{Colors.YELLOW}Config file not found: {config_path}{Colors.NC}")
        print("Creating example config...")
        create_example_config(config_path)
        print(f"{Colors.GREEN}Created example config. Edit it and run again.{Colors.NC}")
        return
    
    deployments = load_config(config_path)
    
    if not deployments:
        print(f"{Colors.YELLOW}No deployments found in config{Colors.NC}")
        return
    
    # Execute action
    if args.action == 'deploy':
        print(f"{Colors.BLUE}=== Deploying Sharables Sections ==={Colors.NC}\n")
        success_count = 0
        for deployment in deployments:
            section = deployment.get('section')
            target = deployment.get('target')
            method = deployment.get('method', 'symlink')
            
            if not section or not target:
                continue
            
            if deploy_section(section, target, method, sharables_dir, project_root):
                success_count += 1
        
        print(f"\n{Colors.GREEN}Deployment complete! ({success_count}/{len(deployments)} sections){Colors.NC}")
        print("\nGit operations:")
        print(f"  - Edit files at their target locations (they're symlinked)")
        print(f"  - Commit/push from: {sharables_dir}")
        print(f"  - Changes are tracked in the sharables repo")
    
    elif args.action == 'undeploy':
        print(f"{Colors.BLUE}=== Undeploying Sharables Sections ==={Colors.NC}\n")
        for deployment in deployments:
            target = deployment.get('target')
            if target:
                undeploy_section(target, project_root)

if __name__ == '__main__':
    main()

