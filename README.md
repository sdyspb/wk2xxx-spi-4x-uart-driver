# WK2xxx SPI to 4x UART Driver (DKMS)

Linux kernel driver for WK2124
SPI-to-UART bridge ICs by WKmic (Chengdu Weikai Microelectronics).

## Features

- 4 independent UART channels (`/dev/ttyWK0..3`)
- Full-duplex, 256-byte FIFO per channel
- Hardware flow control (RTS/CTS)
- RS-485 support (WK2124, WK2168, WK2204)
- Interrupt-driven operation
- DKMS support for automatic rebuild on kernel updates

## Supported Platforms

- Armbian (RK3568, e.g. Firefly AIO-3568J)
- Kernel 6.18+

## Hardware Requirements

- WK2124 (or compatible) connected via SPI
- External 11.0592 MHz crystal for reference clock
- Reset line via GPIO expander (PCA9555) or direct GPIO
- IRQ line on GPIO

See `docs/pinout.md` for the connection table.

## Installation

### Quick install

```bash
git clone https://github.com/sdyspb/wk2xxx-spi-4x-uart-driver.git
cd wk2xxx-spi-4x-uart-driver
sudo ./scripts/install.sh
sudo reboot\
```
