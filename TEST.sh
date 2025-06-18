#! /bin/bash

docker-compose -f wiki.yml exec MediaWiki bash -c '
php maintenance/install.php \
    --dbname="mediawiki" \
    --dbuser="wiki" \
    --dbpass="DEP@ssw0rd" \
    --dbtype="mysql" \
    --dbserver="database" \
    --pass="P@ssw0rd" \
    --scriptpath="" \
    "MyWiki" "Admin"
'

# Копируем LocalSettings.php на хост (проверяем, что это файл)
echo "Копирование LocalSettings.php..."
docker-compose -f wiki.yml exec MediaWiki bash -c '
if [ -f "/var/www/html/LocalSettings.php" ]; then
    cat /var/www/html/LocalSettings.php > /tmp/LocalSettings.php
else
    echo "Ошибка: /var/www/html/LocalSettings.php не найден!"
    exit 1
fi
'

# Забираем файл из контейнера
docker cp wiki:/tmp/LocalSettings.php ./LocalSettings.php

# Проверяем, что файл скопирован
if [ -f "./LocalSettings.php" ]; then
    echo "LocalSettings.php успешно создан!"
else
    echo "Ошибка: Не удалось скопировать LocalSettings.php!"
    exit 1
fi
