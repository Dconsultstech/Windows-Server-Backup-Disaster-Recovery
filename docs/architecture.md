# Backup & Disaster Recovery Architecture

## 1. Overview

This project implements a local-first Backup & Disaster Recovery (BDR)
environment using Windows Server technologies in a Hyper-V lab.

The design protects two major categories of data:

1.  **Active Directory / Domain Controller recovery data**
2.  **Departmental file-share data hosted on SRV01**

The solution uses a dedicated backup repository hosted on DC01 and
separates backup responsibilities between SRV01 and DC01.

------------------------------------------------------------------------

## 2. Lab Environment

  -----------------------------------------------------------------------
  Component                           Role
  ----------------------------------- -----------------------------------
  DC01                                Domain Controller, DNS, Active
                                      Directory, System State backup
                                      repository

  SRV01                               File Server hosting departmental
                                      shares

  CLIENT01                            Windows client used for
                                      connectivity and restore validation

  Hyper-V Host                        Windows 11 Pro physical host

  Domain                              `dconsultstech.local`

  DC01 IP                             `10.10.10.10`
  -----------------------------------------------------------------------

### Departmental data

SRV01 contains departmental folders for:

-   Finance
-   HR
-   IT
-   Sales

These folders are protected through the file-share backup process.

------------------------------------------------------------------------

## 3. Backup Architecture

``` text
                         Windows 11 Pro
                         Hyper-V Host
                              |
             +----------------+----------------+
             |                                 |
          DC01                              SRV01
     Domain Controller                     File Server
     DNS / AD / SYSVOL                 Finance / HR / IT / Sales
             |                                 |
             |                          Backup automation
             |                           using svc-backup
             |                                 |
             +---------------+-----------------+
                             |
                    \DC01\SRV01-Backup
                             |
              +--------------+--------------+
              |                             |
       File-share snapshots          WindowsImageBackup
                                      / System State
```

------------------------------------------------------------------------

## 4. File-Share Backup

The departmental folders on SRV01 are copied into timestamped backup
snapshots stored under:

``` text
\DC01\SRV01-Backup
```

Example:

``` text
\DC01\SRV01-Backup
├── 2026-10-06_060434
│   ├── Finance
│   ├── HR
│   ├── IT
│   └── Sales
└── WindowsImageBackup
```

The timestamped folders provide point-in-time file recovery options.

------------------------------------------------------------------------

## 5. System State Backup

DC01 uses Windows Server Backup (`wbadmin`) to protect System State
information.

The System State backup is stored on a dedicated virtual disk:

``` text
E:
```

The verified backup included recoverable components such as:

-   Active Directory / NTDS
-   SYSVOL / FRS
-   Registry
-   C: volume

System State protection is important because a Domain Controller cannot
be treated like an ordinary file server. Active Directory, SYSVOL, DNS
configuration, and related system components must be recoverable
together.

------------------------------------------------------------------------

## 6. Least-Privilege Backup Design

A permission issue was encountered when the backup automation initially
attempted to access SRV01 shared-folder content.

Instead of granting unnecessary administrator privileges to the
file-share backup process, a dedicated service account was introduced:

``` text
svc-backup
```

The account was granted the permissions required for the backup
operation on SRV01.

The resulting separation was:

``` text
SRV01 file-share backup
        |
    svc-backup
        |
Required file/share permissions only


DC01 System State backup
        |
Domain Administrator
        |
Elevated System State privileges
```

This approach demonstrates practical application of the **Principle of
Least Privilege** and privilege separation.

------------------------------------------------------------------------

## 7. Retention Design

File-share backups use timestamped folders so that older snapshots can
be identified without affecting the special `WindowsImageBackup`
directory.

The file-share retention policy was configured to keep the latest **7
timestamped snapshots**.

`WindowsImageBackup` is explicitly excluded from the file-share
retention deletion process.

System State retention is handled separately because Windows Server
Backup manages System State recovery points differently from the
manually created file-share snapshots.

------------------------------------------------------------------------

## 8. Recovery Flow

A typical recovery process is:

``` text
Failure / Data Loss
       |
       v
Identify recovery requirement
       |
       +------------------------+
       |                        |
 File-level recovery       DC/System State recovery
       |                        |
       v                        v
Select snapshot             Select System State
       |                        |
       v                        v
Restore files             Windows Server Backup
       |                        |
       +-----------+------------+
                   |
                   v
          Validate functionality
                   |
                   v
          Document recovery result
```

------------------------------------------------------------------------

## 9. Security Considerations

The design applies several security principles:

-   Dedicated backup service account for SRV01 file-share access.
-   Least-privilege permissions.
-   Separation of file-server backup and Domain Controller System State
    operations.
-   Restricted access to the backup repository.
-   Separate retention processes for file snapshots and System State.
-   Verification of backup contents before considering the backup valid.

------------------------------------------------------------------------

## 10. Future Improvements

Potential production improvements include:

-   Off-site backup replication.
-   Immutable backup storage.
-   Additional independent backup media.
-   Cloud backup integration.
-   Encryption of backup data.
-   Centralized monitoring and alerting.
-   A dedicated backup server instead of hosting the repository on the
    Domain Controller.
