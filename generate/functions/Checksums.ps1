# Version 0.3.0
# Global cache for checksums
function Set-Checksums {
    param (
        [Parameter(Mandatory,HelpMessage="Enter the checksums file URL. E.g. key to represent the checksums file. E.g. https://github.com/namespace/project/releases/download/v1.0.0/checksums.txt")]
        [string]$ChecksumsUrl
    ,
        [Parameter(Mandatory,HelpMessage="Enter a unique key to represent the checksums file. E.g. project-1.0.0")]
        [string]$ChecksumsKey
    )
    $global:GDIV_CHECKSUMS = if (Get-Variable -Scope Global -Name GDIV_CHECKSUMS -ErrorAction SilentlyContinue) { $global:GDIV_CHECKSUMS } else { @{} }
    $global:GDIV_CHECKSUMS[$ChecksumsKey] = if ($global:GDIV_CHECKSUMS[$ChecksumsKey]) { $global:GDIV_CHECKSUMS[$ChecksumsKey] } else {
        "Fetching checksums from: $ChecksumsUrl" | Write-Host -ForegroundColor DarkGray
        $r = Invoke-WebRequest $ChecksumsUrl
        $checksumsContent = if ($r.headers['Content-Type'] -eq 'text/plain') { $r.Content } else { [System.Text.Encoding]::UTF8.GetString($r.Content) }

        [ordered]@{
            checksumsUrl = $ChecksumsUrl
            checksumsContent = @( $checksumsContent -split "`n" )
            assets = & {
                $assets = [ordered]@{}
                $checksumsContent -split "`n" | % {
                    if ($_ -match '^([a-fA-F0-9]+)[\s\*]+([^\s]+)$') {
                        $sha = $matches[1]
                        $file = $matches[2]
                        $assets[$file] = [ordered]@{
                            sha = $sha
                            shaAlgo = switch ($sha.Length) {
                                64 { 'sha256' }
                                128 { 'sha512' }
                                default { throw "Checksums other than sha256 or sha512 found in $checksumsUrl" }
                            }
                        }
                    }
                }
                $assets
            }
            downloadBaseUrl = Split-Path $checksumsUrl -Parent
        }
    }
}
function Get-ChecksumsFileMeta {
    param (
        [Parameter(Mandatory,HelpMessage="Enter a unique key to represent the checksums file. E.g. project-1.0.0")]
        [string]$ChecksumsKey
    ,
        [Parameter(Mandatory,HelpMessage="Enter a regex to match a file among the checksums.")]
        [string]$Regex
    )
    $file = $global:GDIV_CHECKSUMS[$ChecksumsKey]['assets'].Keys | ? { $_ -match $Regex } | Select-Object -First 1
    if ($file) {
        $sha = $global:GDIV_CHECKSUMS[$ChecksumsKey]['assets'][$file]['sha']
        $shaAlgo = $global:GDIV_CHECKSUMS[$ChecksumsKey]['assets'][$file]['shaAlgo']
        $downloadBaseUrl = $global:GDIV_CHECKSUMS[$checksumsKey]['downloadBaseUrl']
        $file, $sha, $shaAlgo, $downloadBaseUrl
    }else {
        "No file among checksums in $( $global:GDIV_CHECKSUMS[$ChecksumsKey]['checksumsUrl'] ) matching regex: $Regex" | Write-Warning
    }
}
