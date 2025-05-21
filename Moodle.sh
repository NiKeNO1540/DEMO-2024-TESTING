#! /bin/bash

apt-get install –y apache2 apache2-{base,httpd-prefork,mod_php8.0,mods}
apt-get install –y php8.0 php8.0-{curl,fileinfo,fpm-fcgi,gd,intl,ldap,mbstring,mysqlnd,mysqlnd-mysqli,opcache,soap,sodium,xmlreader,xmlrpc,zip,openssl}
systemctl enable --now httpd2
apt-get install –y MySQL-server
systemctl enable --now mysqld

ansible-playbook DEMO-2024-TESTING/Moodle.yml
