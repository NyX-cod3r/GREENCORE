$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$outputDir = Join-Path $root 'simulation\output'
$compiled = Join-Path $outputDir 'sih_model.vvp'

if (-not (Get-Command iverilog -ErrorAction SilentlyContinue)) {
    throw 'iverilog was not found. Install Icarus Verilog and ensure iverilog.exe and vvp.exe are on PATH.'
}

if (-not (Get-Command vvp -ErrorAction SilentlyContinue)) {
    throw 'vvp was not found. Install Icarus Verilog and ensure iverilog.exe and vvp.exe are on PATH.'
}

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
$rtlFiles = Get-ChildItem (Join-Path $root 'rtl') -Filter '*.v' | Sort-Object Name | ForEach-Object FullName
$testbench = Join-Path $root 'simulation\system_frame_tb.v'

Push-Location $root
try {
    & iverilog -g2012 -o $compiled @rtlFiles $testbench
    if ($LASTEXITCODE -ne 0) { throw 'iverilog compilation failed.' }

    & vvp $compiled
    if ($LASTEXITCODE -ne 0) { throw 'vvp simulation failed.' }
}
finally {
    Pop-Location
}

Write-Host "Simulation output: $outputDir\system_results.csv"