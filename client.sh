#!/bin/bash
#client
#arguments：ports parallel time interrupt
#
#args:netType,serverPort
#
netType=$1
serverPort=$2
regex="[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"
chekIp=`echo $serverPort | egrep $regex | wc -l`
ports=(5001 5002)
time=60
count=3
if [ $# -ne 2 ];then
    echo "error of number parameter"
	echo "please use this format:./client netType ip"
	exit
elif [ $netType != "iperf" -a $netType != "netperf" -a $netType != "qperf" ];then
    echo "error parameter"
	echo "please use iperf or netperf or qperf"
	echo "please use this format:./client netType ip"
	exit
elif [ $chekIp -eq 0 ];then
    echo "error parameter"
	echo "please use ip that format is xxx.xxx.xxx.xxx"
	echo "please use this format:./client netType ip"
    exit
else
    which $netType
	if [ $? -eq 0 ];then
        echo "now system support $netType"
    else
        yum install -y $netType || apt install -y $netType
    fi
fi


#input:null
#output:${port}_log
function iperf(){
	#iperf command: iperf -c ip -P parallel -t time -p ports 
	parallels=(1 5 10 16 32)
	interrupt=3
	for port in ${ports[*]}
	do
		ps -ef | grep iperf | grep -v "grep --color=auto" | grep -q $port
		if [ $? -eq 0 ];then
			continue
		else
			#for ((i=1;i<=$count;i++))
			#do
				#echo "${i}count" >> ${port}_log
				echo "${port} test........"
				for parallel in ${parallels[*]}
				do
					/usr/bin/iperf -c $serverPort -P $parallel -i $interrupt -t $time -p $port | tee ${port} 
					needRows=`cat ${port} | tail -n 4 | head -n 2`
					echo "now this port is ${port} and the parallel is ${parallel}------" >> ${port}_log
					echo "${needRows}" >> ${port}_log
					rm -f ${port}
				done
				#echo >> ${port}_log
			#done
			exit
		fi	
	done
}
#input:null
#output:${port}_UDP_STREAM_log,${port}_UDP_RR_log
function netperf(){
	#netperf command:netperf -H ip -t UDP_STREAM -l time -p port -- -m size
	msizes=(1 4 16 64 256 1024 4096 16384)
	rsizes=(64 256 1024 4096 16384 32768)
	for port in ${ports[*]}
	do
		ps -ef | grep netserver | grep -v "grep --color=auto netserver" | grep -q $port
		if [ $? -eq 0 ];then
			continue
		else
		    echo "${port} test........"
		    echo -e "msize\tThroughput(10^6bits/sec)" ${port}_UDP_STREAM_log
			for msize in ${msizes[*]}
			do
				/usr/bin/netperf -H $serverPort -t UDP_STREAM -l $time -p $port -- -m $msize | tee ${port}
				#needRows=`cat ${port} | tail -n 3 | head -n 1 | awk '{print $6}'`
				needRows=`cat ${port} | sed -n '6p' | awk '{print $6}'`				
				echo -n -e "${msize}\t" >> ${port}_UDP_STREAM_log
				echo -n -e "${needRows}\n" >> ${port}_UDP_STREAM_log
				#echo >> ${port}_UDP_STREAM_log
				rm -f ${port}
			done
			exit		
		fi
	done

	for port in ${ports[*]}
	do
		ps -ef | grep $netserver | grep -v "grep --color=auto netserver" | grep -q $port
		if [ $? -eq 0 ];then
			continue
		else
		    echo -e "rsize\tRate(per sec)" >> ${port}_UDP_RR_log
			echo "${port} test........"
			for rsize in ${rsizes[*]}
			do
				/usr/bin/netperf -H serverPort -t UDP_RR -l $time -p $port -- -r $rsize | tee ${port}
				needRows=`cat ${port} | sed -n '7p' | awk '{print $6}'`				
				echo -n -e "${rsize}\t" >> ${port}_UDP_RR_log
				echo -n -e "${needRows}\n" >> ${port}_UDP_RR_log
				#echo >> ${port}_UDP_RR_log
				rm -f ${port}
			done
			exit		
		fi
	done
}
#input:null
#output:tcp_bw_lat,udp_bw_lat
function qperf(){
	#qperf command:qperf ip -oo msg_size:1:64K:*2 -vu tcp_bw tcp_lat 
	#              qperf ip -oo msg_size:1:64K:*2 -vu udp_bw udp_lat 
	/usr/bin/qperf $serverPort -oo msg_size:1:64K:*2 -vu tcp_bw tcp_lat | tee tcp
	#echo -e "tcp_size\t\tbw\t\tlat" >> tcp_bw_lat
	#msg_size=`cat tcp | grep msg_size | head -n 17 | awk '{print $3,$4}'`
	#tcp_bw=`cat tcp | grep -v tcp_bw | grep bw | awk '{print $3,$4}'`
	#latency=`cat tcp | grep latency | awk '{print $3,$4}'`
	#echo -e "${msg_size}\n${tcp_bw}\n${latency}" >> tcp_bw_lat
	echo msg_size: `cat tcp | grep msg_size | head -n 17 | awk '{print $3,$4}'` >> tcp_bw_lat
	echo tcp_bw: `cat tcp | grep -v tcp_bw | grep bw | awk '{print $3,$4}'` >> tcp_bw_lat
	echo latency: `cat tcp | grep latency | awk '{print $3,$4}'` >> tcp_bw_lat
	rm -f tcp

	/usr/bin/qperf $serverPort -oo msg_size:1:64K:*2 -vu udp_bw udp_lat | tee udp
	#echo -e "udp_size\t\tbw\t\tlat" >> udp_bw_lat
	#msg_size=`cat udp | grep msg_size | head -n 17 | awk '{print $3,$4}'`
	#send_bw=`cat udp | grep send_bw | awk '{print $3,$4}'`
	#recv_bw=`cat udp | grep recv_bw | awk '{print $3,$4}'`
	#latency=`cat udp | grep latency | awk '{print $3,$4}'`
	#echo -e "${msg_size}\n${send_bw}\n${recv_bw}\n${latency}" >> udp_bw_lat
	echo msg_size: `cat udp | grep msg_size | head -n 17 | awk '{print $3,$4}'` >> udp_bw_lat
	echo send_bw: `cat udp | grep send_bw | awk '{print $3,$4}'` >> udp_bw_lat
	echo recv_bw: `cat udp | grep recv_bw | awk '{print $3,$4}'` >> udp_bw_lat
	echo latency: `cat udp | grep latency | awk '{print $3,$4}'` >> udp_bw_lat
	rm -f udp
}

case $netType in
iperf)
    iperf
;;
netperf)
    netperf
;;
qperf)
    qperf
;;
esac 






