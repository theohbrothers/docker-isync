@"
# syntax=docker/dockerfile:1
FROM $( $VARIANT['_metadata']['distro'] ):$( $VARIANT['_metadata']['distro_version'] )
ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
ARG BUILDPLATFORM
ARG BUILDOS
ARG BUILDARCH
ARG BUILDVARIANT
RUN set -eu; \
    echo "TARGETPLATFORM=`$TARGETPLATFORM"; \
    echo "TARGETOS=`$TARGETOS"; \
    echo "TARGETARCH=`$TARGETARCH"; \
    echo "TARGETVARIANT=`$TARGETVARIANT"; \
    echo "BUILDPLATFORM=`$BUILDPLATFORM"; \
    echo "BUILDOS=`$BUILDOS"; \
    echo "BUILDARCH=`$BUILDARCH"; \
    echo "BUILDVARIANT=`$BUILDVARIANT";

# Install isync
RUN apk add --no-cache ca-certificates
RUN set -eux; \
    apk add --no-cache $( $VARIANT['_metadata']['package'] )~$( $VARIANT['_metadata']['package_version'] ); \
    # For mbsync-get-cert to get a self-signed certificate
    apk add --no-cache openssl; \
    mbsync --version


"@

foreach ($c in $VARIANT['_metadata']['components']) {
    if ($c -eq 'pingme') {
        $PINGME_VERSION = 'v0.2.5'
        Generate-DownloadBinary @{
            binary = 'pingme'
            version = $PINGME_VERSION
            checksumsUrl = "https://github.com/kha7iq/pingme/releases/download/$PINGME_VERSION/pingme_checksums.txt"
            archiveformat = '.tar.gz'
            archivefiles = @(
                'pingme'
                'LICENSE.md'
            )
            architectures = $VARIANT['_metadata']['platforms']
            testCommand = 'pingme --version'
        }
    }

    if ($c -eq 'restic') {
        $RESTIC_VERSION = 'v0.15.1'
        Generate-DownloadBinary @{
            binary = 'restic'
            version = $RESTIC_VERSION
            checksumsUrl = "https://github.com/restic/restic/releases/download/$RESTIC_VERSION/SHA256SUMS"
            archiveformat = '.bz2'
            architectures = $VARIANT['_metadata']['platforms']
            testCommand = 'restic version'
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
