# Cron-based example

## Usage

Start the container:

```sh
docker-compose up
```

At entrypoint:

- `/.mbsyncrc` is created for account `test@example.com`
- A crontab is created that runs `mbsync` daily at `00:00`
- `crond` is started

View `/.mbsyncrc` config:

```sh
docker-compose exec isync cat /.mbsyncrc
```

To run the first-time backup:

```sh
docker-compose exec isync mbsync --config /.mbsyncrc --all --verbose
```

Now, wait out for `00:00` of tomorrow.

At `00:00`, your incremental backup would have run very quickly.

List backup files:

```sh
docker-compose exec isync ls -alR /mail
```

Start a shell:

```sh
docker-compose exec isync sh
```
