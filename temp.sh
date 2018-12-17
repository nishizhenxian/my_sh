#!/bin/bash
while [ 1 == 1 ]
do
sleep 5
busybox devmem 0x940120d0 8 0x01
ts=$(busybox devmem 0x940120d0)
    if [ $ts == "0x00000001" ]
    then
        value=$(busybox devmem 0x940160d4)
        echo $value
        echo "last of three number is:${value:0-3:3}"
        hexva=$((0x${value:0-3:3}))
        echo "number of hex is: $hexva"
        decva=$[($hexva-109)*165/798-40]
        echo "now this CPU temperature is: $decva"
        date	
    fi
done
