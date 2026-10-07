# ==========================================
# SRV01 Backup Retention Script
# Retention Policy: Keep Latest 7 Snapshots
# ==========================================

$BackupRoot = "\\DC01\SRV01-Backup"
$RetentionCount = 7
$LogFile = "C:\Scripts\Backup-Retention.log"

# Start logging
Add-Content $LogFile "`n=========================================="
Add-Content $LogFile "Backup Retention Run: $(Get-Date)"
Add-Content $LogFile "=========================================="

# Verify backup repository
if (-not (Test-Path $BackupRoot)) {

    Add-Content $LogFile "ERROR: Backup repository unavailable: $BackupRoot"
    exit 1
}

Add-Content $LogFile "Repository accessible: $BackupRoot"

# Get only timestamped snapshot folders
$BackupFolders = Get-ChildItem -Path $BackupRoot |
    Where-Object {
        $_.PSIsContainer -and
        $_.Name -match '^\d{4}-\d{2}-\d{2}_\d{6}$'
    } |
    Sort-Object Name -Descending

Add-Content $LogFile "Snapshot folders found: $($BackupFolders.Count)"

# Display snapshots
foreach ($Folder in $BackupFolders) {
    Add-Content $LogFile "Snapshot: $($Folder.Name)"
}

# Apply retention policy
if ($BackupFolders.Count -le $RetentionCount) {

    Add-Content $LogFile "Retention limit not exceeded."
    Add-Content $LogFile "Retention policy: Keep $RetentionCount snapshots."

}
else {

    $FoldersToDelete = $BackupFolders | Select-Object -Skip $RetentionCount

    foreach ($Folder in $FoldersToDelete) {

        Add-Content $LogFile "Deleting old snapshot: $($Folder.FullName)"

        Remove-Item -Path $Folder.FullName -Recurse -Force

        Add-Content $LogFile "Deleted: $($Folder.Name)"
    }

    Add-Content $LogFile "Deleted $($FoldersToDelete.Count) old snapshot(s)."
}

# Final verification
$RemainingBackups = Get-ChildItem -Path $BackupRoot |
    Where-Object {
        $_.PSIsContainer -and
        $_.Name -match '^\d{4}-\d{2}-\d{2}_\d{6}$'
    } |
    Sort-Object Name -Descending

Add-Content $LogFile "Remaining snapshots: $($RemainingBackups.Count)"

# Explicitly document WindowsImageBackup protection
$WindowsImageBackup = Join-Path $BackupRoot "WindowsImageBackup"

if (Test-Path $WindowsImageBackup) {
    Add-Content $LogFile "WindowsImageBackup detected and excluded from retention deletion."
}

Add-Content $LogFile "Retention process completed."