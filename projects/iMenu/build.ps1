# Build script for iMenu - Creates distribution package
# Detects shell and OS, cleans dist/, and rebuilds everything

$ErrorActionPreference = "Stop"

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# Detect OS
function Detect-OS {
    $os = if ($IsWindows -or $env:OS -eq "Windows_NT") {
        "windows"
    } elseif ($IsMacOS) {
        "darwin"
    } elseif ($IsLinux) {
        "linux"
    } else {
        # Fallback detection
        $uname = if (Get-Command uname -ErrorAction SilentlyContinue) {
            (uname -s).ToLower()
        } else {
            "unknown"
        }
        if ($uname -like "*linux*") {
            "linux"
        } elseif ($uname -like "*darwin*") {
            "darwin"
        } else {
            "unknown"
        }
    }
    return $os
}

# Detect architecture
function Detect-Arch {
    $arch = if ($IsWindows) {
        if ([Environment]::Is64BitOperatingSystem) {
            "amd64"
        } else {
            "386"
        }
    } elseif ($IsMacOS -or $IsLinux) {
        $unameM = if (Get-Command uname -ErrorAction SilentlyContinue) {
            uname -m
        } else {
            "unknown"
        }
        switch ($unameM) {
            { $_ -in "x86_64", "amd64" } { "amd64" }
            { $_ -in "arm64", "aarch64" } { "arm64" }
            { $_ -like "arm*" } { "arm" }
            default { $unameM }
        }
    } else {
        "unknown"
    }
    return $arch
}

$OS = Detect-OS
$ARCH = Detect-Arch

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🔨 Building iMenu Distribution Package" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Detected:" -ForegroundColor Yellow
Write-Host "   OS: $OS" -ForegroundColor Gray
Write-Host "   Architecture: $ARCH" -ForegroundColor Gray
Write-Host "   Shell: PowerShell" -ForegroundColor Gray
Write-Host ""

# Check if Go is installed
if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
    Write-Error "❌ Go is not installed. Please install Go first."
    Write-Host "   Visit: https://go.dev/dl/" -ForegroundColor Yellow
    exit 1
}

$goVersion = go version
Write-Host "✅ Go found: $goVersion" -ForegroundColor Green
Write-Host ""

# Clean dist directory
Write-Host "🧹 Cleaning dist directory..." -ForegroundColor Yellow
if (Test-Path "dist") {
    Remove-Item -Path "dist" -Recurse -Force
}
Write-Host "✅ Cleaned" -ForegroundColor Green
Write-Host ""

# Recreate dist structure
Write-Host "📁 Creating distribution structure..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path "dist\bin" -Force | Out-Null
New-Item -ItemType Directory -Path "dist\lib" -Force | Out-Null
New-Item -ItemType Directory -Path "dist\docs" -Force | Out-Null
Write-Host "✅ Structure created" -ForegroundColor Green
Write-Host ""

# Update Go dependencies
Write-Host "📦 Updating Go dependencies..." -ForegroundColor Yellow
go mod tidy
Write-Host "✅ Dependencies updated" -ForegroundColor Green
Write-Host ""

# Build executables
Write-Host "🔨 Building executables..." -ForegroundColor Yellow
Write-Host ""

# Build prompt-wizard
Write-Host "   Building prompt-wizard..." -ForegroundColor Gray
$exeName = if ($OS -eq "windows") { "prompt-wizard.exe" } else { "prompt-wizard" }
$exePath = Join-Path "dist\bin" $exeName

go build -o $exePath .\src\prompt-wizard.go
if (Test-Path $exePath) {
    Write-Host "   ✅ Built: $exePath" -ForegroundColor Green
} else {
    Write-Error "   ❌ Failed to build prompt-wizard"
    exit 1
}

# Build prompt-huh (optional)
if (Test-Path "src\prompt-huh.go") {
    Write-Host "   Building prompt-huh..." -ForegroundColor Gray
    $huhExeName = if ($OS -eq "windows") { "prompt-huh.exe" } else { "prompt-huh" }
    $huhExePath = Join-Path "dist\bin" $huhExeName
    try {
        go build -o $huhExePath .\src\prompt-huh.go 2>$null
        if (Test-Path $huhExePath) {
            Write-Host "   ✅ Built: $huhExePath" -ForegroundColor Green
        }
    } catch {
        Write-Host "   ⚠️  prompt-huh build skipped (optional)" -ForegroundColor Yellow
    }
}

Write-Host ""

# Copy wrapper scripts to dist/lib
Write-Host "📋 Copying wrapper scripts..." -ForegroundColor Yellow
Copy-Item "wizard.sh" "dist\lib\" -Force
Copy-Item "wizard.ps1" "dist\lib\" -Force
Write-Host "✅ Wrapper scripts copied" -ForegroundColor Green
Write-Host ""

# Copy documentation to dist/docs
Write-Host "📚 Copying documentation..." -ForegroundColor Yellow
if (Test-Path "docs") {
    Copy-Item "docs\*.md" "dist\docs\" -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Documentation copied" -ForegroundColor Green
} else {
    Write-Host "⚠️  No docs directory found" -ForegroundColor Yellow
}
Write-Host ""

# Note about dist README
if (Test-Path "dist\README.md") {
    Write-Host "✅ Distribution README exists" -ForegroundColor Green
} else {
    Write-Host "📝 Note: dist/README.md should exist for distribution package" -ForegroundColor Yellow
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "✅ Build complete!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "📦 Distribution package created in: dist\" -ForegroundColor Yellow
Write-Host ""
Write-Host "📁 Structure:" -ForegroundColor Cyan
Write-Host "   dist\" -ForegroundColor Gray
Write-Host "   ├── bin\          # Executables" -ForegroundColor Gray
Write-Host "   ├── lib\          # Wrapper scripts" -ForegroundColor Gray
Write-Host "   ├── docs\         # Documentation" -ForegroundColor Gray
Write-Host "   └── README.md     # Package README" -ForegroundColor Gray
Write-Host ""
Write-Host "💡 Usage:" -ForegroundColor Cyan
Write-Host "   cd dist" -ForegroundColor Gray
Write-Host "   . .\lib\wizard.ps1" -ForegroundColor Gray
Write-Host ""

