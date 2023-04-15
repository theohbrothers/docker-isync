# Cron

This demo shows how to setup a cron-based sync.

Start the container:

```sh
docker-compose up
```

At entrypoint:

- `/mbsyncrc` config file is created
- A crontab is created that runs `mbsync` daily at `00:00`
- `crond` is started

View `/mbsyncrc` config:

```sh
docker-compose exec isync cat /mbsyncrc
```

Run the first-time sync:

```sh
docker-compose exec isync /sync
```

Now, wait out for `00:00` of tomorrow.

At `00:00`, your incremental sync would have run very quickly.

List synced files:

```sh
docker-compose exec isync ls -alR /mail
```

Start a shell:

```sh
docker-compose exec isync sh
```
