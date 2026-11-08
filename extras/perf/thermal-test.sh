#!/bin/sh
# thermal-test.sh <mode cpu|cpugpu> <seconds> — logs every 10 s, aborts all load at 92 C
MODE=${1:-cpu}; DUR=${2:-300}; LIMIT=92000
P=/sys/devices/system/cpu/cpufreq/policy0; G=/sys/class/devfreq/ffa30000.gpu
echo performance > $P/scaling_governor
echo "idle: cpu=$(cat /sys/class/thermal/thermal_zone0/temp) gpu=$(cat /sys/class/thermal/thermal_zone1/temp)"
stress-ng --cpu 4 --cpu-method all --verify --timeout ${DUR}s --metrics-brief > /tmp/stress.out 2>&1 &
SP=$!
if [ $MODE = cpugpu ]; then
  echo 600000000 > $G/min_freq
  ( while :; do glmark2-es2-drm --off-screen -b terrain -b refract -b desktop >/dev/null 2>&1; done ) & GP=$!
fi
t0=$(date +%s); max=0; n=0; sf=0; sg=0
while kill -0 $SP 2>/dev/null; do
  sleep 10
  c=$(cat /sys/class/thermal/thermal_zone0/temp); g=$(cat /sys/class/thermal/thermal_zone1/temp)
  [ $c -gt $max ] && max=$c
  n=$((n+1)); sf=$((sf+$(cat $P/scaling_cur_freq)/1000)); sg=$((sg+$(cat $G/cur_freq)/1000000))
  echo "t=$(( $(date +%s)-t0 ))s cpu=$((c/1000))C gpu=$((g/1000))C f=$(( $(cat $P/scaling_cur_freq)/1000 )) gpuf=$(( $(cat $G/cur_freq)/1000000 )) cpucool=$(cat /sys/class/thermal/cooling_device0/cur_state) gpucool=$(cat /sys/class/thermal/cooling_device1/cur_state)"
  if [ $c -ge $LIMIT ] || [ $g -ge $LIMIT ]; then echo "ABORT at cpu=$c gpu=$g"; kill $SP; break; fi
done
[ -n "$GP" ] && { kill $GP; pkill -x glmark2-es2-drm; echo 0 > $G/min_freq; }
wait $SP 2>/dev/null
grep -E "passed|failed:|metrc.*cpu " /tmp/stress.out | sed 's/.*info: *\[[0-9]*\] //'
echo "max cpu temp: $((max/1000))C  avg cpu freq: $((sf/n)) MHz  avg gpu freq: $((sg/n)) MHz  policy: $(cat /sys/class/thermal/thermal_zone0/policy)"; echo schedutil > $P/scaling_governor
