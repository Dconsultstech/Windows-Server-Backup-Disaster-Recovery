
# ==========================================
# D CONSULT TECH
# SRV01 FILE SHARE BACKUP
# ==========================================

$Source = "C:\CompanyData"
$BackupRoot = "\\DC01\SRV01-Backup"

$Timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$Destination = Join-Path $BackupRoot $Timestamp

$LogDirectory = "C:\Scripts\BackupLogs"
$LogFile = Join-Path $LogDirectory "SRV01-Backup_$Timestamp.log"

# ==========================================
# PREPARATION
# ==========================================

Write-Host "=========================================="
Write-Host " D CONSULT TECH - SRV01 FILE BACKUP"
Write-Host "=========================================="

Write-Host "Source      : $Source"
Write-Host "Destination : $Destination"
Write-Host "Started     : $(Get-Date)"
Write-Host ""

# Create local log directory
New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null

# Verify source exists
if (-not (Test-Path $Source)) {
    Write-Host "ERROR: Source path does not exist."
    exit 1
}

# Verify backup destination is reachable
if (-not (Test-Path $BackupRoot)) {
    Write-Host "ERROR: Backup destination is unavailable."
    Write-Host "Destination: $BackupRoot"
    exit 2
}

# Create dated backup directory
New-Item -Path $Destination -ItemType Directory -Force | Out-Null

# ==========================================
# ROBOCOPY BACKUP
# ==========================================

Write-Host "Starting Robocopy..."
Write-Host ""

robocopy $Source $Destination `
    /E `
    /COPY:DAT `
    /DCOPY:DAT `
    /XF desktop.ini `
    /R:3 `
    /W:5 `
    /XJ `
    /NP `
    /TEE `
    /LOG:$LogFile

$RobocopyExitCode = $LASTEXITCODE

# ==========================================
# BACKUP RESULT
# ==========================================

Write-Host ""
Write-Host "=========================================="
Write-Host " BACKUP RESULT"
Write-Host "=========================================="

Write-Host "Robocopy Exit Code : $RobocopyExitCode"
Write-Host "Completed          : $(Get-Date)"
Write-Host "Log File           : $LogFile"

if ($RobocopyExitCode -eq 0) {

    Write-Host "BACKUP STATUS      : SUCCESS"
    Write-Host "No files required copying."

}
elseif ($RobocopyExitCode -ge 1 -and $RobocopyExitCode -le 7) {

    Write-Host "BACKUP STATUS      : SUCCESS"
    Write-Host "Files/folders were copied or differences were detected."

}
else {

    Write-Host "BACKUP STATUS      : FAILED"
    Write-Host "Check the Robocopy log for errors."

}

Write-Host ""
Write-Host "=========================================="

if ($RobocopyExitCode -le 7) {
    exit 0
}
else {
    exit 1
}
