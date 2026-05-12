# 🚀 Linux DevOps Automation Lab

> A comprehensive Linux system administration automation project built with Bash scripting.  
> Designed to simulate real-world DevOps tasks: monitoring, backups, user management, and log analysis.

---

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Tools Used](#-tools-used)
- [Project Structure](#-project-structure)
- [Features](#-features)
- [How to Run](#-how-to-run)
- [Script Descriptions](#-script-descriptions)
- [Cron Job Setup](#-cron-job-setup)
- [Logging System](#-logging-system)
- [Testing Checklist](#-testing-checklist)

---

## 🎯 Project Overview

This lab simulates a DevOps automation environment where Bash scripts handle:

| Task | Script | Description |
|------|--------|-------------|
| System Monitoring | `system_info.sh` | CPU, memory, disk, uptime |
| Automated Backups | `backup.sh` | Timestamp archives with verification |
| User Management | `user_manager.sh` | Add/delete/list/check users |
| Process Monitoring | `process_monitor.sh` | Top processes, live dashboard |
| Log Analysis | `log_report.sh` | Error scanning, failed logins, reports |
| Master Launcher | `main_menu.sh` | Central menu to access all tools |

---

## 🛠️ Tools Used

| Tool | Purpose |
|------|---------|
| **Linux (Ubuntu/WSL)** | Operating system environment |
| **Bash** | Shell scripting language |
| `ps`, `top` | Process monitoring |
| `free`, `df` | Memory and disk usage |
| `tar` | Backup compression |
| `useradd`, `userdel` | User management |
| `grep`, `awk` | Log parsing |
| `crontab` | Scheduled automation |
| `journalctl` | System log reading |

---

## 📁 Project Structure

```
linux-devops-lab/
│
├── scripts/
│   ├── main_menu.sh          ← 🚀 Master launcher (start here!)
│   ├── system_info.sh        ← 🖥️  System performance monitor
│   ├── backup.sh             ← 💾 Automated backup system
│   ├── user_manager.sh       ← 👥 User management console
│   ├── process_monitor.sh    ← 📊 Process monitor dashboard
│   └── log_report.sh         ← 📋 Log analysis & reports
│
├── logs/
│   ├── system.log            ← System info & general logs
│   ├── backup.log            ← Backup operation logs
│   └── process.log           ← Process monitoring logs
│
├── backup/                   ← Backup archives stored here
│
└── README.md                 ← This file
```

---

## ✨ Features

### 🟢 Script 1: System Information (`system_info.sh`)
- ✅ Username and hostname
- ✅ Current date & time
- ✅ CPU model, cores, and usage %
- ✅ Memory (RAM + Swap) with usage %
- ✅ Disk usage for all filesystems
- ✅ Network interface info
- ✅ Top CPU-consuming processes
- ✅ System load average (1m, 5m, 15m)
- ✅ Uptime and last reboot
- ✅ Auto-logs snapshot to `logs/system.log`
- ✅ **Colored terminal output**

### 🟡 Script 2: Automated Backup (`backup.sh`)
- ✅ Backup any folder (default: `~/Documents`)
- ✅ Timestamp in filename: `backup_2026-05-06_11-00.tar.gz`
- ✅ Integrity verification of created archive
- ✅ Auto-cleanup (keeps last 10 backups)
- ✅ Creates demo folder if source doesn't exist
- ✅ Success/failure logged to `logs/backup.log`

### 🔵 Script 3: User Management (`user_manager.sh`)
> ⚠️ Requires `sudo` for add/delete operations

- ✅ Add user (with password + optional sudo)
- ✅ Delete user (with home directory)
- ✅ List all system & regular users
- ✅ Check user existence with full details
- ✅ Show currently logged-in users
- ✅ Input validation & safety checks
- ✅ All actions logged

### 🔴 Script 4: Process Monitor (`process_monitor.sh`)
- ✅ Top 10 CPU-intensive processes
- ✅ Top 10 memory-intensive processes
- ✅ Filter processes by name
- ✅ Live continuous monitor (refreshes every 3s)
- ✅ Kill process by PID or name
- ✅ Process statistics (running, sleeping, zombie)
- ✅ CPU alerts when threshold exceeded
- ✅ Snapshot saved to `logs/process.log`

### 🟣 Script 5: Log Report (`log_report.sh`)
- ✅ Read recent system journal logs
- ✅ Error log analysis (by severity)
- ✅ Count failed SSH login attempts
- ✅ Top offending IPs for failed logins
- ✅ Disk usage report with color-coded warnings
- ✅ Project log statistics dashboard
- ✅ Generate full system report to timestamped file

### 🚀 Bonus: Master Launcher (`main_menu.sh`)
- ✅ Menu-driven interface
- ✅ Live quick stats (CPU, RAM, Disk, Processes)
- ✅ Built-in cron job helper
- ✅ Directory browser for logs & backups
- ✅ Help documentation

---

## 🚀 How to Run

### Prerequisites
```bash
# Make sure you're in WSL (Ubuntu)
# Navigate to the project directory
cd /mnt/e/Self_Learning/DevOps/DevOps_roadmap/linux-devops-lab
```

### Step 1: Make all scripts executable
```bash
chmod +x scripts/*.sh
```

### Step 2: Launch the Master Menu (Recommended)
```bash
bash scripts/main_menu.sh
```

### Step 3: Or run individual scripts
```bash
# System Information
bash scripts/system_info.sh

# Backup (optionally pass a source path)
bash scripts/backup.sh
bash scripts/backup.sh /mnt/c/Users/YourName/Documents

# User Manager (requires sudo)
sudo bash scripts/user_manager.sh

# Process Monitor
bash scripts/process_monitor.sh

# Log Report
bash scripts/log_report.sh
```

---

## ⏰ Cron Job Setup

```bash
# Open the cron editor
crontab -e
```

Add these lines (update the path to match your WSL mount):

```cron
# Run system info every hour — logs to system.log
0 * * * * /mnt/e/Self_Learning/DevOps/DevOps_roadmap/linux-devops-lab/scripts/system_info.sh >> /mnt/e/Self_Learning/DevOps/DevOps_roadmap/linux-devops-lab/logs/system.log 2>&1

# Run backup every day at midnight
0 0 * * * /mnt/e/Self_Learning/DevOps/DevOps_roadmap/linux-devops-lab/scripts/backup.sh >> /mnt/e/Self_Learning/DevOps/DevOps_roadmap/linux-devops-lab/logs/backup.log 2>&1

# Monitor processes every 5 minutes
*/5 * * * * /mnt/e/Self_Learning/DevOps/DevOps_roadmap/linux-devops-lab/scripts/process_monitor.sh >> /mnt/e/Self_Learning/DevOps/DevOps_roadmap/linux-devops-lab/logs/process.log 2>&1
```

### Cron Syntax Reference

```
┌───── minute (0-59)
│ ┌─── hour (0-23)
│ │ ┌─ day of month (1-31)
│ │ │ ┌ month (1-12)
│ │ │ │ ┌ day of week (0-7, 0=Sunday)
│ │ │ │ │
* * * * * command
```

| Schedule | Cron Expression |
|----------|----------------|
| Every hour | `0 * * * *` |
| Every day midnight | `0 0 * * *` |
| Every 5 minutes | `*/5 * * * *` |
| Every Sunday 2am | `0 2 * * 0` |

---

## 📝 Logging System

Every script automatically logs to the `logs/` directory:

| Log File | Populated By | Contains |
|----------|-------------|---------|
| `logs/system.log` | `system_info.sh`, `user_manager.sh`, `log_report.sh` | System snapshots, user events |
| `logs/backup.log` | `backup.sh` | Backup success/failure records |
| `logs/process.log` | `process_monitor.sh` | Process snapshots & alerts |

**Log entry format:**
```
[2026-05-06 13:30:00] [SCRIPT-NAME] [LEVEL] Message
```

Log levels used:
- `[INFO]` — General information
- `[SUCCESS]` — Operation completed successfully
- `[WARN]` — Warning, non-critical
- `[ERROR]` — Something failed
- `[ALERT]` — Threshold exceeded (CPU, memory)

---

## ✅ Testing Checklist

Run these tests to verify everything works:

```bash
# 1. Script runs without error
bash scripts/system_info.sh
echo "Exit code: $?"  # Should be 0

# 2. Backup creates a file
bash scripts/backup.sh
ls -lh backup/  # Should show .tar.gz file

# 3. Verify backup integrity
ls backup/*.tar.gz | xargs -I{} tar -tzf {} | head -5

# 4. User listing works (no root needed)
bash scripts/user_manager.sh  # Choose option 3

# 5. Logs are being generated
cat logs/system.log
cat logs/backup.log

# 6. Process monitor works
bash scripts/process_monitor.sh  # Choose option 1

# 7. Log report works
bash scripts/log_report.sh  # Choose option 5

# 8. Test cron syntax (dry-run)
crontab -l  # List existing jobs
```

---

## 🏆 Bonus Features Implemented

| Feature | Status |
|---------|--------|
| Menu-driven master launcher | ✅ `main_menu.sh` |
| Colored terminal output | ✅ ANSI escape codes |
| Error handling (`if`, `exit 1`) | ✅ All scripts |
| Input validation | ✅ Username format, password match |
| Safety checks | ✅ Root check, self-deletion guard |
| Live process monitor | ✅ 3-second refresh loop |
| Auto-cleanup old backups | ✅ Keeps last 10 |
| Backup integrity verification | ✅ `tar -tzf` |
| CPU/Memory threshold alerts | ✅ Configurable thresholds |
| Full system report export | ✅ Timestamped report files |

---

## 👤 Author

**DevOps Student** | Linux DevOps Automation Lab  
Built as part of the DevOps Learning Roadmap

---

*Last updated: May 2026*
