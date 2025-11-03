#!/bin/bash
STM32HIDBootloader=STM32_HID_Bootloader
EXEC=${STM32HIDBootloader}/firmware/dfu-bootloader.elf
OPENOCD=$(which openocd)

if [ "${OPENOCD}" == "" ]; then
	echo "Install OpenOCD first."
	exit 1
fi

if [ ! -f ${EXEC} ]; then
	echo "Build bootloader first. Please run 'make clean' & 'make' inside the ${STM32HIDBootloader} folder!"
	exit 1
fi

# Erase all flash first
${OPENOCD} -f ${STM32HIDBootloader}/stm32f4eval.cfg \
-c "init; targets; reset init; wait_halt; poll; flash erase_sector 0 0 last; reset run; shutdown"

${OPENOCD} -f ${STM32HIDBootloader}/stm32f4eval.cfg \
-c "init; targets; reset init; wait_halt; poll; flash write_image erase unlock ${EXEC}; reset run; shutdown"
