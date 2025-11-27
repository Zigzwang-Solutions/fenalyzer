# tests/tests.ps1 - Automated Integration Testing Suite
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue" # Continue running even if a test fails

# PATH FIX: Point to the binary in the parent (root) directory
$Binary = "..\fen_parser.exe"

if (-not (Test-Path $Binary)) {
    Write-Error "Binary not found at $Binary. Please run '.\build.ps1' in the root directory first."
    exit 1
}

Write-Host "`n=== STARTING INTEGRATION TESTS ===`n" -ForegroundColor Cyan

# Test Cases: [FEN String] = [Expected Valid (bool)]
$TestCases = @{
    # Valid Cases
    "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1" = $true
    "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1" = $true
    "8/8/8/8/8/8/8/4K2k w - - 0 1" = $true
    
    # Invalid Cases
    "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR" = $false # Missing fields
    "pppppppp/8/8/8/8/8/8/8 w - - 0 1" = $false # Pawns on backrank
    "8/8/8/8/8/8/8/8 w - - 0 1" = $false # Missing Kings
    "rnbqkbnr/pppppppp/9/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1" = $false # Invalid geometry
}

$Passed = 0
$Total = 0

foreach ($Fen in $TestCases.Keys) {
    $Expected = $TestCases[$Fen]
    $Total++
    
    Write-Host "Test #$Total..." -NoNewline
    
    # Run binary and capture output
    $Output = & $Binary $Fen | ConvertFrom-Json
    
    # Assert
    if ($Output.valid -eq $Expected) {
        Write-Host " [PASS]" -ForegroundColor Green
        $Passed++
    } else {
        Write-Host " [FAIL]" -ForegroundColor Red
        Write-Host "   Input: $Fen"
        Write-Host "   Expected: $Expected"
        Write-Host "   Got: $($Output.valid)"
        Write-Host "   Error: $($Output.error)"
    }
}

Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
if ($Passed -eq $Total) {
    Write-Host "All $Total tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "$($Total - $Passed) tests failed." -ForegroundColor Red
    exit 1
}