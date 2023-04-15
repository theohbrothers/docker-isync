# docker-isync

[![github-actions](https://github.com/theohbrothers/docker-isync/workflows/ci-master-pr/badge.svg)](https://github.com/theohbrothers/docker-isync/actions)
[![github-release](https://img.shields.io/github/v/release/theohbrothers/docker-isync?style=flat-square)](https://github.com/theohbrothers/docker-isync/releases/)
[![docker-image-size](https://img.shields.io/docker/image-size/theohbrothers/docker-isync/latest)](https://hub.docker.com/r/theohbrothers/docker-isync)

Dockerized [isync](https://sourceforge.net/projects/isync/).

isync syncs IMAP as a `Maildir` (emails as individual files), in contrast to [imap-backup]( https://github.com/theohbrothers/docker-imap-backup) which syncs IMAP as `.mbox` backup files.

## Tags

All images contain `curl` and `jq`, which are useful for sending notifications if needed.

| Tag | Dockerfile Build Context |
|:-------:|:---------:|
| `:1.4.4`, `:latest` | [View](variants/1.4.4) |
| `:1.4.4-restic` | [View](variants/1.4.4-restic) |

- `restic`: Includes [`restic`](https://github.com/restic/restic). This is useful for [cron-based backups](#cron).

## Usage

> Note: `isync` the project name, `mbsync` is the tool

The config file used in this image is `/mbsyncrc`.

The volume used to store local Maildir is `/mail`.

The main sync script is `/sync`.

Here are three common sync cases:

- [IMAP to Maildir](#imap-to-maildir) - One-way sync of IMAP server to local Maildir
- [Maildir to IMAP](#maildir-to-imap) - One-way sync of local Maildir to IMAP server
- [IMAP to IMAP](#imap-to-imap) - One-way sync of IMAP server to another IMAP server

For cron-based examples, see [below](#cron).

For a simple demo of the three sync cases, see this `docker-compose` [demo](docs/examples/demo).

### IMAP to Maildir

This syncs `test@example.com` to a local Maildir `/mail`.  Sync state is kept in each folder in `/mail`.

Create config file `mbsyncrc`:

```sh
$ cat mbsyncrc
IMAPStore example-remote
Host imap.example.com
User test@example.com
Pass test
AuthMechs LOGIN
SSLType IMAPS
# Limit the number of simultaneous IMAP commands
PipelineDepth 30

MaildirStore example-local
SubFolders Verbatim
# The trailing '/' is important for Path
Path /mail/
Inbox /mail/INBOX

Channel example
Far :example-remote:
Near :example-local:
Patterns *
Create Near
Expunge Near
SyncState *
Sync Pull
```

Sync:

```sh
docker run --rm -it -v $(pwd)/mbsyncrc:/mbsyncrc:ro -v mail:/mail theohbrothers/docker-isync:latest
```

### Maildir to IMAP

This syncs a local Maildir `/mail` to `test2@example.com`. Sync state is kept in each folder in `/mail`.

Create config file `mbsyncrc`:

```sh
$ cat mbsyncrc
IMAPStore example-remote-2
Host imap.example.com
User test2@example.com
Pass test
AuthMechs LOGIN
SSLType IMAPS
# Limit the number of simultaneous IMAP commands
PipelineDepth 30

MaildirStore example-local
SubFolders Verbatim
# The trailing '/' is important for Path
Path /mail/
Inbox /mail/INBOX

Channel example
Far :example-remote-2:
Near :example-local:
Patterns *
Create Far
Expunge Far
SyncState *
Sync Push
```

Sync:

```sh
docker run --rm -it -v $(pwd)/mbsyncrc:/mbsyncrc:ro -v mail:/mail theohbrothers/docker-isync:latest
```

### IMAP to IMAP

This syncs `test@example.com` to `test3@example.com`. Sync state is kept in the `/mbsync` volume. The `/mail` volume is not used since there's no local Maildir.

Create config file `mbsyncrc`:

```sh
$ cat mbsyncrc
IMAPStore example-remote
Host imap.example.com
User test@example.com
Pass test
AuthMechs LOGIN
SSLType IMAPS
# Limit the number of simultaneous IMAP commands
PipelineDepth 30

IMAPStore example-remote-3
Host imap.example.com
User test3@example.com
Pass test
AuthMechs LOGIN
SSLType IMAPS
# Limit the number of simultaneous IMAP commands
PipelineDepth 30

Channel example
Far :example-remote:
Near :example-remote-3:
Patterns *
Create Near
Expunge Near
SyncState /mbsync/
Sync Pull
```

Sync:

```sh
docker run --rm -it -v $(pwd)/mbsyncrc:/mbsyncrc:ro -v mbsync:/mbsync theohbrothers/docker-isync:latest
```

### Cron

For cron-based sync and cron-based backup with notifications, see `docker-compose` example(s):

- [Cron-based sync with notifications](docs/examples/cron-sync)
- [Cron-based sync and backup with notifications in the same container](docs/examples/cron-sync-backup)
- [Cron-based sync and backup with notifications in separate containers](docs/examples/cron-sync-backup-separate)

### Command line usage

To view command line usage:

```sh
docker run --rm -it theohbrothers/docker-isync:latest --help
```

## Known issues

- For Exchange servers or `outlook.com` IMAP servers, it might be necessary to use `PipelineDepth 1` in the config file to limit the number of simultaneous IMAP commands. See [here](https://sourceforge.net/p/isync/bugs/22/).

## Development

Requires Windows `powershell` or [`pwsh`](https://github.com/PowerShell/PowerShell).

```powershell
# Install Generate-DockerImageVariants module: https://github.com/theohbrothers/Generate-DockerImageVariants
Install-Module -Name Generate-DockerImageVariants -Repository PSGallery -Scope CurrentUser -Force -Verbose

# Edit ./generate templates

# Generate the variants
Generate-DockerImageVariants .
```
