#!/bin/bash

#如果不存在创建文件赋予执行权限存在，清空后添加内容
#文件名：board_reboot.sh
#参数：运行多少次，或者写到文件里
cycleNum=$1
regex="^[1-9][0-9]*$"
checkNum=`echo $cycleNum | egrep $regex | wc -l`
curPath=`pwd`
CNT=counter.cur
LOG=os_reboot_testlog.txt
if [ $# -ne 1];then
    echo "Error:This test should set cycle nums"
	echo "please use this format:./board_reboot nums"
	exit
elif [ $cycleNum -eq 0 ];then
    echo "please input a vaild number"
	exit

fi
#determine /etc/rc.local
if cat /etc/redhat-release | grep -i centos
    startFile="/etc/rc.d/rc.local"
	cp $startFile /etc/rc.d/rc.local.bak
	touch $startFile
	chmod a+x $startFile
elif cat /etc/issue | grep -i debian
    startFile="/etc/rc.local"
	touch $startFile
	chmod a+x $startFile
else
    echo "Not't support this distribution"
	exit
fi





#first run this script
cat $startFile | grep "board_reboot.sh"
if [ $? -ne 0 ];then 
	cat << EOF >> $startFile
	#!/bin/bash
	cd $curPath
	bash board_reboot.sh $cycleNum &
	cat $CNT
EOF
    echo 0 > $CNT
	echo "Reboot test starting..." | tee -a $LOG
else
	count=`cat $CNT`
	let count=$count+1
	echo $count > $CNT
	nowDate=`date "+%Y-%m-%d %H:%M:%S"`
	echo "The $count reboot is finished at $nowDate" | tee -a $LOG
	if [ $count -ge $cycleNum];then
		nowDate=`date "+%Y-%m-%d %H:%M:%S"`
		echo "$nowDate the $count is full,stop cycling" | tee -a $LOG
		if cat /etc/redhat-release | grep -i centos
		    rm -f $startFile
		    cp /etc/rc.d/rc.local.bak /etc/rc.d/rc.local
		elif cat /etc/issue | grep -i debian
		    rm -f $startFile
		else
            echo "Not't support this distribution"
	        exit
        fi	
	fi
fi

sleep 10
reboot






