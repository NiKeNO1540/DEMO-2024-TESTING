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
ADMIN_EMAIL="admin@moodle.hq-srv.hq.work"
SITE_FULLNAME="Moodle Platform"
SITE_SHORTNAME="Moodle"
DOMAIN="http://localhost"

# === Установка зависимостей ===
echo "[1/7] Установка apache2, PHP и MySQL..."

apt-get update

apt-get install -y apache2 apache2-{base,httpd-prefork,mod_php8.0,mods}
apt-get install -y php8.0 php8.0-{curl,fileinfo,fpm-fcgi,gd,intl,ldap,mbstring,mysqlnd,mysqlnd-mysqli,opcache,soap,sodium,xmlreader,xmlrpc,zip,openssl}
apt-get install -y MySQL-server

# === Запуск MySQL ===
echo "[2/7] Запуск MySQL..."
systemctl enable --now mysqld
systemctl start mysqld

# === Скачивание Moodle ===
echo "[3/7] Скачивание Moodle..."
cd /var/www/html
git clone -b $MOODLE_VERSION git://git.moodle.org/moodle.git

# === moodledata ===
echo "[4/7] moodledata..."
mkdir -p "$MOODLEDATA_DIR"
chown -R www-data:www-data "$MOODLE_DIR" "$MOODLEDATA_DIR"
chmod -R 755 "$MOODLE_DIR" "$MOODLEDATA_DIR"

# === База данных ===
echo "[5/7] Создание базы данных..."
mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE $DB_NAME DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# === Установка Moodle CLI ===
echo "[6/7] Установка Moodle..."
sudo -u www-data php "$MOODLE_DIR/admin/cli/install.php" \
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

# === Настройка apache2 ===
echo "[7/7] Настройка apache2..."

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

a2ensite moodle.conf
a2enmod rewrite
systemctl restart httpd2

# === Создание CSV пользователей с кастомным полем "group" ===
echo "[8] Создание CSV-файла пользователей..."

cat <<EOF > /tmp/users.csv
username,password,firstname,lastname,email,profile_field_group
Admin,P@ssw0rd,Admin,User,admin@moodle.hq-srv.hq.work,Admin
Manager1,P@ssw0rd,Manager,One,manager1@moodle.hq-srv.hq.work,Manager
Manager2,P@ssw0rd,Manager,Two,manager2@moodle.hq-srv.hq.work,Manager
Manager3,P@ssw0rd,Manager,Three,manager3@moodle.hq-srv.hq.work,Manager
User1,P@ssw0rd,User,One,user1@moodle.hq-srv.hq.work,WS
User2,P@ssw0rd,User,Two,user2@moodle.hq-srv.hq.work,WS
User3,P@ssw0rd,User,Three,user3@moodle.hq-srv.hq.work,WS
User4,P@ssw0rd,User,Four,user4@moodle.hq-srv.hq.work,WS
User5,P@ssw0rd,User,Five,user5@moodle.hq-srv.hq.work,Team
User6,P@ssw0rd,User,Six,user6@moodle.hq-srv.hq.work,Team
User7,P@ssw0rd,User,Seven,user7@moodle.hq-srv.hq.work,Team
EOF

# === Создание кастомного профиля "group" ===
echo "[9] Создание пользовательского поля 'group'..."
sudo -u www-data php "$MOODLE_DIR/user/profile/definelib.php" <<'PHP_SCRIPT'
<?php
define('CLI_SCRIPT', true);
require(dirname(__FILE__) . '/../../config.php');
require_once($CFG->dirroot . '/user/profile/lib.php');

if (!profile_get_custom_field_by_shortname('group')) {
    $field = new stdClass();
    $field->shortname = 'group';
    $field->name = 'Group';
    $field->datatype = 'text';
    $field->categoryid = 1;
    $field->description = 'User group';
    $field->descriptionformat = FORMAT_HTML;
    $field->visible = 1;
    $field->required = 0;
    $field->locked = 0;
    $field->forceunique = 0;
    $field->signup = 0;
    $field->defaultdata = '';
    $field->defaultdataformat = FORMAT_HTML;
    profile_save_custom_field($field);
}
PHP_SCRIPT

# === Загрузка пользователей в Moodle ===
echo "[10] Загрузка пользователей..."
sudo -u www-data php "$MOODLE_DIR/admin/tool/uploaduser/cli/upload_user.php" --file=/tmp/users.csv --mode=addnew

echo "✅ Установка завершена!"
echo "Открой в браузере: $DOMAIN"
echo "Логин администратора: $ADMIN_USER"
echo "Пароль: $ADMIN_PASS"
echo "Пользователи добавлены глобально с кастомным полем 'group'"
