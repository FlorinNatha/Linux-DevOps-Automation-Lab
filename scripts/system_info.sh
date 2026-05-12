#!/bin/bash
# =============================================================
# system_info.sh - System Information & Performance Monitor
# DevOps Lab | Author: DevOps Student
# =============================================================

# ── Color Definitions ─────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Configuration ─────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../logs"
LOG_FILE="$LOG_DIR/system.log"

# ── Ensure log directory exists ───────────────────────────────
mkdir -p "$LOG_DIR"

# ── Logging Function ──────────────────────────────────────────
log() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$LOG_FILE"
}

# ── Banner ────────────────────────────────────────────────────
print_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║          🖥️  SYSTEM INFORMATION MONITOR              ║"
    echo "║              Linux DevOps Lab v1.0                   ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

# ── Section Header ────────────────────────────────────────────
section() {
    echo -e "${YELLOW}${BOLD}▶ $1${RESET}"
    echo -e "${YELLOW}$(printf '─%.0s' {1..55})${RESET}"
}

# ── Get CPU Usage ─────────────────────────────────────────────
get_cpu_usage() {
    # Calculate CPU usage over 1-second interval
    local cpu_idle
    cpu_idle=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | tr -d '%')
    if [ -z "$cpu_idle" ]; then
        cpu_idle=$(top -bn1 | grep "%Cpu" | awk '{print $8}')
    fi
    local cpu_usage
    cpu_usage=$(echo "100 - $cpu_idle" | bc 2>/dev/null || echo "N/A")
    echo "${cpu_usage}%"
}

# ── Get Memory Info ───────────────────────────────────────────
get_memory_info() {
    local total used free usage_pct
    total=$(free -m | awk '/^Mem:/ {print $2}')
    used=$(free -m | awk '/^Mem:/ {print $3}')
    free=$(free -m | awk '/^Mem:/ {print $4}')
    usage_pct=$(free | awk '/^Mem:/ {printf("%.1f", $3/$2 * 100)}')
    echo "Total: ${total}MB | Used: ${used}MB | Free: ${free}MB | Usage: ${usage_pct}%"
}

# ── Get Disk Usage ────────────────────────────────────────────
get_disk_usage() {
    df -h / | awk 'NR==2 {print "Total: "$2" | Used: "$3" | Free: "$4" | Usage: "$5}'
}

# ── Get Top Processes ─────────────────────────────────────────
get_top_processes() {
    ps aux --sort=-%cpu | head -6 | awk 'NR>1 {printf "  %-20s CPU: %-6s MEM: %-6s\n", $11, $3, $4}'
}

# ── Main Display Function ─────────────────────────────────────
display_system_info() {
    print_banner
    local timestamp
    timestamp=$(date '+%A %B %d, %Y %H:%M:%S')

    # ── Basic System Info ──────────────────────────────────────
    section "👤 User & System"
    echo -e "  ${GREEN}User:${RESET}        $(whoami)"
    echo -e "  ${GREEN}Hostname:${RESET}    $(hostname)"
    echo -e "  ${GREEN}Date/Time:${RESET}   $timestamp"
    echo -e "  ${GREEN}OS:${RESET}          $(uname -o) | Kernel: $(uname -r)"
    echo -e "  ${GREEN}Uptime:${RESET}      $(uptime -p 2>/dev/null || uptime | awk -F',' '{print $1}' | awk '{print $3, $4}')"
    echo ""

    # ── CPU Info ──────────────────────────────────────────────
    section "⚡ CPU Performance"
    local cpu_model
    cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | awk -F': ' '{print $2}' 2>/dev/null || echo "Unknown")
    local cpu_cores
    cpu_cores=$(nproc 2>/dev/null || grep -c processor /proc/cpuinfo)
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed 's/.*, *\([0-9.]*\)%* id.*/\1/' | awk '{printf "%.1f", 100-$1}')
    echo -e "  ${GREEN}Model:${RESET}       $cpu_model"
    echo -e "  ${GREEN}Cores:${RESET}       $cpu_cores vCPU(s)"
    echo -e "  ${GREEN}Usage:${RESET}       ${cpu_usage}%"
    echo -e "  ${GREEN}Load Avg:${RESET}    $(cat /proc/loadavg | awk '{print $1, $2, $3}') (1m, 5m, 15m)"
    echo ""

    # ── Memory Info ───────────────────────────────────────────
    section "🧠 Memory Usage"
    local mem_info
    mem_info=$(get_memory_info)
    echo -e "  ${GREEN}RAM:${RESET}         $mem_info"
    local swap_total swap_used
    swap_total=$(free -m | awk '/^Swap:/ {print $2}')
    swap_used=$(free -m | awk '/^Swap:/ {print $3}')
    echo -e "  ${GREEN}Swap:${RESET}        Total: ${swap_total}MB | Used: ${swap_used}MB"
    echo ""

    # ── Disk Usage ────────────────────────────────────────────
    section "💾 Disk Usage"
    echo -e "  ${GREEN}Root (/):${RESET}    $(get_disk_usage)"
    echo ""
    echo -e "  ${CYAN}All Mounted Filesystems:${RESET}"
    df -h --exclude-type=tmpfs --exclude-type=devtmpfs 2>/dev/null | \
        awk 'NR>1 {printf "  %-15s %-8s %-8s %-8s %s\n", $6, $2, $3, $4, $5}'
    echo ""

    # ── Network Info ──────────────────────────────────────────
    section "🌐 Network"
    echo -e "  ${GREEN}Interfaces:${RESET}"
    ip addr show 2>/dev/null | grep -E "^[0-9]+:|inet " | \
        awk '/^[0-9]+:/{iface=$2} /inet /{printf "  %-15s %s\n", iface, $2}' || \
        ifconfig 2>/dev/null | grep -E "^[a-z]|inet " | head -10
    echo ""

    # ── Top Processes ─────────────────────────────────────────
    section "📊 Top CPU Processes"
    echo -e "${CYAN}$(get_top_processes)${RESET}"
    echo ""

    # ── Running Services ──────────────────────────────────────
    section "🔄 System Stats"
    local proc_count
    proc_count=$(ps aux | wc -l)
    local logged_users
    logged_users=$(who | wc -l)
    echo -e "  ${GREEN}Running Processes:${RESET} $proc_count"
    echo -e "  ${GREEN}Logged-in Users:${RESET}   $logged_users"
    echo -e "  ${GREEN}Last Reboot:${RESET}       $(who -b 2>/dev/null | awk '{print $3, $4}' || uptime | awk '{print $3}')"
    echo ""

    echo -e "${CYAN}$(printf '═%.0s' {1..55})${RESET}"
    echo -e "${GREEN}${BOLD}  ✅ System info collected at: $(date '+%Y-%m-%d %H:%M:%S')${RESET}"
    echo -e "${CYAN}$(printf '═%.0s' {1..55})${RESET}"
}

# ── Run & Log ─────────────────────────────────────────────────
log "INFO" "System info script started by $(whoami)"

display_system_info

# Save summary to log
{
    echo "--- System Info Snapshot: $(date) ---"
    echo "User: $(whoami) | Host: $(hostname)"
    echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
    echo "CPU Load: $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
    echo "Memory: $(get_memory_info)"
    echo "Disk: $(get_disk_usage)"
    echo "---"
} >> "$LOG_FILE"

log "INFO" "System info script completed successfully"
echo -e "${MAGENTA}  📝 Log saved to: $LOG_FILE${RESET}"
