#!/bin/bash
# =============================================================
# user_manager.sh - User Management Script
# DevOps Lab | Add, Delete, List, Check users
# =============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; BLUE='\033[0;34m'
WHITE='\033[1;37m'; BOLD='\033[1m'; RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../logs"
LOG_FILE="$LOG_DIR/system.log"
mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [USER-MGR] [$1] $2" >> "$LOG_FILE"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}  ❌ Requires root. Run: sudo $0${RESET}"
        log "ERROR" "Run without root by $(whoami)"
        exit 1
    fi
}

print_banner() {
    clear
    echo -e "${BLUE}${BOLD}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║          👥 USER MANAGEMENT SYSTEM                   ║"
    echo "║              Linux DevOps Lab v1.0                   ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

section() { echo -e "\n${YELLOW}${BOLD}▶ $1${RESET}\n${YELLOW}$(printf '─%.0s' {1..55})${RESET}"; }

user_exists() { id "$1" &>/dev/null; }

add_user() {
    section "➕ Add New User"
    echo -ne "${CYAN}  Username: ${RESET}"; read -r new_user
    if [[ ! "$new_user" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        echo -e "${RED}  ❌ Invalid username format${RESET}"; return 1
    fi
    if user_exists "$new_user"; then
        echo -e "${YELLOW}  ⚠️  User '$new_user' already exists!${RESET}"; return 1
    fi
    echo -ne "${CYAN}  Password: ${RESET}"; read -rs password; echo ""
    echo -ne "${CYAN}  Confirm password: ${RESET}"; read -rs confirm_password; echo ""
    if [ "$password" != "$confirm_password" ]; then
        echo -e "${RED}  ❌ Passwords do not match${RESET}"; return 1
    fi
    echo -ne "${CYAN}  Add to sudo group? (y/n): ${RESET}"; read -r sudo_choice

    if useradd -m -s /bin/bash "$new_user" 2>/dev/null; then
        echo "$new_user:$password" | chpasswd 2>/dev/null
        [[ "$sudo_choice" =~ ^[Yy]$ ]] && usermod -aG sudo "$new_user" 2>/dev/null
        echo -e "${GREEN}  ✅ User '$new_user' created. Home: /home/$new_user${RESET}"
        log "SUCCESS" "User created: $new_user by $(whoami)"
    else
        echo -e "${RED}  ❌ Failed to create user '$new_user'${RESET}"
        log "ERROR" "Failed to create user: $new_user"; return 1
    fi
}

delete_user() {
    section "🗑️  Delete User"
    echo -ne "${CYAN}  Username to delete: ${RESET}"; read -r del_user
    if [ "$del_user" == "root" ] || [ "$del_user" == "$(whoami)" ]; then
        echo -e "${RED}  ❌ Cannot delete root or current user!${RESET}"; return 1
    fi
    if ! user_exists "$del_user"; then
        echo -e "${YELLOW}  ⚠️  User '$del_user' does not exist${RESET}"; return 1
    fi
    id "$del_user"
    echo -ne "${RED}  ⚠️  Delete '$del_user' and home dir? (yes/no): ${RESET}"; read -r confirm
    if [ "$confirm" == "yes" ]; then
        if userdel -r "$del_user" 2>/dev/null; then
            echo -e "${GREEN}  ✅ User '$del_user' deleted${RESET}"
            log "SUCCESS" "User deleted: $del_user by $(whoami)"
        else
            echo -e "${RED}  ❌ Failed to delete user${RESET}"; log "ERROR" "Delete failed: $del_user"
        fi
    else
        echo -e "${YELLOW}  ↩️  Deletion cancelled${RESET}"; log "INFO" "Delete cancelled: $del_user"
    fi
}

list_users() {
    section "📋 System Users"
    printf "  ${WHITE}${BOLD}%-20s %-8s %-8s %s${RESET}\n" "USERNAME" "UID" "GID" "HOME"
    echo -e "  $(printf '─%.0s' {1..55})"
    echo -e "\n  ${CYAN}Regular Users (UID >= 1000):${RESET}"
    awk -F: '$3 >= 1000 && $3 != 65534 {printf "  %-20s %-8s %-8s %s\n", $1, $3, $4, $6}' /etc/passwd
    echo -e "\n  ${MAGENTA}Total accounts: $(wc -l < /etc/passwd) | Regular: $(awk -F: '$3 >= 1000 && $3 != 65534' /etc/passwd | wc -l)${RESET}"
    log "INFO" "User list displayed by $(whoami)"
}

check_user() {
    section "🔍 Check User"
    echo -ne "${CYAN}  Username to check: ${RESET}"; read -r check_username
    if user_exists "$check_username"; then
        echo -e "${GREEN}  ✅ User '$check_username' EXISTS${RESET}"
        id "$check_username"
        local home_dir; home_dir=$(getent passwd "$check_username" | awk -F: '{print $6}')
        echo -e "  ${CYAN}Home: $home_dir | Groups: $(groups "$check_username")${RESET}"
        log "INFO" "Check: $check_username — EXISTS"
    else
        echo -e "${RED}  ❌ User '$check_username' does NOT exist${RESET}"
        log "INFO" "Check: $check_username — NOT FOUND"
    fi
}

show_logged_in() {
    section "🟢 Currently Logged In"
    who
    echo -e "\n  ${CYAN}Last 10 logins:${RESET}"; last -n 10 2>/dev/null
    log "INFO" "Logged-in users displayed"
}

main_menu() {
    print_banner
    log "INFO" "User Manager started by $(whoami)"
    while true; do
        echo -e "${WHITE}${BOLD}  Select an option:${RESET}"
        echo -e "  ${GREEN}[1]${RESET} ➕ Add User"
        echo -e "  ${RED}[2]${RESET} 🗑️  Delete User"
        echo -e "  ${CYAN}[3]${RESET} 📋 List All Users"
        echo -e "  ${YELLOW}[4]${RESET} 🔍 Check User Existence"
        echo -e "  ${BLUE}[5]${RESET} 🟢 Show Logged-In Users"
        echo -e "  ${WHITE}[0]${RESET} 🚪 Exit"
        echo -ne "\n${CYAN}  Choice: ${RESET}"; read -r choice
        case "$choice" in
            1) check_root; add_user ;;
            2) check_root; delete_user ;;
            3) list_users ;;
            4) check_user ;;
            5) show_logged_in ;;
            0) echo -e "\n${GREEN}  👋 Goodbye!${RESET}"; log "INFO" "Exited by $(whoami)"; exit 0 ;;
            *) echo -e "${RED}  ❌ Invalid option${RESET}" ;;
        esac
        echo -ne "\n${YELLOW}  Press Enter to continue...${RESET}"; read -r
        print_banner
    done
}

main_menu
