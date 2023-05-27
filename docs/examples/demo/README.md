# Demo

In this demo, we will demonstrate the three most common sync cases, IMAP to Maildir, Maildir to IMAP, and IMAP to IMAP.

1. Create email accounts `test@example.com`, `test2@example.com`, and `test3@example.com`
1. Setup the web email client
1. Login to web email client and send a few emails to `test@example.com`
1. Demo: Sync IMAP to Maildir (`test@example.com` to a local Maildir `/mail`)
1. Demo: Sync Maildir to IMAP (local Maildir `/mail` to `test2@example.com`)
1. Demo: Sync IMAP to IMAP (`test@example.com` to `test3@example.com`)

To start all services, run:

```sh
docker-compose up
```

The following services are now running:

- `step-ca` as our self-signed CA to sign self-signed certs for `mail.example.com` used by `docker-mailserver`
- `docker-mailserver` as mail server
- `snappymail` as web email client
- `isync` as IMAP sync client

## 1. Create email accounts

First, in `docker-mailserver` container, setup three email accounts with password `test`.

```sh
echo 'test' | docker exec -i $( docker-compose ps -q docker-mailserver ) setup email add test@example.com
echo 'test' | docker exec -i $( docker-compose ps -q docker-mailserver ) setup email add test2@example.com
echo 'test' | docker exec -i $( docker-compose ps -q docker-mailserver ) setup email add test3@example.com
```

Then, confirm all accounts are added. You should see three accounts:

```sh
docker-compose exec docker-mailserver setup email list
```

## 2. Setup web email client

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
  - In `Timeout`, enter `60`
  - Uncheck `Use short login`
  - Check `Use authentication`
  - Check `Use login as sender`
  - Uncheck `Require verification of SSL certificate`
- At bottom right, click `Test` button:
  - Username: `test@example.com`
  - Password: `test`
  - Click on `Test` button. Tests should be green. Click `Save` button

## 3. Login to web email client and send a few emails to yourself

Login to `snappymail` at http://localhost:8888, using username `test@example.com` and password `test`.

Send a few emails to yourself at `test@example.com`.

## 4. Demo: Sync IMAP to Maildir

In this step, we will sync `test@example.com` to a local Maildir in `/mail` in a docker container.

Self-signed cert of IMAP server `imap.example.com` should have been created by the container entrypoint. To view self-signed cert:

```sh
docker-compose exec isync-imap-to-maildir cat /imap.example.com.pem | openssl x509 -text
```

`/mbsyncrc` should have been created by the container entrypoint. To view `/mbsyncrc` config:

```sh
docker-compose exec isync-imap-to-maildir cat /mbsyncrc
```

Now, run the sync (should take only 1 second):

```sh
docker-compose exec isync-imap-to-maildir /sync
```

To list synced files in `/mail`:

```sh
docker-compose exec isync-imap-to-maildir find /mail
```

If you see something like the following, the sync was successful:

```sh
/mail
/mail/Trash
/mail/Trash/.uidvalidity
/mail/Trash/.mbsyncstate
/mail/Trash/tmp
/mail/Trash/cur
/mail/Trash/new
/mail/Sent
/mail/Sent/.uidvalidity
/mail/Sent/.mbsyncstate
/mail/Sent/tmp
/mail/Sent/cur
/mail/Sent/cur/1681553239.33_6.436d48e6cbdf,U=3:2,S
/mail/Sent/cur/1681553239.33_4.436d48e6cbdf,U=1:2,S
/mail/Sent/cur/1681553239.33_5.436d48e6cbdf,U=2:2,S
/mail/Sent/new
/mail/INBOX
/mail/INBOX/.uidvalidity
/mail/INBOX/.mbsyncstate
/mail/INBOX/tmp
/mail/INBOX/cur
/mail/INBOX/new
/mail/INBOX/new/1681553239.33_3.436d48e6cbdf,U=3:2,
/mail/INBOX/new/1681553239.33_2.436d48e6cbdf,U=2:2,
/mail/INBOX/new/1681553239.33_1.436d48e6cbdf,U=1:2,
/mail/Drafts
/mail/Drafts/.uidvalidity
/mail/Drafts/.mbsyncstate
/mail/Drafts/tmp
/mail/Drafts/cur
/mail/Drafts/new
/mail/Junk
/mail/Junk/.uidvalidity
/mail/Junk/.mbsyncstate
/mail/Junk/tmp
/mail/Junk/cur
/mail/Junk/new
```

## 5. Demo: Sync to Maildir to IMAP

In this step, we will sync the Maildir folder `/mail` to `test2@example.com`.

First, create a fresh Maildir `/mail` in this container based on the previous container's Maildir `/mail`:

```sh
docker exec $( docker-compose ps -q isync-imap-to-maildir ) tar -C /mail -cvf - . --exclude=.mbsyncstate --exclude=.uidvalidity | docker exec -i $( docker-compose ps -q isync-maildir-to-imap ) tar -C /mail -xvf -
```

Self-signed cert of IMAP server `imap.example.com` should have been created by the container entrypoint. To view self-signed cert:

```sh
docker-compose exec isync-maildir-to-imap cat /imap.example.com.pem | openssl x509 -text
```

`/mbsyncrc` should have been created by the container entrypoint. To view `/mbsyncrc` config:

```sh
docker-compose exec isync-maildir-to-imap cat /mbsyncrc
```

Run the sync (should take only 1 second):

```sh
docker-compose exec isync-maildir-to-imap /sync
```

Finally, in Snappymail at http://localhost:8888, login to `test2@example.com`. If you see emails present in `INBOX` and `SENT`, the sync was successful.

## 6. Demo: Sync to IMAP to IMAP

In this step, we will sync `test@example.com` to `test3@example.com`.

Self-signed cert of IMAP server `imap.example.com` should have been created by the container entrypoint. To view self-signed cert:

```sh
docker-compose exec isync-imap-to-imap cat /imap.example.com.pem | openssl x509 -text
```

`/mbsyncrc` should have been created by the container entrypoint. To view `/mbsyncrc` config:

```sh
docker-compose exec isync-imap-to-imap cat /mbsyncrc
```

Run the sync (should take only 1 second):

```sh
docker-compose exec isync-imap-to-imap /sync
```

Finally, in Snappymail at http://localhost:8888, login to `test3@example.com`. If you see emails present in `INBOX` and `SENT`, the sync was successful.
