#!/bin/bash
# Copyright (C) 2018-8-29, Estuary
# Author: wangsisi

# Test user id
if [ `whoami` != 'root' ] ; then
    echo "You must be the superuser to run this script" >&2
    exit 1
fi

cd ../../../../utils
.        ./sys_info.sh
.        ./sh-test-lib
cd -

###################  Environmental preparation  #######################

######################  testing the step #############################
case "${distro}" in
    debian)
	install_source_version_remove(){    
		p=$1
		apt-get install -y $p
        print_info $? ${p}_install
		s=$(apt show $p | grep "Source" | awk '{print $2}')	             
		v=$(apt show $p | grep "Version" | awk '{print $2}')
		
		if [ "$s" = "${source1}" -o "$s" = "${source2}" ];then				                 
		   print_info 0 ${p}_source
		else
		   print_info 1 ${p}_source
		fi

		if [ "$v" = "${iversion}" -o "$v" = "${version2}" -o "$v" = "${version3}" ];then
			print_info 0 ${p}_version
		else
			print_info 1 ${p}_version
		fi

		uname=$(uname -r)
		if [ "$p" = "linux-image-${uname}" ];then
		echo -e "$blue this package isn't remove$NC"
		else
		   apt remove -y $p
		   print_info $? ${p}_remove
		fi
	}

	apt-get install -y libcpupower-dev linux-estuary-doc usbip > /dev/null
	iversion=$(apt show libcpupower-dev| grep "Version" | awk '{print $2}')
	version2=$(apt show linux-estuary-doc| grep "Version" | awk '{print $2}')
	version3=$(apt show usbip| grep "Version" | awk '{print $2}')
	source1=$(apt show libcpupower-dev| grep "Source"|awk '{print $2}')
	source2=$(apt show linux-estuary-doc| grep "Source"|awk '{print $2}')
	apt-get remove -y libcpupower-dev linux-estuary-doc usbip > /dev/null
	package_list="libcpupower1 libcpupower-dev linux-cpupower linux-estuary-doc linux-estuary-perf linux-estuary-source linux-headers linux-headers-estuary-arm64 linux-image linux-image-estuary-arm64 linux-kbuild linux-libc-dev linux-perf linux-source linux-support usbip "
#	package_list="linux-perf linux-source "
#   package_list="libcpupower1 linux-estuary-doc linux-estuary-perf linux-estuary-source linux-headers-estuary-arm64 linux-image-estuary-arm64"
	for p in ${package_list};do
		echo "$p install................."
		apt-get install -y $p
		status=0	
		vs=$(apt show $p | grep "Version" | awk '{print $2}')
		if [ "$vs" != "$iversion" -a "$vs" != "$version2" -a "$vs" != "$version3" ];then
			status=1
		fi

		if [ $status -eq 0 ];then
			install_source_version_remove $p
		else
			pa=$(apt search $p | grep $iversion | grep -v db | grep $p |cut -d "/" -f 1)
			pa_num=$(apt search $p | grep $iversion | grep -v db | grep $p |cut -d "/" -f 1|wc -l)
			if [ $pa_num = 1 ]; then
			    install_source_version_remove $pa
			else
				for i in $pa ;do
				    install_source_version_remove $i
				done
			fi
		fi
	done
	;;
    centos)
        install_from_repo_source_version_remove(){
			p=$1
			yum install -y $p > /dev/null
			print_info $? ${p}_install
			v=$(yum info $p | grep -i "version" | awk '{print $3}')
			r=$(yum info $p | grep -i "release" | awk '{print $3}')
			f=$(yum info $p | grep -i "from repo" | awk '{print $4}')

			if [ "$f" = "$from_repo" ];then
				print_info 0 ${p}_from_repo
			else
				print_info 1 ${p}_from_repo
			fi

			if [ "$r" = "${release}" ];then
			   print_info 0 ${p}_source
			else
			   print_info 1 ${p}_source
			fi

			if [ "$v" = "${version}" ];then
				print_info 0 ${p}_version
			else
				print_info 1 ${p}_version
			fi

			yum remove -y $p
			print_info $? ${p}_remove > /dev/null
        }
	    yum install -y kernel-tools-libs-devel >/dev/null
        version=$(yum info kernel-tools-libs-devel | grep -i "version" | awk '{print $3}')
        release=$(yum info kernel-tools-libs-devel | grep -i "release" | awk '{print $3}')
        from_repo=$(yum info kernel-tools-libs-devel | grep -i "from repo" | awk '{print $4}')
        yum remove -y kernel-tools-libs-devel > /dev/null

        package_list="kernel-devel kernel-headers kernel-tools-libs kernel-tools-libs-devel perf python-perf  kernel-debug kernel-debug-debuginfo"
        for pa in ${package_list};do
            echo "$pa install............."
            install_from_repo_source_version_remove $pa
	    done
    ;;
esac
