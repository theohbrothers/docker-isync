# Global cache for checksums
function global:Set-Checksums($k, $url) {
    $global:CHECKSUMS = if (Get-Variable -Scope Global -Name CHECKSUMS -ErrorAction SilentlyContinue) { $global:CHECKSUMS } else { @{} }
    $global:CHECKSUMS[$k] = if ($global:CHECKSUMS[$k]) { $global:CHECKSUMS[$k] } else { [System.Text.Encoding]::UTF8.GetString( (Invoke-WebRequest $url).Content ) -split "`n" }
}
function global:Get-ChecksumsFile ($k, $keyword) {
    $global:CHECKSUMS[$k] | ? { $_ -match $keyword } | % { $_ -split "\s" } | Select-Object -Last 1 | % { $_.TrimStart('*') }
}
function global:Get-ChecksumsSha ($k, $keyword) {
    $global:CHECKSUMS[$k] | ? { $_ -match $keyword } | % { $_ -split "\s" } | Select-Object -First 1
}

# Global functions
function global:Generate-DownloadBinary ($o) {
    Set-StrictMode -Version Latest

    $releaseUrl = "https://$( $o['project'] )/releases/download/$( $o['version'] )"
    $checksumsUrl = "$releaseUrl/$( $o['checksums'] )"
    Set-Checksums $o['binary'] $checksumsUrl

    $binaryUpper = $o['binary'].ToUpper()
@"
# Install $( $o['binary'] )
RUN set -eux; \
    export $( $binaryUpper )_VERSION="$( $o['version'] )"; \
    case "`$( uname -m )" in \

"@
    foreach ($a in ($o['architectures'] -split ',') ) {
        $split = $a -split '/'
        $os = $split[0]
        $arch = $split[1]
        $archv = if ($split.Count -gt 2) { $split[2] } else { '' }
        switch ($a) {
            "$os/386" {
                $regex = "$os[-_](i?$arch|x86)[-_]?$archv$( [regex]::Escape($o['archiveformat']) )$"
                $hardware = 'x86'
            }
            "$os/amd64" {
                $regex = "$os[-_]($arch|x86_64)[-_]?$archv$( [regex]::Escape($o['archiveformat']) )$"
                $hardware = 'x86_64'
            }
            "$os/arm/v6" {
                $regex = "$os[-_]($arch|arm)[-_]?($archv)?$( [regex]::Escape($o['archiveformat']) )$"
                $hardware = 'armhf'
            }
            "$os/arm/v7" {
                $regex = "$os[-_]($arch|arm)[-_]?($archv)?$( [regex]::Escape($o['archiveformat']) )$"
                $hardware = 'armv7l'
            }
            "$os/arm64" {
                $regex = "$os[-_]($arch|aarch64)[-_]?$archv$( [regex]::Escape($o['archiveformat']) )$"
                $hardware = 'aarch64'
            }
            "$os/ppc64le" {
                $regex = "$os[-_]$arch[-_]?$archv$( [regex]::Escape($o['archiveformat']) )$"
                $hardware = 'ppc64le'
            }
            "$os/riscv64" {
                $regex = "$os[-_]$arch[-_]?$archv$( [regex]::Escape($o['archiveformat']) )$"
                $hardware = 'riscv64'
            }
            "$os/s390x" {
                $regex = "$os[-_]$arch[-_]?$archv$( [regex]::Escape($o['archiveformat']) )$"
                $hardware = 's390x'
            }
            default {
                throw "Unsupported architecture: $a"
            }
        }

@"
        '$hardware')  \
            URL=$releaseUrl/$( Get-ChecksumsFile $o['binary'] $regex ); \
            SHA256=$( Get-ChecksumsSha $o['binary'] $regex ); \
            ;; \

"@
    }

@"
        *) \
            echo "Architecture not supported"; \
            exit 1; \
            ;; \
    esac; \

"@

@"
    FILE=$( $o['binary'] )$( $o['archiveformat'] ); \
    wget -q "`$URL" -O "`$FILE"; \
    echo "`$SHA256  `$FILE" | sha256sum -c -; \

"@


    if ($o['archiveformat'] -match '\.tar\.gz|\.tgz') {
        if ($o['archivefiles'].Count -gt 0) {
@"
    tar -xvf "`$FILE" --no-same-owner --no-same-permissions -- $( $o['archivefiles'] -join ' ' ); \
    rm -f "`$FILE"; \

"@
        }else {
@"
    tar -xvf "`$FILE" --no-same-owner --no-same-permissions; \
    rm -f "`$FILE"; \

"@
        }
    }elseif ($o['archiveformat'] -match '\.bz2') {
@"
    bzip2 -d "`$FILE"; \

"@
    }elseif ($o['archiveformat'] -match '\.gz') {
@"
    gzip -d "`$FILE"; \

"@
    }else {
        throw "Invalid 'archiveformat'. Supported formats: .tar.gz, .tgz, .bz2, .gz"
    }

@"
    mv -v $( $o['binary'] ) /usr/local/bin/$( $o['binary'] ); \
    chmod +x /usr/local/bin/$( $o['binary'] ); \
    $( $o['binary'] ) $( $o['versionSubcommand'] ); \

"@

    if ($o.Contains('archivefiles')) {
        if ($license = $o['archivefiles'] | ? { $_ -match 'LICENSE' }) {
@"
    mkdir -p /licenses; \
    mv -v $license /licenses/$license; \

"@
        }
    }

@"
    :


"@
}

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
    if ($c -eq 'pingme') {
        Generate-DownloadBinary @{
            project = 'github.com/kha7iq/pingme'
            version = 'v0.2.5'
            binary = 'pingme'
            archiveformat = '.tar.gz'
            archivefiles = @(
                'pingme'
                'LICENSE.md'
            )
            checksums = 'pingme_checksums.txt'
            architectures = $VARIANT['_metadata']['platforms']
            versionSubcommand = '--version'
        }
    }

    if ($c -eq 'restic') {
        Generate-DownloadBinary @{
            project = 'github.com/restic/restic'
            version = 'v0.15.1'
            binary = 'restic'
            archiveformat = '.bz2'
            checksums = 'SHA256SUMS'
            architectures = $VARIANT['_metadata']['platforms']
            versionSubcommand = 'version'
        }
    }
}

@"
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

"@
