# deploy_agent_aanyar1-tech

A shell script that automatically sets up the full workspace for the Student Attendance Tracker.

## How to Run

bash setup_project.sh

Follow the prompts:
1. Enter a project identifier e.g. demo
2. Choose whether to update thresholds y or N
3. Enter warning threshold e.g. 80
4. Enter failure threshold e.g. 40

## Directory Structure Created

attendance_tracker_input/
- attendance_checker.py
- Helpers/assets.csv
- Helpers/config.json
- reports/reports.log

## How to Run the Attendance Tracker

cd attendance_tracker_demo
python3 attendance_checker.py

## How to Trigger the Archive Feature

Press Ctrl+C at any point while the script is running, for example when you see:
Do you want to update the attendance thresholds? [y/N]:

The script will bundle the current folder into a tar.gz archive, delete the incomplete directory, and exit cleanly.

## Requirements

- bash
- python3
- tar
- sed
