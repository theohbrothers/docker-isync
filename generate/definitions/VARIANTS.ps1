$local:PACKAGE_VERSIONS = @(
    '1.4.4'
)
# Docker image variants' definitions
$local:VARIANTS_MATRIX = @(
    foreach ($v in $local:PACKAGE_VERSIONS) {
        @{
            package_version = $v
            subvariants = @(
                @{ components = @() }
                @{ components = @('pingme') }
                @{ components = @('restic') }
                @{ components = @('restic', 'pingme') }
            )
        }
    }
)

$VARIANTS = @(
    foreach ($variant in $VARIANTS_MATRIX){
        foreach ($subVariant in $variant['subvariants']) {
            @{
                # Metadata object
                _metadata = @{
                    package_version = $variant['package_version']
                    platforms = & {
                        if ( $subVariant['components'] -contains 'pingme') {
                            'linux/386,linux/amd64,linux/arm/v7,linux/arm64'
                        }else {
                            'linux/386,linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64,linux/s390x'
                        }
                    }
                    components = $subVariant['components']
                }
                # Docker image tag. E.g. '3.8-curl'
                tag = @(
                        $variant['package_version']
                        $subVariant['components'] | ? { $_ }
                ) -join '-'
                tag_as_latest = if ($variant['package_version'] -eq $local:PACKAGE_VERSIONS[0] -and $subVariant['components'].Count -eq 0) { $true } else { $false }
            }
        }
    }
)

# Docker image variants' definitions (shared)
$VARIANTS_SHARED = @{
    buildContextFiles = @{
        templates = @{
            'Dockerfile' = @{
                common = $true
                includeHeader = $false
                includeFooter = $false
                passes = @(
                    @{
                        variables = @{}
                    }
                )
            }
            'docker-entrypoint.sh' = @{
                common = $true
                passes = @(
                    @{
                        variables = @{}
                    }
                )
            }
            'sync' = @{
                common = $true
                passes = @(
                    @{
                        variables = @{}
                    }
                )
            }
        }
    }
}

# Global cache for checksums
$global:CHECKSUMS = @{}
function global:Set-Checksums($k, $url) {
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
