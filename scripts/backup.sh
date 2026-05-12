#!/bin/bash
# =============================================================
# backup.sh - Automated Backup System
# DevOps Lab | Backs up folders with timestamp, logs results
# =============================================================

# ── Color Definitions ─────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Configuration ─────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
LOG_DIR="$PROJECT_ROOT/logs"
BACKUP_DIR="$PROJECT_ROOT/backup"
LOG_FILE="$LOG_DIR/backup.log"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M')
MAX_BACKUPS=10   # Keep only last 10 backups

# Default source directory (can be overridden by argument)
DEFAULT_SOURCE="$HOME/Documents"

# ── Setup ─────────────────────────────────────────────────────
mkdir -p "$LOG_DIR" "$BACKUP_DIR"

# ── Logging Function ──────────────────────────────────────────
log() {
    local level="$1"
    local message="$2"
    local log_entry="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message"
    echo "$log_entry" >> "$LOG_FILE"
    case "$level" in
        "SUCCESS") echo -e "  ${GREEN}✅ $message${RESET}" ;;
        "ERROR")   echo -e "  ${RED}❌ $message${RESET}" ;;
        "INFO")    echo -e "  ${CYAN}ℹ️  $message${RESET}" ;;
        "WARN")    echo -e "  ${YELLOW}⚠️  $message${RESET}" ;;
    esac
}

# ── Banner ────────────────────────────────────────────────────
print_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║          💾 AUTOMATED BACKUP SYSTEM                  ║"
    echo "║              Linux DevOps Lab v1.0                   ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

# ── Validate Source Directory ─────────────────────────────────
validate_source() {
    local src="$1"
    if [ ! -e "$src" ]; then
        log "ERROR" "Source path does not exist: $src"
        return 1
    fi
    return 0
}

# ── Perform Backup ────────────────────────────────────────────
perform_backup() {
    local source_dir="$1"
    local dir_name
    dir_name=$(basename "$source_dir")
    local backup_name="${dir_name}_backup_${TIMESTAMP}.tar.gz"
    local backup_path="$BACKUP_DIR/$backup_name"

    log "INFO" "Starting backup of: $source_dir"
    log "INFO" "Destination: $backup_path"

    echo ""
    echo -e "${YELLOW}${BOLD}▶ Creating Backup Archive...${RESET}"
    echo -e "${YELLOW}$(printf '─%.0s' {1..55})${RESET}"

    # Create compressed archive
    if tar -czf "$backup_path" -C "$(dirname "$source_dir")" "$(basename "$source_dir")" 2>/dev/null; then
        local size
        size=$(du -sh "$backup_path" | awk '{print $1}')
        log "SUCCESS" "Backup created: $backup_name (Size: $size)"
        echo -e "  ${GREEN}Archive:   ${BOLD}$backup_name${RESET}"
        echo -e "  ${GREEN}Size:      $size${RESET}"
        echo -e "  ${GREEN}Location:  $BACKUP_DIR${RESET}"
        return 0
    else
        log "ERROR" "Backup FAILED for: $source_dir"
        # Remove partial file if it exists
        [ -f "$backup_path" ] && rm -f "$backup_path"
        return 1
    fi
}

# ── Verify Backup Integrity ───────────────────────────────────
verify_backup() {
    local backup_path="$1"
    echo ""
    echo -e "${YELLOW}${BOLD}▶ Verifying Backup Integrity...${RESET}"
    echo -e "${YELLOW}$(printf '─%.0s' {1..55})${RESET}"

    if tar -tzf "$backup_path" &>/dev/null; then
        local file_count
        file_count=$(tar -tzf "$backup_path" | wc -l)
        log "SUCCESS" "Integrity check PASSED — $file_count files archived"
        echo -e "  ${GREEN}Files archived: $file_count${RESET}"
        echo -e "  ${GREEN}Integrity: ✅ VERIFIED${RESET}"
        return 0
    else
        log "ERROR" "Integrity check FAILED — backup may be corrupted"
        echo -e "  ${RED}Integrity: ❌ FAILED${RESET}"
        return 1
    fi
}

# ── Cleanup Old Backups ───────────────────────────────────────
cleanup_old_backups() {
    echo ""
    echo -e "${YELLOW}${BOLD}▶ Cleaning Up Old Backups...${RESET}"
    echo -e "${YELLOW}$(printf '─%.0s' {1..55})${RESET}"

    local count
    count=$(ls -1 "$BACKUP_DIR"/*.tar.gz 2>/dev/null | wc -l)

    if [ "$count" -gt "$MAX_BACKUPS" ]; then
        local to_delete=$((count - MAX_BACKUPS))
        log "INFO" "Removing $to_delete old backup(s) (keeping last $MAX_BACKUPS)"
        ls -1t "$BACKUP_DIR"/*.tar.gz | tail -n "$to_delete" | while read -r old_backup; do
            rm -f "$old_backup"
            log "INFO" "Deleted old backup: $(basename "$old_backup")"
            echo -e "  ${YELLOW}Removed: $(basename "$old_backup")${RESET}"
        done
    else
        echo -e "  ${GREEN}No cleanup needed ($count/$MAX_BACKUPS backups)${RESET}"
        log "INFO" "No old backups to clean (count: $count)"
    fi
}

# ── Show Backup History ───────────────────────────────────────
show_backup_history() {
    echo ""
    echo -e "${YELLOW}${BOLD}▶ Backup History${RESET}"
    echo -e "${YELLOW}$(printf '─%.0s' {1..55})${RESET}"

    if ls "$BACKUP_DIR"/*.tar.gz &>/dev/null; then
        echo -e "  ${CYAN}Recent backups (newest first):${RESET}"
        ls -lht "$BACKUP_DIR"/*.tar.gz 2>/dev/null | awk '{printf "  📦 %-40s %s %s\n", $9, $5, $6" "$7" "$8}' | \
            sed "s|$BACKUP_DIR/||"
    else
        echo -e "  ${YELLOW}No backups found in $BACKUP_DIR${RESET}"
    fi
}

# ── Create Demo Source if Needed ──────────────────────────────
create_demo_source() {
    local demo_dir="$PROJECT_ROOT/demo_source"
    mkdir -p "$demo_dir"
    echo "Sample config file" > "$demo_dir/config.txt"
    echo "Sample data" > "$demo_dir/data.csv"
    mkdir -p "$demo_dir/subdir"
    echo "Nested file" > "$demo_dir/subdir/nested.txt"
    echo "$demo_dir"
}

# ── Main ──────────────────────────────────────────────────────
main() {
    print_banner
    log "INFO" "Backup script started by $(whoami)"

    # Determine source directory
    local source_dir="${1:-}"

    if [ -z "$source_dir" ]; then
        # Use default or create demo directory
        if [ -d "$DEFAULT_SOURCE" ]; then
            source_dir="$DEFAULT_SOURCE"
            log "INFO" "Using default source: $DEFAULT_SOURCE"
        else
            log "WARN" "Default source $DEFAULT_SOURCE not found. Using demo directory."
            source_dir=$(create_demo_source)
            echo -e "${YELLOW}  ⚠️  Using demo directory: $source_dir${RESET}"
        fi
    fi

    echo -e "${CYAN}  Source:    ${BOLD}$source_dir${RESET}"
    echo -e "${CYAN}  Backup To: ${BOLD}$BACKUP_DIR${RESET}"
    echo -e "${CYAN}  Timestamp: ${BOLD}$TIMESTAMP${RESET}"

    # Validate
    if ! validate_source "$source_dir"; then
        echo -e "${RED}  ❌ Backup aborted — source not found${RESET}"
        exit 1
    fi

    # Backup
    if perform_backup "$source_dir"; then
        local backup_name
        backup_name="${BACKUP_DIR}/$(basename "$source_dir")_backup_${TIMESTAMP}.tar.gz"

        # Verify
        verify_backup "$backup_name"

        # Cleanup
        cleanup_old_backups

        # History
        show_backup_history

        echo ""
        echo -e "${CYAN}$(printf '═%.0s' {1..55})${RESET}"
        echo -e "${GREEN}${BOLD}  🎉 BACKUP COMPLETED SUCCESSFULLY at $(date '+%H:%M:%S')${RESET}"
        echo -e "${CYAN}$(printf '═%.0s' {1..55})${RESET}"
        log "SUCCESS" "Backup process completed successfully"
    else
        echo ""
        echo -e "${CYAN}$(printf '═%.0s' {1..55})${RESET}"
        echo -e "${RED}${BOLD}  ❌ BACKUP FAILED — Check logs at: $LOG_FILE${RESET}"
        echo -e "${CYAN}$(printf '═%.0s' {1..55})${RESET}"
        log "ERROR" "Backup process FAILED"
        exit 1
    fi

    echo -e "${MAGENTA}  📝 Log saved to: $LOG_FILE${RESET}"
}

# ── Usage Help ────────────────────────────────────────────────
usage() {
    echo "Usage: $0 [source_directory]"
    echo ""
    echo "  source_directory  Path to backup (default: ~/Documents)"
    echo ""
    echo "Examples:"
    echo "  $0                         # Backup ~/Documents"
    echo "  $0 /home/user/projects     # Backup specific folder"
    echo "  $0 /etc                    # Backup /etc configs"
}

# ── Entry Point ───────────────────────────────────────────────
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    usage
    exit 0
fi

main "$@"
