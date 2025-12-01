#!/usr/bin/env python3
"""
Sharables Git Helper - Cross-platform
Git operations for sharables from deployed locations
Works on both Windows and Linux/Debian
"""

import os
import sys
import subprocess
from pathlib import Path
from typing import Optional, List, Dict
import argparse

# Colors for terminal output
class Colors:
    GREEN = '\033[0;32m'
    BLUE = '\033[0;34m'
    YELLOW = '\033[1;33m'
    RED = '\033[0;31m'
    NC = '\033[0m'
    
    @staticmethod
    def disable():
        if sys.platform == 'win32':
            try:
                import ctypes
                kernel32 = ctypes.windll.kernel32
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

def run_git_command(sharables_dir: Path, *args, check=True) -> subprocess.CompletedProcess:
    """Run git command in sharables directory"""
    try:
        result = subprocess.run(
            ['git'] + list(args),
            cwd=str(sharables_dir),
            capture_output=True,
            text=True,
            check=check
        )
        return result
    except subprocess.CalledProcessError as e:
        print(f"{Colors.RED}Git error: {e}{Colors.NC}")
        if e.stderr:
            print(e.stderr)
        raise
    except FileNotFoundError:
        print(f"{Colors.RED}Git not found. Please install Git.{Colors.NC}")
        sys.exit(1)

def show_status(sharables_dir: Path):
    """Show git status and deployed locations"""
    print(f"{Colors.BLUE}=== Sharables Git Status ==={Colors.NC}\n")
    
    print(f"{Colors.GREEN}Repository:{Colors.NC} {sharables_dir}")
    
    try:
        remote = run_git_command(sharables_dir, 'remote', 'get-url', 'origin', check=False)
        if remote.returncode == 0:
            print(f"{Colors.GREEN}Remote:{Colors.NC} {remote.stdout.strip()}")
        else:
            print(f"{Colors.GREEN}Remote:{Colors.NC} not set")
    except:
        print(f"{Colors.GREEN}Remote:{Colors.NC} not set")
    
    try:
        branch = run_git_command(sharables_dir, 'branch', '--show-current', check=False)
        if branch.returncode == 0:
            print(f"{Colors.GREEN}Branch:{Colors.NC} {branch.stdout.strip()}")
    except:
        pass
    
    print()
    
    # Show sparse checkout
    try:
        sparse = run_git_command(sharables_dir, 'sparse-checkout', 'list', check=False)
        if sparse.returncode == 0 and sparse.stdout.strip():
            print(f"{Colors.BLUE}Checked out sections:{Colors.NC}")
            for line in sparse.stdout.strip().split('\n'):
                if line.strip():
                    print(f"  {line.strip()}")
        print()
    except:
        pass
    
    # Show changes
    status = run_git_command(sharables_dir, 'status', '--short', check=False)
    print(f"{Colors.BLUE}Changes:{Colors.NC}")
    if status.stdout.strip():
        print(status.stdout)
    else:
        print("  No changes")
    print()

def commit_changes(sharables_dir: Path, message: str, section: Optional[str] = None):
    """Commit changes"""
    # Check for changes
    status = run_git_command(sharables_dir, 'status', '--porcelain', check=False)
    if not status.stdout.strip():
        print(f"{Colors.YELLOW}No changes to commit{Colors.NC}")
        return
    
    print(f"{Colors.BLUE}Staging changes...{Colors.NC}")
    if section:
        run_git_command(sharables_dir, 'add', f'{section}/')
        print(f"{Colors.GREEN}Staged: {section}/{Colors.NC}")
    else:
        run_git_command(sharables_dir, 'add', '.')
    
    print(f"{Colors.BLUE}Committing...{Colors.NC}")
    run_git_command(sharables_dir, 'commit', '-m', message)
    print(f"{Colors.GREEN}✓ Committed{Colors.NC}")

def push_changes(sharables_dir: Path, branch: Optional[str] = None):
    """Push changes to remote"""
    if branch is None:
        branch_result = run_git_command(sharables_dir, 'branch', '--show-current', check=False)
        if branch_result.returncode != 0:
            print(f"{Colors.RED}Could not determine current branch{Colors.NC}")
            return
        branch = branch_result.stdout.strip()
    
    # Check if there are commits to push
    try:
        result = run_git_command(sharables_dir, 'log', f'origin/{branch}..HEAD', '--oneline', check=False)
        if not result.stdout.strip():
            print(f"{Colors.YELLOW}No commits to push{Colors.NC}")
            return
    except:
        # Branch might not exist on remote yet
        pass
    
    print(f"{Colors.BLUE}Pushing to origin/{branch}...{Colors.NC}")
    run_git_command(sharables_dir, 'push', 'origin', branch)
    print(f"{Colors.GREEN}✓ Pushed{Colors.NC}")

def main():
    parser = argparse.ArgumentParser(description='Git operations for sharables')
    parser.add_argument('action', choices=['status', 'commit', 'push', 'sync'],
                       help='Action to perform')
    parser.add_argument('--sharables-dir', type=str, default=None,
                       help='Path to sharables directory (auto-detected if not specified)')
    parser.add_argument('--message', type=str, default=None,
                       help='Commit message (for commit/sync)')
    parser.add_argument('--section', type=str, default=None,
                       help='Specific section to commit')
    parser.add_argument('--branch', type=str, default=None,
                       help='Branch name (for push)')
    
    args = parser.parse_args()
    
    # Find sharables directory
    if args.sharables_dir:
        sharables_dir = Path(args.sharables_dir).resolve()
    else:
        sharables_dir = find_sharables_dir()
    
    if not sharables_dir or not sharables_dir.exists():
        print(f"{Colors.RED}Sharables directory not found{Colors.NC}")
        print("Set SHARABLES_DIR environment variable or run from a project with sharables")
        sys.exit(1)
    
    if not (sharables_dir / '.git').exists():
        print(f"{Colors.RED}Not a git repository: {sharables_dir}{Colors.NC}")
        sys.exit(1)
    
    # Execute action
    if args.action == 'status':
        show_status(sharables_dir)
    
    elif args.action == 'commit':
        if not args.message:
            print(f"{Colors.RED}Commit message required{Colors.NC}")
            print("Use --message 'Your message'")
            sys.exit(1)
        commit_changes(sharables_dir, args.message, args.section)
    
    elif args.action == 'push':
        push_changes(sharables_dir, args.branch)
    
    elif args.action == 'sync':
        if not args.message:
            print(f"{Colors.RED}Commit message required for sync{Colors.NC}")
            print("Use --message 'Your message'")
            sys.exit(1)
        commit_changes(sharables_dir, args.message, args.section)
        push_changes(sharables_dir, args.branch)

if __name__ == '__main__':
    main()

