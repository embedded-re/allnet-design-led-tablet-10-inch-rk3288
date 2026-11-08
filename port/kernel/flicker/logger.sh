#!/bin/sh
# 1 Hz log: time temp0 temp1 cpufreq gpufreq load
while :; do
  echo "$(date +%T) $(cat /sys/class/thermal/thermal_zone0/temp) $(cat /sys/class/thermal/thermal_zone1/temp) $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq) $(cat /sys/class/devfreq/ffa30000.gpu/cur_freq) $(cut -d' ' -f1 /proc/loadavg)"
  sleep 1
done
