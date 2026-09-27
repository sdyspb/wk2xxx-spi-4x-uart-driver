#!/bin/bash
# WK2xxx UART test script
# Usage: ./test-minicom.sh [port] [baud]

PORT="${1:-/dev/ttyWK0}"
BAUD="${2:-115200}"

echo "=== WK2xxx UART Test ==="
echo "Port: $PORT"
echo "Baud: $BAUD"
echo

# Check driver
if ! lsmod | grep -q '^wk2xxx'; then
    echo "ERROR: wk2xxx module not loaded"
    echo "Run: sudo modprobe wk2xxx"
    exit 1
fi
echo "OK: driver loaded"

# Check port exists
if [ ! -c "$PORT" ]; then
    echo "ERROR: $PORT not found"
    ls /dev/ttyWK* 2>/dev/null
    exit 1
fi
echo "OK: $PORT exists"

# Configure port
sudo stty -F "$PORT" "$BAUD" cs8 -cstopb -parenb raw -echo
echo "OK: port configured ($BAUD 8N1 raw)"

echo
echo "=== Test options ==="
echo "1. Loopback (short TX-RX on the connector)"
echo "2. Manual test with minicom"
echo "3. Send one byte and exit"
echo
read -p "Choose [1-3]: " choice

case "$choice" in
    1)
        echo "Testing loopback..."
        ( sudo timeout 3 cat "$PORT" > /tmp/wk_loop.out & ) ; sleep 0.3
        sudo sh -c "printf 'ABC' > $PORT"
        sleep 3
        if [ -s /tmp/wk_loop.out ]; then
            echo "OK: loopback works, received:"
            xxd /tmp/wk_loop.out
        else
            echo "FAIL: no data received (check TX-RX short)"
        fi
        ;;
    2)
        echo "Starting minicom on $PORT at $BAUD..."
        echo "Exit: Ctrl+A, then X"
        sudo minicom -D "$PORT" -b "$BAUD"
        ;;
    3)
        echo "Sending 'A'..."
        sudo timeout 3 sh -c "printf 'A' > $PORT"
        echo "Done (check with oscilloscope/logic analyzer)"
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac
