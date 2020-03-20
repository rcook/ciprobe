<#
.SYNOPSIS
    Build step.

.DESCRIPTION
    Build step.
#>
#Requires -Version 5

[CmdletBinding()]
param(
    [switch] $Trace
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($Trace) {
    Set-PSDebug -Strict -Trace 1
}

Import-Module -Name $PSScriptRoot\common -Force

function getEnv {
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        [string] $Name
    )

    $value = [System.Environment]::GetEnvironmentVariable($Name)
    if ($value -eq $null) {
        throw "Environment variable $Name not defined"
    }
    $value
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

class BuildInfo {
    [string] $BuildDir
    [string] $ProjectSlug
    [bool] $IsTag
    [bool] $IsBranch
    [string] $RefName
    [Version] $Version
}

class Version {
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

function getAppVeyorBuildInfo {
    [OutputType([BuildInfo])]
    param()

    $buildDir = getEnv -Name APPVEYOR_BUILD_FOLDER
    $projectSlug = getEnv -Name APPVEYOR_PROJECT_SLUG
    $isTag = (getEnv -Name APPVEYOR_REPO_TAG) -eq 'true'
    $isBranch = (getEnv -Name APPVEYOR_REPO_TAG) -ne 'true'
    $refName = getEnv -Name APPVEYOR_REPO_BRANCH

    $gitDescription = $(Invoke-ExternalCommand git describe --long --dirty --match='v[0-9]*')
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

    $version = [Version] @{
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

    [BuildInfo] @{
        BuildDir = $buildDir
        ProjectSlug = $projectSlug
        IsTag = $isTag
        IsBranch = $isBranch
        RefName = $refName
        Version = $version
    }
}

function fixUpCargoToml {
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [BuildInfo] $BuildInfo
    )

    $version = $BuildInfo.Version
    $cargoVersion = "$($version.Major ?? 0).$($version.Minor ?? 0).$($version.Patch ?? 0)"

    $cargoTomlPath = Resolve-Path -Path "$($BuildInfo.BuildDir)\Cargo.toml"
    $content = Get-Content -Path $cargoTomlPath -Raw
    $content = $content -replace 'version = ".+"', "version = `"$cargoVersion`""
    $content = $content -replace 'description = ".+"', "description = `"$($BuildInfo.Version.FullVersion)`""
    $content | Out-File -Encoding ascii -FilePath $cargoTomlPath -NoNewline
}

function main {
    [OutputType([void])]
    param()

    $buildInfo = getAppVeyorBuildInfo
    $baseName = "$($buildInfo.ProjectSlug)-$($buildInfo.Version.FullVersion)"

    fixUpCargoToml -BuildInfo $buildInfo

    Invoke-ExternalCommand cargo build
    Invoke-ExternalCommand cargo build --release

    $artifactsDir = Join-Path -Path $buildInfo.BuildDir -ChildPath _artifacts
    New-Item -ErrorAction Ignore -ItemType Directory -Path $artifactsDir | Out-Null
    Write-Output $buildInfo | Out-File -Encoding ascii -FilePath $artifactsDir\build.txt
    Write-Output $buildInfo.Version | Out-File -Encoding ascii -FilePath $artifactsDir\version.txt

    $versionPath = Resolve-Path -Path $artifactsDir\version.txt
    $executablePath = Resolve-Path -Path "$($buildInfo.BuildDir)\target\release\hello-world"
    $stagingDir = Join-Path -Path $artifactsDir -ChildPath $baseName
    New-Item -ErrorAction Ignore -ItemType Directory -Path $stagingDir | Out-Null
    Copy-Item -Path $versionPath -Destination $stagingDir
    Copy-Item -Path $executablePath -Destination $stagingDir

    Compress-Archive `
        -DestinationPath $artifactsDir\$baseName.zip `
        -CompressionLevel Optimal `
        -Path $stagingDir
}

Write-Output 'Build step'
main
