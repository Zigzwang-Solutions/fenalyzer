# run.ps1 - Executes the parser, generates local data, and opens the viewer
param (
    [Parameter(Position=0, Mandatory=$true)]
    [string]$FenInput,
    
    [switch]$Web
)

$ErrorActionPreference = "Stop"
$BinaryName = ".\fen_parser.exe"
$WebIndex = "web\index.html"
$DataFile = "web\data.js"

# 1. Check if binary exists
if (-not (Test-Path $BinaryName)) {
    Write-Host "[ERROR] Binary not found!" -ForegroundColor Red
    Write-Host "Please run '.\build.ps1' first to create the executable." -ForegroundColor Yellow
    exit 1
}

try {
    # 2. Execute validation (Zig)
    $output = & $BinaryName $FenInput
    
    # Try pretty-printing JSON output
    try { 
        $jsonObj = $output | ConvertFrom-Json
        $jsonObj | ConvertTo-Json -Depth 5
    } catch { 
        Write-Host $output 
    }

    # 3. Web Integration (Data File Strategy)
    if ($Web) {
        if (-not (Test-Path $WebIndex)) { throw "File web/index.html not found." }

        # Generate 'data.js' with the FEN as a global variable
        # We use a Here-String to inject the content cleanly
        $jsContent = @"
window.FEN_DATA = "$FenInput";
"@
        Set-Content -Path $DataFile -Value $jsContent -Encoding UTF8
        Write-Host "Local data written to $DataFile" -ForegroundColor DarkGray

        # Open the browser
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