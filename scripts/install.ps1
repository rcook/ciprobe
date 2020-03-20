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
    [switch] $DumpEnv,
    [switch] $Clean
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($Trace) {
    Set-PSDebug -Strict -Trace 1
}

Import-Module -Name $PSScriptRoot\common -Force

function dumpEnv {
    $thisDir = $PSScriptRoot
    $currentDir = Get-Location

    Write-Output "isLinux: $(Get-IsLinux)"
    Write-Output "isMacOS: $(Get-IsMacOS)"
    Write-Output "isWindows: $(Get-IsWindows)"
    Write-Output "executableFileName: $(Get-ExecutableFileName -BaseName base-name)"

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
    Invoke-ExternalCommand git log --oneline --color=never | ForEach-Object {
        Write-Output "  $_"
    }

    Write-Output 'Git tags:'
    Invoke-ExternalCommand git tag | ForEach-Object {
        Write-Output "  $_ $(Invoke-ExternalCommand git rev-list -n 1 $_)"
    }

    Write-Output 'Git branches:'
    Invoke-ExternalCommand git branch -vv -a --color=never | ForEach-Object {
        Write-Output "  $_"
    }

    Write-Output 'Git describe:'
    Write-Output "  $(Invoke-ExternalCommand git describe --long --dirty)"
}

function main {
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [bool] $DumpEnv,
        [Parameter(Mandatory=$true)]
        [bool] $Clean
    )

    if ($Clean) {
        Invoke-ExternalCommand git checkout -- .
        Invoke-ExternalCommand git clean -fxd
    }

    if ($DumpEnv) {
        dumpEnv
    }
}

Write-Output 'Install step'
main -DumpEnv $DumpEnv -Clean $Clean
