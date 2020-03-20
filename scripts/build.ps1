<#
.SYNOPSIS
    Build step.

.DESCRIPTION
    Build step.
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

function fixUpCargoToml {
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [object] $BuildInfo
    )

    $version = $BuildInfo.Version
    $cargoVersion = ''
    if ($version.Major -eq $null) {
        $cargoVersion += '0'
    } else {
        $cargoVersion += $version.Major
    }
    $cargoVersion += '.'
    if ($version.Minor -eq $null) {
        $cargoVersion += '0'
    } else {
        $cargoVersion += $version.Minor
    }
    $cargoVersion += '.'
    if ($version.Patch -eq $null) {
        $cargoVersion += '0'
    } else {
        $cargoVersion += $version.Patch
    }

    $cargoTomlPath = Resolve-Path -Path "$($BuildInfo.BuildDir)\Cargo.toml"
    $content = Get-Content -Path $cargoTomlPath -Raw
    $content = $content -replace 'version = ".+"', "version = `"$cargoVersion`""
    $content = $content -replace 'description = ".+"', "description = `"$($BuildInfo.Version.FullVersion)`""
    $content | Out-File -Encoding ascii -FilePath $cargoTomlPath -NoNewline
}

function main {
    [OutputType([void])]
    param()

    $buildInfo = Get-AppVeyorBuildInfo
    $baseName = "$($buildInfo.ProjectSlug)-$($buildInfo.Version.FullVersion)"

    fixUpCargoToml -BuildInfo $buildInfo

    cargo build
    #Invoke-ExternalCommand cargo build
    #Invoke-ExternalCommand cargo build --release

    $artifactsDir = Join-Path -Path $buildInfo.BuildDir -ChildPath _artifacts
    New-Item -ErrorAction Ignore -ItemType Directory -Path $artifactsDir | Out-Null
    Write-Output $buildInfo | Out-File -Encoding ascii -FilePath $artifactsDir\build.txt
    Write-Output $buildInfo.Version | Out-File -Encoding ascii -FilePath $artifactsDir\version.txt

    $versionPath = Resolve-Path -Path $artifactsDir\version.txt
    $executablePath = Resolve-Path -Path "$($buildInfo.BuildDir)\target\release\$(Get-ExecutableFileName -BaseName hello-world)"
    $stagingDir = Join-Path -Path $artifactsDir -ChildPath $baseName
    New-Item -ErrorAction Ignore -ItemType Directory -Path $stagingDir | Out-Null
    Copy-Item -Path $versionPath -Destination $stagingDir
    Copy-Item -Path $executablePath -Destination $stagingDir

    Compress-Archive `
        -DestinationPath $artifactsDir\$baseName.zip `
        -CompressionLevel Optimal `
        -Path $stagingDir
}

Write-Output 'Build step'
main
