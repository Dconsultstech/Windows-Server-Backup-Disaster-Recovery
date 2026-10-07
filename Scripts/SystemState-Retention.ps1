# ==========================================
# D CONSULT TECH
# System State Backup Retention
# Retention Policy: Keep Latest 2 Backups
# ==========================================

$BackupTarget = "E:"
$RetentionCount = 2
$LogFile = "C:\DCTech-Admin\Scripts\SystemState-Retention.log"

# Start logging
Add-Content $LogFile "`n=========================================="
Add-Content $LogFile "System State Retention Run: $(Get-Date)"
Add-Content $LogFile "=========================================="

# ------------------------------------------
# Get System State Backup Information
# ------------------------------------------

$BackupOutput = wbadmin get versions -backupTarget:$BackupTarget 2>&1

if ($LASTEXITCODE -ne 0) {

    Add-Content $LogFile "ERROR: Unable to query System State backups."
    Add-Content $LogFile "wbadmin exit code: $LASTEXITCODE"
    exit 1
}

# ------------------------------------------
# Extract backup version identifiers
# ------------------------------------------

$Versions = $BackupOutput |
    Where-Object { $_ -match "Version identifier" }

$BackupCount = @($Versions).Count

Add-Content $LogFile "System State backups found: $BackupCount"

# ------------------------------------------
# No backups detected
# ------------------------------------------

if ($BackupCount -eq 0) {

    Add-Content $LogFile "ERROR: No System State backups detected."
    exit 1
}

# ------------------------------------------
# Log detected backups
# ------------------------------------------

foreach ($Version in $Versions) {

    Add-Content $LogFile "Detected: $Version"
}

# ------------------------------------------
# Apply retention policy
# ------------------------------------------

if ($BackupCount -le $RetentionCount) {

    Add-Content $LogFile "Retention limit not exceeded."
    Add-Content $LogFile "Policy: Keep latest $RetentionCount System State backups."

}
else {

    Add-Content $LogFile "Retention limit exceeded."
    Add-Content $LogFile "Removing older System State backups."

    wbadmin delete systemstatebackup `
        -keepVersions:$RetentionCount `
        -backupTarget:$BackupTarget `
        -quiet

    if ($LASTEXITCODE -eq 0) {

        Add-Content $LogFile "System State retention completed successfully."

    }
    else {

        Add-Content $LogFile "ERROR: System State retention failed."
        Add-Content $LogFile "wbadmin exit code: $LASTEXITCODE"
        exit $LASTEXITCODE
    }
}

# ------------------------------------------
# Completion
# ------------------------------------------

Add-Content $LogFile "System State retention process completed."