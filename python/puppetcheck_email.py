import os
import smtplib

# Define email parameters
sender_email = "your_email_address@gmail.com"
receiver_email = "mdrake@walterdrakeinvestments.com"
password = "your_password"

# Run puppet agent -t check command
output = os.system("sudo puppet agent -t")

# Check if the command failed
if output != 0:
    # Send email alert
    with smtplib.SMTP_SSL('smtp.gmail.com', 465) as smtp:
        smtp.login(sender_email, password)
        message = "Subject: Puppet agent check failed\n\n" + \
                  "The puppet agent check has failed. Please investigate.\n\n" + \
                  "Output:\n" + str(output)
        smtp.sendmail(sender_email, receiver_email, message)
