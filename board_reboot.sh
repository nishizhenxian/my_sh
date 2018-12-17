 #! /bin/sh
#
# chkconfig: 35 99 99
# description:Init file for reboot OS
#
log_file=/var/log/tan_reboot.log
count_file=/var/log/tan_reboot.count

r_first() {
	echo 0 > $count_file
	echo "Reboot test starting..." | tee -a $log_file 
	reboot
}

r_second(){
	count=`cat $count_file`
	if [ $count -lt 100 ]
	then
	    count=`expr $count + 1`
		echo "The $count reboot finished at `date`"| tee -a $log_file 
		#fdisk -l >/tmp/01NUM/num_"`date`".log
		#ifconfig -a|grep -i eth >/root/ethx_"`date`".log 
		#lsusb >/root/lspci_"`date`".log
		#free >/root/iomem_"`date`".log
		#dmesg|egrep 'error|fail' >/root/dmesg_"`date`".log
		echo $count > $count_file
		#ipmitool chassis power cycle
		reboot
	else
		echo "counter is full, stop cycling"| tee -a $log_file
		exit
	fi
}

if [ -f $count_file ]
then
	r_second
else
	r_first
fi
	
	
	
