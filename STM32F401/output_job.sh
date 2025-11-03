#!/bin/bash

export KILIBPATH=$HOME/Progetti/RetroBitLab-Library

# --- Setup and Auto-Install for eeplot ---
LOCAL_UTILS_DIR="$(pwd)/utilities"
EEPLOT_SRC_DIR="eeplot-src" # Relative path for source
EEPLOT_EXEC="${LOCAL_UTILS_DIR}/bin/eeplot"
EESHOW_EXEC="${LOCAL_UTILS_DIR}/bin/eeshow" # Assuming eeshow is also built

# Check if eeplot is already installed locally
if [ -f "${EEPLOT_EXEC}" ]; then
    echo "--- eeplot found locally. Skipping setup. ---"
elif [ -d "${EEPLOT_SRC_DIR}" ]; then
    echo "--- eeplot source found. Updating and rebuilding. ---"
    # 1. Check for system dependencies (still needed for rebuilds)
            echo "[1/4] Checking system dependencies..."
            if ! dpkg -s libgit2-dev >/dev/null 2>&1; then
                echo "--------------------------------------------------------------------"
                echo "ERROR: System dependency 'libgit2-dev' not found."
        echo "Please run the following command to install it:"
        echo "sudo apt-get install libgit2-dev"
        echo "--------------------------------------------------------------------"
        exit 1
    fi
    echo "Dependencies OK."

    # 2. Update source
    echo "[2/4] Updating eeplot source (git pull)..."
    (cd "${EEPLOT_SRC_DIR}" && git pull) || { echo "ERROR: git pull failed."; exit 1; }

    # 3. Compile
    echo "[3/4] Compiling eeplot..."
    if ! make -C "${EEPLOT_SRC_DIR}"; then
        echo "ERROR: Compilation (make) failed during update."
        exit 1
    fi

    # 4. Install locally (manual copy)
    cp "${EEPLOT_SRC_DIR}/eeplot" "${LOCAL_UTILS_DIR}/bin/" || { echo "ERROR: Copy 'eeplot' failed."; exit 1; }
    if [ -f "${EEPLOT_SRC_DIR}/eeshow" ]; then
        cp "${EEPLOT_SRC_DIR}/eeshow" "${LOCAL_UTILS_DIR}/bin/" || { echo "ERROR: Copy 'eeshow' failed."; exit 1; }
    fi
    echo "--- eeplot update and rebuild complete. ---"
else
    echo "--- eeplot not found locally. Starting one-time setup procedure ---"
    # 1. Check for system dependencies
    echo "[1/5] Checking system dependencies..."
    if ! dpkg -s libgit2-dev >/dev/null 2>&1; then
        echo "--------------------------------------------------------------------"
        echo "ERRORE: Dipendenza di sistema 'libgit2-dev' non trovata."
        echo "Please run the following command to install it:"
        echo "sudo apt-get install libgit2-dev"
        echo "--------------------------------------------------------------------"
        exit 1
    fi
    echo "Dependencies OK."

    # 2. Clone the repository
    echo "[2/5] Cloning eeplot repository..."
    # rm -rf "${EEPLOT_SRC_DIR}" # Not needed here, as we are in the 'else' branch, meaning it doesn't exist
    if ! git clone https://github.com/DavidWKnight/eeshow-Kicad5-eeplot.git "${EEPLOT_SRC_DIR}"; then
        echo "ERROR: Unable to clone repository. Check connection or URL."
        exit 1
    fi

    # 3. Compile
    echo "[3/5] Compiling eeplot..."
    if ! make -C "${EEPLOT_SRC_DIR}"; then
        echo "ERROR: Compilation (make) failed."
        rm -rf "${EEPLOT_SRC_DIR}"
        exit 1
    fi

    # 4. Install locally (manual copy due to make install issues)
    echo "[4/5] Installing eeplot into ${LOCAL_UTILS_DIR} (manual copy)..."
    mkdir -p "${LOCAL_UTILS_DIR}/bin"
    cp "${EEPLOT_SRC_DIR}/eeplot" "${LOCAL_UTILS_DIR}/bin/" || { echo "ERROR: Copy 'eeplot' failed."; exit 1; }
    if [ -f "${EEPLOT_SRC_DIR}/eeshow" ]; then
        cp "${EEPLOT_SRC_DIR}/eeshow" "${LOCAL_UTILS_DIR}/bin/" || { echo "ERROR: Copy 'eeshow' failed."; exit 1; }
    fi

    # 5. Cleanup
    echo "[5/5] Cleaning up source files..."
    rm -rf "${EEPLOT_SRC_DIR}"

    echo "--- eeplot installation complete. ---"
fi

# Add local utilities to the PATH for this script execution
export PATH="${LOCAL_UTILS_DIR}/bin:${PATH}"
# --- End of Setup ---


PCBNAME=STM32F4XX
PCBNAMEOUT=${PCBNAME}
KICADBOMSCRIPT=${HOME}/.kicad/bom
PDFOUTPUT=${PCBNAME}.pdf
XSLTPROC=$(which xsltproc)
PYTHON3=$(which python3)

ARGS_NUM=$#
# Lanciare con la versione del PCB!!

if [ ${ARGS_NUM} -lt 1 ]; then
	echo "Need the PCB Version!"
	exit 1
fi

# Need KiCAD CLI from a v7+ version installed
KICADCLI=$(which kicad-cli)
if [ "${KICADCLI}" == "" ]; then
	echo "Need to install kicad-cli from a version of KiCAD v7 or greater"
	echo "(on Debian 11 I am using the flatpak option). Put the script"
	echo "into a path available for shell..."
	exit 1
fi

# La versione e' il primo argomento
PCBVER=$1
PCBNAMEOUT=${PCBNAMEOUT}-v${PCBVER}

# La prima volta va generato il file xml!
if [ ! -f ${PCBNAME}.xml ]; then
	echo "Need to run once the BOM Generator from EESCHEMA / Schematic Designer"
	exit 1
fi

# Creiamo la BOM per JLCPCB
${XSLTPROC} -o ${PCBNAME}.csv ${KICADBOMSCRIPT}/bom2grouped_csv_jlcpcb.xsl ${PCBNAME}.xml

echo "Creating BOM for JLCPCB"
${PYTHON3} jlcpcb-check-bom.py ${PCBNAME}.csv ${PCBNAMEOUT}-JLCPCB-BOM.csv

# Generiamo la CPL con uno script simile al plugin di PCBNEW!!!!
./run_generate_cpl.sh ${PCBNAME}.kicad_pcb
if [ $? -ne 0 ]; then
	echo "Error on generating CPL files."
	exit 1
fi

echo "Creating JLCPCB CPL"
if [ -f ${PCBNAME}_cpl_top.csv ]; then
	# Verify if the bot is present
	if [ -f ${PCBNAME}_cpl_bot.csv ]; then
		# We are 2 side board
		./clean_virtual.sh ${PCBNAME}_cpl_top.csv ${PCBNAME}_cpl_bot.csv ${PCBNAME}.kicad_pcb
		cat ${PCBNAME}_cpl_top.csv <(tail -n +2 ${PCBNAME}_cpl_bot.csv) > ${PCBNAMEOUT}-JLCPCB-CPL.csv
	else
		# We have only TOP Side components!
		./clean_virtual.sh ${PCBNAME}_cpl_top.csv ${PCBNAME}.kicad_pcb
		cp ${PCBNAME}_cpl_top.csv ${PCBNAMEOUT}-JLCPCB-CPL.csv
	fi
else
	# Verify if the bot is present
	if [ -f ${PCBNAME}_cpl_bot.csv ]; then
		# We have only BOT side components
		./clean_virtual.sh ${PCBNAME}_cpl_bot.csv ${PCBNAME}.kicad_pcb
		cp ${PCBNAME}_cpl_bot.csv ${PCBNAMEOUT}-JLCPCB-CPL.csv
	else
		# There is no top and no bottom!
		echo "No CPL files present error!"
		exit 1
	fi
fi

echo "Creating PDF..."
# Set KICAD_SYMBOL_DIR to help eeplot find libraries (though eeplot takes them as arguments)
# export KICAD_SYMBOL_DIR="${KILIBPATH}:/usr/share/kicad/library"
eeplot -o ${PDFOUTPUT} \
    /usr/share/kicad/library/Connector.lib \
    /usr/share/kicad/library/Connector_Generic.lib \
    /usr/share/kicad/library/Mechanical.lib \
    /usr/share/kicad/library/power.lib \
    /usr/share/kicad/library/MCU_ST_STM32F4.lib \
    ${KILIBPATH}/CCAP0603.lib \
    ${KILIBPATH}/CCAP0805.lib \
    ${KILIBPATH}/CCAP1206.lib \
    ${KILIBPATH}/CCAP1210.lib \
    ${KILIBPATH}/CLED0805.lib \
    ${KILIBPATH}/CLED1206.lib \
    ${KILIBPATH}/CLED1210.lib \
    ${KILIBPATH}/CRES0603.lib \
    ${KILIBPATH}/CRES0805.lib \
    ${KILIBPATH}/CRES1206.lib \
    ${KILIBPATH}/CRES1210.lib \
    ${KILIBPATH}/PES1-S5-S9-M.lib \
    ${KILIBPATH}/TCAP3528.lib \
    ${KILIBPATH}/RetroBitLab.lib \
    ${PCBNAME}.sch

echo "Creating STEP 3D object..."
${KICADCLI} pcb export step -o ${PCBNAME}.step --force --grid-origin --no-dnp --subst-models ${PCBNAME}.kicad_pcb

echo "Creating VRML 3D object..."
${KICADCLI} pcb export vrml -o ${PCBNAME}.wrl --force --no-dnp ${PCBNAME}.kicad_pcb

# Remove the existing
rm ${PCBNAMEOUT}.zip 2>/dev/null
echo "Generating JLCPCB Project"
cd production
7z -tzip a ../${PCBNAMEOUT}.zip *
exit 0
