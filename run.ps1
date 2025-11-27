# Requires PowerShell 5.0+
# Set Strict Mode to catch errors early

param (
    [Parameter(Position=0)]
    [string]$FenInput,
    [switch]$Rebuild,
    [switch]$Web,
    [switch]$Help
)

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
function Write-LogUrl { param($url) Write-Host $url -ForegroundColor Blue -BackgroundColor White }

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
        if (-not (Test-Path $WebIndex)) {
            throw "Web viewer file not found at: $WebIndex"
        }

        # 1. Obter caminho absoluto e converter para URI
        $absPath = (Resolve-Path $WebIndex).Path
        $fileUri = [System.Uri]$absPath
        
        # 2. Codificar a FEN
        $encodedFen = [System.Uri]::EscapeDataString($FenInput)
        
        # 3. Montar URL Final
        $finalUrl = $fileUri.AbsoluteUri + "?fen=" + $encodedFen
        
        Write-LogInfo "Opening web viewer..."
        Write-Host "Se o navegador nao carregar o tabuleiro, copie e cole este link:" -ForegroundColor Yellow
        Write-LogUrl $finalUrl
        
        # 4. Tentar abrir usando CMD /C START (Mais robusto para URLs locais com parametros)
        # O argumento vazio "" é necessário para o titulo da janela do comando start
        Start-Process "cmd.exe" -ArgumentList "/c start `"`" `"$finalUrl`"" -WindowStyle Hidden
    }
}
catch {
    Write-LogError "Execution failed."
    Write-LogError "Details: $($_.Exception.Message)"
    exit 1
}