#!/bin/bash
# =============================================================
# log_report.sh - Log Report Generator
# DevOps Lab | Reads system logs, counts errors, saves reports
# =============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; BLUE='\033[0;34m'
WHITE='\033[1;37m'; BOLD='\033[1m'; RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../logs"
REPORT_FILE="$LOG_DIR/report_$(date '+%Y-%m-%d_%H-%M').txt"
LOG_FILE="$LOG_DIR/system.log"
mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [LOG-RPT] [$1] $2" >> "$LOG_FILE"
}

print_banner() {
    echo -e "${BLUE}${BOLD}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║          📋 LOG REPORT GENERATOR                     ║"
    echo "║              Linux DevOps Lab v1.0                   ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

section() { echo -e "\n${YELLOW}${BOLD}▶ $1${RESET}\n${YELLOW}$(printf '─%.0s' {1..60})${RESET}"; }

tee_section() {
    local title="$1"
    echo -e "\n${YELLOW}${BOLD}▶ $title${RESET}"
    echo "" >> "$REPORT_FILE"
    echo "════════════════════════════════════════════════" >> "$REPORT_FILE"
    echo "  $title" >> "$REPORT_FILE"
    echo "════════════════════════════════════════════════" >> "$REPORT_FILE"
}

# ── Read System Logs ──────────────────────────────────────────
read_system_logs() {
    section "📖 Recent System Logs"
    echo -e "  ${CYAN}Checking available log sources...${RESET}\n"

    # Try journalctl first, then /var/log/syslog, then /var/log/messages
    if command -v journalctl &>/dev/null; then
        echo -e "  ${GREEN}Source: systemd journal (journalctl)${RESET}"
        echo -e "\n  ${WHITE}Last 30 log entries:${RESET}"
        journalctl -n 30 --no-pager 2>/dev/null | while read -r line; do
            if echo "$line" | grep -qiE "error|fail|critical"; then
                echo -e "  ${RED}$line${RESET}"
            elif echo "$line" | grep -qiE "warn"; then
                echo -e "  ${YELLOW}$line${RESET}"
            else
                echo -e "  $line"
            fi
        done
    elif [ -f "/var/log/syslog" ]; then
        echo -e "  ${GREEN}Source: /var/log/syslog${RESET}"
        tail -30 /var/log/syslog 2>/dev/null
    elif [ -f "/var/log/messages" ]; then
        echo -e "  ${GREEN}Source: /var/log/messages${RESET}"
        tail -30 /var/log/messages 2>/dev/null
    else
        echo -e "  ${YELLOW}  System logs not accessible. Showing project logs instead.${RESET}"
        if [ -f "$LOG_FILE" ]; then
            tail -30 "$LOG_FILE"
        else
            echo -e "  ${RED}  No logs available yet.${RESET}"
        fi
    fi
    log "INFO" "System logs read"
}

# ── Error Log Analysis ────────────────────────────────────────
show_error_logs() {
    section "🔴 Error Log Analysis"
    local error_count=0
    local warn_count=0

    echo -e "  ${CYAN}Scanning for errors and warnings...${RESET}\n"

    # Scan project logs
    if [ -f "$LOG_FILE" ]; then
        error_count=$(grep -ciE "\[ERROR\]|\[ALERT\]" "$LOG_FILE" 2>/dev/null || echo 0)
        warn_count=$(grep -ciE "\[WARN\]" "$LOG_FILE" 2>/dev/null || echo 0)

        echo -e "  ${WHITE}${BOLD}Project Log Summary:${RESET}"
        echo -e "  ${RED}Errors/Alerts: $error_count${RESET}"
        echo -e "  ${YELLOW}Warnings:      $warn_count${RESET}"

        if [ "$error_count" -gt 0 ]; then
            echo -e "\n  ${RED}${BOLD}Recent Errors:${RESET}"
            grep -iE "\[ERROR\]|\[ALERT\]" "$LOG_FILE" | tail -10 | while read -r line; do
                echo -e "  ${RED}  $line${RESET}"
            done
        fi
    fi

    # Scan system journal for errors
    if command -v journalctl &>/dev/null; then
        echo -e "\n  ${WHITE}${BOLD}System Journal Errors (last 24h):${RESET}"
        local sys_errors
        sys_errors=$(journalctl --since "24 hours ago" --no-pager 2>/dev/null | grep -iE "error|failed|critical" | wc -l)
        echo -e "  ${RED}System errors found: $sys_errors${RESET}"
        if [ "$sys_errors" -gt 0 ]; then
            journalctl --since "24 hours ago" --no-pager 2>/dev/null | \
                grep -iE "error|failed|critical" | tail -10 | while read -r line; do
                echo -e "  ${RED}  $line${RESET}"
            done
        fi
    fi
    log "INFO" "Error analysis complete: errors=$error_count warns=$warn_count"
}

# ── Failed Login Attempts ─────────────────────────────────────
count_failed_logins() {
    section "🔐 Failed Login Attempts"
    local failed_count=0

    # Try auth.log
    for logfile in /var/log/auth.log /var/log/secure; do
        if [ -f "$logfile" ]; then
            failed_count=$(grep -c "Failed password\|authentication failure" "$logfile" 2>/dev/null || echo 0)
            echo -e "  ${GREEN}Source: $logfile${RESET}"
            echo -e "  ${RED}${BOLD}Total failed login attempts: $failed_count${RESET}"

            if [ "$failed_count" -gt 0 ]; then
                echo -e "\n  ${CYAN}Top offending IPs:${RESET}"
                grep -iE "Failed password|authentication failure" "$logfile" 2>/dev/null | \
                    grep -oP "from \K[\d.]+" | sort | uniq -c | sort -rn | head -10 | \
                    while read -r count ip; do
                        echo -e "  ${RED}  $count attempts from: $ip${RESET}"
                    done

                echo -e "\n  ${CYAN}Last 5 failed attempts:${RESET}"
                grep -iE "Failed password|authentication failure" "$logfile" 2>/dev/null | \
                    tail -5 | while read -r line; do
                    echo -e "  ${RED}  $line${RESET}"
                done
            fi
            break
        fi
    done

    # Try journalctl
    if [ "$failed_count" -eq 0 ] && command -v journalctl &>/dev/null; then
        failed_count=$(journalctl --no-pager 2>/dev/null | grep -ciE "Failed password|authentication failure" || echo 0)
        echo -e "  ${GREEN}Source: journalctl${RESET}"
        echo -e "  ${RED}${BOLD}Total failed login attempts: $failed_count${RESET}"
        if [ "$failed_count" -gt 0 ]; then
            echo -e "\n  ${CYAN}Last 5 failed attempts:${RESET}"
            journalctl --no-pager 2>/dev/null | grep -iE "Failed password|authentication failure" | \
                tail -5 | while read -r line; do echo -e "  ${RED}  $line${RESET}"; done
        fi
    fi

    if [ "$failed_count" -eq 0 ]; then
        echo -e "  ${GREEN}  ✅ No failed login attempts found${RESET}"
    fi
    log "INFO" "Failed logins counted: $failed_count"
}

# ── Disk Usage Report ─────────────────────────────────────────
disk_usage_report() {
    section "💾 Disk Usage Report"
    echo -e "  ${WHITE}${BOLD}Filesystem Usage:${RESET}"
    df -h --exclude-type=tmpfs --exclude-type=devtmpfs 2>/dev/null | \
        awk 'NR==1 {printf "  %-20s %-8s %-8s %-8s %s\n", $1,$2,$3,$4,$5}
             NR>1  {
                 pct=$5+0
                 if (pct>=90) color="\033[0;31m"
                 else if (pct>=70) color="\033[1;33m"
                 else color="\033[0;32m"
                 printf "  %s%-20s %-8s %-8s %-8s %s\033[0m\n", color, $1,$2,$3,$4,$5
             }'

    echo ""
    echo -e "  ${CYAN}Large files (>100MB) in /var/log:${RESET}"
    find /var/log -size +100M -exec ls -lh {} \; 2>/dev/null | \
        awk '{printf "  %-40s %s\n", $9, $5}' | head -10 || \
        echo -e "  ${GREEN}  No large log files found${RESET}"
    log "INFO" "Disk usage report generated"
}

# ── Generate Full Report ──────────────────────────────────────
generate_full_report() {
    section "📄 Generating Full Report"
    echo -e "  ${CYAN}Saving to: $REPORT_FILE${RESET}\n"

    {
        echo "╔══════════════════════════════════════════════════════╗"
        echo "║         LINUX DEVOPS LAB — SYSTEM REPORT             ║"
        echo "╚══════════════════════════════════════════════════════╝"
        echo ""
        echo "Generated At : $(date)"
        echo "Generated By : $(whoami)@$(hostname)"
        echo "System       : $(uname -o) | Kernel: $(uname -r)"
        echo "Uptime       : $(uptime -p 2>/dev/null || uptime)"
        echo ""

        echo "════════════════════ SYSTEM OVERVIEW ════════════════════"
        echo "CPU Load     : $(cat /proc/loadavg | awk '{print $1, $2, $3}') (1m, 5m, 15m)"
        echo "Memory Usage : $(free -h | awk '/^Mem:/ {print "Used: "$3" / Total: "$2}')"
        echo "Disk (root)  : $(df -h / | awk 'NR==2 {print "Used: "$3"/"$2" ("$5")"}')"
        echo "Processes    : $(ps aux | wc -l) total"
        echo ""

        echo "════════════════════ ERROR SUMMARY ════════════════════"
        if [ -f "$LOG_FILE" ]; then
            echo "Project Errors  : $(grep -ciE '\[ERROR\]' "$LOG_FILE" 2>/dev/null || echo 0)"
            echo "Project Warnings: $(grep -ciE '\[WARN\]' "$LOG_FILE" 2>/dev/null || echo 0)"
        fi

        echo ""
        echo "════════════════════ RECENT PROJECT LOGS ════════════════════"
        if [ -f "$LOG_FILE" ]; then
            tail -50 "$LOG_FILE"
        else
            echo "No project logs found."
        fi

        echo ""
        echo "════════════════════ DISK USAGE ════════════════════"
        df -h --exclude-type=tmpfs --exclude-type=devtmpfs 2>/dev/null

        echo ""
        echo "════════════════════ TOP PROCESSES ════════════════════"
        ps aux --sort=-%cpu | head -15

        echo ""
        echo "════════════════════ END OF REPORT ════════════════════"
        echo "Report saved at: $(date)"
    } > "$REPORT_FILE"

    echo -e "${GREEN}  ✅ Report saved: $(basename "$REPORT_FILE")${RESET}"
    echo -e "${CYAN}  📁 Location: $LOG_DIR${RESET}"
    log "SUCCESS" "Full report generated: $REPORT_FILE"
}

# ── Show Project Log Stats ─────────────────────────────────────
show_log_stats() {
    section "📊 Project Log Statistics"
    if [ ! -f "$LOG_FILE" ]; then
        echo -e "  ${YELLOW}  No project log file found yet${RESET}"; return
    fi

    local total_entries errors warnings successes infos
    total_entries=$(wc -l < "$LOG_FILE")
    errors=$(grep -c "\[ERROR\]\|\[ALERT\]" "$LOG_FILE" 2>/dev/null || echo 0)
    warnings=$(grep -c "\[WARN\]" "$LOG_FILE" 2>/dev/null || echo 0)
    successes=$(grep -c "\[SUCCESS\]" "$LOG_FILE" 2>/dev/null || echo 0)
    infos=$(grep -c "\[INFO\]" "$LOG_FILE" 2>/dev/null || echo 0)

    echo -e "  ${WHITE}${BOLD}Log file: $LOG_FILE${RESET}"
    echo -e "  ${CYAN}Total entries:  $total_entries${RESET}"
    echo -e "  ${GREEN}SUCCESS:        $successes${RESET}"
    echo -e "  ${CYAN}INFO:           $infos${RESET}"
    echo -e "  ${YELLOW}WARNINGS:       $warnings${RESET}"
    echo -e "  ${RED}ERRORS/ALERTS:  $errors${RESET}"

    echo -e "\n  ${WHITE}${BOLD}Last 15 entries:${RESET}"
    tail -15 "$LOG_FILE" | while read -r line; do
        if echo "$line" | grep -qiE "ERROR|ALERT"; then echo -e "  ${RED}$line${RESET}"
        elif echo "$line" | grep -qi "WARN"; then echo -e "  ${YELLOW}$line${RESET}"
        elif echo "$line" | grep -qi "SUCCESS"; then echo -e "  ${GREEN}$line${RESET}"
        else echo -e "  $line"; fi
    done
    log "INFO" "Log stats displayed"
}

# ── Main Menu ─────────────────────────────────────────────────
main_menu() {
    print_banner
    log "INFO" "Log report script started by $(whoami)"
    while true; do
        echo -e "${WHITE}${BOLD}  Select an option:${RESET}"
        echo -e "  ${CYAN}[1]${RESET}  📖 Read Recent System Logs"
        echo -e "  ${RED}[2]${RESET}  🔴 Show Error Logs"
        echo -e "  ${YELLOW}[3]${RESET}  🔐 Count Failed Login Attempts"
        echo -e "  ${GREEN}[4]${RESET}  💾 Disk Usage Report"
        echo -e "  ${BLUE}[5]${RESET}  📊 Project Log Statistics"
        echo -e "  ${MAGENTA}[6]${RESET}  📄 Generate Full System Report"
        echo -e "  ${WHITE}[0]${RESET}  🚪 Exit"
        echo -ne "\n${CYAN}  Choice: ${RESET}"; read -r choice
        case "$choice" in
            1) read_system_logs ;;
            2) show_error_logs ;;
            3) count_failed_logins ;;
            4) disk_usage_report ;;
            5) show_log_stats ;;
            6) generate_full_report ;;
            0) echo -e "\n${GREEN}  👋 Goodbye!${RESET}"; log "INFO" "Exited by $(whoami)"; exit 0 ;;
            *) echo -e "${RED}  ❌ Invalid option${RESET}" ;;
        esac
        echo -ne "\n${YELLOW}  Press Enter to continue...${RESET}"; read -r
        print_banner
    done
}

main_menu
