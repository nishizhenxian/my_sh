#!/bin/bash
#server
#input:netType
#output:null
#
#
netType=$1
ports=(5001 5002)
#preparation
if [ $# -ne 1 ];then
    echo "error of number parameter"
	echo "please this use this format: ./server.sh netType"
	exit
elif [ $netType != "iperf" -a $netType != "netperf" -a $netType != "qperf" ];then
    echo "error parameter"
    echo "please use iperf or netperf or qperf"
	exit
else
    which $netType
	if [ $? -eq 0 ];then
        echo "now system support $netType"
    else
        yum install -y $netType || apt install -y $netType
    fi
fi

#open server port
case $netType in
iperf)
	for i in ${ports[*]}
	do
		echo $i
		ps -ef | grep iperf | grep -v "grep --color=auto" | grep -q $i   
		if [ $? -eq 0  ];then
			continue
		else
			iperf -s -p $i
			break          
		fi
	done
;;
netperf)
	for i in ${ports[*]}
	do
		echo $i
		ps -ef | grep netserver | grep -v "grep --color=auto" | grep -q $i   
		if [ $? -eq 0  ];then
			continue
		else
			netserver -p $i
			break          
		fi
	done
;;
qperf)
    qperf
;;
esac













