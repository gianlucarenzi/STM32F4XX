ROM Based STM32 BOOTLOADER DFU
for generic RetroBit Lab's STM32 based boards
=============

## Notice

This software must be considered experimental and a work in progress. Under no circumstances should these files be used in relation to any critical system(s). Use of these files is at your own risk.

## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


## Summary
This is a driverless (no USB drivers needed, even on Windows) USB DFU bootloader
for **STM32F4xx** devices. 

## Flash the Bootloader
To flash the bootloader you will need an STLINK V2 programmer and an installation of OpenOCD. These procedures are validated on Linux only, but it should be easy to adapt
the scripts to run on Windows and/or Mac OS machines. Any other *nixes are in an unknowledge state. :-(

## The Bootloader's caveats
The flash memory starts by design at 0x08000000 address and the bootloader is compiled in the same area using the correct GNU linker script.
It will use 16K of flash space, it uses the GPIOA0 pin as LED indicator if any (low active), and a GPIOC1 pin as GPIO input for entering in bootmode as DFU device.
The UART2 RX and TX (GPIOA2 and GPIOA3) pins as well as the UART2 are initialized at 115200,8N1 during startup to show some debug information. They can be reprogrammed into the application code
considering the booting setup...
The GPIOC1 pin must be tied to ground for at least 1 second on powerup. The device will switch to rom code as DFU device.
The application must reside into the memory flash regions from 0x08004000 up to the end of the flash memory.
These information must be taken into account when programming any custom application and they should be defined in the GNU linker script file.

For example:

/* For a 128K based flash size device */
_MCU_FLASH_SIZE_ = 0x20000;

/* Bootloader size 16K */
_BOOTLOADER_SIZE_ = 0x4000;

MEMORY
{
	BOOT  (rx) : ORIGIN = 0x08000000, LENGTH = _BOOTLOADER_SIZE_
	FLASH (rx) : ORIGIN = 0x08000000 + _BOOTLOADER_SIZE_, LENGTH = _MCU_FLASH_SIZE_ - _BOOTLOADER_SIZE_
	RAM (xrw)  : ORIGIN = 0x20000000, LENGTH = 64K
}

__bootflash_start = ORIGIN(BOOT);
__bootflash_end = ORIGIN(BOOT) + LENGTH(BOOT);
__appflash_start = ORIGIN(FLASH);
__appflash_end = ORIGIN(FLASH) + LENGTH(FLASH);
__ram_start = ORIGIN(RAM);
__ram_end = ORIGIN(RAM) + LENGTH(RAM);

The BOOT area is here *for reference ONLY* as this should not be used by application itself.

The application in the SystemInit() section *MUST* have those initialization to be correct on running in a different memory space than the classic 0x08000000 area.
This function is usually located into the system_stm32f4xx.c file:

extern uint32_t *__appflash_start; /* Defined by the GNU linker script */

void SystemInit(void)
{
 ...
 ...
 SCB->VTOR = (uint32_t) &__appflash_start;
}

In this way the application can run from a different flash memory address as the code is already relocated into the right segments by the GNU linker script.

## Programming application/Firmware Update

Plug the miniUSB cable in J3 USB Device Connector. Then tie to ground the GPIOC1 for at least 1 second when powering up the device.
If needed press and release the SW1 RESET switch (and act correctly for GPIOC1) to enter into the DFU state.
Download the STM32Cube-Programmer from STMicroelectronics' web-site for your Operating System of choice, then run it.
Click on connect button on the upper right side of the STM32Cube-Programmer window, then select the correct firmware (.hex format) to update the application on the board.
Disconnect from STM32Cube-Programmer, restart the board and... let's go! Your new application is now running!

That's all folks!

