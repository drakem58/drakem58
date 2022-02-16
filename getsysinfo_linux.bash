#!/usr/bin/bash
# getsysinfo
# quick script to gather system information and email it to me

#Define some variables
SYSTEMINFOFILE=/var/sysinfo.out


echo  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" > $SYSTEMINFOFILE
echo  " HOSTNAME " >> $SYSTEMINFOFILE
echo  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
/bin/uname -n >> $SYSTEMINFOFILE

echo  " " >> $SYSTEMINFOFILE
echo  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
echo  " SE Linux status INFORMATION " >> $SYSTEMINFOFILE
echo  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
/sbin/sestatus >> $SYSTEMINFOFILE


echo  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
echo  " ip -a  INFO " >> $SYSTEMINFOFILE
echo  " " >> $SYSTEMINFOFILE
echo  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
/sbin/ip a

echo  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
echo  " NETSTAT -tulp INFO " >> $SYSTEMINFOFILE
echo  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
/bin/netstat -tulp >> $SYSTEMINFOFILE


echo  " " >> $SYSTEMINFOFILE
echo  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
echo  " Linux blockid INFO " >> $SYSTEMINFOFILE
echo  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
/sbin/blkid >> $SYSTEMINFOFILE


echo  " " >> $SYSTEMINFOFILE
echo  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
echo  " Centos firewall running?  " >> $SYSTEMINFOFILE
echo  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
/bin/firewall-cmd --state >> $SYSTEMINFOFILE
echo  " " >> $SYSTEMINFOFILE


echo  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
echo  " FS MOUNTPOINTS INFO " >> $SYSTEMINFOFILE
echo  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
echo  " "
/bin/df -h >> $SYSTEMINFOFILE


echo  " " >> $SYSTEMINFOFILE
echo  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
echo  " /etc/hosts info " >> $SYSTEMINFOFILE
echo  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE

/bin/cat /etc/hosts >> $SYSTEMINFOFILE

/bin/cat $SYSTEMINFOFILE | /bin/mailx " SYSTEM INFO" md6270@att.com
echo   "file is at /var/sysinfo.out"
