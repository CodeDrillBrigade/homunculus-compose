db = new Mongo().getDB(process.env.MONGO_INITDB_DATABASE);

db.createCollection('User', { capped: false });
db.createCollection('Role', { capped: false });

db.Role.insert([
    {
        "_id": "5b4f5239-5942-4b6f-a520-6652bd6e3400",
        "name": "Admin",
        "description": "Admin role",
        "permissions": [
            "ADMIN"
        ],
    }
])

db.User.insert([
    {
        "_id": "4affa16c-c557-428e-ac49-7752a2c9cc78",
        "username": "admin",
        "passwordHash": process.env.HOMUNCULUS_ADMIN_PASSWORD_HASH,
        "name": "admin",
        "surname": "admin",
        "roles": [
            "5b4f5239-5942-4b6f-a520-6652bd6e3400"
        ],
        "contacts": []
    }
])

adminDB = new Mongo().getDB("admin");

adminDB.auth(process.env.MONGO_INITDB_ROOT_USERNAME, process.env.MONGO_INITDB_ROOT_PASSWORD)

rs.initiate()