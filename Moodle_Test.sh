#!/bin/bash

set -e

# === НАСТРОЙКИ ===
MOODLE_VERSION="4.3"
MOODLE_DIR="/var/www/html/moodle"
MOODLE_DATA="/var/moodledata"
MOODLE_DB="moodle"
MOODLE_DB_USER="moodleuser"
MOODLE_DB_PASS="moodle"
MOODLE_SITE_NAME="Moodle"
MOODLE_ADMIN_USER="admin"
MOODLE_ADMIN_PASS="P@ssw0rd"
MOODLE_ADMIN_EMAIL="admin@hq-srv.hq.work"
MOODLE_URL="http://localhost"  # можно заменить на IP/домен

# === УСТАНОВКА ЗАВИСИМОСТЕЙ ===
echo "==> Установка необходимых пакетов..."
apt-get update
apt-get install -y apache2 apache2-{base,httpd-prefork,mod_php8.0,mods}
apt-get install -y php8.0 php8.0-{curl,fileinfo,fpm-fcgi,gd,intl,ldap,mbstring,mysqlnd,mysqlnd-mysqli,opcache,soap,sodium,xmlreader,xmlrpc,zip,openssl}
apt-get install -y MySQL-server unzip wget

# === НАСТРОЙКА MySQL ===
echo "==> Настройка MySQL..."
systemctl start mysqld
systemctl enable mysqld

mysql -u root <<EOF
CREATE DATABASE ${MOODLE} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER '${MOODLE_DB_USER}'@'localhost' IDENTIFIED BY '${MOODLE_DB_PASS}';
GRANT ALL PRIVILEGES ON ${MOODLE}.* TO '${MOODLE_DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

# === УСТАНОВКА MOODLE ===
echo "==> Загрузка и установка Moodle..."
cd /var/www/html
wget https://download.moodle.org/download.php/direct/stable${MOODLE_VERSION//./}/moodle-latest-${MOODLE_VERSION}.tgz -O moodle.tgz
tar -xzf moodle.tgz
rm -f moodle.tgz

mkdir -p "$MOODLE_DATA"
chown -R apache2:apache2 "$MOODLE_DATA"
chmod -R 770 "$MOODLE_DATA"

chown -R apache:apache "$MOODLE_DIR"

# === УСТАНОВКА САЙТА С ПОМОЩЬЮ CLI ===
echo "==> Установка Moodle в headless-режиме..."

cd "$MOODLE_DIR"

sudo -u apache2 /usr/bin/php admin/cli/install.php \
  --chmod=770 \
  --lang=ru \
  --wwwroot="$MOODLE_URL" \
  --dataroot="$MOODLE_DATA" \
  --dbtype=mysqli \
  --dbhost=localhost \
  --dbname="$MOODLE_DB" \
  --dbuser="$MOODLE_DB_USER" \
  --dbpass="$MOODLE_DB_PASS" \
  --fullname="$MOODLE_SITE_NAME" \
  --shortname="moodle" \
  --adminuser="$MOODLE_ADMIN_USER" \
  --adminpass="$MOODLE_ADMIN_PASS" \
  --adminemail="$MOODLE_ADMIN_EMAIL" \
  --non-interactive \
  --agree-license

# === НАСТРОЙКА APACHE ===
echo "==> Настройка Apache..."

cat > /etc/httpd2/conf/sites-available/moodle.conf <<EOF
<VirtualHost *:80>
    ServerName hq-srv.hq.work
    ServerAlias moodle.hq-srv.hq.work
    DocumentRoot "$MOODLE_DIR"
    <Directory "$MOODLE_DIR">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

ln -s /etc/httpd2/conf/sites-available/moodle.conf /etc/httpd2/conf/sites-enabled/

sed -i "s/; max_input_vars = 1000/max_input_vars = 5000/g" /etc/php/8.0/apache2-mod_php/php.ini

systemctl restart httpd2
systemctl enable httpd2

echo "✅ Moodle успешно установлен в headless-режиме!"
echo "🌐 Перейдите по адресу: $MOODLE_URL"
echo "👤 Админ: $MOODLE_ADMIN_USER"
echo "🔑 Пароль: $MOODLE_ADMIN_PASS"
