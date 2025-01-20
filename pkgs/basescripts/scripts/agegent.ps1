#!/usr/bin/env pwsh

param(
  [Parameter(Mandatory = $False)]
  [System.IO.FileInfo] $filename,
  [Parameter(Mandatory = $False, ValueFromPipeline = $True)]
  [String] $ciphertext
)

$homedir = Resolve-Path ~
$cipher = "$homedir/.ssh/secrets/age.key"
$secrets = Join-Path ([Environment]::GetFolderPath('LocalApplicationData'))  ".bubba"
$secret = Join-Path $secrets "age.key"

if (-not (Test-Path $secrets))
{
  New-Item -ItemType Directory -Path $secrets | Out-Null
}

if (-not (Test-Path $secret))
{
  New-Item -ItemType File -Path $secret | Out-Null
  rage -d $cipher -o $secret
}

if ($filename)
{
  Get-Content -Raw $filename | rage -d -i $secret
} elseif ($ciphertext)
{
  Write-Output $ciphertext | rage -d -i $secret
}
