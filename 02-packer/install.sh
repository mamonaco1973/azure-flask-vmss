#!/bin/bash

# List all files and directories in the /flask directory with detailed information (long listing format)
# including file permissions, ownership, size, and modification date.
ls -al /flask

# Check if the environment variable "COSMOS_ENDPOINT" is set
if [ -z "$COSMOS_ENDPOINT" ]; then
    echo "WARNING: COSMOS_ENDPOINT is not set."
else
    # Replace "$COSMOS_ENDPOINT" in the script with its actual value
    echo "NOTE: COSMOS_ENDPOINT is set to $COSMOS_ENDPOINT."
    sed -i "s|\$COSMOS_ENDPOINT|$COSMOS_ENDPOINT|g" /flask/start_flask_app.sh
fi

# Change the permissions of the script `start_flask_app.sh` in the /flask directory to make it executable.
# The `+x` flag ensures the script can be run as a program.
chmod +x /flask/start_flask_app.sh
chmod +x /flask/test_candidates.py

# Install the Python 3 pip package manager 
sudo apt update -y
sudo apt install -y python3-pip stress dos2unix

# Even out any widows LF issues

dos2unix /flask/start_flask_app.sh
dos2unix /flask/app.py
dos2unix /flask/test_candidates.py

# Install the Python dependencies listed in the `requirements.txt` file located in the /flask directory.
# `pip3` refers to the Python 3 version of pip. The `-r` flag specifies the requirements file.
sudo pip3 install -r /flask/requirements.txt --break-system-packages

# Copy the systemd service file `flask_app.service` from the /flask directory to the
# /etc/systemd/system directory, which is the location for user-defined service unit files.
sudo cp /flask/flask_app.service /etc/systemd/system/flask_app.service

# Reload the systemd daemon to recognize the new or updated service file.
# This ensures systemd is aware of changes to service configurations.
sudo systemctl daemon-reload

# Enable the `flask_app` service to start automatically at boot.
# This creates symbolic links for the service in the appropriate systemd directories.
sudo systemctl enable flask_app

# Start the `flask_app` service immediately without waiting for a reboot.
# This activates the service and runs it in the foreground.
sudo systemctl start flask_app

# Display the current status of the `flask_app` service, including its running state, PID, memory usage,
# and any error messages or logs. This helps verify that the service started successfully.
sudo systemctl status flask_app


