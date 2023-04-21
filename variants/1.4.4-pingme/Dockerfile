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

# Install pingme
RUN set -eux; \
    PINGME_VERSION=v0.2.5; \
    case "$( uname -m )" in \
        'x86') \
            URL=https://github.com/kha7iq/pingme/releases/download/v0.2.5/pingme_Linux_x86_64.tar.gz; \
            SHA256=5a14e80693800284f11daf7d5ba71a7cbe78e18948579584f36069d7a2f31d4a; \
            ;; \
        'x86_64') \
            URL=https://github.com/kha7iq/pingme/releases/download/v0.2.5/pingme_Linux_x86_64.tar.gz; \
            SHA256=93133b9c978d5a579526261255c2a7a9ca6dfc5ab42ef65e1de4fab15d8ac808; \
            ;; \
        'armv7l') \
            URL=https://github.com/kha7iq/pingme/releases/download/v0.2.5/pingme_Linux_armv7.tar.gz; \
            SHA256=6f26a3926e6ed038ca132b4d1985cd2f6c0ccf037fbc78f710bdc2cc76b3fc5a; \
            ;; \
        'aarch64') \
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
