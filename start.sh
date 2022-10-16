#!/bin/bash
# NOTE: Debian/Ubuntu httpd user is www-data with id 33 
#       Clearlinux httpd user is httpd with id 80 
#       Debian/Ubuntu mariad user id is 999 
#       Clearlinux mariadb user id is 27

DIR=$(pwd)

if [ -f "$DIR/.env.tmp" ]; then
    grep -qxF "DIR=$DIR" "$DIR/.env.tmp" || echo "DIR=$DIR" >> "$DIR/.env.tmp"
else
    grep -qxF "DIR=$DIR" "$DIR/.env" || echo "DIR=$DIR" >> "$DIR/.env"
fi

VOL=nextcloud

if [ ! -d "$DIR/config/$VOL" ]; then
    echo "Creating $VOL config volume/directory..."
    mkdir -p "$DIR/config/$VOL"
fi
echo "Changing $VOL config directory ownership..."
chown -R 0:0 "$DIR/config/$VOL"

if [ ! -d "$DIR/data/$VOL" ]; then
    echo "Creating $VOL data volume/directory..."
    mkdir -p "$DIR/data/$VOL"
fi
echo "Changing $VOL data directory ownership..."
chown -R 33:33 "$DIR/data/$VOL"

VOL=mariadb

if [ ! -d "$DIR/config/$VOL" ]; then
    echo "Creating $VOL config volume/directory..."
    mkdir -p "$DIR/config/$VOL"
fi
echo "Changing $VOL config directory ownership..."
chown -R 0:0 "$DIR/config/$VOL"

if [ ! -d "$DIR/data/$VOL" ]; then
    echo "Creating $VOL data volume/directory..."
    mkdir -p "$DIR/data/$VOL"
fi
echo "Changing $VOL data directory ownership..."
chown -R 999:999 "$DIR/data/$VOL"

echo "Starting up containers..." 
docker compose up -d

