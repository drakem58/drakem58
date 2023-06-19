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
     InstanceType='t3.micro',
     KeyName='ec2-keypair'


     BlockDeviceMappings=[
         {
            'DeviceName': '/dev/xvda',
            'Ebs': {
                'VolumeSize': 300,
                'VolumeType': 'gp2'
             }
         },
     ],
     NetworkInterfaces=[
         {
            'DeviceIndex': 0,
            'AssociatePublicIpAddress': True,
            'Groups': ['bl_sg_router'],
         }
     ]
  )

     # Wait for the instance to start up
     instance[0].wait_until_running()

     # Print the public IP address of the instance
     print(instance[0].public_ip_address)

