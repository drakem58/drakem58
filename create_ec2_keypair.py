#!/usr/bin/python3

# this script will create an EC2 key pair so another script
# can create EC2 instances, dont forget chmod 400 ec2-keypair.pem

import boto3
	ec2 = boto3.resource('ec2')
		
	# create a file to store the key locally, file will be reused
	ec2outfile = open('ec2-keypair.pem','w')
		
	# call on the boto ec2 function to create a key pair
	key_pair = ec2.create_key_pair(KeyName='ec2-keypair')
		
	# capture the key and store it as a file
	EC2Keypairout = str(key_pair.key_stuff)
	print (EC2Keypairout)
	outfile.write(EC2keypairout)
