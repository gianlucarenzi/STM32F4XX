# STM32F401 DFU Jumper Bootloader

A USB DFU (Device Firmware Update) bootloader for STM32F401xC microcontrollers.

This bootloader does not implement the DFU protocol itself. Instead, it is a "jumper" that either starts the main user application or jumps to the factory-programmed DFU bootloader stored in the STM32's system memory (ROM). This allows for driverless firmware updates on all major operating systems.

## Notice

This software is experimental. Use it at your own risk. The authors are not liable for any damages.

## Hardware Configuration

This bootloader is configured for the following hardware setup:

*   **Microcontroller**: STM32F401xC (e.g., STM32F401CCU6)
*   **System Clock**: 8MHz HSE (High-Speed External) oscillator.
*   **LED Indicator**: `PA0` (active low, turns on when booting).
*   **Boot Mode Pin**: `PC1` (pulled high internally, connect to GND to trigger DFU mode).
*   **Debug Output**: `USART2` (`PA2`=TX, `PA3`=RX) at 115200 baud, 8N1.

## Memory Layout

The bootloader occupies the first 16KB of the flash memory. A further 128KB is reserved at the end of flash for non-volatile data storage (e.g., EEPROM emulation).

*   **MCU Flash Size**: 256KB (`0x08000000` - `0x0803FFFF`)
*   **Bootloader (16KB)**: `0x08000000` - `0x08003FFF`
*   **Application (112KB)**: `0x08004000` - `0x0801FFFF`
*   **EEPROM Emulation (128KB)**: `0x08020000` - `0x0803FFFF`

## How to Build

1.  **Install Toolchain**: Ensure you have the `arm-none-eabi-gcc` toolchain and `make` installed and in your system's PATH.
2.  **Build**: Open a terminal in the project root and run the `make` command.

    ```sh
    make
    ```

3.  **Output**: The compiled bootloader files (`dfu-bootloader.hex`, `dfu-bootloader.bin`) will be located in the `build/` directory.

## How to Flash the Bootloader

You need an ST-Link programmer to perform the initial flash.

1.  **Connect**: Connect the ST-Link to your STM32F401's SWD pins (SWDIO, SWCLK, NRST, GND).
2.  **Erase Chip (Optional but Recommended)**: If you are using a previously programmed chip, it's best to erase it completely.

    ```sh
    st-flash erase
    ```

3.  **Flash**: Run the included `flash.sh` script or use `st-flash` directly.

    ```sh
    # Using the script
    ./flash.sh

    # Or manually
    st-flash write build/dfu-bootloader.bin 0x08000000
    ```

## How to Use

1.  **Enter DFU Mode**: To make the device enter the DFU bootloader, hold the boot mode button (the one connected to `PC1`) to ground while powering on the device or pressing the reset button. Keep it held for at least one second.
2.  **Connect USB**: Connect the device to your computer via USB. It should be detected as an "STM32 Bootloader" device.
3.  **Update Firmware**: Use [STM32CubeProgrammer](https://www.st.com/en/development-tools/stm32cubeprog.html) to connect to the USB DFU device and flash your application firmware (`.hex` or `.bin` format).
4.  **Run Application**: Disconnect from STM32CubeProgrammer and reset the board (without holding the boot mode button). The new application will now run.

## Creating an Application for this Bootloader

If you are developing a user application to run after this bootloader, you must configure your project's linker script and startup code correctly.

### 1. Linker Script

Your application must be linked to run from address `0x08004000`. The `MEMORY` section of your linker script should look like this:

```ld
/* Total Flash size of 256K, Bootloader is 16K, EEPROM area is 128K */
/* Application available space is 256 - 16 - 128 = 112K */
MEMORY
{
  FLASH (rx) : ORIGIN = 0x08004000, LENGTH = 112K
  RAM (xrw)  : ORIGIN = 0x20000000, LENGTH = 64K
}
```

### 2. Vector Table Offset

The microcontroller needs to know where the application's vector table is. In your application's `SystemInit` function (usually found in `system_stm32f4xx.c`), you must set the Vector Table Offset Register (VTOR) before any interrupts are enabled.

```c
// In system_stm32f4xx.c

// Set the vector table base address
#define VECT_TAB_OFFSET  0x4000U /* Offset of 16K for the bootloader */

void SystemInit(void)
{
  // ... other initializations

  /* Configure the Vector Table location */
  SCB->VTOR = FLASH_BASE | VECT_TAB_OFFSET;

  // ... rest of the function
}
```