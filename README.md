# 🧹 Linux Cleaner

A safe and comprehensive Linux system maintenance and cleanup script designed to help keep your system **clean, healthy, and optimized**.

Linux Cleaner performs common maintenance tasks such as APT cleanup, log management, cache cleanup, Docker cleanup, disk health checks, SSD/NVMe TRIM, and more — while prioritizing system safety.

> ⚠️ **Important:** Always review what the script will remove before performing cleanup, especially when running it with `sudo`.

---

## ✨ Features

* 🛡️ **Safe Cleanup**
* 🧪 **`--dry-run` Mode**
* 📦 **APT Cleanup & Package Repair**
* 📝 **Journal / Log Cleanup**
* 🗑️ **Temporary Files Cleanup**
* 🌐 **Browser Cache Cleanup**
* 🐍 **Python / Pip Cache Cleanup**
* 🐳 **Docker Cleanup**
* 💾 **Large File Analysis**
* ⚡ **SSD / NVMe TRIM**
* 🩺 **SMART Disk Health Check**
* 🧠 **RAM & Swap Information**
* 🐧 **Kernel Security Check**
* 💥 **Crash Report Cleanup**
* 💾 **Maintenance State Backup**
* 📋 **Detailed Logs**
* 🚫 **Does Not Automatically Remove Active Kernels**

---

## 🚀 Installation

Clone the repository:

```bash
git clone https://github.com/spyschools/Linux-Cleaner.git
cd Linux-Cleaner
```

Make the script executable:

```bash
chmod +x Linux-Cleaner.sh
```

Run Linux Cleaner:

```bash
sudo ./Linux-Cleaner.sh
```

---

## ⚡ Install as a System Command

You can install Linux Cleaner as a system-wide command:

```bash
sudo install -m 755 Linux-Cleaner.sh /usr/local/bin/linux-cleaner
```

Then run it from anywhere:

```bash
sudo linux-cleaner
```

---

## 🧪 Dry Run

Preview the cleanup operations without applying changes:

```bash
sudo ./Linux-Cleaner.sh --dry-run
```

If installed system-wide:

```bash
sudo linux-cleaner --dry-run
```

> `--dry-run` is recommended before performing a full cleanup, especially on production systems.

---

## 🛡️ Safety Features

Linux Cleaner is designed to minimize the risk of accidental system damage.

The script:

* Performs safety checks before maintenance
* Supports `--dry-run`
* Checks for required commands
* Provides detailed logs
* Handles optional components gracefully
* Avoids automatically removing the active kernel
* Performs package repair operations when required
* Avoids blindly deleting critical system files

### 🚫 Kernel Protection

Linux Cleaner **does not automatically remove active/running kernels**.

This prevents the script from accidentally deleting the kernel currently being used by the system.

---

## 🧰 Maintenance Tasks

### 📦 APT

* Clean package cache
* Remove unnecessary packages
* Repair package configuration/state

### 📝 Journal & Logs

* Analyze system journal
* Remove old journal entries according to the configured cleanup policy
* Record maintenance activity

### 🗑️ Temporary Files

Clean unnecessary temporary files while avoiding critical system locations.

### 🌐 Browser Cache

Clean supported browser cache directories.

### 🐍 Python / Pip

Clean unnecessary Python/Pip cache data.

### 🐳 Docker

Detect and clean unused Docker resources when Docker is installed.

### 💾 Storage Analysis

Analyze large files and help identify what is consuming disk space.

### ⚡ SSD / NVMe

Run filesystem TRIM using `fstrim` when supported.

### 🩺 SMART Health

Check available SMART information using `smartctl`.

### 🧠 Memory

Display:

* RAM usage
* Available memory
* Swap usage

### 🐧 Kernel Security

Inspect the currently running and installed kernel information.

### 💥 Crash Reports

Clean unnecessary crash report files.

---

## 📋 Detailed Logs

Linux Cleaner provides detailed logging to make maintenance activity easier to review and troubleshoot.

Logs can show:

* Operations performed
* Operations skipped
* Detected system information
* Errors and warnings
* Cleanup results

---

## 💾 Maintenance State Backup

Linux Cleaner can preserve maintenance-related state information before performing operations.

This provides an additional layer of protection and makes it easier to understand the system's maintenance status.

---

## 💻 Supported Distributions

Linux Cleaner is primarily designed for **Debian-based Linux distributions**, including:

* Debian
* Ubuntu
* Linux Mint
* Kali Linux
* Other Debian-based distributions

Some features depend on the installed software, filesystem, hardware, and Linux distribution.

---

## 📋 Requirements

### Required

* Bash
* `sudo`
* Debian-based package manager (`apt`)
* `systemd` / `journalctl`

### Optional

The following tools are used when available:

* `docker`
* `smartctl`
* `lsblk`
* `fstrim`

Missing optional tools should not prevent the other maintenance functions from running.

---

## 🔐 Root Privileges

Some operations require administrator privileges.

Run Linux Cleaner with:

```bash
sudo linux-cleaner
```

or:

```bash
sudo ./Linux-Cleaner.sh
```

---

## 🖥️ Usage

Basic cleanup:

```bash
sudo linux-cleaner
```

Dry run:

```bash
sudo linux-cleaner --dry-run
```

Help:

```bash
sudo linux-cleaner --help
```

> Available options may depend on the version of Linux Cleaner installed.

---

## 📸 Example

```text
╔══════════════════════════════════════╗
║          🧹 LINUX CLEANER            ║
║      System Maintenance Tool         ║
╚══════════════════════════════════════╝

[✓] Checking system
[✓] Cleaning APT cache
[✓] Repairing package state
[✓] Cleaning journal logs
[✓] Cleaning temporary files
[✓] Cleaning browser cache
[✓] Cleaning Python/Pip cache
[✓] Checking Docker
[✓] Analyzing large files
[✓] Checking disk health
[✓] Checking RAM & swap
[✓] Checking kernel security
[✓] Running SSD/NVMe TRIM

[✓] Maintenance completed successfully.
```

---

## ⚠️ Disclaimer

Linux Cleaner is provided **as-is**, without warranty.

System cleanup can modify or remove files, packages, caches, logs, and other system resources.

Although Linux Cleaner is designed with safety in mind, users should understand the operations being performed before running the script.

**Use this software at your own risk.**

---

## 🤝 Contributing

Contributions, bug reports, feature requests, and improvements are welcome.

1. Fork the repository
2. Create a feature branch:

```bash
git checkout -b feature/my-feature
```

3. Commit your changes:

```bash
git commit -m "Add new feature"
```

4. Push the branch:

```bash
git push origin feature/my-feature
```

5. Open a Pull Request.

---

## 📄 License

This project is currently distributed without a specified license.

If you want others to freely use, modify, and distribute the project, consider adding an open-source license such as **MIT License**.

---

## ⭐ Support

If you find **Linux Cleaner** useful, please consider giving the repository a ⭐ **Star** on GitHub.

Repository:

**`spyschools/Linux-Cleaner`**

---

## 🧹 Linux Cleaner

**Simple. Safe. Powerful.**

Keep your Linux system **clean, healthy, and maintained.**
