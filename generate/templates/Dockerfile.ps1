# Global cache for checksums
function global:Set-Checksums($k, $url) {
    $global:CHECKSUMS = if (Get-Variable -Scope Global -Name CHECKSUMS -ErrorAction SilentlyContinue) { $global:CHECKSUMS } else { @{} }
    $global:CHECKSUMS[$k] = if ($global:CHECKSUMS[$k]) { $global:CHECKSUMS[$k] } else { [System.Text.Encoding]::UTF8.GetString( (Invoke-WebRequest $url).Content ) -split "`n" }
}
function global:Get-ChecksumsFile ($k, $keyword) {
    $file = $global:CHECKSUMS[$k] | ? { $_ -match $keyword } | % { $_ -split "\s" } | Select-Object -Last 1 | % { $_.TrimStart('*') }
    if ($file) {
        $file
    }else {
        "No file among $k checksums matching regex: $keyword" | Write-Warning
    }
}
function global:Get-ChecksumsSha ($k, $keyword) {
    $sha = $global:CHECKSUMS[$k] | ? { $_ -match $keyword } | % { $_ -split "\s" } | Select-Object -First 1
    if ($sha) {
        $sha
    }else {
        "No sha among $k checksums matching regex: $keyword" | Write-Warning
    }
}

# Global functions
function global:Generate-DownloadBinary ($o) {
    Set-StrictMode -Version Latest

    $releaseUrl = "https://$( $o['project'] )/releases/download/$( $o['version'] )"
    $checksumsUrl = "$releaseUrl/$( $o['checksums'] )"
    Set-Checksums $o['binary'] $checksumsUrl

    $shellVariable = "$( $o['binary'].ToUpper() -replace '[^A-Za-z0-9_]', '_' )_VERSION"
@"
# Install $( $o['binary'] )
RUN set -eux; \
    $shellVariable=$( $o['version'] ); \
    case "`$( uname -m )" in \

"@

    $o['architectures'] = if ($o.Contains('architectures')) { $o['architectures'] } else { 'linux/386,linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64,linux/ppc64le,linux/riscv64,linux/s390x' }
    foreach ($a in ($o['architectures'] -split ',') ) {
        $split = $a -split '/'
        $os = $split[0]
        $arch = $split[1]
        $archv = if ($split.Count -gt 2) { $split[2] } else { '' }
        switch ($a) {
            "$os/386" {
                $hardware = 'x86'
                $regex = "$os[-_](i?$arch|x86(_64)?)[-_]?$archv$( [regex]::Escape($o['archiveformat']) )$"
            }
            "$os/amd64" {
                $hardware = 'x86_64'
                $regex = "$os[-_]($arch|x86(_64)?)[-_]?$archv$( [regex]::Escape($o['archiveformat']) )$"
            }
            "$os/arm/v6" {
                $hardware = 'armhf'
                $regex = "$os[-_]($arch|arm)[-_]?($archv)?$( [regex]::Escape($o['archiveformat']) )$"
            }
            "$os/arm/v7" {
                $hardware = 'armv7l'
                $regex = "$os[-_]($arch|arm)[-_]?($archv)?$( [regex]::Escape($o['archiveformat']) )$"
            }
            "$os/arm64" {
                $hardware = 'aarch64'
                $regex = "$os[-_]($arch|aarch64)[-_]?$archv$( [regex]::Escape($o['archiveformat']) )$"
            }
            "$os/ppc64le" {
                $hardware = 'ppc64le'
                $regex = "$os[-_]$arch[-_]?$archv$( [regex]::Escape($o['archiveformat']) )$"
            }
            "$os/riscv64" {
                $hardware = 'riscv64'
                $regex = "$os[-_]$arch[-_]?$archv$( [regex]::Escape($o['archiveformat']) )$"
            }
            "$os/s390x" {
                $hardware = 's390x'
                $regex = "$os[-_]$arch[-_]?$archv$( [regex]::Escape($o['archiveformat']) )$"
            }
            default {
                throw "Unsupported architecture: $a"
            }
        }

        $file = Get-ChecksumsFile $o['binary'] $regex
        if ($file) {
            $sha = Get-ChecksumsSha $o['binary'] $regex
@"
        '$hardware') \
            URL=$releaseUrl/$file; \
            SHA256=$sha; \
            ;; \

"@
        }
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
    }

    $destination = if ($o.Contains('destination')) { $o['destination'] } else { "/usr/local/bin/$( $o['binary'] )" }
@"
    mv -v $( $o['binary'] ) $destination; \
    chmod +x $destination; \
    $( $o['testCommand'] ); \

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
            testCommand = 'pingme --version'
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
            testCommand = 'restic version'
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
