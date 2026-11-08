#!/bin/sh
# usage: cpu-test.sh [seconds]  — 7z bench + stress-ng verify, aborts load at 92 C
DUR=${1:-120}; LIMIT=92000
P=/sys/devices/system/cpu/cpufreq/policy0
V=$(for r in /sys/class/regulator/*; do [ "$(cat $r/name)" = vdd_cpu ] && echo $r; done)
T(){ cat /sys/class/thermal/thermal_zone0/temp; }
echo performance > $P/scaling_governor
echo "idle: $(T) mC  freq=$(cat $P/scaling_cur_freq)"
( while :; do t=$(T); echo "mon t=$t f=$(cat $P/scaling_cur_freq) v=$(cat $V/microvolts) cool=$(cat /sys/class/thermal/cooling_device0/cur_state)";
  if [ $t -ge $LIMIT ]; then echo "ABORT: $t >= $LIMIT"; pkill -9 7zz; pkill -9 7z; pkill -9 stress-ng; fi; sleep 5; done ) & M=$!
7z b -mmt4 2>&1 | grep -E "^(Avr|Tot)"
stress-ng --cpu 4 --cpu-method all --verify --timeout ${DUR}s --metrics-brief 2>&1 | grep -vE "^stress-ng: info: +\[[0-9]+\] (setting|dispatching|skipped|cache|note)"
kill $M; echo "end: $(T) mC"; echo schedutil > $P/scaling_governor
cat $P/stats/time_in_state | awk '$2>0'
