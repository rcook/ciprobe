<#
.SYNOPSIS
    Install step.

.DESCRIPTION
    Install step.
#>
#Requires -Version 5

[CmdletBinding()]
param(
    [switch] $Trace,
    [switch] $DumpEnv
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($Trace) {
    Set-PSDebug -Strict -Trace 1
}

function Get-IsWindows() {
    [OutputType([bool])]
    param()

    $var = Get-Variable -ErrorAction Ignore -Name IsWindows -Scope Global
    if ($var -ne $null -and ([bool] $var.Value)) {
        $true
    }
    else {
        ($env:OS -ne $null) -and ($env:OS.IndexOf('Windows', [StringComparison]::OrdinalIgnoreCase) -ge 0)
    }
}
Export-ModuleMember -Function Get-IsWindows

function Get-IsLinux() {
    [OutputType([bool])]
    param()

    $var = Get-Variable -ErrorAction Ignore -Name IsLinux -Scope Global
    ($var -ne $null -and ([bool] $var.Value))
}
Export-ModuleMember -Function Get-IsLinux

function Get-IsMacOS() {
    [OutputType([bool])]
    param()

    $var = Get-Variable -ErrorAction Ignore -Name IsMacOS -Scope Global
    ($var -ne $null -and ([bool] $var.Value))
}
Export-ModuleMember -Function Get-IsMacOS

function Invoke-ExternalCommand {
    param()

    if ($args.Count -eq 0) {
        throw 'Must supply some arguments'
    }

    $command = $Args[0]
    $commandArgs = @()
    if ($Args.Count -gt 1) {
        $commandArgs = $Args[1..($Args.Count - 1)]
    }

    $saved = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    & $command $commandArgs
    $result = $LastExitCode
    $ErrorActionPreference = $saved
    if ($result -ne 0) {
        throw "$command $commandArgs failed with exit status $result"
    }
}
Export-ModuleMember -Function Invoke-ExternalCommand

function Get-ExecutableFileName {
    [OutputType([string])]
    param([string] $BaseName)

    if (Get-IsWindows) {
        "$($BaseName).exe"
    }
    elseif ((Get-IsLinux) -or (Get-IsMacOS)) {
        $BaseName
    }
    else {
        throw 'Unsupported platform'
    }
}
Export-ModuleMember -Function Get-ExecutableFileName

function getEnv {
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
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

    if (Get-IsWindows) {
        'x86_64-windows'
    }
    elseif (Get-IsLinux) {
        'x86_64-linux'
    }
    elseif (Get-IsMacOS) {
        'x86_64-macos'
    }
    else {
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
Export-ModuleMember -Function Get-ExecutableFileName


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

function Get-AppVeyorBuildInfo {
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
    }
    elseif (($gitDescriptionParts.Length -eq 4) -and ($gitDescriptionParts[3] -eq 'dirty')) {
        $version = $gitDescriptionParts[0]
        $commitOffset = [int] $gitDescriptionParts[1]
        $commitHash = $gitDescriptionParts[2]
        $isDirty = $true
    }
    else {
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
        IsDirty        = $isDirty
        PlatformId     = $platformId
        Version        = $version
        CommitOffset   = $commitOffset
        CommitHash     = $commitHash
        VersionParts   = $versionParts
        Major          = $major
        Minor          = $minor
        Patch          = $patch
        FullVersion    = $fullVersion
    }

    [BuildInfo] @{
        BuildDir    = $buildDir
        ProjectSlug = $projectSlug
        IsTag       = $isTag
        IsBranch    = $isBranch
        RefName     = $refName
        Version     = $version
    }
}
Export-ModuleMember -Function Get-AppVeyorBuildInfo
