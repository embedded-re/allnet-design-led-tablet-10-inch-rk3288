#!/bin/bash
# sweep.sh <N>  : flash UART-sweep recovery N, boot into it, capture UART2-pad for 30s
# Keep your FTDI on the SAME pad throughout. Whichever N prints bytes = the SoC UART wired to that pad.
D="$(dirname "$0")"; N="$1"; BAUD="${2:-115200}"
img="$D/rec_uart${N}.img"; [ -f "$img" ] || { echo "no $img"; exit 1; }
# get to loader mode
adb reboot loader >/dev/null 2>&1
for i in $(seq 40); do rkdeveloptool ld 2>/dev/null | grep -q Loader && break; sleep 1; done
rkdeveloptool ld 2>/dev/null | grep -q Loader || { echo "device not in loader mode"; exit 1; }
rkdeveloptool wl 0x30000 "$img"          >/dev/null 2>&1 || { echo "flash failed"; exit 1; }
rkdeveloptool wl 0x6000 "$D/misc_recovery.bin" >/dev/null 2>&1
log="$D/sweep_uart${N}.log"; : > "$log"
# capture in background for 30s at BAUD
timeout 32 python3 "$D/uart.py" "$log" "$BAUD" &
cap=$!
sleep 1; rkdeveloptool rd >/dev/null 2>&1
wait $cap 2>/dev/null
n=$(wc -c < "$log")
echo "UART$N (0x$(python3 -c "print(['ff180000','ff190000','ff690000','ff1b0000','ff1c0000'][$N])")) baud=$BAUD : captured ${n} bytes"
[ "$n" -gt 0 ] && { echo "---- first output ----"; head -c 400 "$log" | strings | head; }
