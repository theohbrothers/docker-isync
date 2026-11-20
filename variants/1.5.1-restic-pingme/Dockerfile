# syntax=docker/dockerfile:1
FROM alpine:3.24
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
    apk add --no-cache isync~1.5.1; \
    # For mbsync-get-cert to get a self-signed certificate
    apk add --no-cache openssl; \
    mbsync --version

# Install restic
RUN set -eux; \
    RESTIC_VERSION=0.20.0; \
    case "$( uname -m )" in \
        'x86') \
            URL="https://github.com/restic/restic/releases/download/v0.20.0/restic_0.20.0_linux_386.bz2"; \
            SHA256=a23e8de316f2aa8ab2fcface8128d56c2afd24682dafb213484f87d441a28634; \
            ;; \
        'x86_64') \
            URL="https://github.com/restic/restic/releases/download/v0.20.0/restic_0.20.0_linux_amd64.bz2"; \
            SHA256=0ccd9fa7885074a24603b051e01bf9bd8b5e45d6a1791e9d9887e9e9372107f7; \
            ;; \
        'armhf') \
            URL="https://github.com/restic/restic/releases/download/v0.20.0/restic_0.20.0_linux_arm.bz2"; \
            SHA256=34fcedbb2493ade701e166af0cef5ea3d3f5aad1b0c268c7105e1ec511b7d7e1; \
            ;; \
        'armv7l') \
            URL="https://github.com/restic/restic/releases/download/v0.20.0/restic_0.20.0_linux_arm.bz2"; \
            SHA256=34fcedbb2493ade701e166af0cef5ea3d3f5aad1b0c268c7105e1ec511b7d7e1; \
            ;; \
        'aarch64') \
            URL="https://github.com/restic/restic/releases/download/v0.20.0/restic_0.20.0_linux_arm64.bz2"; \
            SHA256=1188daded239bccb5952a01d2ad33e77a0d3dc34f9d9fc1e7fdda618d44938ef; \
            ;; \
        'ppc64le') \
            URL="https://github.com/restic/restic/releases/download/v0.20.0/restic_0.20.0_linux_ppc64le.bz2"; \
            SHA256=cc5c697380f66a27097f6c560ff3cf897013f89c2c8d3cf2245cab24dd64d688; \
            ;; \
        'riscv64') \
            URL="https://github.com/restic/restic/releases/download/v0.20.0/restic_0.20.0_linux_riscv64.bz2"; \
            SHA256=e96cebcbf4b7bcad67282d583dfde93997eefaee255b43461e0a48bde4d68714; \
            ;; \
        's390x') \
            URL="https://github.com/restic/restic/releases/download/v0.20.0/restic_0.20.0_linux_s390x.bz2"; \
            SHA256=885f49b0fda79cc487b9d1a53e942d35de076e3815d9371ca46b8e21695c93aa; \
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
        'armhf') \
            URL="https://github.com/kha7iq/pingme/releases/download/v0.2.7/pingme_Linux_arm.tar.gz"; \
            SHA256=facd6b1c210b8aee3ba4631aab097d9e52b2a1e946685ef3034a162234c1de35; \
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
