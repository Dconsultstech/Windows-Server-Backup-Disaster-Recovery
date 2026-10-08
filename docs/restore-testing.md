# Backup Verification & Restore Testing

## 1. Purpose

The purpose of restore testing is to confirm that backup data can
actually be recovered and is not merely being generated successfully.

The project tested both:

-   File-level recovery from SRV01 backup snapshots.
-   System State backup integrity and recoverable components.

------------------------------------------------------------------------

## 2. File-Level Backup Verification

The backup repository was verified at:

``` text
\DC01\SRV01-Backup
```

Timestamped snapshots were created for the SRV01 departmental data.

Example:

``` text
2026-10-06_060434
├── Finance
├── HR
├── IT
└── Sales
```

The latest snapshot was inspected to confirm that departmental content
was present.

------------------------------------------------------------------------

## 3. Restore Test

A test file was created within the IT backup data:

``` text
IT\Backup-Test\Recovery-test.txt.txt
```

The file was successfully recovered from the backup repository.

This confirmed that the file-level backup process was not only creating
folders but was capable of supporting an actual recovery operation.

------------------------------------------------------------------------

## 4. Permission Issue Discovered During Backup

During initial testing, the automation could not successfully back up
the contents of the shared folders on SRV01.

The root cause was insufficient access permissions for the account
executing the backup process.

### Resolution

A dedicated service account was introduced:

``` text
svc-backup
```

The account was granted the permissions required to access the protected
shared-folder content.

The SRV01 backup automation was then executed using the service account.

For DC01 System State backup, the domain Administrator account was used
because System State backup requires elevated privileges.

This created a practical privilege separation model:

``` text
SRV01
  |
  +-- File-share backup --> svc-backup
  |
  +-- Required permissions only


DC01
  |
  +-- System State backup --> Domain Administrator
  |
  +-- Elevated privileges
```

This resolved the backup access issue while applying the **Principle of
Least Privilege** to the file-share backup operation.

------------------------------------------------------------------------

## 5. System State Backup Verification

The System State backup was verified using:

``` powershell
wbadmin get versions -backupTarget:E:
```

Verified recovery point:

``` text
Backup time: 10/5/2026 3:47 AM
Backup target: Fixed Disk labeled E:
Version identifier: 10/05/2026-10:47
Can recover: Volume(s), File(s), Application(s), System State
```

------------------------------------------------------------------------

## 6. System State Contents

The recovery point was inspected using:

``` powershell
wbadmin get items `
    -version:10/05/2026-10:47 `
    -backupTarget:E:
```

The output confirmed recoverable components including:

### Active Directory

``` text
Application = AD
Component = ntds
```

### SYSVOL / FRS

``` text
Application = FRS
```

### Registry

``` text
Application = Registry
Component = Registry
```

### C: Volume

The backup also reported the C: volume as recoverable.

------------------------------------------------------------------------

## 7. Restore Validation Results

  Test                                   Result
  -------------------------------------- --------
  Backup repository accessible           Passed
  Timestamped SRV01 snapshots created    Passed
  Department folders present             Passed
  File-level restore                     Passed
  Recovery test file restored            Passed
  System State recovery point verified   Passed
  AD / NTDS present in System State      Passed
  SYSVOL / FRS present                   Passed
  Registry present                       Passed

------------------------------------------------------------------------

## 8. Recovery Testing Approach

The Domain Controller disaster recovery process was documented as a
**non-destructive simulation** rather than intentionally taking the
working DC01 offline or destroying the VM.

This approach reduces the risk of damaging the lab environment while
still demonstrating knowledge of the recovery process.

The documented recovery flow covers:

1.  Identify failure.
2.  Confirm available recovery point.
3.  Restore System State.
4.  Validate Active Directory.
5.  Validate DNS.
6.  Validate SYSVOL and NETLOGON.
7.  Validate domain authentication.
8.  Validate file-share access.

------------------------------------------------------------------------

## 9. Evidence to Capture

For the GitHub portfolio, recommended evidence includes:

-   `dcdiag /test:advertising` showing successful Connectivity and
    Advertising tests.
-   `wbadmin get versions -backupTarget:E:` showing the System State
    recovery point.
-   `wbadmin get items` showing AD, SYSVOL/FRS and Registry components.
-   Backup repository showing timestamped snapshots.
-   Restore test showing the recovered file.
-   Task Scheduler showing configured backup automation.
-   Retention logs showing successful retention processing.

Do not include passwords, secrets, access tokens, or other sensitive
credentials in screenshots.

------------------------------------------------------------------------

## 10. Conclusion

The restore testing phase demonstrated that the BDR solution was capable
of producing usable recovery data and that the recovery process could be
validated rather than assumed.

The most important outcome was the discovery and resolution of the SRV01
backup permission issue. Introducing the `svc-backup` service account
provided the required access while maintaining a more secure
least-privilege model for file-share backup operations.
