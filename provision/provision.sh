#!/bin/bash

# prestashop-workflow provisioning script

apt-get update

apt-get install python-software-properties --assume-yes
add-apt-repository ppa:ondrej/php5-oldstable

apt-get update

# Configurations

PACKAGES="php5 mysql-client mysql-server php5-mysql apache2 tree vim curl"
PACKAGES="$PACKAGES nginx-full php5-fpm php5-cgi spawn-fcgi php-pear php5-gd"
PACKAGES="$PACKAGES php-apc php5-curl php5-mcrypt php5-memcached fcgiwrap git"
PACKAGES="$PACKAGES ruby-dev rubygems libmysqlclient-dev unzip"

APP_TOKEN="/home/vagrant/workflow-documentation/scripts/app_token"
PUBLIC_DIRECTORY="/home/vagrant/public_www"

# Sets mysql pasword
debconf-set-selections <<< 'mysql-server mysql-server/root_password password password'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password password'

echo "Installing packages $PACKAGES ..."

apt-get install $PACKAGES --assume-yes

# Makes apache not init in start
update-rc.d -f  apache2 remove
update-rc.d php5-fpm defaults

# ps client and public folder
if [ ! -d "$PUBLIC_DIRECTORY" ]; then
    mkdir $PUBLIC_DIRECTORY
fi

chown -R vagrant $PUBLIC_DIRECTORY
chgrp -R vagrant $PUBLIC_DIRECTORY

#echo "Installing wp-cli"
#curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar 
#chmod +x wp-cli.phar
#mv wp-cli.phar /usr/local/bin/wp

echo "Installing composer"
curl -sS https://getcomposer.org/installer | php
chmod +x composer.phar
mv composer.phar /usr/local/bin/composer

echo "Installing shop cli"
gem install shop

echo "Install Prestashop Installer"
composer global require "gskema/prestashop-installer=~1.0"

# Installing squizlabs/php_codesniffer & ps-Coding-Standards
#composer create-project wp-coding-standards/wpcs:dev-master --no-dev
#ln -s /home/vagrant/wpcs/vendor/bin/phpcs /usr/local/bin/phpcs
#ln -s /home/vagrant/wpcs/vendor/bin/phpcbf /usr/local/bin/phpcbf

# Generates unique token for application
if [ ! -f "$APP_TOKEN" ]; then
    touch $APP_TOKEN
    echo $RANDOM > $APP_TOKEN
fi
# Activates site

# Apache
cp /home/vagrant/templates/prestashop.apache /etc/apache2/sites-available/prestashop
cp /home/vagrant/templates/httpd.conf /etc/apache2/conf.d/httpd.conf
a2enmod actions
a2dissite default
a2ensite prestashop
service apache2 stop

# Nginx
cp /home/vagrant/templates/prestashop.nginx /etc/nginx/sites-available/prestashop
cp /home/vagrant/templates/www.conf /etc/php5/fpm/pool.d/www.conf
cp /home/vagrant/templates/nginx.conf /etc/nginx/nginx.conf
cp /home/vagrant/templates/nginx.conf /home/vagrant/nginx.conf
rm  /etc/nginx/sites-enabled/*
ln -s /etc/nginx/sites-available/prestashop /etc/nginx/sites-enabled/
service php5-fpm restart
service nginx restart
