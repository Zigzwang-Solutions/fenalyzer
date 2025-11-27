# build.ps1 - Compiles the project (Windows)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ZigSource = "fen_parser.zig"
$BinaryName = "fen_parser.exe"
$CacheDir = ".\zig-cache"

Write-Host "[BUILD] Starting Zig compilation (ReleaseSafe)..." -ForegroundColor Cyan

# Check for Zig compiler
if (-not (Get-Command "zig" -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Zig compiler not found in PATH." -ForegroundColor Red
    exit 1
}

try {
    # Execute compilation
    $process = Start-Process -FilePath "zig" -ArgumentList "build-exe", "$ZigSource", "-O", "ReleaseSafe", "-femit-bin=$BinaryName", "--cache-dir", "$CacheDir" -Wait -NoNewWindow -PassThru
    
    if ($process.ExitCode -ne 0) { 
        throw "Zig compiler returned error code $($process.ExitCode)" 
    }
    
    Write-Host "[SUCCESS] Compilation finished successfully: $BinaryName" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Compilation failed." -ForegroundColor Red
    exit 1
}