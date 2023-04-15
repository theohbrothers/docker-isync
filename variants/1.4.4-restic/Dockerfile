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

RUN set -eux; \
    RESTIC_VERSION=0.15.1; \
    FILE=restic_0.15.1_${TARGETOS}_${TARGETARCH}.bz2; \
    wget -q https://github.com/restic/restic/releases/download/v0.15.1/$FILE; \
    wget -q https://github.com/restic/restic/releases/download/v0.15.1/SHA256SUMS; \
    SHA=$( sha256sum "$FILE" ); \
    cat SHA256SUMS | grep "$FILE" | sha256sum -c -; \
    bzip2 -d "$FILE"; \
    mv restic_0.15.1_${TARGETOS}_${TARGETARCH} /usr/local/bin/restic; \
    chmod +x /usr/local/bin/restic; \
    restic version | grep "^restic $RESTIC_VERSION";

# Install helper scripts
COPY sync /sync
RUN chmod +x /sync

WORKDIR /mail
VOLUME /mail

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "/sync" ]
