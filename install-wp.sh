#!/bin/bash

echo "Instalarea WordPress cu PHP 8.1 și module necesare"

# Solicită detalii de la utilizator
read -p "Introduceți numele domeniului pentru instalarea WordPress: " domain_name
read -p "Introduceți numele bazei de date: " db_name
read -p "Introduceți numele de utilizator MySQL: " db_user
read -s -p "Introduceți parola pentru MySQL: " db_pass
echo
read -p "Introduceți numele de utilizator pentru admin WordPress: " wp_user
read -s -p "Introduceți parola pentru admin WordPress: " wp_pass
read -p "Introduceți email-ul pentru admin WordPress: " wp_email
read -p "Introduceți titlul site-ului WordPress: " wp_title
read -p "Introduceți descrierea site-ului WordPress: " wp_description
echo

# Actualizare și instalare dependențe
sudo apt-get update -y
sudo apt-get upgrade -y
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

# Configurare automată a WordPress (creare utilizator admin și setări site)
cat << EOF | sudo tee /var/www/html/$domain_name/public_html/wp-config-auto.php
<?php
require_once('/var/www/html/$domain_name/public_html/wp-load.php');
require_once('/var/www/html/$domain_name/public_html/wp-admin/includes/admin.php');
require_once('/var/www/html/$domain_name/public_html/wp-includes/pluggable.php');

// Creează utilizatorul admin dacă nu există
if (!username_exists('$wp_user') && !email_exists('$wp_email')) {
    \$user_id = wp_create_user('$wp_user', '$wp_pass', '$wp_email');
    \$user = new WP_User(\$user_id);
    \$user->set_role('administrator');
}

// Setări site
update_option('blogname', '$wp_title');
update_option('blogdescription', '$wp_description');
update_option('admin_email', '$wp_email');

// Dezactivează solicitarea de configurare la prima autentificare
update_option('show_on_front', 'posts');
?>
EOF
sudo php /var/www/html/$domain_name/public_html/wp-config-auto.php

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

echo "Instalarea WordPress pe $domain_name s-a finalizat. Accesați http://$
