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

# Install restic
RUN set -eux; \
    RESTIC_VERSION=v0.15.1; \
    case "$( uname -m )" in \
        'x86') \
            URL="https://github.com/restic/restic/releases/download/v0.15.1/restic_0.15.1_linux_386.bz2"; \
            SHA256=50362f6c4c2d91cf0edc750c578b73605fdbb79443874110cc0a64913553f76b; \
            ;; \
        'x86_64') \
            URL="https://github.com/restic/restic/releases/download/v0.15.1/restic_0.15.1_linux_amd64.bz2"; \
            SHA256=3631e3c3833c84ba71f22ea3df20381676abc7476a7f6d14424d9abfada91414; \
            ;; \
        'armv7l') \
            URL="https://github.com/restic/restic/releases/download/v0.15.1/restic_0.15.1_linux_arm.bz2"; \
            SHA256=1a5c1d2a3b17aa381c318b3f3919f7cfc4cd430c3a2c3053ba055fb4ccf38c97; \
            ;; \
        'aarch64') \
            URL="https://github.com/restic/restic/releases/download/v0.15.1/restic_0.15.1_linux_arm64.bz2"; \
            SHA256=bf6e09743df6899a02f0647d899fb008932760ea872667287bbc47b42091a3b0; \
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

# Install pingme
RUN set -eux; \
    PINGME_VERSION=v0.2.6; \
    case "$( uname -m )" in \
        'x86') \
            URL="https://github.com/kha7iq/pingme/releases/download/v0.2.6/pingme_Linux_x86_64.tar.gz"; \
            SHA256=747e05242f4d1448f2bb7d5cc8903683ec75fa94fa95f2ec1704b0a880a7b9e9; \
            ;; \
        'x86_64') \
            URL="https://github.com/kha7iq/pingme/releases/download/v0.2.6/pingme_Linux_x86_64.tar.gz"; \
            SHA256=2f224389804b433318adaa5b5a4debe9974d8f17a03d2909e4c651cb723a4bed; \
            ;; \
        'armv7l') \
            URL="https://github.com/kha7iq/pingme/releases/download/v0.2.6/pingme_Linux_arm.tar.gz"; \
            SHA256=7feeac9c9a0c353da2a03f0e3eb67aab6bc4a31248c0f3c694a80f15156804d9; \
            ;; \
        'aarch64') \
            URL="https://github.com/kha7iq/pingme/releases/download/v0.2.6/pingme_Linux_arm64.tar.gz"; \
            SHA256=06ead384717a718366d032c11b223ec5285705623c9507a8e3432bc7e4cd6e89; \
            ;; \
        *) \
            echo "Architecture not supported"; \
            exit 1; \
            ;; \
    esac; \
    FILE=pingme.tar.gz; \
    wget -q "$URL" -O "$FILE"; \
    echo "$SHA256  $FILE" | sha256sum -c -; \
    tar -xvf "$FILE" --no-same-owner --no-same-permissions -- pingme LICENSE.md; \
    rm -f "$FILE"; \
    mkdir -pv /usr/local/bin; \
    mv -v pingme /usr/local/bin/pingme; \
    chmod +x /usr/local/bin/pingme; \
    pingme --version; \
    mkdir -p /licenses; \
    mv -v LICENSE.md /licenses/LICENSE.md; \
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
