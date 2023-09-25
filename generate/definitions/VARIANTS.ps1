$local:VERSIONS = @( Get-Content $PSScriptRoot/versions.json -Encoding utf8 -raw | ConvertFrom-Json )
$local:PACKAGE = 'isync'

# Docker image variants' definitions
$local:VARIANTS_MATRIX = @(
    foreach ($v in $local:VERSIONS.isync.versions) {
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
                    job_group_key = $variant['package_version']
                }
                # Docker image tag. E.g. '3.8-curl'
                tag = @(
                        $variant['package_version']
                        $subVariant['components'] | ? { $_ }
                ) -join '-'
                tag_as_latest = if ($variant['package_version'] -eq $local:VARIANTS_MATRIX[0]['package_version'] -and $subVariant['components'].Count -eq 0) { $true } else { $false }
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
