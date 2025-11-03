#!/bin/bash

# This script sets up the environment for running the generate_cpl.py script
# and then executes it.

# --- Configuration ---
# Path to the directory containing the KiCad Python modules
PYTHON_MODULE_PATH="/usr/lib/python3/dist-packages"
PYTHON3=$(which python3)

# Get the directory where this script is located
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# Absolute path to the generate_cpl.py script (assumed to be in the same directory)
PYTHON_SCRIPT="$SCRIPT_DIR/generate_cpl.py"
# --- End Configuration ---

# Check if the user provided a path to the .kicad_pcb file
if [ -z "$1" ]; then
    echo "Error: You must provide the path to the .kicad_pcb file."
    echo "Usage: $0 /path/to/your/project.kicad_pcb"
    exit 1
fi

KICAD_PCB_FILE="$1"

echo "► Setting PYTHONPATH to: $PYTHON_MODULE_PATH"
echo "► Executing script: $PYTHON_SCRIPT"
echo "► Processing file: $KICAD_PCB_FILE"
echo "--------------------------------------------------"

# Set the environment variable and run the python script
PYTHONPATH=$PYTHON_MODULE_PATH ${PYTHON3} "$PYTHON_SCRIPT" "$KICAD_PCB_FILE"

echo "--------------------------------------------------"
echo "✔ Script execution finished."

