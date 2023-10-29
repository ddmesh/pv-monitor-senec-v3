#!/bin/sh


d="$(date +"%Y-%m-%d-%H%M%S")"
BACKUP_DIR="backup"

echo "stopping container"
docker stop graphite grafana

sync

tar cvzf "${BACKUP_DIR}/${d}-fullbackup.tgz" backup.sh  grafana  grafana.readme  graphite-data  graphite.readme  rc.local  senec.sh  start-docker-graphite.sh

sync

echo "restarting container"
docker start graphite grafana
