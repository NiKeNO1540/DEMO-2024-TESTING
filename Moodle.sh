#!/bin/bash

# === НАСТРОЙКИ ===
MOODLE_VERSION="MOODLE_402_STABLE"
MOODLE_DIR="/var/www/html/moodle"
MOODLEDATA_DIR="/var/moodledata"
DB_NAME="moodle"
DB_USER="moodleuser"
DB_PASS="P@ssw0rd"
ADMIN_USER="admin"
ADMIN_PASS="P@ssw0rd"
ADMIN_EMAIL="admin@hq-srv.hq.work"
SITE_FULLNAME="Moodle Platform"
SITE_SHORTNAME="Moodle"
DOMAIN="http://localhost"

# === Установка зависимостей ===
echo "[1/9] Установка Apache, PHP, MySQL..."

apt-get update

apt-get install -y apache2 apache2-{base,httpd-prefork,mod_php8.0,mods}
apt-get install -y php8.0 php8.0-{curl,fileinfo,fpm-fcgi,gd,intl,ldap,mbstring,mysqlnd,mysqlnd-mysqli,opcache,soap,sodium,xmlreader,xmlrpc,zip,openssl}
apt-get install -y MySQL-server

# === Запуск и настройка MySQL ===
echo "[2/9] Запуск MySQL-сервера..."
systemctl enable --now mysqld
systemctl start mysqld

# === Скачивание Moodle ===
echo "[3/9] Скачивание Moodle ($MOODLE_VERSION)..."
cd /var/www/
git clone -b $MOODLE_VERSION git://git.moodle.org/moodle.git

# === Создание директории moodledata ===
echo "[4/9] Создание директории moodledata..."
mkdir -p "$MOODLEDATA_DIR"
chown -R www-data:www-data "$MOODLE_DIR" "$MOODLEDATA_DIR"
chmod -R 755 "$MOODLE_DIR" "$MOODLEDATA_DIR"

# === Создание базы данных и пользователя ===
echo "[5/9] Создание базы данных и пользователя..."
mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE $DB_NAME DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# === Установка Moodle через CLI ===
echo "[6/9] Установка Moodle через CLI..."
sudo -u www-data php /var/www/html/moodle/admin/cli/install.php \
--chmod=2770 \
--lang=ru \
--wwwroot=$DOMAIN \
--dataroot="$MOODLEDATA_DIR" \
--dbtype=mysqli \
--dbhost=localhost \
--dbname=$DB_NAME \
--dbuser=$DB_USER \
--dbpass="$DB_PASS" \
--fullname="$SITE_FULLNAME" \
--shortname="$SITE_SHORTNAME" \
--adminuser=$ADMIN_USER \
--adminpass="$ADMIN_PASS" \
--adminemail="$ADMIN_EMAIL" \
--agree-license \
--non-interactive

# === Настройка Apache конфигурации для Moodle ===
echo "[7/9] Настройка Apache для Moodle..."
cat <<EOF > /etc/httpd2/conf/sites-available/moodle.conf
<VirtualHost *:80>
    DocumentRoot $MOODLE_DIR
    ServerName hq-srv.hq.work
    ServerAlias moodle.hq-srv.hq.work
    <Directory $MOODLE_DIR>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

mkdir -p /etc/httpd2/conf/sites-enabled
ln -sf /etc/httpd2/conf/sites-available/moodle.conf /etc/httpd/conf/sites-enabled/

systemctl enable -- now httpd2
systemctl restart httpd2

# === Создание групп и пользователей ===
echo "[8/9] Создание групп и пользователей..."

# Создание групп
groupadd Admin
groupadd Manager
groupadd WS
groupadd Team

# Создание пользователей и добавление в группы

# Admin
useradd -m -G Admin Admin

# Managers
for i in {1..3}; do
  useradd -m -G Manager Manager$i
done

# WS (User1 - User4)
for i in {1..4}; do
  useradd -m -G WS User$i
done

# Team (User5 - User7)
for i in {5..7}; do
  useradd -m -G Team User$i
done

echo "[9/9] Установка завершена!"
echo "==========================================="
echo "Откройте в браузере: $DOMAIN"
echo "Логин администратора Moodle: $ADMIN_USER"
echo "Пароль администратора Moodle: $ADMIN_PASS"
echo "Созданы группы: Admin, Manager, WS, Team"
echo "Созданы пользователи: Admin, Manager1..3, User1..7"
echo "==========================================="
