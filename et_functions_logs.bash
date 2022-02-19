#!/bin/bash

# script to do a short for loop for actions for edna nodes

 

# Define some variables

##################################################

OUTFILE=/etrade/home/mdrake/scripts/outfile.out  #

1command=`/etrade/bin/etcmd -s kmssh $i df -h`

2command=`/etrade/bin/etcmd -s kmssh $i erotate -z`

third_command=`etcmd -s kmssh root@$i /usr/bin/edna -q -d prd-rb-app-api_accounts -c erotate`

 

##################################################

 

# below function will create node list for a for loop to work on

create_a_list () {

#/etrade/bin/etdeployments $(etdepargs prd:rb:app:api_accounts) > /etrade/home/mdrake/scripts/outfile.out

/etrade/bin/etdeployments $(etdepargs prd:rb:app:api_accounts) > $OUTFILE

}

 

cat $OUTFILE

 

# below function will dump contents of OUTFILE into an email to myself

mail_to_mike () {

mail -s "for loop for edna nodes" michael.drake@etrade.com < $OUTFILE

}

 

# below function will run the node list in for loop doing one command

run_a_command () {

for i in `cat $OUTFILE`

do

echo "==================================="

echo $i

#/etrade/bin/etcmd -s kmssh $i df -h

etcmd -s kmssh root@$i /usr/bin/edna -q -d prd-rb-app-api_accounts -c erotate

#$third_command

#/etrade/bin/etcmd -s kmssh $i erotate -z

echo "==================================="

done

}

 
create_a_list
run_a_command
