#!/bin/bash

mongodb_username=""
mongodb_pwd=""
db_name=""
admin_pwd=""

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
  sudo chown lxd:docker ./seed/data/key.key
fi

DMS_GITHUB_URL="https://raw.githubusercontent.com/docker-mailserver/docker-mailserver/master"
if [[ ! -f mailserver.env]]; then
  wget "${DMS_GITHUB_URL}/mailserver.env"
fi

export MONGODB_ADMIN_USR=$mongodb_username
export MONGODB_ADMIN_PWD=$mongodb_pwd
export HOMUNCULUS_DB_NAME=$db_name
export HOMUNCULUS_ADMIN_PASSWORD_HASH=$pwd_hash

docker-compose up -d

sleep 5

init_cmd="rs.initiate({\"_id\": \"repl0\", \"version\": 1,\"members\": [{\"_id\": 1,\"host\": \"mongodb:27017\",\"priority\": 1}]})"

docker exec homunculus-compose-mongodb-1 mongosh --username $mongodb_username --password $mongodb_pwd --authenticationDatabase admin --eval "$init_cmd"

create_user_cmd="db.createUser({user: \"$MONGODB_ADMIN_USR\", pwd: \"$MONGODB_ADMIN_PWD\",roles: [{role: \"dbOwner\",db: \"homunculus-$HOMUNCULUS_DB_NAME\"}]});"
docker exec homunculus-compose-mongodb-1 mongosh --username $mongodb_username --password $mongodb_pwd --authenticationDatabase admin --eval "use homunculus-$HOMUNCULUS_DB_NAME" --eval "$create_user_cmd"