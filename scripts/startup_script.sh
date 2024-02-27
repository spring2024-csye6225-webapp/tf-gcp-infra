#!/bin/bash

# Set database configuration
DB_HOST="localhost"
DB_USERNAME="abhaydeshpande"
DB_PASSWORD="abhaydeshpande"
DB_NAME="cloudusers"


# Configure the web application with the database settings
sudo sed -i "s/DB_HOST_PLACEHOLDER/$DB_HOST/g" /path/to/your/webapp/config/file
sudo sed -i "s/DB_USERNAME_PLACEHOLDER/$DB_USERNAME/g" /path/to/your/webapp/config/file
sudo sed -i "s/DB_PASSWORD_PLACEHOLDER/$DB_PASSWORD/g" /path/to/your/webapp/config/file
sudo sed -i "s/DB_NAME_PLACEHOLDER/$DB_NAME/g" /path/to/your/webapp/config/file

# Start your web application service
sudo systemctl start your-webapp-service
