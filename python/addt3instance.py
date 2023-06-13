#!/usr/bin/python3

import boto3
ec2 = boto3.resource('ec2')

# create a new T3 EC2 instance, Maxcount is how many, 
instances = ec2.create_instances(
     ImageId='ami-00b6a8a1bd28dfg19',
     MinCount=1,
     MaxCount=2,
     InstanceType='t3',
     KeyName='ec2-keypair'
)
