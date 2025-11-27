# scripts/run.ps1 - Orchestrates execution, data persistence, and visualization
param (
    [Parameter(Position=0, Mandatory=$true)]
    [string]$FenInput,
    
    [switch]$Web
)

$ErrorActionPreference = "Stop"

# --- Path Configuration (Relative to project root) ---
$Root = ".."
$Binary = "$Root\fen_parser.exe"
$WebIndex = "$Root\web\index.html"
$DataFile = "$Root\web\data.js"
$DbTool = "$Root\tools\manage_db.py"

# --- 1. Validation ---
if (-not (Test-Path $Binary)) {
    Write-Host "[ERROR] Binary not found at $Binary" -ForegroundColor Red
    Write-Host "Please run '.\scripts\build.ps1' first." -ForegroundColor Yellow
    exit 1
}

# Check for Python (Optional, for persistence)
$SkipDb = $false
if (-not (Get-Command "python" -ErrorAction SilentlyContinue)) {
    Write-Host "[WARN] Python not found. Database persistence will be skipped." -ForegroundColor Yellow
    $SkipDb = $true
}

try {
    # --- 2. Hash Calculation (Zobrist-like SHA256) ---
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($FenInput)
    $hashBytes = $sha.ComputeHash($bytes)
    $fullHash = -join ($hashBytes | ForEach-Object { $_.ToString("x2") })
    $hashId = $fullHash.Substring(0, 16)

    Write-Host "FEN Hash ID: $hashId" -ForegroundColor DarkGray

    # --- 3. Persistence Layer (Python Bridge) ---
    if (-not $SkipDb) {
        # Call Python to save to SQLite
        python $DbTool "save" $hashId $FenInput
    }

    # --- 4. Core Validation (Zig) ---
    $output = & $Binary $FenInput
    try { 
        $jsonObj = $output | ConvertFrom-Json
        $jsonObj | ConvertTo-Json -Depth 5 
    } catch { 
        Write-Host $output 
    }

    # --- 5. Web Integration ---
    if ($Web) {
        if (-not (Test-Path $WebIndex)) { throw "File web/index.html not found." }

        # Security: Base64 Injection to prevent XSS
        $base64Fen = [System.Convert]::ToBase64String($bytes)
        
        # Inject Data (Browser reads this)
        $jsContent = @"
window.FEN_DATA_B64 = "$base64Fen";
window.FEN_HASH = "$hashId";
"@
        Set-Content -Path $DataFile -Value $jsContent -Encoding UTF8
        Write-Host "Secure data injected into $DataFile" -ForegroundColor DarkGray
        
        # Open Browser
        $absPath = (Resolve-Path $WebIndex).Path
        $fileUri = [System.Uri]$absPath
        
        # Pass ID in URL hash for bookmarking/reference
        $finalUrl = $fileUri.AbsoluteUri + "#id=" + $hashId
        
        Write-Host "Opening web viewer..." -ForegroundColor Cyan
        Start-Process $finalUrl
    }
}
catch {
    Write-Host "[ERROR] Execution failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}