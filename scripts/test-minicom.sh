#!/bin/bash
# WK2xxx UART test helper.
# Usage: ./test-minicom.sh [port] [baud]

PORT="${1:-/dev/ttyWK0}"
BAUD="${2:-115200}"

echo "=== WK2xxx UART Test ==="
echo "Port: ${PORT}"
echo "Baud: ${BAUD}"
echo

if ! lsmod | grep -q '^wk2xxx'; then
    echo "ERROR: wk2xxx not loaded. Run: sudo modprobe wk2xxx"
    exit 1
fi
echo "OK: driver loaded"

if [ ! -c "${PORT}" ]; then
    echo "ERROR: ${PORT} not found."
    ls /dev/ttyWK* 2>/dev/null
    exit 1
fi
echo "OK: ${PORT} exists"

sudo stty -F "${PORT}" "${BAUD}" cs8 -cstopb -parenb raw -echo
echo "OK: configured ${BAUD} 8N1 raw"
echo

echo "1. Loopback test (short TX-RX)"
echo "2. Interactive minicom"
echo "3. Send one byte"
read -p "Choose [1-3]: " choice

case "${choice}" in
    1)
        ( sudo timeout 3 cat "${PORT}" > /tmp/wk_loop.out & ) ; sleep 0.3
        sudo sh -c "printf 'ABC' > ${PORT}"
        sleep 3
        if [ -s /tmp/wk_loop.out ]; then
            echo "OK: loopback works"
            xxd /tmp/wk_loop.out
        else
            echo "FAIL: no data received"
        fi
        ;;
    2)
        sudo minicom -D "${PORT}" -b "${BAUD}"
        ;;
    3)
        sudo timeout 3 sh -c "printf 'A' > ${PORT}"
        echo "Sent."
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac
