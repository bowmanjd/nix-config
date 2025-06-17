#!/usr/bin/env pwsh
[CmdletBinding(DefaultParameterSetName = 'FileList')]
param(
    [Parameter(ParameterSetName='SingleFile', Mandatory=$true, Position=0, HelpMessage="Path to a single SQL script file to process.")]
    [string]$InputPath,

    [Parameter(ParameterSetName='FileList', Mandatory=$true, HelpMessage="Path to a text file containing a list of SQL script file paths to process, one per line.")]
    [string]$FileListPath
)

$InformationPreference = "Continue"

function Invoke-SqlScriptUpdate {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TargetFilePath
    )

    if (-not (Test-Path $TargetFilePath)) {
        Write-Error "File not found: $TargetFilePath"
        return # Exit this function call, allows loop to continue for FileListPath
    }

    $tempFilePath = $null # Initialize for the finally block

    try {
        # Create a temporary file using a PowerShell-specific command
        $tempFile = New-TemporaryFile
        $tempFilePath = $tempFile.FullName

        Copy-Item -Path $TargetFilePath -Destination $tempFilePath -Force

        # Read the content of the temporary file
        $content = Get-Content -Path $tempFilePath -Raw

        # Default modifiedContent to original content
        $modifiedContent = $content

        # Regex to find "CREATE TABLE" and capture the table name.
        $createTablePattern = '(?i)create\s+table\s+([\[\]\w\d\._''\s-]+?)(?=\s*\(|\s+AS\s+|\s*;|\s+GO\b|$)'

        if ($content -match $createTablePattern) {
            $tableName = $matches[1].Trim() # Get the captured table name and trim whitespace

            if (-not [string]::IsNullOrWhiteSpace($tableName)) {
                $contentToWrap = $content -replace '(?is)\s+GO\s*$', '' 

                $modifiedContent = @"
IF OBJECT_ID('$tableName', 'U') IS NULL
BEGIN
$contentToWrap
END
GO
"@
            } else {
                Write-Warning "CREATE TABLE detected in '$TargetFilePath', but table name extraction failed or yielded an empty name. Original content will be used for execution."
            }
        } else {
            $tempModifiedContent = $content -replace '(?i)create\s+proc', 'create or alter proc'
            if ($tempModifiedContent -ne $content) {
                $modifiedContent = $tempModifiedContent
            } else {
                Write-Warning "No CREATE PROC found to modify in '$TargetFilePath'. Original content will be used."
            }
        }

        # Write-Information "Writing modified content to temporary file: $tempFilePath (from '$TargetFilePath')"
        Set-Content -Path $tempFilePath -Value $modifiedContent -Encoding UTF8

        Write-Information "Idempotently executing SQL script: $TargetFilePath"
        sqlcmd -i $tempFilePath
        
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "sqlcmd execution for '$TargetFilePath' finished with exit code: $LASTEXITCODE. There might have been errors."
        }

    }
    catch {
        Write-Error "An error occurred while processing '$TargetFilePath': $($_.Exception.Message)"
        # Error is reported, function will end, and loop (if any) can continue.
    }
    finally {
        if ($tempFilePath -and (Test-Path $tempFilePath)) {
            Remove-Item -Path $tempFilePath -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host "" # Adds a blank line for better readability between multiple file outputs
}

# Main script execution logic based on ParameterSet
switch ($PSCmdlet.ParameterSetName) {
    'SingleFile' {
        Invoke-SqlScriptUpdate -TargetFilePath $InputPath
    }
    'FileList' {
        if (-not (Test-Path $FileListPath)) {
            Write-Error "File list not found: $FileListPath"
            exit 1 # Exit script if the list file itself is not found
        }

        Write-Information "Reading file list from: $FileListPath"

        $fileListRawLines = Get-Content $FileListPath

        # Exclude lines inside the final ```sql code fence
        $inCodeBlock = $false
        $filesToProcess = @()
        foreach ($line in $fileListRawLines) {
            if ($line -match '^\s*```sql\s*$') {
                $inCodeBlock = $true
                continue
            }
            if ($inCodeBlock) {
                if ($line -match '^\s*```\s*$') {
                    $inCodeBlock = $false
                }
                continue
            }
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                $filesToProcess += $line
            }
        }

        if ($filesToProcess.Count -eq 0) {
            Write-Warning "The file list '$FileListPath' is empty or contains only whitespace lines."
            exit 0 
        }

        foreach ($filePathInList in $filesToProcess) {
            $trimmedPath = $filePathInList.Trim()
            Invoke-SqlScriptUpdate -TargetFilePath $trimmedPath
        }

        # Now extract and execute the final SQL code block if present
        $fileListContent = Get-Content $FileListPath -Raw
        $sqlBlockPattern = '(?ms)```sql\s*(.*?)\s*```'
        if ($fileListContent -match $sqlBlockPattern) {
            $finalSqlCode = $matches[1].Trim()
            if ($finalSqlCode) {
                Write-Information "Executing final SQL code block from file list..."
                sqlcmd -Q "$finalSqlCode"
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "sqlcmd execution for final SQL code block finished with exit code: $LASTEXITCODE. There might have been errors."
                }
            }
        }
    }
}
