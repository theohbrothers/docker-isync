function global:Generate-DownloadBinary ($o) {
    Set-StrictMode -Version Latest

    Set-Checksums "$( $o['binary'] )-$( $o['version'] )" $o['checksumsUrl']

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

        $file = Get-ChecksumsFile "$( $o['binary'] )-$( $o['version'] )" $regex
        if ($file) {
            $sha = Get-ChecksumsSha "$( $o['binary'] )-$( $o['version'] )" $regex
@"
        '$hardware') \
            URL=$( Split-Path $o['checksumsUrl'] -Parent )/$file; \
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
    }elseif ($o['archiveformat'] -match '\.zip') {
@"
    unzip "`$FILE" $( $o['binary'] ); \

"@
    }

    $destination = if ($o.Contains('destination')) { $o['destination'] } else { "/usr/local/bin/$( $o['binary'] )" }
    $destinationDir = Split-Path $destination -Parent
@"
    mkdir -pv $destinationDir; \
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
