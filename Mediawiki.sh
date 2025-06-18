#! /bin/bash

apt-get update && apt-get install -y docker-ce docker-compose –y
systemctl enable --now docker.service

mv DEMO-2024-TESTING/LocalSettings.php ~/

docker volume create dbvolume
docker compose -f DEMO-2024-TESTING/wiki.yml up -d
