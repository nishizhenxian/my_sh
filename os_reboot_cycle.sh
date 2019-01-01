
#!/bin/bash
log=os_reboot_testlog.txt
cnt=count.cur
curPath=`pwd`
delay=30
err=0

cycleNum=$1
regex="^[1-9][0-9]*$"
chenkNum=`echo $cycleNum | egrep $regex | wc -l`
nowDate=`date "+%Y-%m-%d %H:%M:%S"`

#check input parameter
if [ $# -ne 1 ];then
	echo "Error:This test should set cycleNums"
	echo "please use this format:./os_reboot_cycle.sh xxx"
	exit 
elif [ $chenkNum -eq 0 ];then
    echo "please input a vaild number."
	exit
fi



#stop cycle
#1 echo 9999 > count.cur


#set up startup script
startFile=""
if cat /etc/issue | grep -i "suse";then
	startFile="/etc/init.d/boot.local"
	touch $startFile
	chmod a+x $startFile
elif [ -e /etc/redhat-release ];then
	startFile="/etc/rc.d/rc.local"
	mv $startFile .
	touch $startFile
	chmod a+x $startFile
elif  cat /etc/issue | grep -i ubuntu;then
	startFile="/etc/rc.local"
	touch $startFile
	chmod a+x $startFile
else
	echo "$nowDate can not get OS vendor" 
	exit 
fi

function check(){
	bash checkall	
	if [ $? -ne 0 ];then
		echo "$nowDate the $count check FAIL" >> $log
		err=1
	else
		echo "$nowDate the $count check OK" >> $log
	fi
}
#first run this script
cat $startfile | grep "os_reboot_cycle"
if [ $? -ne 0 ];then
    echo "0" > $cnt
	count=`cat $cnt`
    cat << EOF >> $startFile
	#!/bin/bash 
	cd $curpath
	bash os_reboot_cycle $cycleNum
	cat count.cur
EOF
	check
	echo "$nowDate count is $count, start cycling" >> $log
else
	count=`cat $cnt`
	let count++
    check
	echo $count > $cnt
	
	#if count is full, stop test
	if [ $count -ge $cycleNum ];then	
		if [ -e /etc/redhat-release ];then
			mv rc.local /etc/rc.d/.
		fi
		echo "$nowDate the $count is full, stop cycling" >> $log
	fi	
fi


#process err mesage
if [ $err -ne 0 ];then
	if [ $count -lt $cycleNum ];then
		echo "$nowDate the $count cycle error, stop cycling" >> $log
		exit
    fi
else
	echo "$nowDate the $count os reset cycle pass" >> $log
fi


#########processing area###########
echo "-----$(cat $CNT)-------"  >> log_test
fio -name=mytest -filename=/dev/sda1:/dev/sdb1:/dev/sdc3  -blocksize=64 -runtime=30 -rw=randrw -rwmixread=50 -rwmixwrite=50 >> log_test
echo "-----------------------------" >> log_test



###################################

sleep $delay
reboot








