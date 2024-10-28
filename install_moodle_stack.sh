#!/bin/bash

# Exit on any error
set -e

get_user_input() {
    echo "Please provide the following information:"
    read -p "MySQL password for moodleuser: " MYSQL_PASSWORD
    read -p "Initial Moodle admin password: " MOODLE_ADMIN_PASSWORD
    read -p "Web address (default: http://localhost:1080/moodle): " WEB_ADDRESS
    WEB_ADDRESS=${WEB_ADDRESS:-"http://localhost:1080/moodle"}
    
    echo "Using the following configuration:"
    echo "Database host: localhost"
    echo "Database name: moodle"
    echo "Database user: moodleuser"
    echo "Web address: $WEB_ADDRESS"
    echo "Data directory: /var/moodledata"
    
    read -p "Continue? (y/n): " CONFIRM
    if [[ $CONFIRM != "y" ]]; then
        echo "Installation cancelled"
        exit 1
    fi
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Security warning
echo "WARNING: This script sets insecure file permissions that are suitable only for"
echo "development and testing purposes. These permissions should NEVER be used on"
echo "production systems or machines accessible from the internet."
echo ""
echo "Type 'Yes, I understand' to continue:"
read -r CONFIRM
if [[ "$CONFIRM" != "Yes, I understand" ]]; then
    echo "Installation cancelled"
    exit 1
fi

# Get user input
get_user_input

echo "Starting installation..."

echo "Updating system packages..."
apt update && apt upgrade -y

echo "Installing LAMP server and PHP extensions..."
apt install -y lamp-server^ php-curl php-gd php-intl php-mbstring php-soap php-zip php-xml php-yaml unzip wget git

# Configure PHP
echo "Configuring PHP..."
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
sed -i 's/;max_input_vars = 1000/max_input_vars = 5000/' /etc/php/$PHP_VERSION/apache2/php.ini
sed -i 's/;max_input_vars = 1000/max_input_vars = 5000/' /etc/php/$PHP_VERSION/cli/php.ini

# Create phpinfo page
# echo "<?php phpinfo();" > /var/www/html/phpinfo.php

systemctl restart apache2

# Create MySQL database and user
echo "Creating MySQL database and user..."
mysql <<EOF
CREATE DATABASE moodle DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'moodleuser'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON moodle.* TO 'moodleuser'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "Downloading and installing Moodle..."
git clone -b MOODLE_404_STABLE git://git.moodle.org/moodle.git /var/www/html/moodle
chown -R www-data /var/www/html
chmod -R 0777 /var/www/html/moodle

echo "Creating moodledata directory..."
mkdir -p /var/moodledata
chmod 0777 /var/moodledata

# Install Moodle
echo "Running Moodle installation..."
cd /var/www/html/moodle/admin/cli
sudo -u www-data /usr/bin/php install.php \
    --wwwroot="$WEB_ADDRESS" \
    --dataroot=/var/moodledata \
    --dbtype=mysqli \
    --dbhost=localhost \
    --dbname=moodle \
    --dbuser=moodleuser \
    --dbpass="$MYSQL_PASSWORD" \
    --fullname="Moodle Site" \
    --shortname="Moodle" \
    --adminuser=admin \
    --adminpass="$MOODLE_ADMIN_PASSWORD" \
    --non-interactive \
    --agree-license

# Install STACK dependencies
echo "Installing STACK dependencies..."
apt install -y gcc gnuplot maxima

# Download STACK question behaviors and types
echo "Installing STACK question behaviors and types..."
git clone https://github.com/maths/moodle-qbehaviour_dfexplicitvaildate.git /var/www/html/moodle/question/behaviour/dfexplicitvaildate
git clone https://github.com/maths/moodle-qbehaviour_dfcbmexplicitvaildate.git /var/www/html/moodle/question/behaviour/dfcbmexplicitvaildate
git clone https://github.com/maths/moodle-qbehaviour_adaptivemultipart.git /var/www/html/moodle/question/behaviour/adaptivemultipart
git clone https://github.com/maths/moodle-qtype_stack.git /var/www/html/moodle/question/type/stack

# Final restart of Apache
systemctl restart apache2

echo "Installation complete!"
echo "Please visit $WEB_ADDRESS to access your Moodle installation."
echo "Admin username: admin"
echo "Admin password: $MOODLE_ADMIN_PASSWORD"
echo "Please change the admin password after first login."
echo ""
echo "Next steps:"
echo "1. Log in to Moodle"
echo "2. Complete the STACK plugin installation through the web interface"
echo "3. Run the STACK health check at: Site Administration > Plugins > Question Types > STACK"
