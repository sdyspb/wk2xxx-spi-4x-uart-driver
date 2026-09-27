# WK2xxx SPI to 4x UART Driver (DKMS)

Linux kernel driver for **WK2124** (and compatible WK2132 / WK2168 / WK2202 / WK2204) SPI-to-UART bridge ICs from WKmic. Exposes four independent UART channels as `/dev/ttyWK0..3`. Packaged as a DKMS module so it rebuilds automatically after kernel updates.

## Features

- 4 independent UART channels (`/dev/ttyWK0..3`)
- Full-duplex, 256-byte FIFO per channel
- Hardware flow control (RTS/CTS)
- RS-485 support (WK2124, WK2168, WK2204)
- Interrupt-driven operation
- DKMS: automatic rebuild on kernel upgrade
- Works with custom Armbian builds where kernel headers may not match the running kernel exactly

## Requirements

- Armbian on RK3568 (tested on Firefly AIO-3568J)
- Kernel 6.18+
- Device Tree overlays for WK2124 already installed and enabled on the system
- `pca9555` GPIO expander available (used for the reset line)

## Installation

### Option 1: Install from .deb package (recommended)

```bash
git clone https://github.com/sdyspb/wk2xxx-spi-4x-uart-driver.git
cd wk2xxx-spi-4x-uart-driver
./build-deb.sh
sudo apt install ./wk2xxx-dkms_1.0.0_all.deb
sudo reboot
```

The package registers the module with DKMS and enables a systemd service (`wk2xxx-build.service`) that compiles and loads the module on first boot. No manual steps required.

### Option 2: Install via install.sh

```bash
git clone https://github.com/sdyspb/wk2xxx-spi-4x-uart-driver.git
cd wk2xxx-spi-4x-uart-driver
sudo ./scripts/install.sh
sudo reboot
```

This is equivalent to the .deb path but without the package manager integration. Use it if you want to install on a running system without building the .deb first.

## Verification

After reboot:

```bash
systemctl status wk2xxx-build.service
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

## Integration into custom Armbian build

1. Build the .deb on any Debian/Ubuntu machine (or on the target SBC):

   ```bash
   ./build-deb.sh
   ```

2. Copy the resulting `.deb` to `userpatches/overlay/` on the Armbian Build host:

   ```
   userpatches/overlay/wk2xxx-dkms_1.0.0_all.deb
   ```

3. In `userpatches/customize-image.sh`, add:

   ```bash
   InstallWk2xxxDriver() {
       apt-get install -y /tmp/overlay/wk2xxx-dkms_1.0.0_all.deb
   }
   ```

   and call `InstallWk2xxxDriver` from `Main()`.

4. Build the image. After first boot, the module will compile automatically via `wk2xxx-build.service`.

## How it works

- `wk2xxx.c` — driver source with compatibility defines (`PORT_WK2XXX`, `UPIO_BUS`, `SERIAL_IO_BUS`) so it compiles against older kernel headers.
- `scripts/prepare-headers.sh` — symlinks the best available headers to `/lib/modules/$(uname -r)/build` so DKMS can find them.
- `scripts/post-build.sh` — patches the `vermagic` string in the compiled `.ko` to match the target kernel version if headers differ.
- `wk2xxx-build.service` — oneshot systemd unit, runs on first boot: prepares headers, builds, installs, runs `depmod`, then loads the module.

## Uninstall

```bash
sudo apt remove --purge wk2xxx-dkms
sudo reboot
```

This removes the DKMS entry, systemd service, module binary, and autoload config.

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| No `/dev/ttyWK*` | Module not loaded | `sudo modprobe wk2xxx`, check `dmesg` |
| `wk2xxx-build.service` failed | Kernel headers unavailable | `apt install linux-headers-current-rockchip64` |
| `dkms build` fails | Missing build tools | `apt install build-essential` |
| `probe failed` on load | Overlay missing or `pca9555` not up | Apply overlays first, verify with `dmesg` |
| CS line stays in Z-state | `spi1m1_cs0` missing from `pinctrl-0` | Fix the overlay |
| No data on TX | Reset line not released | Check `reset-gpio` via `debugfs` |
| `vermagic` mismatched | DKMS skipped `post-build` | Check `/var/lib/dkms/wk2xxx/1.0.0/<kernel>/<arch>/log/make.log` |

Logs:

```bash
journalctl -u wk2xxx-build.service --no-pager
cat /var/lib/dkms/wk2xxx/1.0.0/<kernel>/<arch>/log/make.log
```

## Driver Source

`wk2xxx.c` is derived from the EDATEC patch series submitted to the Linux kernel mailing list:

- LKML patch v4: <https://patchew.org/linux/20260908103129.58085-1-zjzhao@edatec.cn/>
- Original community driver: <https://github.com/britus/wk2xxx>

## License

GPL-2.0+
