#!/bin/bash
# =============================================================
# process_monitor.sh - Process Monitoring Script
# DevOps Lab | Monitor CPU/Memory processes, filter, and log
# =============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; BLUE='\033[0;34m'
WHITE='\033[1;37m'; BOLD='\033[1m'; RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../logs"
LOG_FILE="$LOG_DIR/process.log"
mkdir -p "$LOG_DIR"

# Alert thresholds
CPU_ALERT_THRESHOLD=80
MEM_ALERT_THRESHOLD=80

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [PROC-MON] [$1] $2" >> "$LOG_FILE"
}

print_banner() {
    clear
    echo -e "${MAGENTA}${BOLD}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║          📊 PROCESS MONITOR DASHBOARD                ║"
    echo "║              Linux DevOps Lab v1.0                   ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

section() { echo -e "\n${YELLOW}${BOLD}▶ $1${RESET}\n${YELLOW}$(printf '─%.0s' {1..60})${RESET}"; }

# ── Top CPU Processes ─────────────────────────────────────────
show_top_cpu() {
    section "⚡ Top 10 CPU-Intensive Processes"
    printf "  ${WHITE}${BOLD}%-8s %-20s %-8s %-8s %-s${RESET}\n" "PID" "PROCESS" "CPU%" "MEM%" "USER"
    printf "  $(printf '─%.0s' {1..60})\n"
    ps aux --sort=-%cpu | awk 'NR>1 && NR<=11 {
        printf "  \033[0;36m%-8s %-20s %-8s %-8s %-s\033[0m\n", $2, substr($11,1,20), $3, $4, $1
    }'

    # Alert check
    local top_cpu
    top_cpu=$(ps aux --sort=-%cpu | awk 'NR==2 {print int($3)}')
    if [ "$top_cpu" -ge "$CPU_ALERT_THRESHOLD" ] 2>/dev/null; then
        echo -e "\n  ${RED}${BOLD}🚨 ALERT: High CPU usage detected! Top process: ${top_cpu}%${RESET}"
        log "ALERT" "High CPU usage: ${top_cpu}% — threshold: ${CPU_ALERT_THRESHOLD}%"
    fi
    log "INFO" "Top CPU processes displayed"
}

# ── Top Memory Processes ──────────────────────────────────────
show_top_memory() {
    section "🧠 Top 10 Memory-Intensive Processes"
    printf "  ${WHITE}${BOLD}%-8s %-20s %-10s %-8s %-s${RESET}\n" "PID" "PROCESS" "MEM%" "VSZ(KB)" "USER"
    printf "  $(printf '─%.0s' {1..60})\n"
    ps aux --sort=-%mem | awk 'NR>1 && NR<=11 {
        printf "  \033[0;32m%-8s %-20s %-10s %-8s %-s\033[0m\n", $2, substr($11,1,20), $4, $5, $1
    }'

    # Memory usage overview
    echo ""
    local mem_used_pct
    mem_used_pct=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2*100}')
    echo -e "  ${CYAN}Total System Memory Usage: ${mem_used_pct}%${RESET}"
    if [ "$mem_used_pct" -ge "$MEM_ALERT_THRESHOLD" ] 2>/dev/null; then
        echo -e "  ${RED}${BOLD}🚨 ALERT: High memory usage! (${mem_used_pct}%)${RESET}"
        log "ALERT" "High memory usage: ${mem_used_pct}% — threshold: ${MEM_ALERT_THRESHOLD}%"
    fi
    log "INFO" "Top memory processes displayed"
}

# ── Filter by Process Name ────────────────────────────────────
filter_process() {
    section "🔍 Filter Process by Name"
    echo -ne "${CYAN}  Enter process name to search: ${RESET}"; read -r proc_name

    if [ -z "$proc_name" ]; then
        echo -e "${RED}  ❌ No process name provided${RESET}"; return 1
    fi

    local results
    results=$(ps aux | grep -i "$proc_name" | grep -v grep)

    if [ -z "$results" ]; then
        echo -e "${YELLOW}  ⚠️  No process matching '$proc_name' found${RESET}"
        log "INFO" "Filter search: '$proc_name' — no matches"
    else
        local count; count=$(echo "$results" | wc -l)
        echo -e "${GREEN}  ✅ Found $count process(es) matching '$proc_name':${RESET}\n"
        printf "  ${WHITE}${BOLD}%-8s %-20s %-6s %-6s %-s${RESET}\n" "PID" "COMMAND" "CPU%" "MEM%" "STATUS"
        printf "  $(printf '─%.0s' {1..60})\n"
        echo "$results" | awk '{printf "  \033[0;32m%-8s %-20s %-6s %-6s %-s\033[0m\n", $2, substr($11,1,20), $3, $4, $8}'
        log "INFO" "Filter search: '$proc_name' — $count match(es)"
    fi
}

# ── Process Statistics ────────────────────────────────────────
show_stats() {
    section "📈 Process Statistics"
    local total running sleeping zombie
    total=$(ps aux | wc -l)
    running=$(ps aux | awk '$8=="R"' | wc -l)
    sleeping=$(ps aux | awk '$8~/S/' | wc -l)
    zombie=$(ps aux | awk '$8=="Z"' | wc -l)

    echo -e "  ${GREEN}Total Processes:    $total${RESET}"
    echo -e "  ${CYAN}Running (R):        $running${RESET}"
    echo -e "  ${YELLOW}Sleeping (S):       $sleeping${RESET}"
    if [ "$zombie" -gt 0 ]; then
        echo -e "  ${RED}Zombie (Z):         $zombie  ⚠️${RESET}"
        log "WARN" "Zombie processes detected: $zombie"
    else
        echo -e "  ${GREEN}Zombie (Z):         $zombie ✅${RESET}"
    fi

    echo ""
    section "💻 System Load"
    echo -e "  ${CYAN}Load Average (1/5/15 min): $(cat /proc/loadavg | awk '{print $1, $2, $3}')${RESET}"
    echo -e "  ${CYAN}CPU Cores: $(nproc)${RESET}"

    local load1; load1=$(cat /proc/loadavg | awk '{print $1}')
    local cores; cores=$(nproc)
    echo -e "  ${CYAN}Load per core: $(echo "$load1 $cores" | awk '{printf "%.2f", $1/$2}')${RESET}"
    log "INFO" "Process stats displayed: total=$total running=$running zombie=$zombie"
}

# ── Kill a Process ────────────────────────────────────────────
kill_process() {
    section "💀 Kill a Process"
    echo -ne "${CYAN}  Enter PID or process name: ${RESET}"; read -r proc_input

    if [[ "$proc_input" =~ ^[0-9]+$ ]]; then
        # Kill by PID
        if ps -p "$proc_input" &>/dev/null; then
            local proc_name; proc_name=$(ps -p "$proc_input" -o comm= 2>/dev/null)
            echo -ne "${RED}  Kill PID $proc_input ($proc_name)? (yes/no): ${RESET}"; read -r confirm
            if [ "$confirm" == "yes" ]; then
                if kill "$proc_input" 2>/dev/null; then
                    echo -e "${GREEN}  ✅ Process $proc_input killed${RESET}"
                    log "SUCCESS" "Killed PID $proc_input ($proc_name) by $(whoami)"
                else
                    echo -e "${RED}  ❌ Failed — try with sudo${RESET}"
                fi
            else
                echo -e "${YELLOW}  ↩️  Cancelled${RESET}"
            fi
        else
            echo -e "${RED}  ❌ PID $proc_input not found${RESET}"
        fi
    else
        # Kill by name
        local pids; pids=$(pgrep -x "$proc_input" 2>/dev/null)
        if [ -z "$pids" ]; then
            echo -e "${YELLOW}  ⚠️  No process named '$proc_input' found${RESET}"
        else
            echo -e "${CYAN}  PIDs found: $pids${RESET}"
            echo -ne "${RED}  Kill all '$proc_input' processes? (yes/no): ${RESET}"; read -r confirm
            if [ "$confirm" == "yes" ]; then
                pkill -x "$proc_input" && echo -e "${GREEN}  ✅ Killed all '$proc_input' processes${RESET}" || \
                    echo -e "${RED}  ❌ Failed to kill${RESET}"
                log "SUCCESS" "Killed process: $proc_input by $(whoami)"
            fi
        fi
    fi
}

# ── Continuous Monitor ────────────────────────────────────────
continuous_monitor() {
    section "🔄 Continuous Monitor (Ctrl+C to stop)"
    echo -e "  ${YELLOW}Refreshing every 3 seconds...${RESET}\n"
    log "INFO" "Continuous monitor started by $(whoami)"
    while true; do
        clear
        echo -e "${MAGENTA}${BOLD}  📊 LIVE PROCESS MONITOR — $(date '+%Y-%m-%d %H:%M:%S')${RESET}"
        echo -e "${MAGENTA}$(printf '═%.0s' {1..60})${RESET}"
        echo -e "${CYAN}  CPU Load: $(cat /proc/loadavg | awk '{print $1, $2, $3}') | Processes: $(ps aux | wc -l)${RESET}"
        echo -e "${CYAN}  Memory: $(free -h | awk '/^Mem:/ {print "Used: "$3"/"$2}')${RESET}\n"
        printf "  ${WHITE}${BOLD}%-8s %-22s %-7s %-7s %-s${RESET}\n" "PID" "COMMAND" "CPU%" "MEM%" "USER"
        printf "  $(printf '─%.0s' {1..60})\n"
        ps aux --sort=-%cpu | awk 'NR>1 && NR<=16 {
            printf "  %-8s %-22s %-7s %-7s %-s\n", $2, substr($11,1,22), $3, $4, $1
        }'
        echo -e "\n${YELLOW}  Press Ctrl+C to exit${RESET}"
        sleep 3
    done
}

# ── Save Snapshot ─────────────────────────────────────────────
save_snapshot() {
    section "💾 Save Process Snapshot"
    {
        echo "=== Process Snapshot: $(date) ==="
        echo "=== Top CPU Processes ==="
        ps aux --sort=-%cpu | head -20
        echo ""
        echo "=== Top Memory Processes ==="
        ps aux --sort=-%mem | head -20
        echo ""
        echo "=== System Load ==="
        cat /proc/loadavg
        echo "=== End Snapshot ==="
    } >> "$LOG_FILE"
    echo -e "${GREEN}  ✅ Snapshot saved to: $LOG_FILE${RESET}"
    log "INFO" "Process snapshot saved by $(whoami)"
}

# ── Main Menu ─────────────────────────────────────────────────
main_menu() {
    print_banner
    log "INFO" "Process monitor started by $(whoami)"
    while true; do
        echo -e "${WHITE}${BOLD}  Select an option:${RESET}"
        echo -e "  ${CYAN}[1]${RESET}  ⚡ Top CPU Processes"
        echo -e "  ${GREEN}[2]${RESET}  🧠 Top Memory Processes"
        echo -e "  ${YELLOW}[3]${RESET}  🔍 Filter by Process Name"
        echo -e "  ${BLUE}[4]${RESET}  📈 Process Statistics"
        echo -e "  ${RED}[5]${RESET}  💀 Kill a Process"
        echo -e "  ${MAGENTA}[6]${RESET}  🔄 Continuous Monitor (live)"
        echo -e "  ${WHITE}[7]${RESET}  💾 Save Snapshot to Log"
        echo -e "  ${WHITE}[0]${RESET}  🚪 Exit"
        echo -ne "\n${CYAN}  Choice: ${RESET}"; read -r choice
        case "$choice" in
            1) show_top_cpu ;;
            2) show_top_memory ;;
            3) filter_process ;;
            4) show_stats ;;
            5) kill_process ;;
            6) continuous_monitor ;;
            7) save_snapshot ;;
            0) echo -e "\n${GREEN}  👋 Goodbye!${RESET}"; log "INFO" "Exited by $(whoami)"; exit 0 ;;
            *) echo -e "${RED}  ❌ Invalid option${RESET}" ;;
        esac
        echo -ne "\n${YELLOW}  Press Enter to continue...${RESET}"; read -r
        print_banner
    done
}

main_menu
