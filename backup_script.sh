#! /bin/bash
echo Starting on $(hostname -s)

target_dir = "/etc"
dest_dir = "/opt/backup"

mkdir -p /opt/backup

tar -czf /opt/backup/$(hostname -s)-$(date+"%d.%m.%y").tgz /etc

echo Ended
