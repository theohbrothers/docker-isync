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
    echo "TARGETPLATFORM="; \
    echo "TARGETOS="; \
    echo "TARGETARCH="; \
    echo "TARGETVARIANT="; \
    echo "BUILDPLATFORM="; \
    echo "BUILDOS="; \
    echo "BUILDARCH="; \
    echo "BUILDVARIANT=";

# Install isync
RUN apk add --no-cache ca-certificates
RUN set -eux; \
    apk add --no-cache isync~1.4.4; \
    # For mbsync-get-cert to get a self-signed certificate
    apk add --no-cache openssl; \
    mbsync --version

# Install restic
# These packages are needed for all restic features to work. See: https://github.com/restic/restic/blob/0.15.1/docker/Dockerfile
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

# Install pingme
RUN set -eux; \
    export PINGME_VERSION="0.2.5"; \
    OS=$( uname -o ); \
    # The naming conventions of the binaries is not consistent, hence the need for ARCH workaround
    ARCH=$( \
        if [ "$TARGETARCH" = 'amd64' ]; then \
            uname -m; \
        elif [ "$TARGETARCH" = '386' ]; then \
            echo "i$TARGETARCH"; \
        else \
            echo "$TARGETARCH"; \
        fi; \
    ); \
    FILE=pingme_${OS}_${ARCH}${TARGETVARIANT}.tar.gz; \
    wget https://github.com/kha7iq/pingme/releases/download/v$PINGME_VERSION/pingme_checksums.txt; \
    wget -q https://github.com/kha7iq/pingme/releases/download/v${PINGME_VERSION}/$FILE; \
    cat pingme_checksums.txt | grep "$FILE" | sha256sum -c -; \
    tar -xvf "$FILE" -- pingme LICENSE.md; \
    chmod +x pingme; \
    mv pingme /usr/local/bin/pingme; \
    mv LICENSE.md /usr/local/bin/pingme.LICENSE; \
    pingme --version | grep "$PINGME_VERSION"; \
    rm -f pingme_checksums.txt; \
    rm -f "$FILE";

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
