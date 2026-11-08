#!/bin/sh
# Live backlight PWM sweep (run on the tablet). Keeps pwm-backlight bound (unbinding it tears
# down the panel + DRM via device links!) and rewrites the RK3288 PWM0 registers directly.
# PWM0 @0xff680000: +4 PERIOD, +8 DUTY (counts of the 74.25 MHz pclk, prescale 1, inverted pol).
# Usage: pwm-sweep.sh <seconds per step> "label:freq_khz:duty_percent" ...
STEP=$1; shift
CLK=74250
for t in "$@"; do
    lab=${t%%:*}; rest=${t#*:}; khz=${rest%%:*}; pct=${rest#*:}
    per=$((CLK / khz)); duty=$((per * pct / 100))
    devmem2 0xff680008 w 0 >/dev/null
    devmem2 0xff680004 w $per >/dev/null
    devmem2 0xff680008 w $duty >/dev/null
    msg="TEST $lab   $khz kHz   $pct %"
    printf '\033[2J\033[H\n\n\n\n\n        %s\n\n\n' "$msg" > /dev/tty1
    echo "$msg  (period $per, duty $duty counts)"
    sleep $STEP
done
