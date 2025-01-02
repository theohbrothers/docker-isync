# syntax=docker/dockerfile:1
FROM alpine:3.19
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
    apk add --no-cache isync~1.4.4; \
    # For mbsync-get-cert to get a self-signed certificate
    apk add --no-cache openssl; \
    mbsync --version

# Install restic
RUN set -eux; \
    RESTIC_VERSION=v0.15.2; \
    case "$( uname -m )" in \
        'x86') \
            URL="https://github.com/restic/restic/releases/download/v0.15.2/restic_0.15.2_linux_386.bz2"; \
            SHA256=9245cafed0bc3f0531950cb8f31e3b7c2711a2785c79ec088d554bb8fe16ae81; \
            ;; \
        'x86_64') \
            URL="https://github.com/restic/restic/releases/download/v0.15.2/restic_0.15.2_linux_amd64.bz2"; \
            SHA256=44ce3367b0b413ad48757de8e2a1f4e2c30137e7cdc77db64906f3eb7087b78f; \
            ;; \
        'armhf') \
            URL="https://github.com/restic/restic/releases/download/v0.15.2/restic_0.15.2_linux_arm.bz2"; \
            SHA256=3a379eedcb90ad0ec60a24c89f9892eb7a12ddb8a28045e432fc2c43e7faa186; \
            ;; \
        'armv7l') \
            URL="https://github.com/restic/restic/releases/download/v0.15.2/restic_0.15.2_linux_arm.bz2"; \
            SHA256=3a379eedcb90ad0ec60a24c89f9892eb7a12ddb8a28045e432fc2c43e7faa186; \
            ;; \
        'aarch64') \
            URL="https://github.com/restic/restic/releases/download/v0.15.2/restic_0.15.2_linux_arm64.bz2"; \
            SHA256=1f9d03503d8756311b7904e99aee3460f1ace427aad88f6dcba6a97a9c5a8171; \
            ;; \
        's390x') \
            URL="https://github.com/restic/restic/releases/download/v0.15.2/restic_0.15.2_linux_s390x.bz2"; \
            SHA256=574aeb6cb673aa96cab6fa82656126f1ece4079edf89f68de09a3fce708ad47e; \
            ;; \
        *) \
            echo "Architecture not supported"; \
            exit 1; \
            ;; \
    esac; \
    FILE=restic.bz2; \
    wget -q "$URL" -O "$FILE"; \
    echo "$SHA256  $FILE" | sha256sum -c -; \
    bzip2 -d "$FILE"; \
    mkdir -pv /usr/local/bin; \
    mv -v restic /usr/local/bin/restic; \
    chmod +x /usr/local/bin/restic; \
    restic version; \
    :

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
