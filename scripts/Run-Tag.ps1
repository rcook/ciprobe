$ErrorActionPreference = 'Stop'

$env:APPVEYOR_BUILD_FOLDER = Resolve-Path -Path $PSScriptRoot\..
$env:APPVEYOR_REPO_TAG = 'true'
$env:APPVEYOR_REPO_BRANCH = 'v100'
$env:APPVEYOR_PROJECT_SLUG = 'ciprobe'

scripts/install.ps1
scripts/build.ps1
scripts/test.ps1
