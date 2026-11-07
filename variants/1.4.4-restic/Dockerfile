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
    RESTIC_VERSION=0.19.1; \
    case "$( uname -m )" in \
        'x86') \
            URL="https://github.com/restic/restic/releases/download/v0.19.1/restic_0.19.1_linux_386.bz2"; \
            SHA256=c715a3de2fffb70a4c7864ef2d195db8bad96bc0284757cd5bd0f43362f2a191; \
            ;; \
        'x86_64') \
            URL="https://github.com/restic/restic/releases/download/v0.19.1/restic_0.19.1_linux_amd64.bz2"; \
            SHA256=f415415624dcc452f2a02b8c33641791a8c6d6d3b65bbb3543fcf9a25151585c; \
            ;; \
        'armhf') \
            URL="https://github.com/restic/restic/releases/download/v0.19.1/restic_0.19.1_linux_arm.bz2"; \
            SHA256=1edc5f67b0dd0d028586ab28c34b4da7522eabce933b3f6cd04f9ea184c2a502; \
            ;; \
        'armv7l') \
            URL="https://github.com/restic/restic/releases/download/v0.19.1/restic_0.19.1_linux_arm.bz2"; \
            SHA256=1edc5f67b0dd0d028586ab28c34b4da7522eabce933b3f6cd04f9ea184c2a502; \
            ;; \
        'aarch64') \
            URL="https://github.com/restic/restic/releases/download/v0.19.1/restic_0.19.1_linux_arm64.bz2"; \
            SHA256=a5f64aaab53d51e311fa3829124c5b703f2d14cf187d8640b6be3b2b49376465; \
            ;; \
        'ppc64le') \
            URL="https://github.com/restic/restic/releases/download/v0.19.1/restic_0.19.1_linux_ppc64le.bz2"; \
            SHA256=6bebeb6001ad42650e17ddf10f187464dcc2e220ab3d24ade2413a74bf54735b; \
            ;; \
        'riscv64') \
            URL="https://github.com/restic/restic/releases/download/v0.19.1/restic_0.19.1_linux_riscv64.bz2"; \
            SHA256=fe2215a9879861139a3a02c8f5d62d1be16d29d393aa11bea652b92ea8ac52fa; \
            ;; \
        's390x') \
            URL="https://github.com/restic/restic/releases/download/v0.19.1/restic_0.19.1_linux_s390x.bz2"; \
            SHA256=c9398ef8cb658039b782c6d9be8f724ca9c95775ca3e232842b858d4fe6ba3b3; \
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
    BIN=restic; \
    mv -v "$BIN" /usr/local/bin/restic; \
    chmod +x /usr/local/bin/restic; \
    restic version; \
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
