# WK2xxx SPI to 4x UART Driver (DKMS)

Linux kernel driver for the **WK2124** (and compatible WK2132 / WK2168 / WK2202 / WK2204) SPI-to-UART bridge ICs from WKmic (Chengdu Weikai Microelectronics). The driver exposes four independent UART channels and is packaged as a DKMS module so it rebuilds automatically after kernel updates.

## Features

- 4 independent UART channels (`/dev/ttyWK0..3`)
- Full-duplex operation with 256-byte FIFO per channel
- Hardware flow control (RTS/CTS)
- RS-485 support (WK2124, WK2168, WK2204)
- Interrupt-driven operation (no polling)
- DKMS integration for automatic rebuild on kernel upgrades
- Device Tree overlay ready for RK3568‑based boards

## Supported Platforms

- Armbian (tested on **RK3568**, e.g. Firefly AIO‑3568J)
- Linux kernel **6.18+**

## Hardware Requirements

- WK2124 (or compatible) connected via SPI
- External **11.0592 MHz** crystal for the reference clock
- Reset line via GPIO expander (PCA9555) or direct GPIO
- IRQ line on a GPIO

See [`docs/pinout.md`](docs/pinout.md) for the detailed connection table and [`wk2124-sch.JPG`](wk2124-sch.JPG) for the schematic.

## Installation

### Quick install

```bash
git clone https://github.com/sdyspb/wk2xxx-spi-4x-uart-driver.git
cd wk2xxx-spi-4x-uart-driver
sudo ./scripts/install.sh
sudo reboot
```

### Manual DKMS install

```bash
sudo apt install build-essential dkms linux-headers-$(uname -r)

sudo mkdir -p /usr/src/wk2xxx-1.0.0
sudo cp Makefile dkms.conf wk2xxx.c /usr/src/wk2xxx-1.0.0/
cd /usr/src/wk2xxx-1.0.0

sudo dkms add -m wk2xxx -v 1.0.0
sudo dkms build -m wk2xxx -v 1.0.0
sudo dkms install -m wk2xxx -v 1.0.0 --force

# Device Tree overlay
sudo cp overlays/pixelnas-wk2xxx.dts /boot/overlay-user/
sudo armbian-add-overlay /boot/overlay-user/pixelnas-wk2xxx.dts
sudo reboot
```

> ⚠️ **Warning:** The `wk2xxx.c` source file is **not yet present** in this repository.  
> DKMS cannot build without it. Add the driver source before running the install script.

## Verification

After reboot:

```bash
lsmod | grep wk2xxx
ls /dev/ttyWK*
dmesg | grep -i wk2xxx
```

Expected output:

```text
wk2xxx                 24576  0
/dev/ttyWK0  /dev/ttyWK1  /dev/ttyWK2  /dev/ttyWK3
wk2xxx spi1.0: WK2124 SPI to UART bridge, 4 ports
```

## Testing

### Quick test

```bash
sudo ./scripts/test-minicom.sh /dev/ttyWK0 115200
```

> ⚠️ **Warning:** `scripts/test-minicom.sh` is not included yet. Create it or run the manual tests below.

### Loopback test

1. Short the **TX** and **RX** pins on the WK2124 channel connector.
2. Run:

```bash
sudo stty -F /dev/ttyWK0 115200 raw -echo
( sudo timeout 3 cat /dev/ttyWK0 > /tmp/loop.out & ) ; sleep 0.3
sudo sh -c "printf 'ABC' > /dev/ttyWK0"
sleep 3
xxd /tmp/loop.out
```

Expected result: `41 42 43` (hex for `ABC`).

### Minicom

```bash
sudo minicom -D /dev/ttyWK0 -b 115200
```

Exit with `Ctrl+A`, then `X`.

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| No `/dev/ttyWK*` | Driver not loaded | `sudo modprobe wk2xxx` |
| `probe failed` | Missing reference clock | Add a `fixed-clock` node to the overlay |
| CS line stays in Z‑state | `spi1m1_cs0` missing from `pinctrl-0` | Add `&spi1m1_cs0` to `pinctrl-0` |
| No data on TX | Reset line not released | Check `reset-gpio` state |
| `vermagic` mismatch | Headers ≠ running kernel | Use DKMS (this package) |

## What is missing in the repository

- **`wk2xxx.c`** – the actual driver source. Without it DKMS cannot build.
- **`scripts/test-minicom.sh`** – helper script for interactive testing (optional but recommended).
- **CI workflow** – e.g. GitHub Actions to verify compilation on a clean Armbian rootfs.
- **More detailed `docs/pinout.md`** – fill in the real pin mapping for your board.

## License

GPL-2.0+
