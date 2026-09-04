#!/usr/bin/env bash
# ============================================================
# KaliCleaner v3
# Universal English Edition
# Safe maintenance utility for Kali Linux / Debian-based OS
#
# Usage:
#   sudo ./KaliCleaner-v3.sh
#   sudo ./KaliCleaner-v3.sh --dry-run
#   sudo ./KaliCleaner-v3.sh --full
#   sudo ./KaliCleaner-v3.sh --info
#   sudo ./KaliCleaner-v3.sh --help
# ============================================================

set -Eeuo pipefail
IFS=$'\n\t'

VERSION="3.0"
SCRIPT_NAME="Linux-Cleaner"
LOG_FILE="/var/log/kalicleaner-v3.log"
BACKUP_DIR="/var/backups/kalicleaner-v3"
DRY_RUN=0

# Terminal colors
RESET='\033[0m'
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'

setup_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    chmod 600 "$LOG_FILE"
}

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

info() {
    printf '%b[INFO]%b %s\n' "$BLUE" "$RESET" "$*"
    log "[INFO] $*"
}

success() {
    printf '%b[ OK ]%b %s\n' "$GREEN" "$RESET" "$*"
    log "[ OK ] $*"
}

warning() {
    printf '%b[WARN]%b %s\n' "$YELLOW" "$RESET" "$*"
    log "[WARN] $*"
}

error() {
    printf '%b[ERR ]%b %s\n' "$RED" "$RESET" "$*"
    log "[ERR ] $*"
}

run_cmd() {
    if (( DRY_RUN )); then
        printf '%b[DRY ]%b ' "$MAGENTA" "$RESET"
        printf '%q ' "$@"
        printf '\n'
        log "[DRY] $*"
    else
        "$@"
    fi
}

require_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This program must be run as root."
        echo "Use: sudo $0"
        exit 1
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

pause_screen() {
    echo
    read -r -p "Press Enter to continue..." _
}

confirm() {
    local prompt="${1:-Continue?}"
    local answer
    read -r -p "$prompt [y/N]: " answer
    [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]
}

header() {
    clear
    printf '%b' "$CYAN"
    echo "============================================================"
    echo "                    LINUX CLEANER v$VERSION"
    echo "============================================================"
    printf '%b' "$RESET"
    echo "Universal English Edition | Safe System Maintenance"
    if (( DRY_RUN )); then
        printf '%b\n' "${MAGENTA}DRY-RUN MODE: no changes will be made.${RESET}"
    fi
    echo
}

os_info() {
    local pretty="Unknown"
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        pretty="${PRETTY_NAME:-Unknown}"
    fi
    printf 'OS             : %s\n' "$pretty"
    printf 'Kernel         : %s\n' "$(uname -r)"
    printf 'Architecture   : %s\n' "$(uname -m)"
    printf 'Hostname       : %s\n' "$(hostname)"
    printf 'Uptime         : %s\n' "$(uptime -p 2>/dev/null || true)"
}

show_disk_usage() {
    echo "------------------------------------------------------------"
    echo "DISK USAGE"
    echo "------------------------------------------------------------"
    df -hT /
    echo
    df -hT /home 2>/dev/null || true
}

show_memory_usage() {
    echo "------------------------------------------------------------"
    echo "MEMORY / SWAP"
    echo "------------------------------------------------------------"
    free -h
    echo
    swapon --show 2>/dev/null || true
}

system_info() {
    header
    echo "SYSTEM INFORMATION"
    echo "------------------------------------------------------------"
    os_info
    echo
    show_disk_usage
    echo
    show_memory_usage
}

record_free_space() {
    df -B1 / | awk 'NR==2 {print $4}'
}

human_bytes() {
    numfmt --to=iec --suffix=B "$1" 2>/dev/null || echo "$1 bytes"
}

backup_package_state() {
    mkdir -p "$BACKUP_DIR"
    local stamp
    stamp="$(date '+%Y%m%d-%H%M%S')"

    if command_exists dpkg-query; then
        dpkg-query -W -f='${binary:Package}\t${Version}\n' \
            > "$BACKUP_DIR/packages-$stamp.txt" 2>/dev/null || true
    fi

    if [[ -f /etc/fstab ]]; then
        cp -a /etc/fstab "$BACKUP_DIR/fstab-$stamp" 2>/dev/null || true
    fi

    if [[ -f /etc/apt/sources.list ]]; then
        cp -a /etc/apt/sources.list "$BACKUP_DIR/sources.list-$stamp" 2>/dev/null || true
    fi

    if [[ -d /etc/apt/sources.list.d ]]; then
        tar -czf "$BACKUP_DIR/apt-sources-$stamp.tar.gz" \
            -C /etc/apt sources.list.d 2>/dev/null || true
    fi

    success "Maintenance state backup created: $BACKUP_DIR"
}

apt_cleanup() {
    echo "------------------------------------------------------------"
    echo "APT CLEANUP"
    echo "------------------------------------------------------------"

    backup_package_state
    info "Cleaning APT package cache..."
    run_cmd apt-get clean
    run_cmd apt-get autoclean -y

    info "Removing automatically installed packages no longer required..."
    run_cmd apt-get autoremove --purge -y

    success "APT cleanup completed."
}

repair_packages() {
    echo "------------------------------------------------------------"
    echo "PACKAGE REPAIR"
    echo "------------------------------------------------------------"

    info "Configuring pending packages..."
    if (( DRY_RUN )); then
        run_cmd dpkg --configure -a
    else
        dpkg --configure -a || warning "dpkg reported an issue; continuing."
    fi

    info "Repairing dependency problems..."
    if (( DRY_RUN )); then
        run_cmd apt-get -f install -y
    else
        apt-get -f install -y || warning "APT dependency repair reported an issue."
    fi

    success "Package repair step completed."
}

journal_cleanup() {
    echo "------------------------------------------------------------"
    echo "SYSTEMD JOURNAL CLEANUP"
    echo "------------------------------------------------------------"

    if ! command_exists journalctl; then
        warning "journalctl is not available."
        return
    fi

    info "Current journal usage:"
    journalctl --disk-usage 2>/dev/null || true

    echo
    info "Vacuuming journal entries older than 7 days..."
    run_cmd journalctl --vacuum-time=7d

    success "Journal cleanup completed."
}

old_log_cleanup() {
    echo "------------------------------------------------------------"
    echo "OLD LOG CLEANUP"
    echo "------------------------------------------------------------"

    info "Removing compressed/old logs older than 30 days..."
    if (( DRY_RUN )); then
        find /var/log -type f \
            \( -name '*.gz' -o -name '*.old' \) \
            -mtime +30 -print 2>/dev/null || true
    else
        find /var/log -type f \
            \( -name '*.gz' -o -name '*.old' \) \
            -mtime +30 -delete 2>/dev/null || true
    fi

    success "Old log cleanup completed."
}

temp_cleanup() {
    echo "------------------------------------------------------------"
    echo "TEMPORARY FILE CLEANUP"
    echo "------------------------------------------------------------"

    info "Removing files that have not been accessed recently."

    if (( DRY_RUN )); then
        find /tmp -xdev -type f -atime +3 -print 2>/dev/null || true
        find /var/tmp -xdev -type f -atime +7 -print 2>/dev/null || true
    else
        find /tmp -xdev -type f -atime +3 -delete 2>/dev/null || true
        find /var/tmp -xdev -type f -atime +7 -delete 2>/dev/null || true
    fi

    success "Temporary file cleanup completed."
}

user_cache_cleanup() {
    echo "------------------------------------------------------------"
    echo "USER CACHE CLEANUP"
    echo "------------------------------------------------------------"

    local homes=(/root /home/*)
    local home_dir

    for home_dir in "${homes[@]}"; do
        [[ -d "$home_dir" ]] || continue
        [[ -d "$home_dir/.cache" ]] || continue

        info "Cleaning cache: $home_dir/.cache"

        if (( DRY_RUN )); then
            find "$home_dir/.cache" -mindepth 1 -maxdepth 1 -print 2>/dev/null || true
        else
            find "$home_dir/.cache" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + 2>/dev/null || true
        fi
    done

    success "User cache cleanup completed."
}

browser_cache_cleanup() {
    echo "------------------------------------------------------------"
    echo "BROWSER CACHE CLEANUP"
    echo "------------------------------------------------------------"

    local homes=(/root /home/*)
    local home_dir

    for home_dir in "${homes[@]}"; do
        [[ -d "$home_dir" ]] || continue

        info "Checking browser caches under $home_dir"

        local targets=(
            "$home_dir/.mozilla/firefox/*/cache2"
            "$home_dir/.cache/mozilla/firefox"
            "$home_dir/.cache/chromium"
            "$home_dir/.config/chromium/*/Cache"
            "$home_dir/.config/google-chrome/*/Cache"
            "$home_dir/.cache/google-chrome"
        )

        local target
        for target in "${targets[@]}"; do
            if (( DRY_RUN )); then
                compgen -G "$target" >/dev/null 2>&1 || continue
                printf '%s\n' "$target"
            else
                # Use glob expansion only after existence check.
                for expanded in $target; do
                    [[ -e "$expanded" ]] || continue
                    rm -rf -- "$expanded" 2>/dev/null || true
                done
            fi
        done
    done

    success "Browser cache cleanup completed."
}

thumbnail_cleanup() {
    echo "------------------------------------------------------------"
    echo "THUMBNAIL CACHE CLEANUP"
    echo "------------------------------------------------------------"

    local homes=(/root /home/*)
    local home_dir

    for home_dir in "${homes[@]}"; do
        [[ -d "$home_dir/.cache/thumbnails" ]] || continue
        info "Cleaning thumbnails: $home_dir"

        if (( DRY_RUN )); then
            find "$home_dir/.cache/thumbnails" -type f -print 2>/dev/null || true
        else
            find "$home_dir/.cache/thumbnails" -type f -delete 2>/dev/null || true
        fi
    done

    success "Thumbnail cleanup completed."
}

python_cleanup() {
    echo "------------------------------------------------------------"
    echo "PYTHON / PIP CACHE CLEANUP"
    echo "------------------------------------------------------------"

    info "Removing Python bytecode caches from common writable/system locations."

    local roots=(/root /home /opt /usr/local)
    local root_dir

    for root_dir in "${roots[@]}"; do
        [[ -d "$root_dir" ]] || continue

        if (( DRY_RUN )); then
            find "$root_dir" -type d -name '__pycache__' -prune -print 2>/dev/null || true
            find "$root_dir" -type f -name '*.pyc' -print 2>/dev/null || true
        else
            find "$root_dir" -type d -name '__pycache__' -prune -exec rm -rf -- {} + 2>/dev/null || true
            find "$root_dir" -type f -name '*.pyc' -delete 2>/dev/null || true
        fi
    done

    if command_exists pip3; then
        info "Cleaning pip cache..."
        run_cmd pip3 cache purge
    fi

    success "Python/Pip cleanup completed."
}

docker_cleanup() {
    echo "------------------------------------------------------------"
    echo "DOCKER CLEANUP"
    echo "------------------------------------------------------------"

    if ! command_exists docker; then
        warning "Docker is not installed."
        return
    fi

    info "Docker disk usage:"
    docker system df 2>/dev/null || true

    if (( DRY_RUN )); then
        info "Dry-run: Docker prune was not executed."
        return
    fi

    if confirm "Remove unused Docker containers, networks, images and build cache?"; then
        docker system prune -f
        success "Docker cleanup completed."
    else
        warning "Docker cleanup skipped."
    fi
}

kernel_check() {
    echo "------------------------------------------------------------"
    echo "KERNEL SAFETY CHECK"
    echo "------------------------------------------------------------"

    local current
    current="$(uname -r)"

    echo "Running kernel: $current"
    echo
    echo "Installed kernel packages:"
    dpkg-query -W -f='${binary:Package}\t${Version}\n' 'linux-image-*' \
        2>/dev/null | grep -E '^linux-image-[0-9]' || true

    echo
    warning "Automatic kernel removal is intentionally disabled."
    echo "Remove old kernels manually only after confirming the running kernel"
    echo "and keeping at least one known-good fallback kernel."
}

crash_cleanup() {
    echo "------------------------------------------------------------"
    echo "CRASH REPORT CLEANUP"
    echo "------------------------------------------------------------"

    if [[ ! -d /var/crash ]]; then
        info "No /var/crash directory found."
        return
    fi

    info "Removing crash reports older than 14 days."

    if (( DRY_RUN )); then
        find /var/crash -type f -mtime +14 -print 2>/dev/null || true
    else
        find /var/crash -type f -mtime +14 -delete 2>/dev/null || true
    fi

    success "Crash report cleanup completed."
}

large_files() {
    echo "------------------------------------------------------------"
    echo "LARGE FILE ANALYZER"
    echo "------------------------------------------------------------"
    echo "Files larger than 500 MiB under /var and /home:"
    echo

    if ! command_exists numfmt; then
        find /var /home -xdev -type f -size +500M \
            -printf '%s %p\n' 2>/dev/null | sort -nr | head -20
        return
    fi

    find /var /home -xdev -type f -size +500M \
        -printf '%s %p\n' 2>/dev/null |
        sort -nr |
        head -20 |
        numfmt --field=1 --to=iec
}

trim_ssd() {
    echo "------------------------------------------------------------"
    echo "SSD / NVMe TRIM"
    echo "------------------------------------------------------------"

    if ! command_exists fstrim; then
        warning "fstrim is not installed."
        return
    fi

    info "Checking mounted filesystems eligible for TRIM..."
    findmnt -rn -t ext4,ext3,xfs,btrfs,f2fs 2>/dev/null || true
    echo

    if (( DRY_RUN )); then
        info "Dry-run: fstrim was not executed."
        return
    fi

    if confirm "Run fstrim on the root filesystem?"; then
        fstrim -v /
        success "TRIM command completed for /."
    else
        warning "TRIM skipped."
    fi
}

smart_health() {
    echo "------------------------------------------------------------"
    echo "DISK SMART HEALTH"
    echo "------------------------------------------------------------"

    if ! command_exists smartctl; then
        warning "smartctl is not installed."
        echo "Install with: apt install smartmontools"
        return
    fi

    local disks=()
    while read -r name type; do
        [[ "$type" == "disk" ]] || continue
        disks+=("/dev/$name")
    done < <(lsblk -dn -o NAME,TYPE 2>/dev/null)

    if ((${#disks[@]} == 0)); then
        warning "No physical disks detected."
        return
    fi

    local disk
    for disk in "${disks[@]}"; do
        echo
        echo "Device: $disk"
        smartctl -H "$disk" 2>/dev/null || warning "SMART health could not be read for $disk."
    done
}

full_cleanup() {
    echo "============================================================"
    echo "FULL SAFE CLEANUP"
    echo "============================================================"
    echo
    warning "This performs the non-destructive cleanup operations."
    echo "It does NOT remove the active kernel or personal documents."
    echo

    if (( ! DRY_RUN )); then
        confirm "Continue with full cleanup?" || {
            warning "Full cleanup cancelled."
            return
        }
    fi

    local before after freed
    before="$(record_free_space)"

    apt_cleanup
    repair_packages
    journal_cleanup
    old_log_cleanup
    temp_cleanup
    user_cache_cleanup
    browser_cache_cleanup
    thumbnail_cleanup
    python_cleanup
    crash_cleanup

    sync

    after="$(record_free_space)"
    freed=$((after - before))

    echo
    echo "============================================================"
    echo "CLEANUP SUMMARY"
    echo "============================================================"

    if (( DRY_RUN )); then
        echo "Mode: DRY-RUN"
        echo "No changes were made."
    elif (( freed > 0 )); then
        echo "Estimated additional free space: $(human_bytes "$freed")"
    else
        echo "Estimated additional free space: 0 B"
    fi

    success "Full safe cleanup completed."
}

show_help() {
    cat <<EOF
$SCRIPT_NAME v$VERSION

Usage:
  sudo $0                  Interactive menu
  sudo $0 --dry-run        Preview cleanup actions
  sudo $0 --full           Run full safe cleanup
  sudo $0 --info           Show system information
  sudo $0 --help           Show this help

Options:
  --dry-run                Do not modify the system
  --full                   Run the full safe cleanup
  --info                   Show disk, memory and OS information
  --help                   Show this help

Log:
  $LOG_FILE

Backup:
  $BACKUP_DIR
EOF
}

menu() {
    while true; do
        header

        echo " 1. System Information"
        echo " 2. Disk Usage"
        echo " 3. Memory / Swap"
        echo " 4. APT Cleanup"
        echo " 5. Package Repair"
        echo " 6. Journal Cleanup"
        echo " 7. Old Log Cleanup"
        echo " 8. Temporary Files"
        echo " 9. User Cache"
        echo "10. Browser Cache"
        echo "11. Thumbnail Cache"
        echo "12. Python / Pip Cache"
        echo "13. Docker Cleanup"
        echo "14. Kernel Safety Check"
        echo "15. Crash Reports"
        echo "16. Large File Analyzer"
        echo "17. SSD / NVMe TRIM"
        echo "18. SMART Disk Health"
        echo "19. FULL SAFE CLEANUP"
        echo " 0. Exit"
        echo

        read -r -p "Select an option: " option

        case "$option" in
            1) system_info; pause_screen ;;
            2) header; show_disk_usage; pause_screen ;;
            3) header; show_memory_usage; pause_screen ;;
            4) header; apt_cleanup; pause_screen ;;
            5) header; repair_packages; pause_screen ;;
            6) header; journal_cleanup; pause_screen ;;
            7) header; old_log_cleanup; pause_screen ;;
            8) header; temp_cleanup; pause_screen ;;
            9) header; user_cache_cleanup; pause_screen ;;
            10) header; browser_cache_cleanup; pause_screen ;;
            11) header; thumbnail_cleanup; pause_screen ;;
            12) header; python_cleanup; pause_screen ;;
            13) header; docker_cleanup; pause_screen ;;
            14) header; kernel_check; pause_screen ;;
            15) header; crash_cleanup; pause_screen ;;
            16) header; large_files; pause_screen ;;
            17) header; trim_ssd; pause_screen ;;
            18) header; smart_health; pause_screen ;;
            19) header; full_cleanup; pause_screen ;;
            0) success "Goodbye."; exit 0 ;;
            *) warning "Invalid option."; sleep 1 ;;
        esac
    done
}

main() {
    require_root
    setup_logging

    case "${1:-}" in
        --dry-run)
            DRY_RUN=1
            menu
            ;;
        --full)
            full_cleanup
            ;;
        --info)
            system_info
            ;;
        --help|-h)
            show_help
            ;;
        "")
            menu
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 2
            ;;
    esac
}

main "$@"
