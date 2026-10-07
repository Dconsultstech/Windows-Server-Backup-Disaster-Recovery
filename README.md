# Windows Server Backup & Disaster Recovery

## Project Overview

This project demonstrates the design and implementation of a local Windows Server Backup and Disaster Recovery (BDR) solution for a small business environment.

The solution was built in a virtualized Windows Server lab and focuses on protecting critical infrastructure services, Active Directory, System State data, and departmental file shares.

The project implements backup, verification, retention, restore testing, disaster recovery procedures, and PowerShell-based automation.

---

## Objectives

The primary objectives were to:

* Design a reliable local-first backup strategy.
* Protect Active Directory and Domain Controller services.
* Back up critical departmental file shares.
* Verify backup integrity and recoverability.
* Implement automated backup retention.
* Test file-level restoration.
* Develop a documented Domain Controller disaster recovery procedure.
* Monitor backup and recovery operations using PowerShell.

---

## Lab Environment

| Component              | Configuration         |
| ---------------------- | --------------------- |
| Hypervisor             | Microsoft Hyper-V     |
| Domain                 | dconsultstech.local |
| Domain Controller      | DC01                  |
| File Server            | SRV01                 |
| Client                 | CLIENT01              |
| Server OS              | Windows Server 2025   |
| Client OS              | Windows 11            |
| Backup Strategy        | Local-first           |
| System State Target    | 60 GB virtual disk    |
| File Backup Repository | \\DC01\SRV01-Backup |

---

## Architecture

` ext
                         D CONSULT TECH
                        LAB ENVIRONMENT
                              |
                    Windows Server Infrastructure
                              |
          ┌───────────────────┼───────────────────┐
          │                   │                   │
        DC01                SRV01             CLIENT01
   Domain Controller       File Server          Client
          │                   │
          │              Company Data
          │                   │
          │          ┌────────┼────────┐
          │          │        │        │
          │       Finance     HR       IT      Sales
          │
          └───────────────┐
                          │
                    Backup System
                          │
          ┌───────────────┴───────────────┐
          │                               │
     File-Share Backup              System State
          │                               │
\\DC01\SRV01-Backup                       E:
          │                               │
   Timestamped snapshots           AD / SYSVOL /
                                  Registry / C:
`

---

# Backup Strategy

The project uses a two-layer backup strategy.

### 1. File-Share Backup

Critical departmental data from SRV01 is copied into timestamped backup snapshots.

Example:

`	ext
\\DC01\SRV01-Backup
│
├── 2026-10-06_060434
│   ├── Finance
│   ├── HR
│   ├── IT
│   └── Sales
│
└── WindowsImageBackup

`

The file-share backup protects departmental business data.

### 2. System State Backup

DC01 System State is backed up to a dedicated virtual disk.

The System State backup protects critical Domain Controller components including:

* Active Directory
* NTDS
* SYSVOL
* Registry
* System volume

---

# Backup Verification

Backup verification was performed using Windows Server Backup tools.

`powershell
wbadmin get versions -backupTarget:E:
`

This confirmed that a valid System State recovery point existed.

Backup contents were further inspected with:

`powershell
wbadmin get items -version:10/05/2026-10:47 -backupTarget:E:
`

The recovery point contained Active Directory/NTDS, SYSVOL/FRS, Registry, and the system volume.

---

# File-Level Restore Testing

A controlled file restoration test was performed using data from the file-share backup repository.

The backup contained departmental data including:

`	ext
Finance
HR
IT
Sales
`

A test file was successfully recovered, demonstrating that the file backup could be used for practical data restoration rather than simply confirming that backup files existed.

---

# Backup Retention

Automated retention policies were implemented using PowerShell.

### File-Share Retention

The file-share retention policy keeps the latest **7 timestamped snapshots**.

The retention script:

`	ext
SRV01-Backup-Retention.ps1
`

specifically targets timestamped snapshot folders and excludes the WindowsImageBackup directory.

### System State Retention

The System State retention policy is configured to keep the latest **2 recovery points**.

The retention process uses:

`powershell
wbadmin delete systemstatebackup
`

with the appropriate -keepVersions parameter.

The policy also prevents deletion when fewer than two System State backups are available.

---

# Scheduled Automation

Windows Task Scheduler was used to automate backup operations.

The environment contains scheduled processes for:

* File-share backup
* File-share backup retention
* System State retention

PowerShell scripts are executed with appropriate administrative privileges.

Task execution is monitored using:

`powershell
Get-ScheduledTaskInfo
`

The task result code is checked to determine whether the scheduled operation completed successfully.

---

# Disaster Recovery Simulation

A non-destructive Domain Controller disaster recovery simulation was performed.

The scenario assumed that DC01 experienced a catastrophic operating-system failure and could no longer provide:

* Active Directory
* DNS
* Domain authentication
* SYSVOL
* Domain services

The recovery process was documented rather than intentionally destroying the working Domain Controller.

### Recovery Workflow

`	ext
Identify Failure
      ↓
Identify Recovery Point
      ↓
Verify System State Backup
      ↓
Restore System State / System Image
      ↓
Restart Domain Controller
      ↓
Verify Active Directory
      ↓
Verify DNS
      ↓
Verify SYSVOL
      ↓
Verify Authentication
      ↓
Verify Client Connectivity
      ↓
Validate File Services
`

---

# Recovery Validation

Post-recovery validation includes:

### Active Directory

`powershell
Get-ADDomain
Get-ADDomainController
`

### DNS

`powershell
Get-Service DNS
nslookup dconsultstech.local
`

### Domain Controller Health

`powershell
dcdiag
`

### SYSVOL and NETLOGON

`powershell
Get-SmbShare
`

### Users

`powershell
Get-ADUser -Filter *
`

### Computers

`powershell
Get-ADComputer -Filter *
`

These checks provide a structured method for determining whether the recovered Domain Controller is operational.

---

# Monitoring

A PowerShell-based Backup & DR Health Check was developed to monitor:

* Backup repository availability
* File-share backup snapshots
* System State backup availability
* DNS service
* Netlogon service
* Backup scheduled tasks
* Retention scheduled tasks
* Backup logs

Example:

`	ext
D CONSULT TECH - BACKUP & DR HEALTH CHECK

[PASS] Backup repository accessible
[PASS] File backup snapshots found
[PASS] System State backup detected
[PASS] DNS service is running
[PASS] Netlogon service is running
[PASS] Backup scheduled task exists
[PASS] Retention scheduled task exists
`

---

## Troubleshooting Experience

### 1. Shared Folder Backup Permission Issue

During the implementation of the backup solution, the automation initially failed to back up content from the shared folders hosted on **SRV01**. The issue was traced to insufficient permissions for the account executing the backup process.

To resolve this while following the **Principle of Least Privilege**, I introduced a dedicated backup service account:

* Created a `svc-backup` domain service account for backup operations.
* Granted the account only the permissions required to access and back up the departmental shared folders on **SRV01**.
* Configured the SRV01 file-share backup automation to run under the `svc-backup` account rather than using a highly privileged administrator account.
* Used the domain `Administrator` account for the DC01 System State backup automation because the required System State backup operation required elevated privileges.
* Verified that the backup process could successfully access and back up the required shared-folder content after the permissions were corrected.

This troubleshooting process demonstrated practical experience with **NTFS/share permissions, service accounts, privilege separation, PowerShell automation, and least-privilege access control**.

### 2. Domain Controller DNS and Directory Service Issue

During disaster recovery validation, `dcdiag /test:advertising` initially failed because the DNS Server service on DC01 was stopped. This prevented proper resolution of the Domain Controller's AD-related records and affected directory service connectivity.

I identified the stopped DNS service, started it, and reran the diagnostic test:

```powershell
Start-Service DNS
dcdiag /test:advertising
```

The subsequent diagnostic completed successfully, with both **Connectivity** and **Advertising** tests passing.

This demonstrated practical troubleshooting of **DNS, Active Directory, Netlogon, and Domain Controller connectivity**.
--

# Security Considerations

The project incorporates several security considerations:

* Administrative operations require appropriate privileges.
* Backup data is stored separately from the primary departmental data.
* Backup retention prevents unlimited accumulation of recovery points.
* System State backups are protected by a defined retention policy.
* Backup scripts are separated from the production data directories.
* Sensitive credentials and backup contents are excluded from the GitHub repository.

---

# Skills & Technologies Demonstrated

### Windows Server Administration

* Active Directory Domain Services
* DNS
* Group Policy
* File and folder permissions
* SMB file sharing
* Windows Server Backup
* System State Backup
* Windows Task Scheduler

### PowerShell

* Backup automation
* Retention automation
* Scheduled task management
* Health checks
* Logging
* Backup verification
* System administration

### Disaster Recovery

* Backup strategy
* Recovery point verification
* File restoration
* System State recovery planning
* Disaster recovery simulation
* Post-recovery validation
* Recovery documentation

---

# Key Outcomes

The project resulted in a functional local-first Backup & Disaster Recovery environment capable of:

* Protecting critical departmental file shares.
* Protecting Domain Controller System State.
* Maintaining defined backup retention periods.
* Performing tested file-level restoration.
* Supporting documented Domain Controller recovery procedures.
* Automating backup administration using PowerShell.
* Monitoring backup infrastructure and scheduled operations.

---

# Future Improvements

Potential improvements include:

* Off-site backup replication.
* Azure Backup integration.
* Immutable backup storage.
* Additional Domain Controller for redundancy.
* Automated email/Teams alerts.
* Centralized monitoring.
* Backup encryption.
* Recovery Point Objective (RPO) and Recovery Time Objective (RTO) measurements.
* Regular scheduled disaster recovery exercises.

---

# Project Outcome

This project demonstrates practical experience designing, implementing, testing, automating, and documenting a Windows Server Backup and Disaster Recovery solution.

It combines infrastructure administration, Active Directory, Windows Server Backup, PowerShell automation, data recovery, monitoring, and disaster recovery planning in a single end-to-end infrastructure project.
