# Demo script showing how to use prompt-wizard from PowerShell
# Usage: .\demo-powershell.ps1

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$IMenuDir = Split-Path -Parent $ScriptDir
$WizardFunctions = Join-Path $IMenuDir "wizard.ps1"

# Source the wizard functions
if (Test-Path $WizardFunctions) {
    . $WizardFunctions
} else {
    Write-Error "❌ wizard.ps1 not found at $WizardFunctions"
    exit 1
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  Interactive Wizard Demo using PowerShell" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Example 1: Simple input
Write-Host "📝 Example 1: Text Input" -ForegroundColor Yellow
$resultFile = [System.IO.Path]::GetTempFileName()
$json = '[{"type":"input","title":"What is your name?","description":"Enter your full name","key":"name","placeholder":"John Doe"}]'
$result = iwizard-RunInline -JsonString $json -ResultFile $resultFile
if ($result) {
    $parsed = $result | ConvertFrom-Json
    Write-Host "✅ You entered: $($parsed.name)" -ForegroundColor Green
}
Remove-Item $resultFile -ErrorAction SilentlyContinue
Write-Host ""

# Example 2: Select from options
Write-Host "📝 Example 2: Select from Options" -ForegroundColor Yellow
$resultFile = [System.IO.Path]::GetTempFileName()
$json = '[{"type":"select","title":"Choose your favorite color","description":"Select one option","key":"color","options":["Red","Blue","Green","Yellow","Purple"]}]'
$result = iwizard-RunInline -JsonString $json -ResultFile $resultFile
if ($result) {
    $parsed = $result | ConvertFrom-Json
    Write-Host "✅ You chose: $($parsed.color)" -ForegroundColor Green
}
Remove-Item $resultFile -ErrorAction SilentlyContinue
Write-Host ""

# Example 3: Multi-select
Write-Host "📝 Example 3: Multi-Select" -ForegroundColor Yellow
$resultFile = [System.IO.Path]::GetTempFileName()
$json = '[{"type":"multiselect","title":"Select your hobbies","description":"You can select multiple options","key":"hobbies","options":["Reading","Gaming","Sports","Music","Travel"]}]'
$result = iwizard-RunInline -JsonString $json -ResultFile $resultFile
if ($result) {
    $parsed = $result | ConvertFrom-Json
    Write-Host "✅ You selected:" -ForegroundColor Green
    $parsed.hobbies | ForEach-Object { Write-Host "   - $_" -ForegroundColor Gray }
}
Remove-Item $resultFile -ErrorAction SilentlyContinue
Write-Host ""

# Example 4: Confirmation
Write-Host "📝 Example 4: Confirmation" -ForegroundColor Yellow
$resultFile = [System.IO.Path]::GetTempFileName()
$json = '[{"type":"confirm","title":"Do you want to continue?","description":"Final confirmation","key":"continue"}]'
$result = iwizard-RunInline -JsonString $json -ResultFile $resultFile
if ($result) {
    $parsed = $result | ConvertFrom-Json
    if ($parsed.continue) {
        Write-Host "✅ You confirmed: Yes" -ForegroundColor Green
    } else {
        Write-Host "❌ You confirmed: No" -ForegroundColor Red
    }
}
Remove-Item $resultFile -ErrorAction SilentlyContinue
Write-Host ""

# Example 5: Wizard with multiple steps
Write-Host "📝 Example 5: Multi-Step Wizard" -ForegroundColor Yellow
$resultFile = [System.IO.Path]::GetTempFileName()
$json = @'
[
  {
    "type": "input",
    "title": "What is your name?",
    "description": "Enter your full name",
    "key": "name",
    "placeholder": "John Doe"
  },
  {
    "type": "select",
    "title": "Choose your favorite color",
    "description": "Select one option",
    "key": "color",
    "options": ["Red", "Blue", "Green", "Yellow", "Purple"]
  },
  {
    "type": "multiselect",
    "title": "Select your hobbies",
    "description": "You can select multiple options",
    "key": "hobbies",
    "options": ["Reading", "Gaming", "Sports", "Music", "Travel"]
  },
  {
    "type": "confirm",
    "title": "Do you want to continue?",
    "description": "Final confirmation",
    "key": "continue"
  }
]
'@
$result = iwizard-RunInline -JsonString $json -ResultFile $resultFile
if ($result) {
    $parsed = $result | ConvertFrom-Json
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "✅ Wizard Results:" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "Name: $($parsed.name)" -ForegroundColor Yellow
    Write-Host "Color: $($parsed.color)" -ForegroundColor Yellow
    Write-Host "Hobbies: $($parsed.hobbies -join ', ')" -ForegroundColor Yellow
    Write-Host "Continue: $($parsed.continue)" -ForegroundColor Yellow
}
Remove-Item $resultFile -ErrorAction SilentlyContinue
Write-Host ""

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "✅ Demo complete!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

