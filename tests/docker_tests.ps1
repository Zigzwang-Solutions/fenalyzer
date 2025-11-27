# tests/docker_tests.ps1 - Automated Docker Container Testing Suite
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# Configuration
$ImageName = "fenalyzer:test"

Write-Host "`n=== STARTING DOCKER TESTS ===`n" -ForegroundColor Cyan

# 1. Prerequisite Check
if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
    Write-Error "Docker is not installed or not in PATH."
    exit 1
}

# 2. Build Test
# PATH FIX: Build context is '..' (parent directory) to find the Dockerfile in root
Write-Host "Test #1: Building Image from parent context..." -NoNewline
docker build -t $ImageName .. > $null 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host " [PASS]" -ForegroundColor Green
} else {
    Write-Host " [FAIL]" -ForegroundColor Red
    Write-Error "Docker build failed."
    exit 1
}

# 3. Security Test (Non-root User)
Write-Host "Test #2: Checking Non-root User..." -NoNewline
$UserOutput = docker run --rm --entrypoint whoami $ImageName
if ($UserOutput.Trim() -eq "appuser") {
    Write-Host " [PASS]" -ForegroundColor Green
} else {
    Write-Host " [FAIL]" -ForegroundColor Red
    Write-Host "   Expected: appuser"
    Write-Host "   Got: $UserOutput"
    Write-Host "   (Security Risk: Container might be running as root)"
}

# 4. Logic Integration Test
Write-Host "Test #3: Verifying FEN Parsing Logic..." -NoNewline
$TestFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
$JsonOutput = docker run --rm $ImageName $TestFen | ConvertFrom-Json

if ($JsonOutput.valid -eq $true -and $JsonOutput.active_color -eq "white") {
    Write-Host " [PASS]" -ForegroundColor Green
} else {
    Write-Host " [FAIL]" -ForegroundColor Red
    Write-Host "   Container returned invalid data."
}

# 5. Cleanup
Write-Host "Cleaning up test image..." -ForegroundColor DarkGray
docker rmi $ImageName > $null 2>&1

Write-Host "`n=== DOCKER SUITE COMPLETE ===`n" -ForegroundColor Cyan