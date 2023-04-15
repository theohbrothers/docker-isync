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
    if ($c -eq 'restic') {
@'
# See: https://github.com/restic/restic/blob/0.15.1/docker/Dockerfile
RUN apk add --update --no-cache ca-certificates fuse openssh-client tzdata jq
RUN set -eux; \
    RESTIC_VERSION=0.15.1; \
    FILE=restic_${RESTIC_VERSION}_${TARGETOS}_${TARGETARCH}.bz2; \
    wget -q https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/$FILE; \
    wget -q https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/SHA256SUMS; \
    SHA=$( sha256sum "$FILE" ); \
    cat SHA256SUMS | grep "$FILE" | sha256sum -c -; \
    rm -f SHA256SUMS; \
    bzip2 -d "$FILE"; \
    mv restic_${RESTIC_VERSION}_${TARGETOS}_${TARGETARCH} /usr/local/bin/restic; \
    chmod +x /usr/local/bin/restic; \
    restic version | grep "^restic $RESTIC_VERSION";


'@
    }
}

@"
# Install notification tools
RUN apk add --no-cache curl jq

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
