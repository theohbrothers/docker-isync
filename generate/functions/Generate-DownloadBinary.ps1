# Version 0.3.0
function Generate-DownloadBinary ($o) {
    Set-StrictMode -Version Latest

    $o['binary'] = if ($o.Contains('binary')) { $o['binary'] } else { throw "binary is required" } # E.g. foo
    $o['version'] = if ($o.Contains('version')) { $o['version'] } else { throw "version is required" } # E.g. v1.0.0
    $o['checksumsUrl'] = if ($o.Contains('checksumsUrl')) { $o['checksumsUrl'] } else { '' } # E.g. https://github.com/namespace/project/releases/download/v1.0.0/checksums.txt"
    $o['repository'] = if ($o.Contains('repository')) { $o['repository'] } else { '' } # E.g. namespace/project
    $o['archiveformat'] = if ($o.Contains('archiveformat')) { $o['archiveformat'] } else { '' } # E.g. .tar.gz
    $o['archivefiles'] = if ($o.Contains('archivefiles')) { ,$o['archivefiles'] } else { ,@() }
    $o['platforms'] = if ($o.Contains('platforms')) { $o['platforms'] } else { 'linux/386,linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64,linux/ppc64le,linux/riscv64,linux/s390x' }
    $o['platformFallback'] = if ($o.Contains('platformFallback')) { $o['platformFallback'] } else { '' } # linux/amd64
    $o['destination'] = if ($o.Contains('destination')) { $o['destination'] } else { '' } # E.g. /usr/local/bin/foo
    $o['testCommand'] = if ($o.Contains('testCommand')) { $o['testCommand'] } else { '' } # E.g. foo --version

    $checksumsKey = "$( $o['binary'] )-$( $o['version'] )"
    $files = [ordered]@{}
    if ($o['checksumsUrl']) {
        Set-Checksums -ChecksumsUrl $o['checksumsUrl'] -ChecksumsKey $checksumsKey
    }else {
        Set-GithubReleaseFiles -Repository $o['repository'] -Tag $o['version'] -Binary $o['binary']
    }
    $shellVariable = "$( $o['binary'].ToUpper() -replace '[^A-Za-z0-9_]', '_' )_VERSION"
@"
# Install $( $o['binary'] )
RUN set -eux; \
    $shellVariable=$( $o['version'] ); \
    case "`$( uname -m )" in \

"@

    $platforms = [ordered]@{
        "linux/386" = [ordered]@{
            hardware = 'x86'
            regex = "linux[-_.](i?386|x86(_64)?)[-_.]?$( [regex]::Escape($o['archiveformat']) )$|(i?386|x86(_64)?)[-_.]?.*?[-_.]linux.*?$( [regex]::Escape($o['archiveformat']) )$"
        }
        "linux/amd64" = [ordered]@{
            hardware = 'x86_64'
            regex = "linux[-_.](amd64|x86(_64)?)[-_.]?$( [regex]::Escape($o['archiveformat']) )$|(amd64|x86(_64)?)[-_.]?.*?[-_.]linux.*?$( [regex]::Escape($o['archiveformat']) )$"
        }
        "linux/arm/v6" = [ordered]@{
            hardware = 'armhf'
            regex = "linux[-_.](arm)[-_.]?(v6)?$( [regex]::Escape($o['archiveformat']) )$|(arm)[-_.]?(v6)?.*?[-_.]linux.*?$( [regex]::Escape($o['archiveformat']) )$"
        }
        "linux/arm/v7" = [ordered]@{
            hardware = 'armv7l'
            regex = "linux[-_.](arm)[-_.]?(v7)?$( [regex]::Escape($o['archiveformat']) )$|(arm)[-_.]?(v7)?.*?[-_.]linux.*?$( [regex]::Escape($o['archiveformat']) )$"
        }
        "linux/arm64" = [ordered]@{
            hardware = 'aarch64'
            regex = "linux[-_.](arm64|aarch64)[-_.]?$( [regex]::Escape($o['archiveformat']) )$|(arm64|aarch64)[-_.]?.*?[-_.]linux.*?$( [regex]::Escape($o['archiveformat']) )$"
        }
        "linux/ppc64le" = [ordered]@{
            hardware = 'ppc64le'
            regex = "linux[-_.](ppc64le)[-_.]?$( [regex]::Escape($o['archiveformat']) )$|(ppc64le)[-_.]?.*?[-_.]linux.*?$( [regex]::Escape($o['archiveformat']) )$"
        }
        "linux/riscv64" = [ordered]@{
            hardware = 'riscv64'
            regex = "linux[-_.](riscv64)[-_.]?$( [regex]::Escape($o['archiveformat']) )$|(riscv64)[-_.]?.*?[-_.]linux.*?$( [regex]::Escape($o['archiveformat']) )$"
        }
        "linux/s390x" = [ordered]@{
            hardware = 's390x'
            regex = "linux[-_.](s390x)[-_.]?$( [regex]::Escape($o['archiveformat']) )$|(s390x)[-_.]?.*?[-_.]linux.*?$( [regex]::Escape($o['archiveformat']) )$"
        }
    }

    $shaAlgoAll = ''
    foreach ($platform in ($o['platforms'] -split ',')) {
        $file, $sha, $shaAlgo, $downloadBaseUrl = if ($o['checksumsUrl']) {
            Get-ChecksumsFileMeta -ChecksumsKey $checksumsKey -Regex $platforms[$platform]['regex']
        }else {
            Get-GithubReleaseFileMeta -ChecksumsKey $checksumsKey -Regex $platforms[$platform]['regex']
        }

        if ($file -and $sha -and $shaAlgo -and $downloadBaseUrl) {
            $shaAlgoAll = if ($shaAlgoAll) { $shaAlgoAll } else { $shaAlgo }
@"
        '$( $platforms[$platform]['hardware'] )') \
            URL="$downloadBaseUrl/$file"; \
            $( $shaAlgoAll.ToUpper() )=$sha; \
            ;; \

"@
        }
    }

    if ($o['platformFallback']) {
        $file, $sha, $shaAlgo, $downloadBaseUrl = if ($o['checksumsUrl']) {
            Get-ChecksumsFileMeta -ChecksumsKey $checksumsKey -Regex $platforms[$o['platformFallback']]['regex']
        }else {
            Get-GithubReleaseFileMeta -ChecksumsKey $checksumsKey -Regex $platforms[$o['platformFallback']]['regex']
        }

        if ($file -and $sha -and $shaAlgo -and $downloadBaseUrl) {
@"
        *) \
            URL="$downloadBaseUrl/$file"; \
            $( $shaAlgoAll.ToUpper() )=$sha; \
            ;; \
    esac; \

"@
        }
    }else {
@"
        *) \
            echo "Architecture not supported"; \
            exit 1; \
            ;; \
    esac; \

"@
    }

@"
    FILE=$( $o['binary'] )$( $o['archiveformat'] ); \
    wget -q "`$URL" -O "`$FILE"; \
    echo "`$$( $shaAlgoAll.ToUpper() )  `$FILE" | $( $shaAlgoAll.ToLower() )sum -c -; \

"@

    $destination = if ($o['destination']) { $o['destination'] } else { "/usr/local/bin/$( $o['binary'] )" }
    $destinationDir = Split-Path $destination -Parent
    if ($o['archiveformat'] -match '\.tar\.gz|\.tgz') {

@"
    mkdir -p extract; \
    tar -C extract -xvf "`$FILE" --no-same-owner --no-same-permissions$( if ($o['archivefiles'].Length) { " -- $( $o['archivefiles'] -join ' ' )" } ); \
    mkdir -pv $destinationDir; \
    BIN=`$( find extract -type f -name "$( $o['binary'] )" | head -n1 ); \
    mv -v "`$BIN" $destination; \
    chmod +x $destination; \
    $( $o['testCommand'] ); \

"@

        if ($o['archivefiles'].Length) {
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

        if ($o['archivefiles'].Length) {
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
