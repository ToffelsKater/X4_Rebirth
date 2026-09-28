param([ValidateSet('Debug','Release')][string]$Configuration = 'Release',
      [ValidateSet('build','build-next')][string]$BuildDirectory = 'build',
      [switch]$SkipTests)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
$vsPath = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vsPath) { throw 'Visual Studio C++ x64 tools not found' }
$cmake = Join-Path $vsPath 'Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe'
if (-not (Test-Path $cmake)) { $cmake = (Get-Command cmake.exe -ErrorAction Stop).Source }
Write-Host "CMake: $cmake"
$ctest = Join-Path (Split-Path $cmake) 'ctest.exe'
& $cmake -S $projectRoot -B (Join-Path $projectRoot $BuildDirectory) -G 'Visual Studio 17 2022' -A x64
if ($LASTEXITCODE -ne 0) { throw 'Configure failed' }
& $cmake --build (Join-Path $projectRoot $BuildDirectory) --config $Configuration
if ($LASTEXITCODE -ne 0) { throw 'Build failed' }
if ($SkipTests) { return }
& $ctest --test-dir (Join-Path $projectRoot $BuildDirectory) -C $Configuration --output-on-failure
if ($LASTEXITCODE -ne 0) { throw 'Tests failed' }
