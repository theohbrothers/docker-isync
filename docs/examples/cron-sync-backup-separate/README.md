# Cron sync and backup (separate containers)

This demo shows a cron-based sync of IMAP to a local Maildir in `/mail`, and a cron-based backup of `mail` using [restic](https://github.com/restic/restic), in separate containers.

Start the container(s):

```sh
docker-compose up
```

`isync` service is now running:

- `/mbsyncrc` config file is created
- `/notify.sh` is created
- A crontab is created that runs `/sync` and `/notify.sh` daily at `00:00`
- `crond` is started

`restic` service is now running:

- `/backup.sh` is created
- `/notify.sh` is created
- A crontab is created that runs `/backup.sh` and `/notify.sh` daily at `00:05`
- `crond` is started

## 1. Perform first-time sync

View `/mbsyncrc` config:

```sh
docker-compose exec isync cat /mbsyncrc
```

Run a first-time sync (this will fail, because `test@example.com` is not a real account. See next step):

```sh
docker-compose exec isync /sync
```

Since there's no such IMAP account as `test@example.com`, let's create some files in `/mail` to simulate a successful sync:

```sh
docker-compose exec isync mkdir -p /mail/INBOX /mail/INBOX/cur /mail/INBOX/new /mail/INBOX/tmp
docker-compose exec isync touch /mail/INBOX/new/123 /mail/INBOX/new/456
docker-compose exec isync touch /mail/INBOX/.mbsyncstate /mail/INBOX/.uidvalidity
```

Finally, list the files:

```sh
docker-compose exec isync find /mail
```

## 2. Perform first-time backup

Perform a first-time backup of `/mail` using `restic`. This helps to ensure subsequent cron-based `restic` backups are speedy, since `restic` backups are incremental.

```sh
docker-compose exec restic /backup.sh
```

The backup should succeed:

```sh
Files:           4 new,     0 changed,     0 unmodified
Dirs:            5 new,     0 changed,     0 unmodified
Data Blobs:      0 new
Tree Blobs:      5 new
Added to the repository: 2.758 KiB (1.341 KiB stored)

processed 4 files, 0 B in 0:00
snapshot c9ed53b0 saved
```

## 3. Wait for cron sync

Now, wait out for `00:00` of tomorrow.

At `00:00`, the incremental sync would have run very quickly.

List synced files:

```sh
docker-compose exec isync find /mail
```

## 4. Wait for cron backup

Now, wait out for `00:05` of tomorrow.

At `00:05`, the `restic` incremental backup would have run very quickly.

List synced files:

```sh
docker-compose exec isync find /mail
```

## 5. Restore a backup

If `/mail` is ever lost, `restic restore` can easily restore the data.

First, list the backup snapshots:

```sh
docker exec -it $( docker-compose ps -q restic ) restic snapshots
```

You should see a list of snapshots:

```txt
repository 5ba7868d opened (version 2, compression level auto)
ID        Time                 Host          Tags        Paths
--------------------------------------------------------------
c9ed53b0  2023-04-15 15:48:48  346a68a05c86  cron        /mail
81ec9c8f  2023-04-15 00:00:00  346a68a05c86  cron        /mail
--------------------------------------------------------------
2 snapshots
```

Restore the latest snapshot `81ec9c8f` to the `/restore` volume:

```sh
docker exec -it $( docker-compose ps -q restic ) restic restore 81ec9c8f --target /restore
```

List restored files in `/restore`:

```sh
docker exec -it $( docker-compose ps -q restic ) find /restore
```

If all is well, clean out the `/mail` volume:

```sh
docker-compose exec restic sh -c 'find /mail -mindepth 1 -maxdepth 1 | xargs rm -rf'
```

Restore the latest snapshot `81ec9c8f` to the `/mail` volume:

```sh
docker exec -it $( docker-compose ps -q restic ) restic restore 81ec9c8f --target /mail
```

List restored files in `/mail`:

```sh
docker exec -it $( docker-compose ps -q restic ) find /mail
```

The backup is fully restored.
