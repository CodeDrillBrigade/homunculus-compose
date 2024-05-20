# Homunculus

![Homunculus Icon](https://raw.githubusercontent.com/CodeDrillBrigade/Homunculus-desk/main/public/logo192.png)

Homunculus is a simple app to manage biochemistry lab inventories.<br>
It supports:

-   Multiple users with different permissions
-   Managing multiple rooms with multiple cabinets, with a shelf granularity.
-   Managing different types of materials with different configuration, allowing to specify the structure of each box.
-   Updating the current inventory, keeping a History of the usage of each material.

### Roadmap

-   [x] First bare, working version (0.0.2)
-   [ ] Improving roles and permissions
-   [ ] Improving search
-   [ ] Add alerts

## Running Homunculus
This repository provides all the components needed to run Homunculus out of the box:
- A MongoDB database instance
- A [mailer service](https://github.com/LotuxPunk/Hermes)
- The Homunculus backend
- The Homunculus frontend

To automatically set up all the variables needed to run the environment the first time you can run:

```bash
sudo ./create-homunculus.sh --mongodb_username DB_ADMIN_USERNAME --mongodb_pwd DB_ADMIN_PWD --db_name DB_NAME --mailer_config MAILER_CONFIG_STRING --frontend_url FRONTEND_URL --backend_url BACKEND_URL
```

### :warning: Troubleshooting
Depending on your system you may or may not need to run the command with sudo. 
Sudo it's needed to change the ownership of the key file of MongoDb, at line 59:
```bash
  # Sets up the permission for the key. You may not need this
  sudo chown lxd:docker ./seed/data/key.key
```
If the script goes in error because the user:group is not valid, comment the line and run it again

### Explanation of the parameters

- `DB_ADMIN_USERNAME`: the username of the user that will be both admin of mongodb and of your homunculus database.
- `DB_ADMIN_PWD`: the password for that user.
- `DB_NAME`: the name of your homunculus db. In the end, the name will be `homunculus-DB_NAME`.
- `MAILER_CONFIG_STRING`: Homunculus needs to be able to send email for the reset password and invitation process. You
can do so both providing a [Resend](https://resend.com/) (It has a great free tier) or by making it connect to your own 
SMTP server by passing the string `smtp://SMTP_USERNAME:SMTP_PASSWORD@IP:PORT`. The configuration will be stored internally 
and never provided at client side.
- `FRONTEND_URL`: the url of your frontend. Needed to format the emails.
- `BACKEND_URL`: the url of your backend. 

You need to run this only once. The following time, it is enough to run:

```bash
docker-compose --env-file ./homunculus.env up -d
```

## Bootstrap
When the system is started for the first time, an admin user with a temporary password (1 hour) is created. You can find the credentials in the
logs of homunculus by running:

```bash
homunculus-compose-homunculus-1
```

You will find something like this:
```bash
12:29:24.300 [DefaultDispatcher-worker-1] INFO  Application - Autoreload is disabled because the development mode is off.
12:29:24.603 [DefaultDispatcher-worker-1] INFO  [Koin] - Koin started with 20 definitions in 0.415955 ms
12:29:24.647 [DefaultDispatcher-worker-1] INFO  Application - Application started in 0.372 seconds.
12:29:24.647 [DefaultDispatcher-worker-1] INFO  Application - Starting database configuration
12:29:25.058 [DefaultDispatcher-worker-1] INFO  Application - Created index by_fuzzy_name on MaterialDaoImpl
12:29:25.075 [DefaultDispatcher-worker-1] INFO  Application - Created index by_email on UserDaoImpl
12:29:25.084 [DefaultDispatcher-worker-1] INFO  Application - Created index by_username on UserDaoImpl
12:29:25.105 [DefaultDispatcher-worker-1] INFO  Application - Created index by_shelf_id on BoxDaoImpl
12:29:25.105 [DefaultDispatcher-worker-1] INFO  Application - Database configuration completed
12:29:25.105 [DefaultDispatcher-worker-1] INFO  Application - Starting system initialization
12:29:25.158 [DefaultDispatcher-worker-1] INFO  Application - Admin role not found, creating
12:29:25.188 [DefaultDispatcher-worker-1] INFO  Application - No users found in the database, creating the default admin
--> 12:29:25.278 [DefaultDispatcher-worker-1] INFO  Application - Created admin with username: admin and temporaryToken: <YOUR_TOKEN>
12:29:25.293 [DefaultDispatcher-worker-4] INFO  Application - Responding at http://0.0.0.0:8080
```