#!/bin/bash

L=0
B=20

parted -s /dev/md0 mklabel gpt

for i in $(seq 1 5);
        do
        parted /dev/md0 mkpart primary ext4 $L% $B%
        L=$((L+=20))
        B=$((B+=20))
        done

