#!/bin/bash
DIR=$(pwd)

PHP="8.0"
URL="https://raw.githubusercontent.com/docker-library/php/master/${PHP}/bullseye/fpm"
TAG="${PHP}-fpm-bullseye-opt"
NC=23

export CFLAGS="-O3 -march=native"
export CPPFLAGS=${CFLAGS}
export CXXFLAGS=${CFLAGS}
export MAKEOPTS="-j4"

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

# build docker image
docker build --rm -t "php:${TAG}" .
echo $(docker images | grep ${TAG})

mkdir -p $DIR/build/nextcloud-fpm && cd $DIR/build/nextcloud-fpm
# download files via git sparse clone this time
git clone --depth 1 --filter=blob:none --sparse \
  https://github.com/nextcloud/docker.git .
git sparse-checkout set ${NC}/fpm
sed -i "s/^FROM php:$PHP-fpm.*$/FROM php:${TAG}/g" "$DIR/build/nextcloud-fpm/${NC}/fpm/Dockerfile"
docker build --rm -t nextcloud:fpm-opt $DIR/build/nextcloud-fpm/${NC}/fpm
docker images | grep opt
