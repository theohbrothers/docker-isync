# Cron sync

This demo shows a cron-based sync of IMAP to a local Maildir in `/mail`.

Start the container(s):

```sh
docker-compose up
```

`isync` service is now running:

- `/mbsyncrc` config file is created
- A crontab is created that runs sync daily at `00:00`
- `crond` is started

## 1. Perform first-time sync

View `/mbsyncrc` config:

```sh
docker-compose exec isync cat /mbsyncrc
```

Run a first-time sync:

```sh
docker-compose exec isync /sync
```

## 2. Wait for cron sync

Now, wait out for `00:00` of tomorrow.

At `00:00`, the incremental sync would have run very quickly.

List synced files:

```sh
docker-compose exec isync find /mail
```
