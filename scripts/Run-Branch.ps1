$ErrorActionPreference = 'Stop'

$env:APPVEYOR_BUILD_FOLDER = $PSScriptRoot
$env:APPVEYOR_REPO_TAG = 'false'
$env:APPVEYOR_REPO_BRANCH = 'test-branch'
$env:APPVEYOR_PROJECT_SLUG = 'ciprobe'

scripts/install.ps1 -Clean
scripts/build.ps1
scripts/test.ps1
