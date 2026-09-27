# WK2xxx SPI to 4x UART Driver (DKMS)

Linux kernel driver for **WK2124** (and compatible WK2132 / WK2168 / WK2202 / WK2204) SPI-to-UART bridge ICs from WKmic. Exposes four independent UART channels as `/dev/ttyWK0..3` and rebuilds automatically after kernel updates via DKMS.

## Features

- 4 independent UART channels (`/dev/ttyWK0..3`)
- Full-duplex, 256-byte FIFO per channel
- Hardware flow control (RTS/CTS)
- RS-485 support (WK2124, WK2168, WK2204)
- Interrupt-driven operation
- DKMS: automatic rebuild on kernel upgrade
- Works even when kernel headers do not match the running kernel exactly (fallback + vermagic patch)

## Requirements

- Armbian on RK3568 (tested on Firefly AIO-3568J)
- Kernel 6.18+
- Device Tree overlays for WK2124 already installed and enabled on the system
- `pca9555` GPIO expander available (used for the reset line)

> ⚠️ Warning: This package installs **only the DKMS driver**. Device Tree overlays (`pixelnas-i2c`, `pixelnas-exp`, `pixelnas-wk2xxx`) must already be present and enabled on the system before installation.

## Installation

```bash
git clone https://github.com/sdyspb/wk2xxx-spi-4x-uart-driver.git
cd wk2xxx-spi-4x-uart-driver
sudo ./scripts/install.sh
sudo reboot
```

The installer:

1. Installs `build-essential` and `dkms`.
2. Ensures kernel headers are present. If the exact package for the running kernel is missing, it falls back to `linux-headers-current-rockchip64` (or another suitable package).
3. Prepares a headers symlink at `/lib/modules/$(uname -r)/build` (`scripts/prepare-headers.sh`).
4. Registers, builds, and installs the module via DKMS.
5. Patches `vermagic` in the built `.ko` if headers and kernel versions differ (`scripts/post-build.sh`).
6. Enables autoload via `/etc/modules-load.d/wk2xxx.conf`.

No manual editing of kernel config, headers, or `vermagic` is required.

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
spi1.0: ttyWK0 at *unknown* (irq = 104, base_baud = 691200) is a wk2xxx
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

## How it works

The package is resilient to custom Armbian builds where the running kernel version differs from the available headers:

- `scripts/prepare-headers.sh` — symlinks the best available headers to `/lib/modules/$(uname -r)/build`, so DKMS can find them.
- `scripts/post-build.sh` — after DKMS compiles the module, it patches the `vermagic` string in the binary to match the target kernel version. If lengths differ, the module is left untouched and a warning is printed.
- `wk2xxx.c` — contains compatibility defines (`PORT_WK2XXX`, `UPIO_BUS`, `SERIAL_IO_BUS`) so it compiles against older kernel headers.

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| No `/dev/ttyWK*` | Module not loaded | `sudo modprobe wk2xxx`, check `dmesg` |
| `dkms build` fails | Kernel headers unavailable | `apt install linux-headers-current-rockchip64` |
| `probe failed` on load | Overlay missing or `pca9555` not up | Apply overlays first, verify with `dmesg` |
| CS line stays in Z-state | `spi1m1_cs0` missing from `pinctrl-0` | Fix the overlay |
| No data on TX | Reset line not released | Check `reset-gpio` via `debugfs` |
| `vermagic` still mismatched after install | DKMS skipped `post-build` | Check `/var/lib/dkms/wk2xxx/1.0.0/<kernel>/<arch>/log/make.log` |

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
