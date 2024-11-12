#!/usr/bin/env pwsh

$homedir = Resolve-Path ~
$cipher = "$homedir/.ssh/secrets/age.key"
$secrets = Join-Path ([Environment]::GetFolderPath('LocalApplicationData'))  ".bubba"
$secret = Join-Path $secrets "age.key"

if (-not (Test-Path $secrets)) {
  New-Item -ItemType Directory -Path $secrets
}

if (-not (Test-Path $secret)) {
  New-Item -ItemType File -Path $secret
  rage -d $cipher -o $secret
}

if [ -t 0 ]; then 
  if [ $# -ne 0 ]; then 
    ENCRYPTEDFILE="$1"
  fi
else
  TMPFILE="$(mktemp)"
  while IFS='' read -r line; do
    printf "%s\n" "$line"
  done > "$TMPFILE"
  ENCRYPTEDFILE="$TMPFILE"
fi

if [ -f "$ENCRYPTEDFILE" ]; then
  rage -d -i "$secret" < "$ENCRYPTEDFILE"
fi

if [ -f "$TMPFILE" ]; then
  rm "$TMPFILE"
fi
