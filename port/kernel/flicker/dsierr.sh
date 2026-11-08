#!/bin/sh
# log DSI_INT_ST0/ST1 (clear-on-read) whenever non-zero, polled every 0.2 s
while :; do
  a=$(devmem2 0xff9600bc w | sed -n 's/.*: //p'); b=$(devmem2 0xff9600c0 w | sed -n 's/.*: //p')
  [ "$a$b" != "0x000000000x00000000" ] && echo "$(cut -d' ' -f1 /proc/uptime) ST0=$a ST1=$b"
  sleep 0.2
done
