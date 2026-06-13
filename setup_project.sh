#!/usr/bin/env bash
# setup_project.sh - Automated Project Bootstrapper
# Usage: bash setup_project.sh
# Interrupt at any time with Ctr1+C to trigger the archive-and-cleanupmtrap.

set -euo pipefail

# Colour helpers

red='\033[0;31m'; green='\033[0;32m'; yellow='\033[1;33'
cyan='\033[0;36'; bold='\033[1m'; raset='\033[0m'

info()    { echo -e "${CYANE}[INFO]${RESET} $*"; }
success() { echo -e "${GREEN}[OK]${RESET}   $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*"; }

#Global: project root (set after user provides the name)

PROJECT_DIR=""


# SIGINT trap - archive whatever exists, the clean up

handle_interrupt() {
	echo ""
	warn "Interrupt received! Performing cleanup..."

	if [[ -n "$PROJECT_DIR" && -d "$PROJECT_DIR" ]]; then
		ARCHIVE_NAME="${PROJECT_DIR}_archive.tar.gz"
		info "Bundling '$PROJECT_DIR}' -> ' ${ARCHIVE_NAME}' ..."

		if tar -czf "$ARCHIVE_NAME" "$PROJECT_DIR" 2>/dev/null; then
			success "Archive create: ${ARCHIVE_NAME}"
		else
	           error "Archive creation failed - directory NOT deleted."
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

# 1. Prompt for project name
echo ""
echo -e "${BOLD}=== Student Attendance Tracker - Project Bootstrapper ===${RESET}"
echo ""

while true; do
	read -rp "Enter a project identifier (Letter, number, underscores); "PROJECT_INPUT
	PROJECT_INPUT="${PROJECT_INPUT// /_}"  # replace spaces with underscores

	if [[ -z "$PROJECT_INPUT" ]]; then
		error "Project name can not be empty. Please try again."
		continue
	fi  


     if   [[ ! "$PROJECT_INPUT" =~ ^[A-Za-z0-9_]+$ ]]; then
            error "Name must contain only letters, numbers, and underscores."
            continue
       fi

         break
 done

PROJECT_DIT="attendance_traker_${PROJECT_INPUT}"

# Guard againt overwriting an existing directory
if [[ -d "$PROJECT_DIR" ]]; THEN
	error "Directory '${PROJECT_DIR}' already exists."
	error "Remove it first or choose a different name."
	exit 1
	
fi


# 2. Create directory architecture

info "Creating directory structure for '${PROJECT_DIT}' ..."


mkdir -p "${PROJECT_DIR}/Helpers"

mkdir -p "${PROJECT_DIR}/reports"

suceess "Directories created."

# 3. Write source files  (real content from the project bundle)

info "writing source files ..."

# ---attendance_checker.py
cat > "${PROJECT_DIR}/attendance_checker.py" << 'PYEDF'
#!/usr/bin/enc python3
"""
attendance_checker.py
Student Attendance Tracker -main logic
"""


import csv 
import json
import os
from datetime import dateime


def run_attendance_check():
    # 1. Load Config
    with open('Helpers/config.json', 'r') as f:
        config = json.load(f)
    
    # 2. Archive old reports.log if it exists
    if os.path.exists('reports/reports.log'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename('reports/reports.log', f'reports/reports_{timestamp}.log.archive')
 
    # 3. Process Data
    with open('Helpers/assets.csv', mode='r') as f, open('reports/reports.log', 'w') as log:
        reader = csv.DictReader(f)
        total_sessions = config['total_sessions']
        
        log.write(f"--- Attendance Report Run: {datetime.now()} ---\n")
        
        for row in reader:
            name = row['Names']
            email = row['Email']
            attended = int(row['Attendance Count'])
            
            # Simple Math: (Attended / Total) * 100
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
PYEDF

#---assets.csv
cat > "${PROJECT_DIR}/Helpers/assets.csv" << 'CSVEOF'
Email,                    Name,         Attendance Count, Absence Count
alice@example.com,      Alice Johnson,        14,              1
bob@example.com,        Bob Smith,            7,               8
charlie@example.com,    Charlie Davis,        4,               11
diana@example.com,      Diana Prince,         15,              0
CSVEOF
# --- config.json---
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
 

# --- Reports.log
 cat > "${PROJECT_DIR}/reports/reports.log" << 'LOGEOF'
--- Attendance Report Run: 2026-02-06 18:10:01.468726 ---
[2026-02-06 18:10:01.469363] ALERT SENT TO bob@example.com: URGENT: Bob Smith, your attendance is 46.7%. You will fail this class.
[2026-02-06 18:10:01.469424] ALERT SENT TO charlie@example.com: URGENT: Charlie Davis, your attendance is 26.7%. You will fail this class.
LOGEOF
 
success "All source files written."


# 4. Dynamic configuration with sed

echo ""
read -rp "Do you want to update the attendance thresholds? [y/N]: " UPDATE_CONFIGS
UPDATE_CONFIG="${UPDATE_CONFIG,,}"  # lowercase

if [[ "$UPDATE_CONFIG" == "Y" ||  "UPDATE_CONFIG" == "yes" ]];  then
       # --- Warning threshold ---
    while true; do
        read -rp "  Warning threshold (default 75, enter 1-100): " WARN_VAL
        WARN_VAL="${WARN_VAL:-75}"
        if [[ "$WARN_VAL" =~ ^[0-9]+$ ]] && (( WARN_VAL >= 1 && WARN_VAL <= 100 )); then
            break
        fi
        error "  Please enter a whole number between 1 and 100."
    done
 
    # --- Failure threshold ---
    while true; do
        read -rp "  Failure threshold (default 50, enter 1-100): " FAIL_VAL
        FAIL_VAL="${FAIL_VAL:-50}"
        if [[ "$FAIL_VAL" =~ ^[0-9]+$ ]] && (( FAIL_VAL >= 1 && FAIL_VAL <= 100 )); then
            break
        fi
        error "  Please enter a whole number between 1 and 100."
    done
 
    # Enforce: failure < warning
    if (( FAIL_VAL >= WARN_VAL )); then
        warn "Failure threshold (${FAIL_VAL}) must be less than warning threshold (${WARN_VAL})."
        warn "Using defaults: warning=75, failure=50."
        WARN_VAL=75
        FAIL_VAL=50
    fi
 
    CONFIG_FILE="${PROJECT_DIR}/Helpers/config.json"
 
    # sed in-place substitution (compatible with GNU sed and macOS BSD sed)
    if sed --version 2>/dev/null | grep -q GNU; then
        sed -i "s/\"warning\": [0-9]*/\"warning\": ${WARN_VAL}/" "$CONFIG_FILE"
        sed -i "s/\"failure\": [0-9]*/\"failure\": ${FAIL_VAL}/" "$CONFIG_FILE"
    else
        # macOS / BSD requires an empty-string extension argument
        sed -i '' "s/\"warning\": [0-9]*/\"warning\": ${WARN_VAL}/" "$CONFIG_FILE"
        sed -i '' "s/\"failure\": [0-9]*/\"failure\": ${FAIL_VAL}/" "$CONFIG_FILE"
    fi
 
    success "config.json updated → warning=${WARN_VAL}%  failure=${FAIL_VAL}%"
else
    info "Skipping threshold update — defaults retained (warning=75%, failure=50%)."
fi

# 5. Environment health check ..."

echo ""
info "Running environment health check ..."

# ---python check---
if command -v python3 &>/dev/null: then
	PY_VER=$(python3 --version 2>&1)
	success "Python 3 found: ${PY_VER}"
   else
	   warn "python3 not found on PATH. Install Python 3 before running the tracker."
fi

#---Directory structures verificantion---
REQUIRED_FILES=(
	"${PROJECT_DIR}/attendance_checker.py"
	"{PROJECT_DIR}/Helpers/assets.csv"
 	"{PROJECT_DIR}/Helper/config.json"
	"{PROJECT_DIR}/reports.log"
) 
ALL_OK=true
for FILE in "${REQUIRED_FILES[@]}": do
	if [[ -f "$FILE" ]]; then
		success "found: ${FILE}"
	  else
		  error "Missing: ${FILE}"
		  ALL_OK=fase
       fi
    done

if [[ "ALL_OK"== true ]]; then
	success "Directory structure verified - all files present."
      else
	      error "some files are missing. Check the output above."
	      exit 1

fi


# 6. Done

echo ""
echo -e "${GREEN}${BOLD}===========================${RESET}"
echo -e "${GREEN}${BOLD}  Setup complete!${RESET}"
echo -e "${GREEN}${BOLD}===========================${RESET}"
echo ""
echo -e " Project root : ${BOLD}${PROJECT_DIR}/${RESET}"
echo -e " Run the app  : ${BOLD}cd ${PROJECT_DIR} && python3 attendance_checker.py${RESET}"
echo ""
 

   
 
 

                                                     
	
  

                 
