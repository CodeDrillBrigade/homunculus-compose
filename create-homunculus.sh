#!/bin/bash

mongodb_username=""
mongodb_pwd=""
db_name=""
admin_pwd=""
mongodb_port="27017"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --mongodb_username)
            mongodb_username="$2"
            shift 2
            ;;
        --mongodb_pwd)
            mongodb_pwd="$2"
            shift 2
            ;;
        --db_name)
            db_name="$2"
            shift 2
            ;;
        --admin_pwd)
            admin_pwd="$2"
            shift 2
            ;;
        --mongodb_port)
            mongodb_port="$2"
            shift 2
            ;;
        *)
            echo "Error: Unsupported flag $1" >&2
            exit 1
            ;;
    esac
done

if [[ ! -f ./seed/data/key.key ]]; then
  mkdir -p ./seed/data
  openssl rand -base64 756 > ./seed/data/key.key
  chmod 400 ./seed/data/key.key
fi

pwd_hash=$(htpasswd -nbBC 10 USER "$admin_pwd" | awk -F':' '{print $2}')

export MONGODB_ADMIN_USR=$mongodb_username
export MONGODB_ADMIN_PWD=$mongodb_pwd
export HOMUNCULUS_DB_NAME=$db_name
export HOMUNCULUS_ADMIN_PASSWORD_HASH=$pwd_hash
export MONGODB_IP=127.0.0.1
export MONGODB_PORT=$mongodb_port

docker-compose up -d