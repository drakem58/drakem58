#!/usr/bin/bash

# this is a script that will use pdsh to pull in dmidecode info
# to later be parsed by another tool such as pup or xidel
set -x
# define some variables
infile=/home/mdrake/bloc-96/testnode.in
mcred=/home/mdrake/mcred.mwd

# put a cred file that has the hash value in it first on the server you want to run the pdsh on

export WCOLL=$infile
getdmidecode () {
for i in `cat $infile` 
do
	scp -P52222 $mcred mdrake@$i:/home/mdrake/.
	sleep 5
#	pdsh -w $i ' cat $mcred | sudo -iS dmidecode' | dshbak -fd ./dmi_decode
	pdsh -Rssh -w $i ' cat /home/mdrake/mcred.mwd | sudo -iS dmidecode ' | dshbak -fd ./dmi_decode.$i
	ssh mdrake@$i -p52222 "rm -rf $mcred"
	echo $i ;
done
}

#getdmidecode

pdsh -Rssh 'echo "#!Perl56" > .pw && cat .pw | sudo -iS dmidecode ' | dshbak -fd dmidecodeh 
