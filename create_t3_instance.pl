#!/usr/bin/python3

# quick script to create a couple of T3 nodes based on an AMI-ID
# use "aws ec2 describe-instances to see if you can see any
# else can use the console if you have credentials

import boto3
ec2 = boto3.resource('ec2')

# create a new T3 EC2 instance
instances = ec2.create_instances(
     ImageId='ami-00b6a8a2bd28daf19',
     MinCount=1,
     MaxCount=2,
     InstanceType='t3',
     KeyName='ec2-keypair'
