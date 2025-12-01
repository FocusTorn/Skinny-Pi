# PowerShell Support for prompt-wizard

The `prompt-wizard` Go executable can now be used from both **bash scripts** and **PowerShell scripts**.

## Quick Start

### 1. Source the PowerShell Functions

```powershell
# Source the helper functions
. .\wizard.ps1
```

### 2. Use the Wizard Functions

```powershell
# Simple input
$json = '[{"type":"input","title":"What is your name?","key":"name"}]'
$result = iwizard-RunInline -JsonString $json
$parsed = $result | ConvertFrom-Json
Write-Host "Hello, $($parsed.name)"
```

## Functions

### `iwizard-RunInline`

Run wizard with an inline JSON string.

**Usage:**
```powershell
iwizard-RunInline -JsonString '<json-string>' [-ResultFile 'path/to/result.json']
```

**Example:**
```powershell
$json = @'
[
  {
    "type": "select",
    "title": "Choose a color",
    "key": "color",
    "options": ["Red", "Blue", "Green"]
  }
]
'@

$result = iwizard-RunInline -JsonString $json
$parsed = $result | ConvertFrom-Json
Write-Host "You chose: $($parsed.color)"
```

### `iwizard-RunJson`

Run wizard with JSON input (auto-detects file path vs JSON string).

**Usage:**
```powershell
iwizard-RunJson -JsonInput '<json-string>' [-ResultFile 'path/to/result.json']
iwizard-RunJson -JsonInput '/path/to/file.json' [-ResultFile 'path/to/result.json']
```

**Example:**
```powershell
# From JSON string
$result = iwizard-RunJson -JsonInput '[{"type":"input","title":"Name","key":"name"}]'

# From file
$result = iwizard-RunJson -JsonInput ".\wizard-example.json"
```

## JSON Format

The JSON format is the same as for bash scripts:

```json
[
  {
    "type": "input",
    "title": "What is your name?",
    "description": "Enter your full name",
    "key": "name",
    "placeholder": "John Doe",
    "default": "Anonymous"
  },
  {
    "type": "select",
    "title": "Choose a color",
    "description": "Select one option",
    "key": "color",
    "options": ["Red", "Blue", "Green"]
  },
  {
    "type": "multiselect",
    "title": "Select hobbies",
    "description": "You can select multiple",
    "key": "hobbies",
    "options": ["Reading", "Gaming", "Sports"]
  },
  {
    "type": "confirm",
    "title": "Continue?",
    "description": "Final confirmation",
    "key": "continue"
  }
]
```

## Step Types

- **`input`**: Text input field
- **`select`**: Single selection from options
- **`multiselect`**: Multiple selections from options
- **`confirm`**: Yes/No confirmation

## Result Format

The wizard returns JSON with the results keyed by the `key` field from each step:

```json
{
  "name": "John Doe",
  "color": "Blue",
  "hobbies": ["Reading", "Gaming"],
  "continue": true
}
```

## Examples

### Example 1: Simple Input

```powershell
. .\wizard.ps1

$json = '[{"type":"input","title":"What is your name?","key":"name"}]'
$result = iwizard-RunInline -JsonString $json
$parsed = $result | ConvertFrom-Json
Write-Host "Hello, $($parsed.name)!"
```

### Example 2: Multi-Step Wizard

```powershell
. .\wizard.ps1

$json = @'
[
  {"type":"input","title":"Name","key":"name"},
  {"type":"select","title":"Color","key":"color","options":["Red","Blue"]},
  {"type":"confirm","title":"Continue?","key":"continue"}
]
'@

$result = iwizard-RunInline -JsonString $json
$parsed = $result | ConvertFrom-Json

if ($parsed.continue) {
    Write-Host "$($parsed.name) chose $($parsed.color)"
}
```

### Example 3: Save Results to File

```powershell
. .\wizard.ps1

$json = '[{"type":"input","title":"Repository name","key":"repo"}]'
$result = iwizard-RunInline -JsonString $json -ResultFile ".\result.json"

# Results are saved to result.json
$parsed = Get-Content ".\result.json" | ConvertFrom-Json
Write-Host "Repository: $($parsed.repo)"
```

## Auto-Build

The functions automatically build the `prompt-wizard` executable if it doesn't exist:

- On **Windows**: Builds `prompt-wizard.exe`
- On **Linux/Mac**: Builds `prompt-wizard`

The executable is built in the same directory as the PowerShell functions script.

## Comparison: Bash vs PowerShell

| Feature | Bash | PowerShell |
|---------|------|------------|
| Source functions | `source wizard.sh` | `. .\wizard.ps1` |
| Run inline | `iwizard_run_inline '<json>'` | `iwizard-RunInline -JsonString '<json>'` |
| Run from file | `iwizard_run_json '/path/to/file.json'` | `iwizard-RunJson -JsonInput '/path/to/file.json'` |
| Result file | `iwizard_run_inline '<json>' result.json` | `iwizard-RunInline -JsonString '<json>' -ResultFile 'result.json'` |
| Parse result | `echo "$result" \| jq` | `$result \| ConvertFrom-Json` |

## Demo Script

Run the demo script to see examples:

```powershell
.\demo-powershell.ps1
```

## Notes

- The Go executable is built automatically on first use if it doesn't exist
- The executable name is auto-detected (`prompt-wizard.exe` on Windows, `prompt-wizard` on Linux/Mac)
- Results are returned as JSON strings that can be parsed with `ConvertFrom-Json`
- The wizard runs interactively in the terminal (TUI interface)

