#!/bin/bash

# usage
# ./restartContainers.sh [MARIADB_ROOT_PASSWORD] [MARIADB_PASSWORD]
# use same passwords as when initially calling rebuildContainers.sh

# EG:
# ./restartContainers.sh 123 1234

clear; printf "\033[3J"
docker-compose stop
MARIADB_ROOT_PASSWORD=$1 MARIADB_PASSWORD=$2 docker-compose up --detach mariadb1
MARIADB_ROOT_PASSWORD=$1 MARIADB_PASSWORD=$2 docker-compose up --detach mariadb2
MARIADB_PASSWORD=$3 docker-compose up --detach lucee
docker-compose up --detach ftp
