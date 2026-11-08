#!/bin/sh
# colorbars.sh — labelled pure-colour bars (24-bit escape codes) for checking the panel channel order
bar(){ printf '\033[1;38;2;255;255;255;48;2;0;0;0m %-8s \033[0m\033[48;2;%s;%s;%sm%*s\033[0m\n' "$1" $2 $3 $4 100 ''; }
clear
for i in 1 2; do
bar RED 255 0 0; bar GREEN 0 255 0; bar BLUE 0 0 255; bar YELLOW 255 255 0
bar CYAN 0 255 255; bar MAGENTA 255 0 255; bar WHITE 255 255 255; echo
done
sleep 100000
