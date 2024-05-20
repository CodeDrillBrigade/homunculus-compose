# Checks if replica set is already initiated
check_cmd="rs.status()"
status=$(mongosh --host $MONGODB_HOST --port 27017 --username $MONGODB_ADMIN_USR --password $MONGODB_ADMIN_PWD --authenticationDatabase admin --eval "$check_cmd")

echo "$status" | grep -q 'ok: 1'

# Check the exit status of grep
if [ $? -ne 0 ]; then
  # Initiates the replica set in mongo db
  init_cmd="rs.initiate({\"_id\": \"repl0\", \"version\": 1,\"members\": [{\"_id\": 1,\"host\": \"$MONGODB_HOST:27017\",\"priority\": 1}]})"
  mongosh --host $MONGODB_HOST --port 27017 --username $MONGODB_ADMIN_USR --password $MONGODB_ADMIN_PWD --authenticationDatabase admin --eval "$init_cmd"
else
  echo "Replica set already initiated"
fi

mongosh --host $MONGODB_HOST --port 27017 --username $MONGODB_ADMIN_USR --password $MONGODB_ADMIN_PWD --authenticationDatabase $HOMUNCULUS_DB

if [ $? -ne 0 ]; then
  # Creates the user in the Homunculus database
  create_user_cmd="db.createUser({user: \"$MONGODB_ADMIN_USR\", pwd: \"$MONGODB_ADMIN_PWD\",roles: [{role: \"dbOwner\",db: \"$HOMUNCULUS_DB\"}]});"
  mongosh --host $MONGODB_HOST --port 27017 --username $MONGODB_ADMIN_USR --password $MONGODB_ADMIN_PWD --authenticationDatabase admin --eval "use $HOMUNCULUS_DB" --eval "$create_user_cmd"
else
  echo "User already created"
fi