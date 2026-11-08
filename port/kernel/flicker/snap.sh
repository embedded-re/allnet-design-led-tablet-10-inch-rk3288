#!/bin/sh
# Snapshot display-related state. Usage: snap.sh > file
r() { # base count(words)
  b=$1; n=$2; i=0
  while [ $i -lt $n ]; do a=$(printf 0x%08x $((b + i*4)))
    v=$(devmem2 $a w 2>/dev/null | sed -n 's/.*: \(0x[0-9A-Fa-f]*\)$/\1/p'); echo "$a $v"; i=$((i+1)); done; }
echo "### date/uptime"; date; uptime
echo "### thermal"; cat /sys/class/thermal/thermal_zone*/temp
echo "### cpufreq"; cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor; cat /sys/devices/system/cpu/cpu0/cpufreq/stats/time_in_state 2>/dev/null
echo "### gpu devfreq"; cat /sys/class/devfreq/*/cur_freq
echo "### backlight"; for f in brightness actual_brightness bl_power; do echo "$f $(cat /sys/class/backlight/*/$f)"; done
echo "### pwm debugfs"; cat /sys/kernel/debug/pwm 2>/dev/null
echo "### dri state"; cat /sys/kernel/debug/dri/*/state 2>/dev/null
echo "### clk_summary (display/pll/pwm/dsi/vop)"; grep -Ei 'pll|vop|dsi|pwm|dclk|aclk_vio|hclk_vio|lcdc|mipi|24m' /sys/kernel/debug/clk/clk_summary
echo "### regulator_summary"; cat /sys/kernel/debug/regulator/regulator_summary
echo "### PWM0 0xff680000"; r 0xff680000 4
echo "### DSI0 0xff960000"; r 0xff960000 54
echo "### VOPB 0xff930000"; r 0xff930000 128
echo "### VOPL 0xff940000"; r 0xff940000 128
echo "### GRF SOC_CON6/CON14/CON15 (dsi/lvds sel)"; r 0xff77025c 1; r 0xff77027c 2
echo "### interrupts"; grep -Ei "vop|dsi|eth|mmc|dw_" /proc/interrupts
echo "### dmesg drm/dsi/panel"; dmesg | grep -Ei 'dsi|panel|vop|drm|backlight|jadard' | tail -40
