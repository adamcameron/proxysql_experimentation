#!/bin/bash

# usage
# ./rebuildContainers.sh [LUCEE_PASSWORD] [MARIADB_ROOT_PASSWORD] [MARIADB_PASSWORD]
# EG:
# ./rebuildContainers.sh 12345 123 1234

clear; printf "\033[3J"
docker-compose down --remove-orphans --volumes
LUCEE_PASSWORD=$1 docker-compose build --no-cache
MARIADB_ROOT_PASSWORD=$2 MARIADB_PASSWORD=$3 docker-compose up --force-recreate --detach
