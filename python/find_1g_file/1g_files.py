#!/usr/bin/python3

# modules
import os # this is allow for python to move around the linux cli

def list_1g_files(directory ):
    # Define the size threshold in bytes (1 megabyte = 1,048,576 bytes)
    size_threshold = 1048576
    # iterate over the files in the directory
    for filename1 in os.listdir(directory):
        file_path = os.path.join(directory, filename1)


        # check to see if file is bigger than 1 meg
        if os.path.isfile(file_path) and os.path.getsize(file_path) > size_threshold:
            print(filename1)

def remove_1g_files(directory ):
    # Define the size threshold in bytes (1 megabyte = 1,048,576 bytes)
    size_threshold = 1048576
    for filename2 in os.listdir(directory):
        filepath = os.path.join(directory, filename2)
        if os.path.isfile(filepath) and os.path.getsize(filepath) > size_threshold: # checking to see if file is bigger than one gig and is a file
            os.remove(filepath)
            print("File {filename2} removed.")

directory_path = "/var/test"
list_1g_files(directory_path)
remove_1g_files(directory_path)
