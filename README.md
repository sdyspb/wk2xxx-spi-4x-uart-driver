# WK2xxx SPI to 4x UART Driver (DKMS)

Linux kernel driver for the **WK2124** (and compatible WK2132 / WK2168 / WK2202 / WK2204) SPI-to-UART bridge ICs from WKmic. Exposes four independent UART channels as `/dev/ttyWK0..3`. Packaged as a DKMS module, so it rebuilds automatically after kernel updates.

## Features

- 4 independent UART channels (`/dev/ttyWK0..3`)
- Full-duplex, 256-byte FIFO per channel
- Hardware flow control (RTS/CTS)
- RS-485 support (WK2124, WK2168, WK2204)
- Interrupt-driven operation
- DKMS integration for automatic rebuild on kernel upgrades

## Requirements

- Armbian on RK3568 (tested on Firefly AIO-3568J)
- Kernel 6.18+
- Device Tree overlay for WK2124 already installed and enabled on the system
- `pca9555` GPIO expander available (used for the reset line)
- Build dependencies: `build-essential`, `dkms`, kernel headers

> ⚠️ Warning: This package installs **only the DKMS driver**. Device Tree overlays and their dependencies (`pixelnas-i2c`, `pixelnas-exp`, `pixelnas-wk2xxx`) must already be present and enabled on the system before installation.

## Installation

```bash
git clone https://github.com/sdyspb/wk2xxx-spi-4x-uart-driver.git
cd wk2xxx-spi-4x-uart-driver
sudo ./install.sh
sudo reboot
```

The installer performs the following steps:

1. Installs `build-essential` and `dkms`.
2. Prepares kernel headers for the running kernel (`scripts/prepare-headers.sh`).
3. Copies sources to `/usr/src/wk2xxx-1.0.0/`.
4. Registers, builds, and installs the module via DKMS.
5. Enables autoload through `/etc/modules-load.d/wk2xxx.conf`.

## Verification

After reboot:

```bash
dkms status
lsmod | grep wk2xxx
ls /dev/ttyWK*
dmesg | grep -iE "wk2xxx|ttyWK"
```

Expected:

```text
wk2xxx/1.0.0, 6.18.54-current-rockchip64, aarch64: installed
wk2xxx                 24576  0
/dev/ttyWK0  /dev/ttyWK1  /dev/ttyWK2  /dev/ttyWK3
wk2xxx spi1.0: WK2124 SPI to UART bridge, 4 ports
spi1.0: ttyWK0 at *unknown* (irq = XX, base_baud = 691200) is a wk2xxx
```

## Testing

### Loopback

Short **TX** and **RX** on the desired channel, then:

```bash
sudo stty -F /dev/ttyWK0 115200 raw -echo
( sudo timeout 3 cat /dev/ttyWK0 > /tmp/loop.out & ) ; sleep 0.3
sudo sh -c "printf 'ABC' > /dev/ttyWK0"
sleep 3
xxd /tmp/loop.out
```

Expected: `41 42 43` (hex for `ABC`).

### Minicom

```bash
sudo minicom -D /dev/ttyWK0 -b 115200
```

Exit with `Ctrl+A`, then `X`.

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| No `/dev/ttyWK*` | Module not loaded | `sudo modprobe wk2xxx` |
| `dkms build` fails | Kernel headers missing | `sudo apt install linux-headers-$(uname -r)` |
| `probe failed` on load | Overlay not applied or `pca9555` unavailable | Check `dmesg`, verify overlays |
| CS line stays in Z-state | `spi1m1_cs0` missing from `pinctrl-0` | Fix the overlay |
| No data on TX | Reset line not released | Check `reset-gpio` state via `debugfs` |
| `vermagic` mismatch | Headers version differs from kernel | `post-build.sh` patches it automatically |

## Driver Source

`wk2xxx.c` is derived from the EDATEC patch series submitted to the Linux kernel mailing list:

- LKML patch v4: <https://patchew.org/linux/20260908103129.58085-1-zjzhao@edatec.cn/>
- Original community driver: <https://github.com/britus/wk2xxx>

## Uninstall

```bash
sudo dkms remove -m wk2xxx -v 1.0.0 --all
sudo rm -rf /usr/src/wk2xxx-1.0.0
sudo rm -f /etc/modules-load.d/wk2xxx.conf
sudo reboot
```
