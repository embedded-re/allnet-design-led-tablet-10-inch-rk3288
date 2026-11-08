#!/bin/sh
# Bounce eth0 N times and count stmmac "Failed to reset the dma"; restores networking at the end.
N=${1:-10}; LOG=/root/eth-bounce.log
base=$(dmesg | grep -c "Failed to reset the dma")
echo "start $(date +%T) base=$base" > $LOG
for i in $(seq 1 $N); do
    ip link set eth0 down; sleep 2
    before=$(dmesg | grep -c "Failed to reset the dma")
    ip link set eth0 up; sleep 2
    after=$(dmesg | grep -c "Failed to reset the dma")
    echo "cycle $i: $([ $after -gt $before ] && echo FAIL || echo ok) operstate=$(cat /sys/class/net/eth0/operstate)" >> $LOG
done
echo "fails=$(( $(dmesg | grep -c 'Failed to reset the dma') - base ))/$N" >> $LOG
/etc/local.d/net-retry.start >> $LOG 2>&1
echo "end $(date +%T) $(ip -4 -o addr show eth0 | awk '{print $4}')" >> $LOG
