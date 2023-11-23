#!/bin/bash

mdadm --zero-superblock --force /dev/sd{b,c,d,e,f,g}

wipefs --all --force /dev/sd{b,c,d,e,f,g}

mdadm --create --verbose /dev/md0 -l 5 -n 3 /dev/sd{b,c,d}

echo "Information of arrays RAID5:"

mdadm -D /dev/md0

mkdir /etc/mdadm/

echo "DEVICE partitions" > /etc/mdadm/mdadm.conf

mdadm --detail --scan | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf

