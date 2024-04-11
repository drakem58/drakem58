#!/usr/bin/env python3

import shutil
import os
import logging

# Configure logging
logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler('file_operations.log'),  # log to a file
            logging.StreamHandler()                      # log to standard output
        ]
)

def move_file(src, dest):
    try:
        # Move the file
        shutil.move(src, dest)
        print(f"File moved from {src} to {dest}")
        logging.info(f"File moved from {src} to {dest}")
    except FileNotFoundError:
        print(f"The source file {src} does not exist.")
        logging.error(f"The source file {src} does not exist.")
    except PermissionError:
        print(f"Permission denied: unable to move the file from {src} to {dest}.")
        logging.error(f"Permission denied: unable to move the file from {src} to {dest}.")
    except Exception as e:
        print(f"Error occurred: {e}")
        

# Using the function
source_path = '/home/mdrake/testfile.out'
destination_path = '/var/tmp/testfile.out'
move_file(source_path, destination_path)
