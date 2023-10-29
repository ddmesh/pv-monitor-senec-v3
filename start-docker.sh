#!/bin/bash

GRAFANA_BASE="/root/grafana/data"
GRAPHITE_BASE="/root/graphite-data"

# Das Datenverzeichniss für Grafana habe ich im Homeverzeichniss von Root
mkdir -p ${GRAFANA_BASE}

# start docker as deamon. das fuellt auch das datenverzeichniss
docker run --name grafana -u $(id -u) -d -v "${GRAFANA_BASE}:/var/lib/grafana" -p 80:3000 grafana/grafana-oss

# start datenbank


mkdir -p ${GRAPHITE_BASE}/statsd/config ${GRAPHITE_BASE}/graphite/storage ${GRAPHITE_BASE}/graphite/conf

docker run -d \
 --name graphite \
 --restart=always \
 -v ${GRAPHITE_BASE}/graphite/conf:/opt/graphite/conf \
 -v ${GRAPHITE_BASE}/graphite/storage:/opt/graphite/storage \
 -v ${GRAPHITE_BASE}/statsd/config:/opt/statsd/config \
 -p 81:80 \
 -p 2003-2004:2003-2004 \
 -p 2023-2024:2023-2024 \
 -p 8125:8125/udp \
 -p 8126:8126 \
 graphiteapp/graphite-statsd
