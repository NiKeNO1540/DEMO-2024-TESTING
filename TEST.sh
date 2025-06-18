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

# Копируем сгенерированный LocalSettings.php на хост
docker-compose -f wiki.yml exec MediaWiki cat /var/www/html/LocalSettings.php > ./LocalSettings.php
