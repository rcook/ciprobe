<#
.SYNOPSIS
    Test step.

.DESCRIPTION
    Test step.
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

function main {
    [OutputType([void])]
    param()

    Invoke-ExternalCommand cargo test

    Invoke-ExternalCommand cargo test --release
}

Write-Output 'Test step'
main