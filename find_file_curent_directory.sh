#!/bin/bash

# short script that checks for a file in the current directory
# uses argument expansion to capture all files as arguments

for itfile in ${@}
do
if [[ -f $itfile ]]
then
    echo "file ${itfile} exists "
else
    echo "file ${itfile} does not exist "
fi
done
