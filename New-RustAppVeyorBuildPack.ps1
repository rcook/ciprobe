<#
.SYNOPSIS
    Create new Rust AppVeyor build pack.

.DESCRIPTION
    Create new Rust AppVeyor build pack.
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
    $zipPath = Join-Path -Path $PSScriptRoot -ChildPath rust-appveyor-build-pack.zip
    Compress-Archive `
        -DestinationPath $zipPath `
        -CompressionLevel Optimal `
        -Path $scriptsDir\*
}

Write-Output 'New-RustAppVeyorBuildPack'
main
