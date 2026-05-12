#!/bin/bash
# =============================================================
# main_menu.sh - Master Control Script (Bonus)
# DevOps Lab | Launches all tools from one menu
# =============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; BLUE='\033[0;34m'
WHITE='\033[1;37m'; BOLD='\033[1m'; RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║        🚀  LINUX DEVOPS AUTOMATION LAB                  ║"
    echo "║             Master Control Panel v1.0                   ║"
    echo "║                                                          ║"
    echo "╠══════════════════════════════════════════════════════════╣"
    echo "║  👤 User: $(printf '%-47s' "$(whoami)@$(hostname)")║"
    echo "║  📅 Date: $(printf '%-47s' "$(date '+%A, %d %B %Y %H:%M:%S')")║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

show_quick_stats() {
    echo -e "${BLUE}$(printf '─%.0s' {1..62})${RESET}"
    echo -e "  ${WHITE}Quick Stats:${RESET} " \
        "CPU: ${CYAN}$(top -bn1 | grep "Cpu(s)" | sed 's/.*, *\([0-9.]*\)%* id.*/\1/' | awk '{printf "%.0f%%", 100-$1}')${RESET}" \
        "| RAM: ${CYAN}$(free -h | awk '/^Mem:/{print $3"/"$2}')${RESET}" \
        "| Disk: ${CYAN}$(df -h / | awk 'NR==2{print $5}')${RESET}" \
        "| Procs: ${CYAN}$(ps aux | wc -l)${RESET}"
    echo -e "${BLUE}$(printf '─%.0s' {1..62})${RESET}"
    echo ""
}

main_menu() {
    while true; do
        print_banner
        show_quick_stats

        echo -e "${WHITE}${BOLD}  🛠️  Available Tools:${RESET}"
        echo ""
        echo -e "  ${CYAN}[1]${RESET}  🖥️  System Information Monitor"
        echo -e "  ${GREEN}[2]${RESET}  💾 Automated Backup System"
        echo -e "  ${BLUE}[3]${RESET}  👥 User Management Console"
        echo -e "  ${MAGENTA}[4]${RESET}  📊 Process Monitor Dashboard"
        echo -e "  ${YELLOW}[5]${RESET}  📋 Log Report Generator"
        echo ""
        echo -e "  ${WHITE}[6]${RESET}  📁 Open Logs Directory"
        echo -e "  ${WHITE}[7]${RESET}  📁 Open Backup Directory"
        echo -e "  ${WHITE}[8]${RESET}  ⏰ Show Cron Jobs"
        echo -e "  ${WHITE}[9]${RESET}  📖 Help & Documentation"
        echo ""
        echo -e "  ${RED}[0]${RESET}  🚪 Exit"
        echo ""
        echo -e "${CYAN}$(printf '─%.0s' {1..62})${RESET}"
        echo -ne "${CYAN}${BOLD}  Enter your choice: ${RESET}"
        read -r choice

        case "$choice" in
            1)
                echo -e "${CYAN}  Launching System Info Monitor...${RESET}"
                sleep 0.5
                bash "$SCRIPT_DIR/system_info.sh"
                echo -ne "\n${YELLOW}  Press Enter to return to menu...${RESET}"; read -r
                ;;
            2)
                echo -e "${CYAN}  Launching Backup System...${RESET}"
                sleep 0.5
                bash "$SCRIPT_DIR/backup.sh"
                echo -ne "\n${YELLOW}  Press Enter to return to menu...${RESET}"; read -r
                ;;
            3)
                echo -e "${CYAN}  Launching User Manager...${RESET}"
                sleep 0.5
                bash "$SCRIPT_DIR/user_manager.sh"
                ;;
            4)
                echo -e "${CYAN}  Launching Process Monitor...${RESET}"
                sleep 0.5
                bash "$SCRIPT_DIR/process_monitor.sh"
                ;;
            5)
                echo -e "${CYAN}  Launching Log Report Generator...${RESET}"
                sleep 0.5
                bash "$SCRIPT_DIR/log_report.sh"
                ;;
            6)
                echo -e "${CYAN}  Contents of logs/:${RESET}\n"
                ls -lh "$SCRIPT_DIR/../logs/" 2>/dev/null || echo "  No logs yet"
                echo -ne "\n${YELLOW}  Press Enter to continue...${RESET}"; read -r
                ;;
            7)
                echo -e "${CYAN}  Contents of backup/:${RESET}\n"
                ls -lh "$SCRIPT_DIR/../backup/" 2>/dev/null || echo "  No backups yet"
                echo -ne "\n${YELLOW}  Press Enter to continue...${RESET}"; read -r
                ;;
            8)
                echo -e "${CYAN}  Current cron jobs for $(whoami):${RESET}\n"
                crontab -l 2>/dev/null || echo -e "  ${YELLOW}No cron jobs set yet.${RESET}"
                echo -e "\n  ${WHITE}To set up cron jobs, run: ${CYAN}crontab -e${RESET}"
                echo -e "  ${WHITE}Recommended cron entries:${RESET}"
                echo -e "  ${GREEN}0 * * * *  $SCRIPT_DIR/system_info.sh >> $SCRIPT_DIR/../logs/system.log 2>&1${RESET}"
                echo -e "  ${GREEN}0 0 * * *  $SCRIPT_DIR/backup.sh >> $SCRIPT_DIR/../logs/backup.log 2>&1${RESET}"
                echo -e "  ${GREEN}*/5 * * * * $SCRIPT_DIR/process_monitor.sh >> $SCRIPT_DIR/../logs/process.log 2>&1${RESET}"
                echo -ne "\n${YELLOW}  Press Enter to continue...${RESET}"; read -r
                ;;
            9)
                echo -e "${CYAN}"
                echo "  ══════════════════════════════════════════════"
                echo "   LINUX DEVOPS LAB — HELP & DOCUMENTATION"
                echo "  ══════════════════════════════════════════════"
                echo -e "${RESET}"
                echo -e "  ${WHITE}Scripts:${RESET}"
                echo -e "  ${GREEN}system_info.sh${RESET}     — Shows system stats & logs them"
                echo -e "  ${GREEN}backup.sh${RESET}          — Backups a folder with timestamp"
                echo -e "  ${GREEN}user_manager.sh${RESET}    — Add/delete/list Linux users (root)"
                echo -e "  ${GREEN}process_monitor.sh${RESET} — Monitor & filter processes"
                echo -e "  ${GREEN}log_report.sh${RESET}      — Analyze logs & generate reports"
                echo ""
                echo -e "  ${WHITE}Usage:${RESET}"
                echo -e "  bash system_info.sh"
                echo -e "  bash backup.sh [/path/to/source]"
                echo -e "  sudo bash user_manager.sh"
                echo -e "  bash process_monitor.sh"
                echo -e "  bash log_report.sh"
                echo ""
                echo -e "  ${WHITE}Logs stored in:${RESET} $SCRIPT_DIR/../logs/"
                echo -e "  ${WHITE}Backups stored in:${RESET} $SCRIPT_DIR/../backup/"
                echo -ne "\n${YELLOW}  Press Enter to continue...${RESET}"; read -r
                ;;
            0)
                echo -e "\n${CYAN}${BOLD}"
                echo "  ╔══════════════════════════════════╗"
                echo "  ║   Thanks for using DevOps Lab!   ║"
                echo "  ║   Keep learning, keep building!  ║"
                echo "  ╚══════════════════════════════════╝"
                echo -e "${RESET}"
                exit 0
                ;;
            *)
                echo -e "${RED}  ❌ Invalid option. Please try again.${RESET}"
                sleep 1
                ;;
        esac
    done
}

main_menu
