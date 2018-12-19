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
    netTool=`which $netType`
	if [ $? -eq 0 ];then
        echo "now system support $netType"
    else
        yum install -y which bc  $netType || apt install -y bc which $netType
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
		ps -ef | grep -v "grep --color=auto" | grep -q "$netType -s"
		if [ $? -eq 0 ];then
			ps -ef | grep -v "$netType -s" | grep "$netType -c"| grep -q $port
			if [ $? -eq 0 ];then
				continue
			else
				#for ((i=1;i<=$count;i++))
				#do
					#echo "${i}count" >> ${port}_log
					echo "${port} test........"
					for parallel in ${parallels[*]}
					do
						$netTool -c $serverPort -P $parallel -i $interrupt -t $time -p $port | tee ${port} 
						needRows=`cat ${port} | tail -n 4 | head -n 2`
						echo "now this port is ${port} and the parallel is ${parallel}------" >> ${port}_log
						echo "${needRows}" >> ${port}_log
						rm -f ${port}
					done
					#echo >> ${port}_log
				#done
				exit
			fi
		
		else
			ps -ef | grep "$netType -c"| grep -q $port
			if [ $? -eq 0 ];then
				continue
			else
				#for ((i=1;i<=$count;i++))
				#do
					#echo "${i}count" >> ${port}_log
					echo "${port} test........"
					for parallel in ${parallels[*]}
					do
						$netTool -c $serverPort -P $parallel -i $interrupt -t $time -p $port | tee ${port} 
						needRows=`cat ${port} | tail -n 4 | head -n 2`
						echo "now this port is ${port} and the parallel is ${parallel}------" >> ${port}_log
						echo "${needRows}" >> ${port}_log
						rm -f ${port}
					done
					#echo >> ${port}_log
				#done
				exit
			fi		
		fi	
	done
}
#input:null
#output:${port}_UDP_STREAM_log,${port}_UDP_RR_log
function install_netperf(){
	wget http://htsat.vicp.cc:804/liubeijie/netperf-2.5.0.tar.gz;
	tar -zxvf netperf-2.5.0.tar.gz;
	cd netperf-netperf-2.5.0;
	./configure -build=alpha;
	make;make install
}
function netperf_UDP_STREAM(){
	#netperf command:netperf -H ip -t UDP_STREAM -l time -p port -- -m msize
	msizes=(1 4 16 64 256 1024 4096 16384 32768 65507)
	for port in ${ports[*]}
	do
		ps -ef | grep "$netType" | grep -v "grep --color=auto" | grep -q $port
		if [ $? -eq 0 ];then
			continue
		else
		    echo "${port} test........"
		    echo -e "msize\tThroughput(10^6bits/sec)" >> ${port}_UDP_STREAM_log
			for msize in ${msizes[*]}
			do
				$netTool -H $serverPort -t UDP_STREAM -l $time -p $port -- -m $msize | tee ${port}
				#needRows=`cat ${port} | tail -n 3 | head -n 1 | awk '{print $6}'`
				needRows=`cat ${port} | sed -n '6p' | awk '{print $6}'`				
				echo -n -e "${msize}\t" >> ${port}_UDP_STREAM_log
				echo -n -e "${needRows}\n" >> ${port}_UDP_STREAM_log
				#echo >> ${port}_UDP_STREAM_log
				rm -f ${port}
			done
			break		
		fi
	done
}
#input:null
#output:tcp_bw_lat,udp_bw_lat
function netperf_UDP_RR(){
	#netperf command:netperf -H ip -t UDP_RR -l time -p port -- -r rsize
	rsizes=(64 256 1024 4096 16384 32768)
	for port in ${ports[*]}
	do
		ps -ef | grep "$netType" | grep -v "grep --color=auto" | grep -q $port
		if [ $? -eq 0 ];then
			continue
		else
		    echo -e "rsize\tRate(per sec)" >> ${port}_UDP_RR_log
			echo "${port} test........"
			for rsize in ${rsizes[*]}
			do
				$netTool -H $serverPort -t UDP_RR -l $time -p $port -- -r $rsize | tee ${port}
				needRows=`cat ${port} | sed -n '7p' | awk '{print $6}'`				
				echo -n -e "${rsize}\t" >> ${port}_UDP_RR_log
				echo -n -e "${needRows}\n" >> ${port}_UDP_RR_log
				#echo >> ${port}_UDP_RR_log
				rm -f ${port}
			done
			break		
		fi
	done
}


function num_unit(){
	nums=($1)
	units=($2)
	let totalNums=${#nums[*]}-1
	for ((i=0; i<=${totalNums}; i++))
	do
		case ${units[$i]} in
			KB/sec)
				awk 'BEGIN{printf "%.2f\n",('${nums[$i]}'/1024)}'
			;;
			MB/sec)
				echo ${nums[$i]}
			;;
			GB/sec)
				echo "${nums[$i]}*1024" | bc
			;;
			bytes/sec)
				echo ${nums[$i]}
			;;
		esac
	done
}

function qperf(){
	#qperf ip -oo msg_size:1:64K:*2 -vu tcp_bw tcp_lat 
	$netTool $serverPort -oo msg_size:1:64K:*2 -vu tcp_bw tcp_lat | tee tcp
	tcp_bw_num=`cat tcp | grep -v tcp_bw | grep bw | awk '{print $3}'`
	tcp_bw_unit=`cat tcp | grep -v tcp_bw | grep bw | awk '{print $4}'`
	echo "******tcp_bw*********"
	num_unit "${tcp_bw_num[*]}" "${tcp_bw_unit[*]}"		
	echo "******latency*********"
	echo "`cat tcp | grep latency | awk '{print $3}'`"
		
	#qperf ip -oo msg_size:1:64K:*2 -vu udp_bw udp_lat
	$netTool $serverPort -oo msg_size:1:64K:*2 -vu udp_bw udp_lat | tee udp
	send_bw_num=`cat udp | grep send_bw | awk '{print $3}'` 
	send_bw_unit=`cat udp | grep send_bw | awk '{print $4}'` 
	recv_bw_num=`cat udp | grep recv_bw | awk '{print $3}'` 
	recv_bw_unit=`cat udp | grep recv_bw | awk '{print $4}'`	
	echo "******udp_send_bw*********"
	num_unit "${send_bw_num[*]}" "${send_bw_unit[*]}"	
	echo "******udp_recv_bw*********"
	num_unit "${recv_bw_num[*]}" "${recv_bw_unit[*]}"	
	echo "******latency*********"
	echo "`cat udp | grep latency | awk '{print $3}'`" 	
	rm -f tcp udp
}

#for in ((i=0;i<=$count;i++))
#do
case $netType in
iperf)
    iperf
;;
netperf)
#	install_netperf
    netperf_UDP_STREAM
	netperf_UDP_RR
;;
qperf)
    qperf
;;
esac
#done









