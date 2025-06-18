#! /bin/bash

apt-get update && apt-get install -y docker-ce docker-compose -y
systemctl enable --now docker.service


docker volume create dbvolume
docker compose -f /root/wiki.yml up -d
