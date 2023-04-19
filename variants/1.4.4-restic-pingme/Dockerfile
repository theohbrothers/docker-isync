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
RUN set -eux; \
    export RESTIC_VERSION="v0.15.1"; \
    case "$( uname -m )" in \
        'x86')  \
            URL=https://github.com/restic/restic/releases/download/v0.15.1/restic_0.15.1_linux_386.bz2; \
            SHA256=50362f6c4c2d91cf0edc750c578b73605fdbb79443874110cc0a64913553f76b; \
            ;; \
        'x86_64')  \
            URL=https://github.com/restic/restic/releases/download/v0.15.1/restic_0.15.1_linux_amd64.bz2; \
            SHA256=3631e3c3833c84ba71f22ea3df20381676abc7476a7f6d14424d9abfada91414; \
            ;; \
        'armv7l')  \
            URL=https://github.com/restic/restic/releases/download/v0.15.1/restic_0.15.1_linux_arm.bz2; \
            SHA256=1a5c1d2a3b17aa381c318b3f3919f7cfc4cd430c3a2c3053ba055fb4ccf38c97; \
            ;; \
        'aarch64')  \
            URL=https://github.com/restic/restic/releases/download/v0.15.1/restic_0.15.1_linux_arm64.bz2; \
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
    mv -v restic /usr/local/bin/restic; \
    chmod +x /usr/local/bin/restic; \
    restic version; \
    :

# Install pingme
RUN set -eux; \
    export PINGME_VERSION="v0.2.5"; \
    case "$( uname -m )" in \
        'x86')  \
            URL=https://github.com/kha7iq/pingme/releases/download/v0.2.5/pingme_Linux_i386.tar.gz; \
            SHA256=5a14e80693800284f11daf7d5ba71a7cbe78e18948579584f36069d7a2f31d4a; \
            ;; \
        'x86_64')  \
            URL=https://github.com/kha7iq/pingme/releases/download/v0.2.5/pingme_Linux_x86_64.tar.gz; \
            SHA256=93133b9c978d5a579526261255c2a7a9ca6dfc5ab42ef65e1de4fab15d8ac808; \
            ;; \
        'armv7l')  \
            URL=https://github.com/kha7iq/pingme/releases/download/v0.2.5/pingme_Linux_armv7.tar.gz; \
            SHA256=6f26a3926e6ed038ca132b4d1985cd2f6c0ccf037fbc78f710bdc2cc76b3fc5a; \
            ;; \
        'aarch64')  \
            URL=https://github.com/kha7iq/pingme/releases/download/v0.2.5/pingme_Linux_arm64.tar.gz; \
            SHA256=496bb93402611d5710bc66b26f64f13fc0f888d0b3cc1f4d7960c7c631860dd3; \
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
