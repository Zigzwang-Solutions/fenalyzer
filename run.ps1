# run.ps1 - Securely validates FEN and handles web data injection
param (
    [Parameter(Position=0, Mandatory=$true)]
    [string]$FenInput,
    
    [switch]$Web
)

$ErrorActionPreference = "Stop"
$BinaryName = ".\fen_parser.exe"
$WebIndex = "web\index.html"
$DataFile = "web\data.js"

# 1. Check binary existence
if (-not (Test-Path $BinaryName)) {
    Write-Host "[ERROR] Binary not found!" -ForegroundColor Red
    Write-Host "Please run '.\build.ps1' first." -ForegroundColor Yellow
    exit 1
}

try {
    # 2. Execute Zig Logic
    $output = & $BinaryName $FenInput
    
    try { 
        $jsonObj = $output | ConvertFrom-Json
        $jsonObj | ConvertTo-Json -Depth 5
    } catch { 
        Write-Host $output 
    }

    # 3. Secure Web Integration
    if ($Web) {
        if (-not (Test-Path $WebIndex)) { throw "File web/index.html not found." }

        # SECURITY FIX: Encode to Base64 to prevent Code Injection/XSS
        # This neutralizes quotes, slashes, and scripts inside the FEN string.
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($FenInput)
        $base64Fen = [System.Convert]::ToBase64String($bytes)

        # Inject the safe Base64 string
        $jsContent = @"
window.FEN_DATA_B64 = "$base64Fen";
"@
        Set-Content -Path $DataFile -Value $jsContent -Encoding UTF8
        Write-Host "Secure local data written to $DataFile" -ForegroundColor DarkGray

        # Open Browser
        $absPath = (Resolve-Path $WebIndex).Path
        $fileUri = [System.Uri]$absPath
        $finalUrl = $fileUri.AbsoluteUri 
        
        Write-Host "Opening web viewer..." -ForegroundColor Cyan
        Start-Process $finalUrl
    }
}
catch {
    Write-Host "[ERROR] Execution failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}