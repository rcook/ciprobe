<#
.SYNOPSIS
    Probe CI/CD environment.

.DESCRIPTION
    Gather information like environment variables etc.
#>

[CmdletBinding()]
param()

function invoke() {
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

$thisDir = $PSScriptRoot
$currentDir = Get-Location

Write-Output "IsLinux: $IsLinux"
Write-Output "IsMacOS: $IsMacOS"
Write-Output "IsWindows: $IsWindows"
Write-Output "thisDir: $thisDir"
Write-Output "currentDir: $currentDir"

Write-Output "Files under $($thisDir):"
Get-ChildItem -Recurse -Path $thisDir | Sort-Object FullName | ForEach-Object {
    Write-Output "  $($_.FullName)"
}

if ($thisDir -ne $currentDir) {
    Write-Output "Files under $($currentDir):"
    Get-ChildItem -Recurse -Path $currentDir | Sort-Object FullName | ForEach-Object {
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
