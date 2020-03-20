<#
.SYNOPSIS
    Probe CI/CD environment.

.DESCRIPTION
    Gather information like environment variables etc.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$thisDir = $PSScriptRoot
$currentDir = Get-Location
$artifactsDir = Join-Path -Path $thisDir -ChildPath _artifacts
New-Item -ErrorAction Ignore -ItemType Directory -Path $artifactsDir | Out-Null
$artifactsDir = Resolve-Path -Path $artifactsDir

Write-Output "IsLinux=$IsLinux" | Tee-Object -FilePath $artifactsDir\vars.txt
Write-Output "IsMacOS=$IsMacOS" | Tee-Object -FilePath $artifactsDir\vars.txt -Append
Write-Output "IsWindows=$IsWindows" | Tee-Object -FilePath $artifactsDir\vars.txt -Append
Write-Output "thisDir=$thisDir" | Tee-Object -FilePath $artifactsDir\vars.txt -Append
Write-Output "currentDir=$currentDir" | Tee-Object -FilePath $artifactsDir\vars.txt -Append
Write-Output "artifactsDir=$artifactsDir" | Tee-Object -FilePath $artifactsDir\vars.txt -Append

Get-ChildItem -Recurse -Path $thisDir | Select-Object FullName | Tee-Object -FilePath $artifactsDir\this-dir.txt
Get-ChildItem -Recurse -Path $currentDir | Select-Object FullName | Tee-Object -FilePath $artifactsDir\current-dir.txt
Get-ChildItem -Path Env: | Tee-Object -FilePath $artifactsDir\env.txt
