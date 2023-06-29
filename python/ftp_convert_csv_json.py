

write a python3 script that will ftp to 10.1.10.87 as ftp-uranus , 
cd into upload directory, look for a *.csv file, 
convert to jason and save it locally under /var/tmp/*.json


from ftplib import FTP  # connecting to a vsftp server
import csv
import json

# FTP connection details
ftp_host = '10.1.10.87'
ftp_user = 'ftp-uranus'
ftp_pass = '???????' # better to use key pair or another way to access user password.
upload_dir = 'upload'

# Target file extension and destination directory for JSON files
target_extension = '.csv'
destination_dir = '/var/tmp/'

def ftp_to_json():
    # Connect to FTP server
    ftp = FTP(ftp_host)
    ftp.login(user=ftp_user, passwd=ftp_pass)

    # Change to the upload directory
    ftp.cwd(upload_dir)

    # Find all files in the directory
    files = ftp.nlst()

    # Filter for CSV files
    csv_files = [file for file in files if file.lower().endswith(target_extension)]

    if not csv_files:
        print(f"No CSV files found in the '{upload_dir}' directory.")
        ftp.quit()
        return

    # Process each CSV file
    for file in csv_files:
        print(f"Converting '{file}' to JSON...")

        # Download the CSV file
        ftp.retrbinary('RETR ' + file, open(file, 'wb').write)

        # Convert CSV to JSON
        json_filename = file.rsplit('.', 1)[0] + '.json'
        with open(file, 'r') as csv_file:
            csv_data = csv.DictReader(csv_file)
            json_data = json.dumps(list(csv_data), indent=4)

        # Save JSON file locally
        json_path = f"{destination_dir}{json_filename}"
        with open(json_path, 'w') as json_file:
            json_file.write(json_data)

        print(f"CSV file '{file}' converted to JSON and saved as '{json_path}'.")

    # Close FTP connection
    ftp.quit()

# Start the FTP to JSON conversion process
ftp_to_json()
