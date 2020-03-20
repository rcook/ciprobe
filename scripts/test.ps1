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

Write-Output 'Test step'
