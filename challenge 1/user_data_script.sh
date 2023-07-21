#!/bin/bash

# System-Update
sudo yum update -y

# Installation von Apache, MariaDB, PHP und zusätzlichen Paketen
sudo yum install -y httpd mariadb-server php php-mysqlnd unzip

# EPEL und Remi Repository für PHP 7.4 hinzufügen
sudo amazon-linux-extras install epel
sudo yum install https://rpms.remirepo.net/enterprise/remi-release-8.rpm

# PHP 7.4 aktivieren und benötigte PHP-Pakete installieren
sudo amazon-linux-extras enable php7.4
sudo yum clean metadata
sudo yum install php-cli php-pdo php-fpm php-json php-mysqlnd php php-{mbstring,json,xml,mysqlnd}

# Starten und Aktivieren von Apache und MariaDB
sudo systemctl start httpd
sudo systemctl enable httpd
sudo systemctl start mariadb
sudo systemctl enable mariadb

# WordPress herunterladen und konfigurieren
cd /var/www/html
sudo curl -LO https://wordpress.org/latest.zip
sudo unzip latest.zip
sudo mv -f wordpress/* ./
sudo rm -rf wordpress latest.zip
sudo chown -R apache:apache /var/www/html

# Konfiguration von MariaDB für WordPress
sudo mysql -e "CREATE DATABASE wordpress;"
sudo mysql -e "CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'wppassword';"
sudo mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

sudo yum update -y

# Neustart von Apache um alle Änderungen zu übernehmen
sudo systemctl restart httpd

# Überprüfung der PHP-Version
php -v
sudo yum update -y
