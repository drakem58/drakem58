#!/usr/bin/python3


# quick python3 script to ping on a list of hostnames
# should be resolvable by /etc/hosts or dns

import socket  # For connecting two nodes on a network to communicate with each other
import sys     # To get access to some variables used/maintained by interpreter and function that interact with interpreter
import os      # Allows an interface with the OS that Python is running on.


mpingfile = open("./mping_host.out","r")
for host_name in mpingfile:
        server_state = os.system('ping -c 2 ' + host_name ) # default is one ping
        if server_state == 0:
                print(host_name +"===== Server is UP=====")
        else:
                print(host_name +"==== Server is DOWN====")
