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
MOODLE_URL="http://moodle.hq-srv.hq.work"  # можно заменить на IP/домен
PUBLIC_LINK="https://disk.yandex.ru/d/eG9AroTg7RIDqw"
DOWNLOAD_URL=$(curl -s "https://cloud-api.yandex.net/v1/disk/public/resources/download?public_key=$PUBLIC_LINK" | grep -oP '(?<="href":")[^"]+')

# === УСТАНОВКА ЗАВИСИМОСТЕЙ ===
echo "==> Установка необходимых пакетов..."
apt-get update
apt-get install -y apache2 apache2-{base,httpd-prefork,mod_php8.0,mods}
apt-get install -y php8.0 php8.0-{curl,fileinfo,fpm-fcgi,gd,intl,ldap,mbstring,mysqlnd,mysqlnd-mysqli,opcache,soap,sodium,xmlreader,xmlrpc,zip,openssl}
apt-get install -y MySQL-server unzip wget

# === НАСТРОЙКА MySQL ===
echo "==> Настройка MySQL..."
systemctl start mysqld
systemctl enable --now mysqld

echo "==> Перерыв..."
sleep 3
echo "==> Продолжаем!"

mysql -u root <<EOF
CREATE DATABASE ${MOODLE_DB} DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
CREATE USER '${MOODLE_DB_USER}'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MOODLE_DB_PASS}';
GRANT ALL PRIVILEGES ON ${MOODLE_DB}.* TO '${MOODLE_DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

# === УСТАНОВКА MOODLE ===
echo "==> Загрузка и установка Moodle..."
apt-get install -y git
# Проверка, что ссылка получена
if [ -z "$DOWNLOAD_URL" ]; then
  echo "Не удалось получить ссылку на скачивание."
  exit 1
fi
curl -L -o moodle.zip "$(printf %s "$DOWNLOAD_URL")"
unzip moodle.zip
mv -f moodle /var/www/html/
mv -f moodledata /var/

chown -R apache2:apache2 "$MOODLE_DATA"
chmod -R 777 "$MOODLE_DATA"

chown -R apache2:apache2 "$MOODLE_DIR"
chmod -R 777 "$MOODLE_DIR"

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
systemctl enable --now httpd2

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

echo " Moodle успешно установлен в headless-режиме!"
echo " Перейдите по адресу: $MOODLE_URL"
echo "Админ: $MOODLE_ADMIN_USER"
echo "Пароль: $MOODLE_ADMIN_PASS"
