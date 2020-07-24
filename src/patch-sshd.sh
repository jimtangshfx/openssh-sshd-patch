#!/bin/bash
#A shell script written by Jim T to patch the sshd file and print out debug info in /var/log/auth.log .
#Be sure that root user has called this
case `id -un` in

#case user root
   "root")
;;

#case another user called it
    *)
echo "Must be root run this utility" 2>&1
exit 1
;;
esac
echo "Welcome to sshd debug tool. Please do not close current ssh session before and after running this script until you make sure the new sshd is working and you can establish new ssh connection to restarted sshd service."
echo "Otherwise, you may lose ssh access forever!"
echo "In case anything goes wrong, you can simply run 'rm -f /usr/sbin/sshd','cp /usr/sbin/sshd.bak /usr/sbin/sshd' then 'service ssh restart' to roll back to original sshd".

#checking OS version.
MY_U1604_FLAG=`grep -c "DISTRIB_RELEASE=16.04" /etc/lsb-release`
MY_U1404_FLAG=`grep -c "DISTRIB_RELEASE=14.04" /etc/lsb-release`
if [ $MY_U1604_FLAG -eq 0 ] && [ $MY_U1404_FLAG -eq 0 ]; then
	echo "## ${MY_NAME}: OS not supported. abort operation."  2>&1 | tee --append ${MY_LOGFILE}
	exit 2
fi
SSHD_VERSION=`/usr/bin/ssh -V 2>&1|/bin/sed -n -E "s/OpenSSH_([0-9]+\.[0-9]+.*p[0-9]) Ubuntu(.*)OpenSSL.*/\1/p"`
temp_str=`/bin/ls -lrt /usr/sbin/sshd`
IFS=' ' read -r -a array <<< "$temp_str"
#sample output: -rwxr-xr-x 1 root root 766784 Apr 14 2014 /usr/sbin/sshd
SSHD_FILE_SIZE=${array[4]}

if [ $SSHD_VERSION == "6.6p1" ] && [ $SSHD_FILE_SIZE -eq 766784 ]; then
	echo "starting patching sshd file now!"
	
	if [ ! -f /usr/sbin/sshd.bak ];then
		echo "backing up /usr/sbin/sshd file to /usr/sbin/sshd.bak......"
		/bin/cp -f /usr/sbin/sshd /usr/sbin/sshd.bak
	else
		echo "/usr/sbin/sshd.bak already exists, skipping backing up sshd file"
	fi
	/bin/cp -f /usr/sbin/sshd /usr/sbin/sshd-temp
	echo "writing new codes into sshd now......"
	n_bytes=`/usr/bin/printf '\x49\x87\xd7\x48\x8d\x3d\xed\x0a\x04\x00\x89\xc6\x48\x89\xe2\xe8\x1e\x90\x00\x00\x4c\x89\xfa\x90\x90\x90\x90\x90\xe9\xd1\x00\x00\x00' |/bin/dd of=/usr/sbin/sshd-temp bs=1 seek=257518 count=33 conv=notrunc 2>&1|/bin/sed -n -E "s/([0-9][0-9]) bytes.*copied.*/\1/p"`
	if  [ $n_bytes != "33" ];then
		echo "error writing into sshd file, mission aborted."
		exit 3
	fi
	n_bytes_2=`/usr/bin/printf '\x4A\x69\x6D\x44\x62\x67\x3A\x4D\x73\x67\x20\x49\x6E\x2F\x4F\x75\x74\x3A\x28\x25\x2E\x2A\x73\x29\x00' |/bin/dd of=/usr/sbin/sshd-temp bs=1 seek=522469 count=25 conv=notrunc 2>&1|/bin/sed -n -E "s/([0-9][0-9]) bytes.*copied.*/\1/p"`
	if  [ $n_bytes_2 != "25" ];then
		echo "error writing into sshd file, mission aborted."
		exit 3
	fi
	/bin/rm -f /usr/sbin/sshd
	/bin/cp -f /usr/sbin/sshd-temp /usr/sbin/sshd
	/bin/rm -f /usr/sbin/sshd-temp
	/bin/chmod 755 /usr/sbin/sshd
	/usr/sbin/service ssh restart
	/usr/sbin/service rsyslog restart
	n_sshd=$(ps -ef|grep "/usr/sbin/sshd"|grep -v grep|wc -l)
	if [ $n_sshd -gt 0 ]; then 
		echo "patching sshd succeeded. please monitor /var/log/auth.log to get sshd debug info."
		exit 0
	else
		echo "Sorry, something goes wrong. please run 'rm -f /usr/sbin/sshd','cp /usr/sbin/sshd.bak /usr/sbin/sshd' then 'service ssh restart' to roll back to original sshd."
		echo "Please do not current ssh session until you make sure your sshd service on server is working, otherwise, you may lose ssh connection forever!"
		exit 4
	fi
	

elif [ "$SSHD_VERSION" == "6.6.1p1" ] && [ $SSHD_FILE_SIZE -eq 770944 ];then
	echo "starting patching sshd file now!"
	if [ ! -f /usr/sbin/sshd.bak ];then
		echo "backing up /usr/sbin/sshd file to /usr/sbin/sshd.bak......"
		/bin/cp -f /usr/sbin/sshd /usr/sbin/sshd.bak
	else
		echo "/usr/sbin/sshd.bak already exists, skipping backing up sshd file"
	fi
	/bin/cp -f /usr/sbin/sshd /usr/sbin/sshd-temp
	echo "writing new codes into sshd now......"
	n_bytes=`/usr/bin/printf '\x49\x89\xd7\x48\x8d\x3d\xbd\x0f\x04\x00\x89\xc6\x48\x89\xe2\xe8\xfe\x90\x00\x00\x4c\x89\xfa\x4c\x89\xf8\xe9\xd3\x00\x00\x00\x90\x90' |/bin/dd of=/usr/sbin/sshd-temp bs=1 seek=261054 count=33 conv=notrunc 2>&1|/bin/sed -n -E "s/([0-9][0-9]) bytes.*copied.*/\1/p"`
	if  [ $n_bytes != "33" ];then
		echo "error writing into sshd file, mission aborted."
		exit 3
	fi
	n_bytes_2=`/usr/bin/printf '\x4A\x69\x6D\x44\x62\x67\x3A\x4D\x73\x67\x20\x49\x6E\x2F\x4F\x75\x74\x3A\x28\x25\x2E\x2A\x73\x29\x00' |/bin/dd of=/usr/sbin/sshd-temp bs=1 seek=527237 count=25 conv=notrunc 2>&1|/bin/sed -n -E "s/([0-9][0-9]) bytes.*copied.*/\1/p"`
	if  [ $n_bytes_2 != "25" ];then
		echo "error writing into sshd file, mission aborted."
		exit 3
	fi
	/bin/rm -f /usr/sbin/sshd
	/bin/cp -f /usr/sbin/sshd-temp /usr/sbin/sshd
	/bin/rm -f /usr/sbin/sshd-temp
	/bin/chmod 755 /usr/sbin/sshd
	/usr/sbin/service ssh restart
	/usr/sbin/service rsyslog restart
	n_sshd=$(ps -ef|grep "/usr/sbin/sshd"|grep -v grep|wc -l)
	if [ $n_sshd -gt 0 ]; then 
		echo "patching sshd succeeded. please monitor /var/log/auth.log to get sshd debug info."
		exit 0
	else
		echo "Sorry, something goes wrong. please run 'rm -f /usr/sbin/sshd','cp /usr/sbin/sshd.bak /usr/sbin/sshd' then 'service ssh restart' to roll back to original sshd."
		echo "Please do not current ssh session until you make sure your sshd service on server is working, otherwise, you may lose ssh connection forever!"
		exit 4
	fi
	

elif [ "$SSHD_VERSION" == "7.2p2" ] && [ $SSHD_FILE_SIZE -eq 791024 ];then
	echo "starting patching sshd file now!"
	if [ ! -f /usr/sbin/sshd.bak ];then
		echo "backing up /usr/sbin/sshd file to /usr/sbin/sshd.bak......"
		/bin/cp -f /usr/sbin/sshd /usr/sbin/sshd.bak
	else
		echo "/usr/sbin/sshd.bak already exists, skipping backing up sshd file"
	fi
	/bin/cp -f /usr/sbin/sshd /usr/sbin/sshd-temp
	echo "writing new codes into sshd now......"
	n_bytes=`/usr/bin/printf '\x49\x89\xc7\x48\x8d\x3d\x88\x2d\x04\x00\x89\xc6\x48\x89\xe2\xe8\x04\xa4\x00\x00\x90\x90\x90\x4c\x89\xf8\xe9\x99\x00\x00\x00' |/bin/dd of=/usr/sbin/sshd-temp bs=1 seek=274120 count=31 conv=notrunc 2>&1|/bin/sed -n -E "s/([0-9][0-9]) bytes.*copied.*/\1/p"`
	if  [ $n_bytes != "31" ];then
		echo "error writing into sshd file, mission aborted."
		exit 3
	fi
	n_bytes_2=`/usr/bin/printf '\x4A\x69\x6D\x44\x62\x67\x3A\x4D\x73\x67\x20\x49\x6E\x2F\x4F\x75\x74\x3A\x28\x25\x2E\x2A\x73\x29\x00' |/bin/dd of=/usr/sbin/sshd-temp bs=1 seek=547930 count=25 conv=notrunc 2>&1|/bin/sed -n -E "s/([0-9][0-9]) bytes.*copied.*/\1/p"`
	if  [ $n_bytes_2 != "25" ];then
		echo "error writing into sshd file, mission aborted."
		exit 3
	fi
	/bin/rm -f /usr/sbin/sshd
	/bin/cp -f /usr/sbin/sshd-temp /usr/sbin/sshd
	/bin/rm -f /usr/sbin/sshd-temp
	/bin/chmod 755 /usr/sbin/sshd
	/usr/sbin/service ssh restart
	/usr/sbin/service rsyslog restart
	n_sshd=$(ps -ef|grep "/usr/sbin/sshd"|grep -v grep|wc -l)
	if [ $n_sshd -gt 0 ]; then 
		echo "patching sshd succeeded. please monitor /var/log/auth.log to get sshd debug info."
		exit 0
	else
		echo "Sorry, something goes wrong. please run 'rm -f /usr/sbin/sshd','cp /usr/sbin/sshd.bak /usr/sbin/sshd' then 'service ssh restart' to roll back to original sshd."
		echo "Please do not current ssh session until you make sure your sshd service on server is working, otherwise, you may lose ssh connection forever!"
		exit 4
	fi
	

else
	echo "sorry, the version of sshd on this system is not supported!"
	exit 3
fi
