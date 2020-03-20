<#
.SYNOPSIS
    Compress scripts.

.DESCRIPTION
    Compress scripts.
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

    $scriptsDir = Resolve-Path -Path $PSScriptRoot\scripts

    $distDir = Join-Path -Path $PSScriptRoot -ChildPath dist
    Remove-Item -ErrorAction Ignore -Force -Recurse -Path $distDir
    New-Item -ItemType Directory -Path $distDir | Out-Null
    $distDir = Resolve-Path -Path $distDir

    $zipPath = Join-Path -Path $distDir -ChildPath scripts.zip
    Compress-Archive -DestinationPath $zipPath -CompressionLevel Optimal -Path $scriptsDir\*
}

Write-Output 'Compress-Scripts'
main
