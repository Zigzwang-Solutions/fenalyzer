# Requires PowerShell 5.0+
# Set Strict Mode to catch errors early
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Configuration
$ZigSource = "fen_parser.zig"
$BinaryName = "fen_parser.exe"
$CacheDir = ".\zig-cache"
$WebIndex = "web\index.html"

# Logging Helpers
function Write-LogInfo { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-LogError { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }
function Write-LogSuccess { param($msg) Write-Host "[SUCCESS] $msg" -ForegroundColor Green }

function Show-Usage {
    Write-Host "Usage: .\run.ps1 [options] `"<fen_string>`""
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Rebuild    Force recompilation of the Zig binary"
    Write-Host "  -Web        Open the FEN in the web viewer"
    Write-Host "  -Help       Show this help message"
    Write-Host ""
    Write-Host "Example:"
    Write-Host "  .\run.ps1 -Web `"rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1`""
}

# Parameters
param (
    [string]$FenInput,
    [switch]$Rebuild,
    [switch]$Web,
    [switch]$Help
)

if ($Help) { Show-Usage; exit 0 }

# Dependency Check
if (-not (Get-Command "zig" -ErrorAction SilentlyContinue)) {
    Write-LogError "Zig compiler not found in PATH."
    exit 1
}

# Compilation Logic
if ($Rebuild -or -not (Test-Path $BinaryName)) {
    Write-LogInfo "Compiling $ZigSource (ReleaseSafe)..."
    try {
        # Redirect stderr to catch build errors
        $process = Start-Process -FilePath "zig" -ArgumentList "build-exe", "$ZigSource", "-O", "ReleaseSafe", "-femit-bin=$BinaryName", "--cache-dir", "$CacheDir" -Wait -NoNewWindow -PassThru
        
        if ($process.ExitCode -ne 0) {
            throw "Zig compilation exited with code $($process.ExitCode)"
        }
        Write-LogSuccess "Compilation finished successfully."
    }
    catch {
        Write-LogError "Compilation failed."
        exit 1
    }
}

# Execution Logic
if ([string]::IsNullOrWhiteSpace($FenInput)) {
    Write-LogError "No FEN string provided."
    Show-Usage; exit 1
}

Write-LogInfo "Analyzing FEN..."

try {
    # Execute binary
    $output = & ".\$BinaryName" $FenInput
    
    # Try Pretty Print JSON
    try {
        $jsonObj = $output | ConvertFrom-Json
        $jsonObj | ConvertTo-Json -Depth 5
    }
    catch {
        Write-Host $output
    }

    # Web Viewer Integration
    if ($Web) {
        # Load .NET assembly for safe URL encoding
        Add-Type -AssemblyName System.Web
        $encodedFen = [System.Web.HttpUtility]::UrlEncode($FenInput)
        
        $absPath = (Resolve-Path $WebIndex).Path
        $url = "file://$absPath?fen=$encodedFen"
        
        Write-LogInfo "Opening web viewer..."
        Start-Process $url
    }
}
catch {
    Write-LogError "Execution failed or binary returned an error code."
    exit $LASTEXITCODE
}