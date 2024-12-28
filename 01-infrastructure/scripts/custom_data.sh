#!/bin/bash

sudo apt update -y
sudo apt upgrade -y

# if [ ! -d "/flask" ]; then
#     # Install Apache HTTP Server
#     sudo apt update -y
#     sudo apt install -y apache2 

#     # Create a dummy landing page
#     echo "Dummy landing page on host " > /var/www/html/index.html
#     hostname >> /var/www/html/index.html
    
#     # Create a dummy directory so that /gtg health check will succeed
#     mkdir /var/www/html/gtg
#     touch /var/www/html/gtg/index.html
    
#     # Update Apache configuration to listen on port 8000
#     systemctl stop apache2
#     sed -i 's/^Listen 80$/Listen 8000/' /etc/apache2/ports.conf

#     # Enable and start Apache service
    
#     systemctl enable apache2
#     systemctl start apache2

# # If /flash exists assume we are running the flask-app AMI and that the 
# # "flask-app" service has been installed.
# # Get status of flask_app service.

# else
#     echo "/flask directory exists. Script will not run." >> /tmp/custom_data.log
#     systemctl status flask_app
# fi
