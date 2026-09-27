#!/bin/bash
set -e

KERNELVER="$1"
if [ -z "${KERNELVER}" ]; then
    exit 0
fi

# Найти все собранные .ko под DKMS-деревом пакета
mapfile -t MODULES < <(find /var/lib/dkms/wk2xxx -type f -name "wk2xxx.ko" 2>/dev/null)

if [ "${#MODULES[@]}" -eq 0 ]; then
    echo "[post-build] no wk2xxx.ko found under /var/lib/dkms/wk2xxx"
    exit 0
fi

for MODULE in "${MODULES[@]}"; do
    python3 - "${MODULE}" "${KERNELVER}" <<'PYEOF'
import sys, subprocess, pathlib

ko = pathlib.Path(sys.argv[1])
target = sys.argv[2]

out = subprocess.check_output(["modinfo", "-F", "vermagic", str(ko)]).decode().strip()
current = out.split()[0]

if current == target:
    print(f"[post-build] OK ({ko}): {current}")
    sys.exit(0)

if len(current) != len(target):
    print(f"[post-build] length mismatch ({ko}): '{current}' vs '{target}'")
    sys.exit(0)

data = ko.read_bytes()
if current.encode() not in data:
    print(f"[post-build] ERROR ({ko}): '{current}' not in binary")
    sys.exit(1)

data = data.replace(current.encode(), target.encode())
ko.write_bytes(data)
print(f"[post-build] patched ({ko}): {current} -> {target}")
PYEOF
done
