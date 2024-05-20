#!/bin/bash

# Extraction of the script parameters
mongodb_username=""
mongodb_pwd=""
db_name=""
mailer_config=""
frontend_url=""

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
            db_name="homunculus-$2"
            shift 2
            ;;
        --admin_pwd)
            admin_pwd="$2"
            shift 2
            ;;
        --mailer_config)
            mailer_config="$2"
            shift 2
            ;;
        --frontend_url)
            frontend_url="$2"
            shift 2
            ;;
        *)
            echo "Error: Unsupported flag $1" >&2
            exit 1
            ;;
    esac
done

# MongoDb Configuration
# creates a secret key and assigns permission to the docker user (note: requires sudo)
if [[ ! -f ./seed/data/key.key ]]; then
  mkdir -p ./seed/data
  openssl rand -base64 756 > ./seed/data/key.key
  chmod 400 ./seed/data/key.key
  # Sets up the permission for the key. You may not need this
  # sudo chown lxd:docker ./seed/data/key.key
fi

# Creates the mongodb part of the .env file
rm homunculus.env
echo "# The admin username of mongodb. Note: is an admin both of the admin and local databases" >> homunculus.env
echo "MONGODB_ADMIN_USR=$mongodb_username" >> homunculus.env
echo "# The password for the admin user" >> homunculus.env
echo "MONGODB_ADMIN_PWD=$mongodb_pwd" >> homunculus.env
echo "# The name of the homunculus database" >> homunculus.env
echo "HOMUNCULUS_DB=$db_name" >> homunculus.env

# Hermes configuration
# Creates the folders for Hermes
mkdir -p ./hermes/config/forms
mkdir -p ./hermes/config/mails
mkdir -p ./hermes/config/templates

# Populates and moves the templates
reset_pwd_id=$(uuidgen)
invite_id=$(uuidgen)
cp ./templates/forgot_template.hbs "./hermes/config/templates/$reset_pwd_id.hbs"
cp ./templates/invite_template.hbs "./hermes/config/templates/$invite_id.hbs"

# If I have a SMTP configuration, I will update the templates accordingly, otherwise I'll use an api key based config
mail_credentials=""
smtp_pattern="smtp://*:*@*:*"
if [[ $mailer_config == $smtp_pattern ]]; then
    # Remove the prefix "smtp://"
    temp="${$mailer_config#smtp://}"

    # Extract username and the rest (password@ip:port)
    username="${temp%%:*}"
    rest="${temp#*:}"

    # Extract password and the rest (ip:port)
    password="${rest%%@*}"
    rest="${rest#*@}"

    # Extract IP and port
    ip="${rest%%:*}"
    port="${rest#*:}"

    mail_credentials="\"type\": \"SMTP\",\n\"username\": \"$username\",\n\"password\": \"$password\",\n\"smtpHost\": \"$ip\",\n\"smtpPort\": $port"

else
    mail_credentials="\"provider\": \"RESEND\",\n\"apiKey\": \"$mailer_config\""
fi

# Updates and moves the reset password mail configuration
reset_content=$(<"./templates/forgot_mail.json")
reset_content=$(echo "$reset_content" | sed "s/<GENERATED_RESET_MAIL_ID>/$reset_pwd_id/")
reset_content=$(echo "$reset_content" | sed "s/<MAIL_CREDENTIALS>/$mail_credentials/")
echo "$reset_content" > "./templates/forgot_mail.json"
cp ./templates/forgot_mail.json ./hermes/config/mails/forgot_mail.json

# Updates and moves the invite mail configuration
invite_content=$(<"./templates/invite_mail.json")
invite_content=$(echo "$invite_content" | sed "s/<GENERATED_RESET_MAIL_ID>/$invite_id/")
invite_content=$(echo "$invite_content" | sed "s/<MAIL_CREDENTIALS>/$mail_credentials/")
echo "$invite_content" > "./templates/invite_mail.json"
cp ./templates/invite_mail.json ./hermes/config/mails/invite_mail.json

# Homunculus Configuration
# Creates the Homunculus part in the .env file
echo "" >> homunculus.env
echo "# The auth secret for the JWT" >> homunculus.env
echo "AUTH_SECRET=$(uuidgen)" >> homunculus.env
echo "# The auth secret for the refresh JWT" >> homunculus.env
echo "REFRESH_SECRET=$(uuidgen)" >> homunculus.env
echo "# The Homunculus frontend url, needed to correctly populate the emails" >> homunculus.env
echo "HOMUNCULUS_URL=$frontend_url" >> homunculus.env
echo "# The Hermes template id for the reset password email, automatically generated" >> homunculus.env
echo "RESET_PASSWORD_TEMPLATE_ID=$reset_pwd_id" >> homunculus.env
echo "# The Hermes template id for the invitation email, automatically generated" >> homunculus.env
echo "INVITE_TEMPLATE_ID=$invite_id" >> homunculus.env

# Starts docker compose
docker-compose --env-file ./homunculus.env up -d

# Small wait
sleep 5

# Initiates the replica set in mongo db
init_cmd="rs.initiate({\"_id\": \"repl0\", \"version\": 1,\"members\": [{\"_id\": 1,\"host\": \"mongodb:27017\",\"priority\": 1}]})"
docker exec homunculus-compose-mongodb-1 mongosh --username $mongodb_username --password $mongodb_pwd --authenticationDatabase admin --eval "$init_cmd"

# Creates the user in the Homunculus database
create_user_cmd="db.createUser({user: \"$mongodb_username\", pwd: \"$mongodb_pwd\",roles: [{role: \"dbOwner\",db: \"$db_name\"}]});"
docker exec homunculus-compose-mongodb-1 mongosh --username $mongodb_username --password $mongodb_pwd --authenticationDatabase admin --eval "use $db_name" --eval "$create_user_cmd"