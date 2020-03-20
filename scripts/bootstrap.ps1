$env:MYCARGOBIN = Resolve-Path -Path "$(if ($env:USERPROFILE -ne $null) { $env:USERPROFILE } else { $env:HOME })\.cargo\bin"
$env:PATH = $env:PATH + [System.IO.Path]::PathSeparator + $env:MYCARGOBIN
