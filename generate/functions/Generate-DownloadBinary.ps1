# Version 0.1.1
function Generate-DownloadBinary ($o) {
    Set-StrictMode -Version Latest

    $checksumsKey = "$( $o['binary'] )-$( $o['version'] )"
    $files = [ordered]@{}
    if ($o['checksumsUrl']) {
        Set-Checksums $checksumsKey  $o['checksumsUrl']
    }else {
        $release = Invoke-RestMethod "https://api.github.com/repos/$( $o['repository'] )/releases/tags/$( $o['version'] )"
        $releaseAssetsFiles = $release.assets | ? { $_.name -match [regex]::Escape($o['binary']) -and $_.name -notmatch '\.sha\d+$' }
        foreach ($f in $releaseAssetsFiles ) {
            $sha = & {
                $shaF = $release.assets | ? { $_.name -eq "$( $f.name ).sha256" -or $_ -eq "$( $f.name ).sha512" }
                $r = Invoke-WebRequest $shaF.browser_download_url
                $c = if ($r.headers['Content-Type'] -eq 'text/plain') { $r.Content } else { [System.Text.Encoding]::UTF8.GetString($r.Content) }
                $c = $c.Trim() -replace '^([a-fA-F0-9]+) .+', '$1' # The checksum is the first column
                $c
            }
            $files[$f.name] = $sha
        }
    }
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
        $os = $split[0]  # E.g. 'linux'
        $arch = $split[1]  # E.g. 'amd64'
        $archv = if ($split.Count -gt 2) { $split[2] } else { '' } # E.g. 'v6' or ''
        switch ($a) {
            "$os/386" {
                $hardware = 'x86'
                $regex = "$os[-_](i?$arch|x86(_64)?)[-_]?$archv$( [regex]::Escape($o['archiveformat']) )$|(i?$arch|x86(_64)?)[-_]?$archv.*?[-_]$os.*?$( [regex]::Escape($o['archiveformat']) )$"
            }
            "$os/amd64" {
                $hardware = 'x86_64'
                $regex = "$os[-_]($arch|x86(_64)?)[-_]?$archv$( [regex]::Escape($o['archiveformat']) )$|($arch|x86(_64)?)[-_]?$archv.*?[-_]$os.*?$( [regex]::Escape($o['archiveformat']) )$"
            }
            "$os/arm/v6" {
                $hardware = 'armhf'
                $regex = "$os[-_]($arch|arm)[-_]?($archv)?$( [regex]::Escape($o['archiveformat']) )$|($arch|arm)[-_]?($archv)?.*?[-_]$os.*?$( [regex]::Escape($o['archiveformat']) )$"
            }
            "$os/arm/v7" {
                $hardware = 'armv7l'
                $regex = "$os[-_]($arch|arm)[-_]?($archv)?$( [regex]::Escape($o['archiveformat']) )$|($arch|arm)[-_]?($archv)?.*?[-_]$os.*?$( [regex]::Escape($o['archiveformat']) )$"
            }
            "$os/arm64" {
                $hardware = 'aarch64'
                $regex = "$os[-_]($arch|aarch64)[-_]?$archv$( [regex]::Escape($o['archiveformat']) )$|($arch|aarch64)[-_]?$archv.*?[-_]$os.*?$( [regex]::Escape($o['archiveformat']) )$"
            }
            "$os/ppc64le" {
                $hardware = 'ppc64le'
                $regex = "$os[-_]$arch[-_]?$archv$( [regex]::Escape($o['archiveformat']) )$|$arch[-_]?$archv.*?[-_]$os.*?$( [regex]::Escape($o['archiveformat']) )$"
            }
            "$os/riscv64" {
                $hardware = 'riscv64'
                $regex = "$os[-_]$arch[-_]?$archv$( [regex]::Escape($o['archiveformat']) )$|$arch[-_]?$archv.*?[-_]$os.*?$( [regex]::Escape($o['archiveformat']) )$"
            }
            "$os/s390x" {
                $hardware = 's390x'
                $regex = "$os[-_]$arch[-_]?$archv$( [regex]::Escape($o['archiveformat']) )$|$arch[-_]?$archv.*?[-_]$os.*?$( [regex]::Escape($o['archiveformat']) )$"
            }
            default {
                throw "Unsupported architecture: $a"
            }
        }

        $file = $sha = $url = ''
        if ($o['checksumsUrl']) {
            $file = Get-ChecksumsFile $checksumsKey $regex
            $sha = Get-ChecksumsSha $checksumsKey $regex
            $url = Split-Path $o['checksumsUrl'] -Parent
        } else {
            $file = $files.Keys | ? { $_ -match $regex } | Select-Object -First 1
            if ($file) {
                $url = "https://github.com/$( $o['repository'] )/releases/download/$( $o['version'] )"
                $sha = $files[$file]
            }else {
                throw "No file matched regex: $regex"
            }
        }
        if ($file -and $sha) {
@"
        '$hardware') \
            URL="$url/$file"; \
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

    $destination = if ($o.Contains('destination')) { $o['destination'] } else { "/usr/local/bin/$( $o['binary'] )" }
    $destinationDir = Split-Path $destination -Parent
    if ($o['archiveformat'] -match '\.tar\.gz|\.tgz') {

@"
    mkdir -p extract; \
    tar -C extract -xvf "`$FILE" --no-same-owner --no-same-permissions$( if ($o['archivefiles'].Count -gt 0) { " -- $( $o['archivefiles'] -join ' ' )" } ); \
    mkdir -pv $destinationDir; \
    BIN=`$( find extract -type f -name "$( $o['binary'] )" | head -n1 ); \
    mv -v "`$BIN" $destination; \
    chmod +x $destination; \
    $( $o['testCommand'] ); \

"@

        if ($o.Contains('archivefiles')) {
            if ($license = $o['archivefiles'] | ? { $_ -match 'license' }) {
@"
    mkdir -p /licenses; \
    mv -v extract/$license /licenses/$license; \

"@
            }
        }
@"
    rm -rf extract; \
    rm -f "`$FILE"; \

"@
    }elseif ($o['archiveformat'] -match '\.bz2') {
@"
    bzip2 -d "`$FILE"; \
    mkdir -pv $destinationDir; \
    BIN=$( $o['binary'] ); \
    mv -v "`$BIN" $destination; \
    chmod +x $destination; \
    $( $o['testCommand'] ); \
    rm -f "`$FILE"; \

"@
    }elseif ($o['archiveformat'] -match '\.gz') {
@"
    gzip -d "`$FILE"; \
    mkdir -pv $destinationDir; \
    BIN=$( $o['binary'] ); \
    mv -v "`$BIN" $destination; \
    chmod +x $destination; \
    $( $o['testCommand'] ); \
    rm -f "`$FILE"; \

"@
    }elseif ($o['archiveformat'] -match '\.zip') {
@"
    unzip "`$FILE" -d extract; \
    mkdir -pv $destinationDir; \
    BIN=`$( find extract -type f -name "$( $o['binary'] )" | head -n1 ); \
    mv -v "`$BIN" $destination; \
    chmod +x $destination; \
    $( $o['testCommand'] ); \

"@

        if ($o.Contains('archivefiles')) {
            if ($license = $o['archivefiles'] | ? { $_ -match 'license' }) {
@"
mkdir -p /licenses; \
mv -v extract/$license /licenses/$license; \

"@
            }
        }
@"
    rm -rf extract; \
    rm -f "`$FILE"; \

"@
    }else {
@"
    BIN=$( $o['binary'] ); \
    mkdir -pv $destinationDir; \
    mv -v "`$BIN" $destination; \
    chmod +x $destination; \
    $( $o['testCommand'] ); \

"@
    }

@"
    :


"@
}
