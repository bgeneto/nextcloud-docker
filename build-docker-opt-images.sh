#!/bin/bash
# NOTE: Debian/Ubuntu httpd user is www-data with id 33
#       Clearlinux httpd user is httpd with id 80
#       Debian/Ubuntu mariad user id is 999
#       Clearlinux mariadb user id is 27

DIR=$(pwd)

# create .env file from template and source it 
if [ ! -e ".env" ]; then
    echo "Renaming .env file..."
    mv .env.tmp .env
    echo "DIR=${DIR}" >> .env
fi
source .env 

# http and db uid/gid 
DBID=27

# software versions

# php-fpm github repo
URL="https://raw.githubusercontent.com/docker-library/php/master/${PHP}/bullseye/fpm"

# opt image tag 
TAG="${PHP}-fpm-bullseye-opt"

# storage (nextcloud files) folder 
NCDATA="/mnt/storage"

# default optimizations flags
export CFLAGS="-O3 -march=native"
export CPPFLAGS=${CFLAGS}
export CXXFLAGS=${CFLAGS}
export MAKEOPTS="-j$(nproc)"

function start_containers {
    echo "Starting up all containers..."
    cd ${DIR}
    docker compose up -d --remove-orphans
    sudo chmod -R g=u "$DIR/data/nextcloud"
    sudo chmod -R g=u "$NCDATA"
}

echo "Creating required folders..."
if [ ! -d "$NCDATA" ]; then
    echo "Creating data storage directory..."
    sudo mkdir -p "$NCDATA"
    sudo chown -R 33:80 "$NCDATA"
    sudo chmod -R g=u "$NCDATA"
fi

VOL=nextcloud
if [ ! -d "$DIR/config/$VOL" ]; then
    echo "Creating $VOL config volume/directory..."
    mkdir -p "$DIR/config/$VOL"
fi
echo "Changing $VOL config directory ownership..."
sudo chown -R 0:0 "$DIR/config/$VOL"

if [ ! -d "$DIR/data/$VOL" ]; then
    echo "Creating $VOL data volume/directory..."
    mkdir -p "$DIR/data/$VOL"
fi
echo "Changing $VOL data directory ownership..."
sudo chown -R 33:80 "$DIR/data/$VOL"
sudo chmod -R g=u "$DIR/data/$VOL"

VOL=mariadb
if [ ! -d "$DIR/config/$VOL" ]; then
    echo "Creating $VOL config volume/directory..."
    mkdir -p "$DIR/config/$VOL"
fi
echo "Changing $VOL config directory ownership..."
sudo chown -R 0:0 "$DIR/config/$VOL"

if [ ! -d "$DIR/data/$VOL" ]; then
    echo "Creating $VOL data volume/directory..."
    mkdir -p "$DIR/data/$VOL"
fi
echo "Changing $VOL data directory ownership..."
sudo chown -R $DBID:$DBID "$DIR/data/$VOL"

# check if we want to use an optimized image 
if [ $USE_OPT_IMG -eq 0 ]; then
    start_containers
    exit 0
fi;

# php docker files to download
declare -a files=("Dockerfile"
                  "docker-php-entrypoint"
                  "docker-php-ext-configure"
                  "docker-php-ext-enable"
                  "docker-php-ext-install"
                  "docker-php-source"
                 )
# create build dir
mkdir -p $DIR/build/php-fpm && cd $DIR/build/php-fpm

# download github files
if [ ! -f "Dockerfile" ]; then
  for file in "${files[@]}"
  do
    wget "$URL/$file"
    chmod +x "$file"
  done
fi

# change optimization level
sed -i "s/-O2/-O3 -march=native/" "Dockerfile"

# build php optimized docker image
docker build --rm -t "php:${TAG}" .
echo $(docker images | grep ${TAG})

sudo rm -rf $DIR/build/nextcloud-fpm
mkdir -p $DIR/build/nextcloud-fpm && cd $DIR/build/nextcloud-fpm
# download files via git sparse clone this time
git clone --depth 1 --filter=blob:none --sparse \
  https://github.com/nextcloud/docker.git .
git sparse-checkout set ${NC}/fpm
sed -i "s/^FROM php:$PHP-fpm.*$/FROM php:${TAG}/g" "$DIR/build/nextcloud-fpm/${NC}/fpm/Dockerfile"
# build nextcloud opt image 
docker build --rm -t nextcloud:fpm $DIR/build/nextcloud-fpm/${NC}/fpm
docker images | grep opt
start_containers
