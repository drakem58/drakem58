#!/usr/bin/bash
# getsysinfo
# quick script to gather system information and email it to me

#Define some variables
SYSTEMINFOFILE=/var/sysinfo.out


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" > $SYSTEMINFOFILE
echo " HOSTNAME " >> $SYSTEMINFOFILE
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
/bin/uname -a >> $SYSTEMINFOFILE

echo " " >> $SYSTEMINFOFILE
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
echo " EEPROM INFORMATION " >> $SYSTEMINFOFILE
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
/usr/sbin/eeprom >> $SYSTEMINFOFILE


echo " " >> $SYSTEMINFOFILE
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
echo " IFCONFIG INFO " >> $SYSTEMINFOFILE
echo " " >> $SYSTEMINFOFILE
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
echo " NETSTAT -rn INFO " >> $SYSTEMINFOFILE
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
/bin/netstat -rn >> $SYSTEMINFOFILE


echo " " >> $SYSTEMINFOFILE
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
echo " SOLARIS VM METADB INFO " >> $SYSTEMINFOFILE
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
/sbin/metadb >> $SYSTEMINFOFILE


echo " " >> $SYSTEMINFOFILE
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
echo " SOLARIS VM METASTAT -P INFO " >> $SYSTEMINFOFILE
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
/sbin/metastat -p >> $SYSTEMINFOFILE
echo " " >> $SYSTEMINFOFILE
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
echo " FS MOUNTPOINTS INFO " >> $SYSTEMINFOFILE
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
/bin/df -k >> $SYSTEMINFOFILE


echo " " >> $SYSTEMINFOFILE
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
echo " VCS STATUS INFO " >> $SYSTEMINFOFILE
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SYSTEMINFOFILE
/opt/VRTS/bin/hastatus -sum >> $SYSTEMINFOFILE

/bin/cat $SYSTEMINFOFILE | /bin/mailx " SYSTEM INFO" md6270@att.com
