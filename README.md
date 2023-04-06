# docker-isync

[![github-actions](https://github.com/theohbrothers/docker-isync/workflows/ci-master-pr/badge.svg)](https://github.com/theohbrothers/docker-isync/actions)
[![github-release](https://img.shields.io/github/v/release/theohbrothers/docker-isync?style=flat-square)](https://github.com/theohbrothers/docker-isync/releases/)
[![docker-image-size](https://img.shields.io/docker/image-size/theohbrothers/docker-isync/latest)](https://hub.docker.com/r/theohbrothers/docker-isync)

Dockerized [isync](https://sourceforge.net/projects/isync/).

isync syncs IMAP as a Maildir (emails as individual files), in contrast to [imap-backup]( https://github.com/theohbrothers/docker-imap-backup) which syncs IMAP as .mbox backup files.

## Tags

| Tag | Dockerfile Build Context |
|:-------:|:---------:|
| `:1.4.4`, `:latest` | [View](variants/1.4.4) |

## Usage

> Note: `isync` the project name, `mbsync` is the tool

See the following docker-compose examples:

- [Cron-based sync using crond](docs/examples/cron)
- [Demo sync](docs/examples/demo)

```sh
# Print command line usage
docker run --rm -it theohbrothers/docker-isync:1.4.4 --help

# Create a mbsync config of your IMAP and Maildir settings
# See: https://isync.sourceforge.io/mbsync.html#CONFIGURATION
# See: https://wiki.archlinux.org/title/Isync
nano .mbsyncrc

# Sync
docker run --rm -it \
    -v $(pwd)/.mbsyncrc:/.mbsyncrc \
    -v mail:/mail \
    theohbrothers/docker-isync:1.4.4 mbsync --config /.mbsyncrc --all --verbose
```

## Development

Requires Windows `powershell` or [`pwsh`](https://github.com/PowerShell/PowerShell).

```powershell
# Install Generate-DockerImageVariants module: https://github.com/theohbrothers/Generate-DockerImageVariants
Install-Module -Name Generate-DockerImageVariants -Repository PSGallery -Scope CurrentUser -Force -Verbose

# Edit ./generate templates

# Generate the variants
Generate-DockerImageVariants .
```
