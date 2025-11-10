# build_test.ps1
# Windows-friendly build and test script for MathScript compiler
# Usage: Run from repository root in PowerShell: .\build_test.ps1

param([string]$Example)

$ErrorActionPreference = "Stop"
$root = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
Set-Location $root

$cc = "gcc"
Write-Host "Building mathsc with $cc..."
& $cc -g -Wall -Wno-unused-function -Isrc -o mathsc src/ast.c src/codegen.c src/main.c src/semantic.c y.tab.c lex.yy.c -lm
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed (exit $LASTEXITCODE)"
    exit $LASTEXITCODE
}

# Ensure output directory exists
New-Item -ItemType Directory -Path output -Force | Out-Null
# Remove old generic plot if present to avoid confusion
Remove-Item -Path .\output\plot.png -ErrorAction SilentlyContinue -Force

# Clean legacy/unknown files from output/ to avoid confusion. Keep only
# files that match the new naming scheme: *.py, *.py.out, and *_plot.png
Write-Host "Cleaning legacy files from output/..."
Get-ChildItem -Path .\output -File -ErrorAction SilentlyContinue | Where-Object { 
    -not ($_.Name -match '\.py$' -or $_.Name -match '\.py\.out$' -or $_.Name -match '_plot\.png$')
} | ForEach-Object { Write-Host " Removing $($_.Name)"; Remove-Item -Force $_.FullName -ErrorAction SilentlyContinue }

# Determine which examples to run. If an example name was provided, try to run just that one.
if ($Example) {
    # Accept either 'ex1_simple_ops' or 'ex1_simple_ops.ms' or full filename
    $candidate1 = Join-Path -Path ".\examples" -ChildPath $Example
    $candidate2 = $candidate1
    if (-not ($candidate2 -like "*.ms")) { $candidate2 = "$candidate1.ms" }

    if (Test-Path $candidate1) {
        $examples = @( Get-Item $candidate1 )
    } elseif (Test-Path $candidate2) {
        $examples = @( Get-Item $candidate2 )
    } else {
        Write-Error "Example '$Example' not found in .\examples."
        exit 2
    }
} else {
    $examples = Get-ChildItem .\examples -Filter *.ms
}

foreach ($ex in $examples) {
    $base = [IO.Path]::GetFileNameWithoutExtension($ex.Name)
    Write-Host "\n--- Compiling: $($ex.Name) -> output\$base.py ---"
    # Use a relative path for the input file to avoid issues with non-ASCII absolute paths
    $relInput = ".\\examples\\$($ex.Name)"
    & .\mathsc $relInput ("output\" + $base + ".py")
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "mathsc returned non-zero exit code: $LASTEXITCODE"
    }
}

Write-Host "\n--- All examples processed. See the 'output' folder for generated .py, .py.out and plots. ---"