<#
.SYNOPSIS
    Get scripts.

.DESCRIPTION
    Get scripts.
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


function main {
    [OutputType([void])]
    param()

    $zipPath = Resolve-Path -Path $PSScriptRoot\dist\scripts.zip

    $outputDir = Join-Path -Path $PSScriptRoot -ChildPath output
    Remove-Item -ErrorAction Ignore -Force -Recurse -Path $outputDir
    New-Item -ItemType Directory -Path $outputDir | Out-Null
    $outputDir = Resolve-Path -Path $outputDir

    Expand-Archive -DestinationPath $outputDir -Path $zipPath
}


Write-Output 'Get-Scripts'
main
