#!/bin/bash
for i in {0..255}
do
    num=`dmidecode -t $i | wc -l`
    if [ $num -eq 4  ];then
        continue
    elif [ $num -gt 4 ];then
        echo "$i"
        dmidecode -t $i | head -n 40
        echo "----------------------------"
    else
        echo "$i"
        dmidecode -t $i
        echo "----------------------------"
    fi
done
