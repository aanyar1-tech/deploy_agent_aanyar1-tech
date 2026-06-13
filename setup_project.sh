#!/usr/bin/env bash
set -eo pipefail
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*"; }
PROJECT_DIR=""
handle_interrupt() {
    echo ""
    warn "Interrupt received! Performing cleanup..."
    if [[ -n "$PROJECT_DIR" && -d "$PROJECT_DIR" ]]; then
        ARCHIVE_NAME="${PROJECT_DIR}_archive.tar.gz"
        info "Bundling '${PROJECT_DIR}' -> '${ARCHIVE_NAME}' ..."
        if tar -czf "$ARCHIVE_NAME" "$PROJECT_DIR" 2>/dev/null; then
            success "Archive created: ${ARCHIVE_NAME}"
        else
            error "Archive creation failed."
            exit 1
        fi
        info "Removing incomplete directory '${PROJECT_DIR}' ..."
        rm -rf "$PROJECT_DIR"
        success "Workspace cleaned up."
    else
        info "No project directory to archive."
    fi
    error "Setup aborted by user."
    exit 1
}
trap handle_interrupt SIGINT
echo ""
echo -e "${BOLD}=== Student Attendance Tracker - Project Bootstrapper ===${RESET}"
echo ""
while true; do
    read -rp "Enter a project identifier (letters, numbers, underscores): " PROJECT_INPUT
    PROJECT_INPUT="${PROJECT_INPUT// /_}"
    if [[ -z "$PROJECT_INPUT" ]]; then
        error "Project name cannot be empty. Please try again."
        continue
    fi
    if [[ ! "$PROJECT_INPUT" =~ ^[A-Za-z0-9_]+$ ]]; then
        error "Name must contain only letters, numbers, and underscores."
        continue
    fi
    break
done
PROJECT_DIR="attendance_tracker_${PROJECT_INPUT}"
if [[ -d "$PROJECT_DIR" ]]; then
    error "Directory '${PROJECT_DIR}' already exists. Remove it first."
    exit 1
fi
info "Creating directory structure for '${PROJECT_DIR}' ..."
mkdir -p "${PROJECT_DIR}/Helpers"
mkdir -p "${PROJECT_DIR}/reports"
success "Directories created."
info "Writing source files ..."
cat > "${PROJECT_DIR}/attendance_checker.py" << 'PYEOF'
import csv
import json
import os
from datetime import datetime
def run_attendance_check():
    with open('Helpers/config.json', 'r') as f:
        config = json.load(f)
    if os.path.exists('reports/reports.log'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename('reports/reports.log', f'reports/reports_{timestamp}.log.archive')
    with open('Helpers/assets.csv', mode='r') as f, open('reports/reports.log', 'w') as log:
        reader = csv.DictReader(f)
        total_sessions = config['total_sessions']
        log.write(f"--- Attendance Report Run: {datetime.now()} ---\n")
        for row in reader:
            name = row['Names']
            email = row['Email']
            attended = int(row['Attendance Count'])
            attendance_pct = (attended / total_sessions) * 100
            message = ""
            if attendance_pct < config['thresholds']['failure']:
                message = f"URGENT: {name}, your attendance is {attendance_pct:.1f}%. You will fail this class."
            elif attendance_pct < config['thresholds']['warning']:
                message = f"WARNING: {name}, your attendance is {attendance_pct:.1f}%. Please be careful."
            if message:
                if config['run_mode'] == "live":
                    log.write(f"[{datetime.now()}] ALERT SENT TO {email}: {message}\n")
                    print(f"Logged alert for {name}")
                else:
                    print(f"[DRY RUN] Email to {email}: {message}")
if __name__ == "__main__":
    run_attendance_check()
PYEOF
cat > "${PROJECT_DIR}/Helpers/assets.csv" << 'CSVEOF'
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
CSVEOF
cat > "${PROJECT_DIR}/Helpers/config.json" << 'JSONEOF'
{
    "thresholds": {
        "warning": 75,
        "failure": 50
    },
    "run_mode": "live",
    "total_sessions": 15
}
JSONEOF
cat > "${PROJECT_DIR}/reports/reports.log" << 'LOGEOF'
--- Attendance Report Run: 2026-02-06 18:10:01.468726 ---
[2026-02-06 18:10:01.469363] ALERT SENT TO bob@example.com: URGENT: Bob Smith, your attendance is 46.7%. You will fail this class.
[2026-02-06 18:10:01.469424] ALERT SENT TO charlie@example.com: URGENT: Charlie Davis, your attendance is 26.7%. You will fail this class.
LOGEOF
success "All source files written."
echo ""
read -rp "Do you want to update the attendance thresholds? [y/N]: " UPDATE_CONFIG
UPDATE_CONFIG="${UPDATE_CONFIG,,}"
if [[ "$UPDATE_CONFIG" == "y" || "$UPDATE_CONFIG" == "yes" ]]; then
    while true; do
        read -rp "  Warning threshold (default 75, enter 1-100): " WARN_VAL
        WARN_VAL="${WARN_VAL:-75}"
        if [[ "$WARN_VAL" =~ ^[0-9]+$ ]] && (( WARN_VAL >= 1 && WARN_VAL <= 100 )); then break; fi
        error "Please enter a whole number between 1 and 100."
    done
    while true; do
        read -rp "  Failure threshold (default 50, enter 1-100): " FAIL_VAL
        FAIL_VAL="${FAIL_VAL:-50}"
        if [[ "$FAIL_VAL" =~ ^[0-9]+$ ]] && (( FAIL_VAL >= 1 && FAIL_VAL <= 100 )); then break; fi
        error "Please enter a whole number between 1 and 100."
    done
    if (( FAIL_VAL >= WARN_VAL )); then
        warn "Failure must be less than warning. Using defaults: warning=75, failure=50."
        WARN_VAL=75; FAIL_VAL=50
    fi
    CONFIG_FILE="${PROJECT_DIR}/Helpers/config.json"
    sed -i "s/\"warning\": [0-9]*/\"warning\": ${WARN_VAL}/" "$CONFIG_FILE"
    sed -i "s/\"failure\": [0-9]*/\"failure\": ${FAIL_VAL}/" "$CONFIG_FILE"
    success "config.json updated: warning=${WARN_VAL}%  failure=${FAIL_VAL}%"
else
    info "Skipping threshold update - defaults retained (warning=75%, failure=50%)."
fi
echo ""
info "Running environment health check ..."
if command -v python3 &>/dev/null; then
    PY_VER=$(python3 --version 2>&1)
    success "Python 3 found: ${PY_VER}"
else
    warn "python3 not found. Install Python 3 before running the tracker."
fi
REQUIRED_FILES=(
    "${PROJECT_DIR}/attendance_checker.py"
    "${PROJECT_DIR}/Helpers/assets.csv"
    "${PROJECT_DIR}/Helpers/config.json"
    "${PROJECT_DIR}/reports/reports.log"
)
ALL_OK=true
for FILE in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$FILE" ]]; then
        success "Found: ${FILE}"
    else
        error "Missing: ${FILE}"
        ALL_OK=false
    fi
done
if [[ "$ALL_OK" == true ]]; then
    success "Directory structure verified - all files present."
else
    error "Some files are missing."
    exit 1
fi
echo ""
echo -e "${GREEN}${BOLD}======================================${RESET}"
echo -e "${GREEN}${BOLD}  Setup complete!${RESET}"
echo -e "${GREEN}${BOLD}======================================${RESET}"
echo ""
echo -e "  Project root : ${BOLD}${PROJECT_DIR}/${RESET}"
echo -e "  Run the app  : ${BOLD}cd ${PROJECT_DIR} && python3 attendance_checker.py${RESET}"
echo ""
