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
    [bool] $IsTagged
    [string] $GitDescription
    [bool] $IsDirty
    [string] $PlatformId
    [string] $FullVersion
}

function getVersionAppVeyor {
    [OutputType([Version])]
    param()

    $isTagged = $env:APPVEYOR_REPO_TAG -eq 'true'

    $gitDescription = $(invoke git describe --long --dirty --match='v[0-9]*')
    $parts = $gitDescription.Split('-')
    if ($parts.Length -eq 3) {
        $isDirty = $false
    } elseif (($parts.Length -eq 4) -and ($parts[3] -eq 'dirty')) {
        $isDirty = $true
    } else {
        throw "Invalid git description $gitDescription"
    }

    $platformId = getPlatformId
    $fullVersion = "$gitDescription-$platformId"

    [Version] @{
        IsTagged = $isTagged
        GitDescription = $gitDescription
        IsDirty = $isDirty
        PlatformId = $platformId
        FullVersion = $fullVersion
    }
}

#dumpEnv
Write-Output (getVersionAppVeyor)
Write-Output '(done)'
