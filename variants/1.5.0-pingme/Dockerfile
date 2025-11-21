# syntax=docker/dockerfile:1
FROM alpine:3.21
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
    apk add --no-cache isync~1.5.0; \
    # For mbsync-get-cert to get a self-signed certificate
    apk add --no-cache openssl; \
    mbsync --version

# Install pingme
RUN set -eux; \
    PINGME_VERSION=v0.2.7; \
    case "$( uname -m )" in \
        'x86') \
            URL="https://github.com/kha7iq/pingme/releases/download/v0.2.7/pingme_Linux_x86_64.tar.gz"; \
            SHA256=f956feddf4e0af7b8d5e3cc8bf1cd7ffe3f72ec7bf78d1fcde51844838f34f02; \
            ;; \
        'x86_64') \
            URL="https://github.com/kha7iq/pingme/releases/download/v0.2.7/pingme_Linux_x86_64.tar.gz"; \
            SHA256=f956feddf4e0af7b8d5e3cc8bf1cd7ffe3f72ec7bf78d1fcde51844838f34f02; \
            ;; \
        'armv7l') \
            URL="https://github.com/kha7iq/pingme/releases/download/v0.2.7/pingme_Linux_arm.tar.gz"; \
            SHA256=facd6b1c210b8aee3ba4631aab097d9e52b2a1e946685ef3034a162234c1de35; \
            ;; \
        'aarch64') \
            URL="https://github.com/kha7iq/pingme/releases/download/v0.2.7/pingme_Linux_arm64.tar.gz"; \
            SHA256=a0e546338bb9b1881c999f508a31ee8c1da3fdac1ee376eb12df26647f51142b; \
            ;; \
        *) \
            echo "Architecture not supported"; \
            exit 1; \
            ;; \
    esac; \
    FILE=pingme.tar.gz; \
    wget -q "$URL" -O "$FILE"; \
    echo "$SHA256  $FILE" | sha256sum -c -; \
    mkdir -p extract; \
    tar -C extract -xvf "$FILE" --no-same-owner --no-same-permissions -- pingme LICENSE.md; \
    mkdir -pv /usr/local/bin; \
    BIN=$( find extract -type f -name "pingme" | head -n1 ); \
    mv -v "$BIN" /usr/local/bin/pingme; \
    chmod +x /usr/local/bin/pingme; \
    pingme --version; \
    mkdir -p /licenses; \
    mv -v extract/LICENSE.md /licenses/LICENSE.md; \
    rm -rf extract; \
    rm -f "$FILE"; \
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
