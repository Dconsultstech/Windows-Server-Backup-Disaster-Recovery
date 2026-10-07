# ==========================================
# D CONSULT TECH
# Backup & Disaster Recovery Health Check
# ==========================================

$BackupRoot = "\\DC01\SRV01-Backup"
$SystemStateTarget = "E:"
$LogFile = "C:\DCTech-Admin\Scripts\Backup-DR-HealthCheck.log"

$BackupTaskName = "SRV01-Backup"
$RetentionTaskName = "SRV01-Backup-Retention"

$RetentionCount = 7

# ------------------------------------------
# Start Report
# ------------------------------------------

$Report = @()

$Report += "=========================================="
$Report += "D CONSULT TECH - BACKUP & DR HEALTH CHECK"
$Report += "=========================================="
$Report += "Date: $(Get-Date)"
$Report += "Server: $env:COMPUTERNAME"
$Report += ""

# ------------------------------------------
# 1. Backup Repository
# ------------------------------------------

if (Test-Path $BackupRoot) {

    $Report += "[PASS] Backup repository accessible: $BackupRoot"

}
else {

    $Report += "[FAIL] Backup repository unavailable: $BackupRoot"
}

# ------------------------------------------
# 2. File Backup Snapshots
# ------------------------------------------

if (Test-Path $BackupRoot) {

    $Snapshots = Get-ChildItem -Path $BackupRoot |
        Where-Object {
            $_.PSIsContainer -and
            $_.Name -match '^\d{4}-\d{2}-\d{2}_\d{6}$'
        } |
        Sort-Object Name -Descending

    if ($Snapshots.Count -gt 0) {

        $LatestSnapshot = $Snapshots | Select-Object -First 1

        $Report += "[PASS] File backup snapshots found: $($Snapshots.Count)"
        $Report += "[INFO] Latest snapshot: $($LatestSnapshot.Name)"

    }
    else {

        $Report += "[FAIL] No file backup snapshots found."
    }
}

# ------------------------------------------
# 3. Retention Check
# ------------------------------------------

if ($Snapshots.Count -le $RetentionCount) {

    $Report += "[PASS] Snapshot retention within configured limit: $RetentionCount"

}
else {

    $Report += "[WARNING] Snapshot count exceeds retention limit."
}

# ------------------------------------------
# 4. Windows System State Backup
# ------------------------------------------

try {

    $SystemState = wbadmin get versions -backupTarget:$SystemStateTarget 2>&1

    if ($SystemState -match "Version identifier") {

        $Report += "[PASS] System State backup detected on $SystemStateTarget"

    }
    else {

        $Report += "[FAIL] No System State backup detected."
    }

}
catch {

    $Report += "[FAIL] Unable to query System State backup."
}

# ------------------------------------------
# 5. DNS Service
# ------------------------------------------

$DNS = Get-Service DNS -ErrorAction SilentlyContinue

if ($DNS.Status -eq "Running") {

    $Report += "[PASS] DNS service is running."

}
else {

    $Report += "[FAIL] DNS service is not running."
}

# ------------------------------------------
# 6. Netlogon Service
# ------------------------------------------

$Netlogon = Get-Service Netlogon -ErrorAction SilentlyContinue

if ($Netlogon.Status -eq "Running") {

    $Report += "[PASS] Netlogon service is running."

}
else {

    $Report += "[FAIL] Netlogon service is not running."
}

# ------------------------------------------
# 7. Backup Scheduled Task
# ------------------------------------------

$BackupTask = Get-ScheduledTask `
    -TaskName $BackupTaskName `
    -ErrorAction SilentlyContinue

if ($BackupTask) {

    $Report += "[PASS] Backup scheduled task exists."

}
else {

    $Report += "[FAIL] Backup scheduled task not found."
}

# ------------------------------------------
# 8. Retention Scheduled Task
# ------------------------------------------

$RetentionTask = Get-ScheduledTask `
    -TaskName $RetentionTaskName `
    -ErrorAction SilentlyContinue

if ($RetentionTask) {

    $Report += "[PASS] Retention scheduled task exists."

}
else {

    $Report += "[FAIL] Retention scheduled task not found."
}

# ------------------------------------------
# 9. Retention Log
# ------------------------------------------

$RetentionLog = "C:\Scripts\Backup-Retention.log"

if (Test-Path $RetentionLog) {

    $Report += "[PASS] Retention log exists."

}
else {

    $Report += "[WARNING] Retention log not found."
}

# ------------------------------------------
# 10. Final Report
# ------------------------------------------

$Report += ""
$Report += "=========================================="
$Report += "BACKUP & DR HEALTH CHECK COMPLETED"
$Report += "=========================================="

$Report | Tee-Object -FilePath $LogFile

Write-Host ""
Write-Host "Health check completed."
Write-Host "Report: $LogFile"