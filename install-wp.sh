#!/bin/bash

echo "Instalarea WordPress cu PHP 8.1 și module necesare"

# Solicită detalii de la utilizator
read -p "Introduceți numele domeniului pentru instalarea WordPress: " domain_name
read -p "Introduceți numele bazei de date: " db_name
read -p "Introduceți numele de utilizator MySQL: " db_user
read -s -p "Introduceți parola pentru MySQL: " db_pass
echo

# Actualizare și instalare dependențe
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install -y apache2 mysql-server php8.1 php8.1-mysql php8.1-xml php8.1-curl php8.1-gd php8.1-mbstring php8.1-imagick redis-server php-redis

# Configurare MySQL
sudo mysql -e "CREATE DATABASE $db_name;"
sudo mysql -e "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_pass';"
sudo mysql -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Descărcarea și instalarea WordPress
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
sudo mkdir -p /var/www/html/$domain_name/public_html
sudo mv wordpress/* /var/www/html/$domain_name/public_html/
sudo chown -R www-data:www-data /var/www/html/$domain_name/public_html
sudo chmod -R 755 /var/www/html/$domain_name/public_html

# Configurare WordPress
cp /var/www/html/$domain_name/public_html/wp-config-sample.php /var/www/html/$domain_name/public_html/wp-config.php
sed -i "s/database_name_here/$db_name/" /var/www/html/$domain_name/public_html/wp-config.php
sed -i "s/username_here/$db_user/" /var/www/html/$domain_name/public_html/wp-config.php
sed -i "s/password_here/$db_pass/" /var/www/html/$domain_name/public_html/wp-config.php

# Configurare Apache Virtual Host
sudo touch /etc/apache2/sites-available/$domain_name.conf
cat <<EOF | sudo tee /etc/apache2/sites-available/$domain_name.conf
<VirtualHost *:80>
    ServerAdmin webmaster@$domain_name
    ServerName $domain_name
    ServerAlias www.$domain_name
    DocumentRoot /var/www/html/$domain_name/public_html
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

sudo a2ensite $domain_name.conf
sudo systemctl restart apache2

echo "Instalarea WordPress pe $domain_name s-a finalizat. Accesați http://$domain_name pentru a continua configurarea."
