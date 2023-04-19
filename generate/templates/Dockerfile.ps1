@"
# syntax=docker/dockerfile:1
FROM alpine:3.17
ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
ARG BUILDPLATFORM
ARG BUILDOS
ARG BUILDARCH
ARG BUILDVARIANT
RUN set -eu; \
    echo "TARGETPLATFORM=$TARGETPLATFORM"; \
    echo "TARGETOS=$TARGETOS"; \
    echo "TARGETARCH=$TARGETARCH"; \
    echo "TARGETVARIANT=$TARGETVARIANT"; \
    echo "BUILDPLATFORM=$BUILDPLATFORM"; \
    echo "BUILDOS=$BUILDOS"; \
    echo "BUILDARCH=$BUILDARCH"; \
    echo "BUILDVARIANT=$BUILDVARIANT";

# Install isync
RUN apk add --no-cache ca-certificates
RUN set -eux; \
    apk add --no-cache isync~$( $VARIANT['_metadata']['package_version'] ); \
    # For mbsync-get-cert to get a self-signed certificate
    apk add --no-cache openssl; \
    mbsync --version


"@

foreach ($c in $VARIANT['_metadata']['components']) {
    if ($c -eq 'pingme') {
        Generate-DownloadBinary @{
            project = 'github.com/kha7iq/pingme'
            version = 'v0.2.5'
            binary = 'pingme'
            archiveformat = '.tar.gz'
            archivefiles = @(
                'pingme'
                'LICENSE.md'
            )
            checksums = 'pingme_checksums.txt'
            architectures = $VARIANT['_metadata']['platforms']
            versionSubcommand = '--version'
        }
    }

    if ($c -eq 'restic') {
        Generate-DownloadBinary @{
            project = 'github.com/restic/restic'
            version = 'v0.15.1'
            binary = 'restic'
            archiveformat = '.bz2'
            checksums = 'SHA256SUMS'
            architectures = $VARIANT['_metadata']['platforms']
            versionSubcommand = 'version'
        }
    }
}

@"
# Install notification tools
RUN apk add --no-cache curl jq

# Install copy tools
RUN apk add --no-cache rsync

# Install helper scripts
COPY sync /sync
RUN chmod +x /sync

WORKDIR /mail
VOLUME /mail

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "/sync" ]

"@
