<#
.SYNOPSIS
    Probe CI/CD environment.

.DESCRIPTION
    Gather information like environment variables etc.
#>
#Requires -Version 5

[CmdletBinding()]
param(
    [switch] $Trace
)

Set-StrictMode -Version Latest
if ($Trace) {
    Set-PSDebug -Strict -Trace 1
}

function invoke {
    param()

    if ($args.Count -eq 0) {
        throw 'Must supply some arguments'
    }

    $command = $Args[0]
    $commandArgs = @()
    if ($Args.Count -gt 1) {
        $commandArgs = $Args[1..($Args.Count - 1)]
    }

    & $command $commandArgs
    $result = $LastExitCode
    if ($result -ne 0) {
        throw "$command $commandArgs failed with exit status $result"
    }
}

$ErrorActionPreference = 'Stop'

function dumpEnv {
    $thisDir = $PSScriptRoot
    $currentDir = Get-Location

    Write-Output "IsLinux: $IsLinux"
    Write-Output "IsMacOS: $IsMacOS"
    Write-Output "IsWindows: $IsWindows"
    Write-Output "thisDir: $thisDir"
    Write-Output "currentDir: $currentDir"

    Write-Output "Files under $($thisDir):"
    Get-ChildItem -Force -Recurse -Path $thisDir | Sort-Object FullName | ForEach-Object {
        Write-Output "  $($_.FullName)"
    }

    if ($thisDir -ne $currentDir) {
        Write-Output "Files under $($currentDir):"
        Get-ChildItem -Force -Recurse -Path $currentDir | Sort-Object FullName | ForEach-Object {
            Write-Output "  $($_.FullName)"
        }
    }

    Write-Output 'Environment:'
    Get-ChildItem -Path Env: | Sort-Object Key | ForEach-Object {
        Write-Output "  $($_.Key) = $($_.Value)"
    }

    Write-Output 'Git log:'
    invoke git log --oneline --color=never | ForEach-Object {
        Write-Output "  $_"
    }

    Write-Output 'Git tags:'
    invoke git tag | ForEach-Object {
        Write-Output "  $_ $(invoke git rev-list -n 1 $_)"
    }

    Write-Output 'Git branches:'
    invoke git branch -vv -a --color=never | ForEach-Object {
        Write-Output "  $_"
    }

    Write-Output 'Git describe:'
    Write-Output "  $(invoke git describe --long --dirty)"
}

function getPlatformId {
    [OutputType([string])]
    param()

    if ($IsWindows -or (($env:OS -ne $null) -and ($env:OS.IndexOf('Windows', [StringComparison]::OrdinalIgnoreCase) -ge 0))) {
        'x86_64-windows'
    } elseif ($IsLinux) {
        'x86_64-linux'
    } elseif ($IsMacOS) {
        'x86_64-macos'
    } else {
        throw 'Unsupported platform'
    }
}

class Version {
    [string] $ProjectSlug
    [bool] $IsTag
    [bool] $IsBranch
    [string] $RefName
    [string] $GitDescription
    [bool] $IsDirty
    [string] $PlatformId
    [string] $Version
    [int] $CommitOffset
    [string] $CommitHash
    [object] $VersionParts
    [object] $Major
    [object] $Minor
    [object] $Patch
    [string] $FullVersion
}

function getVersionAppVeyor {
    [OutputType([Version])]
    param()

    $projectSlug = $env:APPVEYOR_PROJECT_SLUG
    $isTag = $env:APPVEYOR_REPO_TAG -eq 'true'
    $isBranch = $env:APPVEYOR_REPO_TAG -ne 'true'
    $refName = $env:APPVEYOR_REPO_BRANCH

    $gitDescription = $(invoke git describe --long --dirty --match='v[0-9]*')
    $gitDescriptionParts = $gitDescription.Split('-')
    if ($gitDescriptionParts.Length -eq 3) {
        $version = $gitDescriptionParts[0]
        $commitOffset = [int] $gitDescriptionParts[1]
        $commitHash = $gitDescriptionParts[2]
        $isDirty = $false
    } elseif (($gitDescriptionParts.Length -eq 4) -and ($gitDescriptionParts[3] -eq 'dirty')) {
        $version = $gitDescriptionParts[0]
        $commitOffset = [int] $gitDescriptionParts[1]
        $commitHash = $gitDescriptionParts[2]
        $isDirty = $true
    } else {
        throw "Invalid Git description $gitDescription"
    }

    if ($version[0] -ne 'v') {
        throw "Invalid version $version"
    }

    $versionParts = $version.Substring(1).Split('.')
    if (($versionParts.Length -lt 1) -or ($versionParts.Length -gt 3)) {
        throw "Invalid version $version"
    }

    $major = if ($versionParts.Length -gt 0) { [int] $versionParts[0] } else { $null }
    $minor = if ($versionParts.Length -gt 1) { [int] $versionParts[1] } else { $null }
    $patch = if ($versionParts.Length -gt 2) { [int] $versionParts[2] } else { $null }

    $platformId = getPlatformId

    $fullVersion = $version

    if ($commitOffset -gt 0) {
        $fullVersion += "-$commitOffset"
    }

    $fullVersion += "-$commitHash"

    if ($isDirty) {
        $fullVersion += '-dirty'
    }

    if ($isBranch) {
        $fullVersion += "-$refName"
    }

    $fullVersion += "-$platformId"

    [Version] @{
        ProjectSlug = $projectSlug
        IsTag = $isTag
        IsBranch = $isBranch
        RefName = $refName
        GitDescription = $gitDescription
        IsDirty = $isDirty
        PlatformId = $platformId
        Version = $version
        CommitOffset = $commitOffset
        CommitHash = $commitHash
        VersionParts = $versionParts
        Major = $major
        Minor = $minor
        Patch = $patch
        FullVersion = $fullVersion
    }
}

#dumpEnv

$version = getVersionAppVeyor
$baseName = "$($version.ProjectSlug)-$($version.FullVersion)"

$artifactsDir = Join-Path -Path $env:APPVEYOR_BUILD_FOLDER -ChildPath _artifacts
New-Item -ErrorAction Ignore -ItemType Directory -Path $artifactsDir | Out-Null
$stagingDir = Join-Path -Path $artifactsDir -ChildPath $baseName
New-Item -ErrorAction Ignore -ItemType Directory -Path $stagingDir | Out-Null

Write-Output $version | Out-File -Encoding ascii -FilePath $stagingDir\version.txt
Write-Output 'Hello world' | Out-File -Encoding ascii -FilePath $stagingDir\data.txt

Compress-Archive `
    -DestinationPath $artifactsDir\$baseName.zip `
    -CompressionLevel Optimal `
    -Path $stagingDir

exit 1
