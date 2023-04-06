# Demo sync

In this `docker-compose` example, we will:

- Create a mail account `test@example.com`
- Setup the web email client for `test@example.com`
- Login to web email client and send a few emails to `test@example.com`
- Sync `test@example.com` using `isync`

## Usage

To start all services, run:

```sh
docker-compose up
```

The following services are now running:

- `step-ca` as our self-signed CA, to sign self-signed certs for `docker-mailserver`
- `docker-mailserver` as mail server
- `snappymail` as web email client
- `isync` as IMAP sync client

### 1. Create email account

First, setup a `docker-mailserver` email account `test@example.com` and password `test`:

```sh
docker-compose exec docker-mailserver setup email add test@example.com
```

Once done, wait for about 10s and `docker-mailserver` will automatically setup the email account.

### 2. Setup web email client

Login to `snappymail` Admin Panel at http://localhost:8888/?admin. Username is `admin`. Get the Admin Panel password by running:

```sh
docker-compose exec snappymail cat /var/lib/snappymail/_data_/_default_/admin_password.txt
```

In `snappymail` Admin Panel, click `Domains`, and click `+ Add Domain` button:

- In `Name` box, enter `example.com`
- Click `IMAP` tab:
  - In `Server` box, enter `imap.example.com`
  - In `Secure` dropdown, select `SSL/TLS`
  - In `Port` , enter `993`
  - In `Timeout`, enter `300`
  - Uncheck `Use short login`
  - Uncheck `Require verification of SSL certificate`
- Click `SMTP` tab:
  - In `Server` box, enter `smtp.example.com`
  - In `Secure` dropdown, select `SSL/TLS`
  - In `Port` , enter `465`
  - In `Timeout`, enter `60
  - Uncheck `Use short login`
  - Check `Use authentication`
  - Check `Use login as sender`
  - Uncheck `Require verification of SSL certificate`
- At bottom right, click `Test` button:
  - Username: `test@example.com`
  - Password: `test`
  - Click on `Test` button. Tests should be green. Click `Save` button

### 3. Login to web email client and send a few emails to yourself

Login to `snappymail` at http://localhost:8888, using username `test@example.com` and password `test`.

Send a few emails to yourself at `test@example.com`.

### 4. Run IMAP sync

Self-signed cert of IMAP server `imap.example.com` should have been created.

View self-signed cert:

```sh
docker-compose exec isync cat /imap.example.com.pem
docker-compose exec isync cat /imap.example.com.pem | openssl x509 -text
```

`/.mbsyncrc` shoud have been created.

View `/.mbsyncrc` config:

```sh
docker-compose exec isync cat /.mbsyncrc
```

Now, run the sync (should take only 1 second):

```sh
docker-compose exec isync mbsync --config /.mbsyncrc --all --verbose
```

List synced files:

```sh
docker-compose exec isync ls -alR /mail
```

Start a shell:

```sh
docker-compose exec isync sh
```
