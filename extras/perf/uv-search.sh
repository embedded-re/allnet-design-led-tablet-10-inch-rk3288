#!/bin/bash
# Undervolt search for one CPU frequency. usage: uv-search.sh <kHz> <start_mV> <min_mV> [secs]
# Pins the CPU at <kHz>, writes SYR827 VSEL0 directly (i2c0 0x40), stress-ng --verify per step.
# Log: extras/perf/uv-log.txt  (one line per step: freq mV result temp)
F=$1; MV=$2; MIN=$3; SECS=${4:-30}
cd "$(dirname "$0")/../.."
TSH=port/emmc/tsh; LOG=extras/perf/uv-log.txt
wait_up(){ for i in $(seq 1 60); do sleep 3; $TSH true 2>/dev/null && return 0; done; return 1; }
while [ $MV -ge $MIN ]; do
  code=$(( (MV*10 - 7125) / 125 )); hex=$(printf '0x%02x' $((0x80 | code)))
  out=$(timeout $((SECS+40)) $TSH "
    P=/sys/devices/system/cpu/cpufreq/policy0
    echo performance > \$P/scaling_governor
    echo 126000 > \$P/scaling_min_freq; echo $F > \$P/scaling_max_freq; echo $F > \$P/scaling_min_freq
    sleep 0.2; [ \$(cat \$P/scaling_cur_freq) = $F ] || { echo BADFREQ; exit; }
    i2cset -f -y 0 0x40 0x00 $hex; sleep 0.1
    r=\$(stress-ng --cpu 4 --cpu-method all --verify --timeout ${SECS}s 2>&1)
    f2=\$(cat \$P/scaling_cur_freq); t=\$(cat /sys/class/thermal/thermal_zone0/temp)
    echo \"\$r\" | grep -qE 'failed: 0' && ! echo \"\$r\" | grep -qiE 'fail.*[1-9]|error' && res=PASS || res=FAIL
    [ \$f2 = $F ] || res=\"\$res(freq-changed-\$f2)\"
    echo \"\$res t=\$t\"
    # restore firmware-owned voltage for this OPP before returning
    echo 126000 > \$P/scaling_min_freq; echo schedutil > \$P/scaling_governor
  " 2>&1 | tail -1)
  [ -z "$out" ] && out="CRASH"
  echo "$(date +%T) f=$F mV=$MV vsel=$hex -> $out" | tee -a $LOG
  case "$out" in
    PASS*) MV=$((MV-25));;
    *) [ "$out" = CRASH ] && { echo "waiting for reboot..."; wait_up && echo up; }; exit 1;;
  esac
done
