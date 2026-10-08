# Disaster Recovery Runbook

## 1. Purpose

This runbook provides a structured procedure for recovering the Windows
Server lab environment after a major failure.

The primary recovery objective is to restore:

-   Active Directory
-   DNS
-   SYSVOL
-   Domain Controller functionality
-   File-share data
-   Client authentication and connectivity

This document is designed for controlled recovery exercises and should
be adapted before use in a production environment.

------------------------------------------------------------------------

## 2. Recovery Scenarios

### Scenario A --- Deleted or Corrupted File

Use the timestamped SRV01 backup snapshots.

### Scenario B --- File Server Data Loss

Restore the required departmental folders from the latest verified
snapshot.

### Scenario C --- Domain Controller Failure

Use the verified System State backup to recover the Domain Controller
and its critical AD components.

------------------------------------------------------------------------

## 3. Recovery Prerequisites

Before beginning recovery, confirm:

-   The backup repository is accessible.
-   A valid file-share snapshot exists.
-   A valid System State recovery point exists.
-   The backup has previously been verified.
-   The recovery target has sufficient disk capacity.
-   Administrative credentials are available.
-   The recovery process is documented.

Do not delete or overwrite the only available recovery point before a
replacement backup has been verified.

------------------------------------------------------------------------

## 4. File-Level Recovery Procedure

### Step 1 --- Locate the backup repository

``` powershell
Test-Path "\DC01\SRV01-Backup"
```

Expected result:

``` text
True
```

### Step 2 --- List available snapshots

``` powershell
Get-ChildItem "\DC01\SRV01-Backup" |
    Where-Object {
        $_.PSIsContainer -and
        $_.Name -match '^\d{4}-\d{2}-\d{2}_\d{6}$'
    } |
    Sort-Object Name -Descending
```

### Step 3 --- Select the appropriate recovery point

Choose the latest snapshot that contains the required version of the
data.

Example:

``` text
2026-10-06_060434
```

### Step 4 --- Locate the required department

Example:

``` text
\DC01\SRV01-Backup6-10-06_060434\IT
```

### Step 5 --- Restore the required file or folder

Copy the required data back to the appropriate SRV01 location.

### Step 6 --- Validate

Confirm:

-   The file exists.
-   The file opens correctly.
-   The intended user can access it.
-   NTFS/share permissions remain appropriate.

------------------------------------------------------------------------

## 5. System State Verification

Before a Domain Controller recovery exercise, verify available System
State backups:

``` powershell
wbadmin get versions -backupTarget:E:
```

A valid recovery point should show a version identifier.

Example verified recovery point:

``` text
Version identifier: 10/05/2026-10:47
```

To inspect the backup contents:

``` powershell
wbadmin get items `
    -version:10/05/2026-10:47 `
    -backupTarget:E:
```

The verified backup contained recoverable components including:

-   Active Directory / NTDS
-   SYSVOL / FRS
-   Registry
-   C: volume

------------------------------------------------------------------------

## 6. Domain Controller Recovery Procedure

> **Important:** Do not intentionally destroy the production Domain
> Controller to test this procedure. Use a controlled lab VM, recovery
> environment, or documented simulation.

### Recovery sequence

``` text
Identify DC failure
        |
        v
Confirm valid System State backup
        |
        v
Prepare recovery environment
        |
        v
Restore System State
        |
        v
Restart / allow recovery process
        |
        v
Validate AD
        |
        v
Validate DNS
        |
        v
Validate SYSVOL / NETLOGON
        |
        v
Validate client authentication
```

------------------------------------------------------------------------

## 7. Post-Recovery Validation

### Active Directory

``` powershell
Get-ADDomain
Get-ADDomainController
```

### DNS

``` powershell
Get-Service DNS
nslookup dconsultstech.local
nslookup DC01.dconsultstech.local
```

### Domain Controller diagnostics

``` powershell
dcdiag /test:advertising
```

Expected result:

``` text
DC01 passed test Connectivity
DC01 passed test Advertising
```

### Netlogon

``` powershell
Get-Service Netlogon
```

Expected state:

``` text
Running
```

### SYSVOL and NETLOGON

``` powershell
Get-SmbShare
```

Confirm that the Domain Controller exposes the expected:

``` text
SYSVOL
NETLOGON
```

### Active Directory inventory

``` powershell
Get-ADComputer -Filter * |
    Select-Object Name, Enabled
```

Also verify important user accounts and groups.

------------------------------------------------------------------------

## 8. Client Validation

From CLIENT01, validate:

-   DNS resolution.
-   Domain connectivity.
-   Ability to authenticate with a domain account.
-   Access to required network resources.
-   Access to restored file shares.

Example:

``` powershell
nslookup dconsultstech.local
```

------------------------------------------------------------------------

## 9. Recovery Completion Criteria

Recovery is considered successful when:

-   Active Directory responds normally.
-   DNS is operational.
-   Netlogon is running.
-   SYSVOL and NETLOGON are available.
-   Domain clients can authenticate.
-   Required file shares are accessible.
-   Restored files open successfully.
-   `dcdiag` passes the relevant tests.
-   Backup and recovery evidence is documented.

------------------------------------------------------------------------

## 10. Lessons Learned

The lab demonstrated that successful disaster recovery depends on more
than simply having a backup.

Key lessons include:

1.  **Backups must be verified.**
2.  **Recovery procedures must be documented.**
3.  **Permissions can prevent otherwise valid backups from succeeding.**
4.  **Domain Controllers require specialized System State protection.**
5.  **Least-privilege service accounts improve backup security.**
6.  **Post-recovery validation is essential.**
