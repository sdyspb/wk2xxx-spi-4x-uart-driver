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
- Device Tree overlay `pixelnas-wk2xxx` applied

## Installation

### Pre-check: overlay

Verify the `pixelnas-wk2xxx` overlay is applied:

```bash
cat /proc/device-tree/spi@fe620000/spi_wk2xxx@0/compatible
```

Expected: `wkmic,wk2124`.

If the file is missing, apply the overlay:

```bash
sudo cp pixelnas-wk2xxx.dts /boot/overlay-user/
sudo armbian-add-overlay /boot/overlay-user/pixelnas-wk2xxx.dts
sudo reboot
```

### Install the driver

Download the latest `.deb` from the [Releases page](https://github.com/sdyspb/wk2xxx-spi-4x-uart-driver/releases) and install:

```bash
sudo apt install ./wk2xxx-dkms_1.0.0_all.deb
sudo reboot
```

During `apt install`, the package:

1. Pulls in `dkms`, `build-essential`, and `linux-headers-current-rockchip64`.
2. Registers the module with DKMS.
3. Enables `wk2xxx-build.service`.

On first boot, `wk2xxx-build.service`:

1. Prepares kernel headers.
2. Builds the module via DKMS.
3. Patches `vermagic` if headers differ.
4. Installs the `.ko`, runs `depmod`.
5. Loads the module (`modprobe wk2xxx`).

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

### Minicom

```bash
sudo apt install -y minicom
sudo minicom -D /dev/ttyWK0 -b 115200
```

Exit with `Ctrl+A`, then `X`.

### Simple send

```bash
sudo stty -F /dev/ttyWK0 115200 raw -echo
sudo timeout 3 sh -c "printf 'A' > /dev/ttyWK0"
```

## Integration into a custom Armbian build

1. Download the `.deb` from the [Releases page](https://github.com/sdyspb/wk2xxx-spi-4x-uart-driver/releases).
2. Copy it to `userpatches/overlay/` on the Armbian Build host:
   ```
   userpatches/overlay/wk2xxx-dkms_1.0.0_all.deb
   ```
3. In `userpatches/customize-image.sh`, add:

   ```bash
   InstallWk2xxxDriver() {
       apt-get update -qq
       apt-get install -y -qq "/tmp/overlay/wk2xxx-dkms_1.0.0_all.deb"
   }
   ```

   and call `InstallWk2xxxDriver` from `Main()`.

4. Build the image with `INSTALL_HEADERS=yes`:

   ```bash
   ./compile.sh build BOARD=pixelnas BRANCH=current BUILD_DESKTOP=no \
       BUILD_MINIMAL=no KERNEL_CONFIGURE=no RELEASE=trixie INSTALL_HEADERS=yes
   ```

After first boot, the driver compiles automatically.

## How it works

- `wk2xxx.c` — driver source with compatibility defines (`PORT_WK2XXX`, `UPIO_BUS`, `SERIAL_IO_BUS`).
- `scripts/prepare-headers.sh` — symlinks the best available headers to `/lib/modules/$(uname -r)/build`.
- `scripts/post-build.sh` — patches the `vermagic` string in the compiled `.ko` if headers differ from the target kernel.
- `wk2xxx-build.service` — oneshot systemd unit, runs on first boot to build, install, and load the module.

## Uninstall

```bash
sudo apt remove --purge wk2xxx-dkms
sudo reboot
```

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| No `/dev/ttyWK*` and `lsmod` empty | Module not loaded | `sudo modprobe wk2xxx`, check `dmesg` |
| No `/dev/ttyWK*`, module loaded, `spi1.0` missing in `/sys/bus/spi/devices/` | `pixelnas-wk2xxx` overlay not applied | Apply the overlay (see Installation) |
| No `/dev/ttyWK*`, module loaded, `spi1.0` present | `pca9555` not up or `reset-gpio` unavailable | `dmesg \| grep -iE "pca9555\|wk2xxx"` |
| `wk2xxx-build.service` failed | Kernel headers unavailable | `sudo apt install linux-headers-current-rockchip64` |
| `dkms build` fails | Missing build tools | `sudo apt install build-essential` |
| CS line stays in Z-state | `spi1m1_cs0` missing from `pinctrl-0` | Fix the `pixelnas-wk2xxx` overlay |
| No data on TX | Reset line not released | Check `reset-gpio` state via `/sys/kernel/debug/gpio` |
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
