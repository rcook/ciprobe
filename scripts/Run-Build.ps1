[CmdletBinding()]
param(
    [switch] $Trace
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($Trace) {
    Set-PSDebug -Strict -Trace 1
}

function main {
    [OutputType([void])]
    param()

    $baseName = 'rust-appveyor-build-pack'
    $repoDir = Resolve-Path -Path $PSScriptRoot\..

    $bootstrapPath = Join-Path -Path $repoDir -ChildPath "$baseName.ps1"
    if (-not (Test-Path -Path $bootstrapPath)) {
        Invoke-WebRequest `
            -Uri https://github.com/rcook/$baseName/releases/latest/download/$baseName.ps1 `
            -OutFile $bootstrapPath
    }
    $bootstrapPath = Resolve-Path -Path $bootstrapPath

    $packDir = Join-Path -Path $repoDir -ChildPath $baseName
    if (-not (Test-Path -Path $packDir)) {
        & $bootstrapPath
    }
    $packDir = Resolve-Path -Path $packDir

    # Simulate tag build
    <#
    $env:APPVEYOR_BUILD_FOLDER = Resolve-Path -Path $repoDir
    $env:APPVEYOR_REPO_TAG = 'true'
    $env:APPVEYOR_REPO_BRANCH = 'v100'
    $env:APPVEYOR_PROJECT_SLUG = 'ciprobe'
    #>

    # Simulate branch build
    <#
    $env:APPVEYOR_BUILD_FOLDER = Resolve-Path -Path $repoDir
    $env:APPVEYOR_REPO_TAG = 'false'
    $env:APPVEYOR_REPO_BRANCH = 'test-branch'
    $env:APPVEYOR_PROJECT_SLUG = 'ciprobe'
    #>

    & $packDir\install.ps1
    & $packDir\build.ps1
    & $packDir\test.ps1
}

main
