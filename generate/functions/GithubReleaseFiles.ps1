# Version 0.3.0
# Global cache for Github release files
function Set-GithubReleaseFiles {
    param (
        [Parameter(Mandatory,HelpMessage="Enter a Github repository. E.g. namespace/project")]
        [ValidateScript({$_ -match '^\w+/\w+$'})]
        [string]$Repository
    ,
        [Parameter(Mandatory,HelpMessage="Enter a tag. E.g. v1.0.0")]
        [ValidateScript({$_ -match '^[\w-_.]+'})]
        [string]$Tag
    ,
        [Parameter(Mandatory,HelpMessage="Enter a binary name. E.g. mybin")]
        [string]$Binary
    )
    $global:GDIV_RELEASE_FILES = if (Get-Variable -Scope Global -Name GDIV_RELEASE_FILES -ErrorAction SilentlyContinue) { $global:GDIV_RELEASE_FILES } else { @{} }
    $global:GDIV_RELEASE_FILES[$checksumsKey] = if ($global:GDIV_RELEASE_FILES[$checksumsKey]) { $global:GDIV_RELEASE_FILES[$checksumsKey] } else {
        [ordered]@{
            repository = "$Repository"
            tag = "$Tag"
            binary = "$Binary"
            releaseUrl = "https://api.github.com/repos/$Repository/releases/tags/$Tag"
            downloadBaseUrl = "https://github.com/$Repository/releases/download/$Tag"
            assets = & {
                $params = @{}
                if ($env:GH_TOKEN) {
                    $params['Headers'] = @{
                        'Accept' = 'application/vnd.github+json'
                        'Authorization' = "token $env:GH_TOKEN"
                        'X-GitHub-Api-Version' = '2026-03-10'
                    }
                }
                $assets = [ordered]@{}
                $releaseUrl = "https://api.github.com/repos/$Repository/releases/tags/$Tag"
                "Fetching release: $releaseUrl" | Write-Host -ForegroundColor DarkGray
                $release = Invoke-RestMethod $releaseUrl @params
                $releaseBinaryAssets = $release.assets | ? { $_.name -match [regex]::Escape($Binary) -and $_.name -notmatch '\.sha\d+$' }
                foreach ($f in $releaseBinaryAssets ) {
                    $sha = & {
                        $shaF = $release.assets | ? { $_.name -eq "$( $f.name ).sha256" -or $_.name -eq "$( $f.name ).sha512" } | Select-Object -First 1
                        "Fetching checksum file: $( $shaF.browser_download_url )" | Write-Host -ForegroundColor DarkGray
                        $r = Invoke-WebRequest $shaF.browser_download_url
                        $c = if ($r.headers['Content-Type'] -eq 'text/plain') { $r.Content } else { [System.Text.Encoding]::UTF8.GetString($r.Content) }
                        $c = $c.Trim() -replace '^([a-fA-F0-9]+) .+', '$1' # The checksum is the first column
                        $c
                    }
                    $assets[$f.name] = [ordered]@{
                        sha = $sha
                        shaAlgo = switch ($sha.Length) {
                            64 { 'sha256' }
                            128 { 'sha512' }
                            default { throw "Checksums other than sha256 or sha512 found in $checksumsUrl" }
                        }
                    }
                }
                $assets
            }
        }
    }
}
function Get-GithubReleaseFileMeta {
    param (
        [Parameter(Mandatory,HelpMessage="Enter a unique key to represent the checksums file. E.g. project-1.0.0")]
        [string]$ChecksumsKey
    ,
        [Parameter(Mandatory,HelpMessage="Enter a regex to match a file among the checksums.")]
        [string]$Regex
    )
    $file = $global:GDIV_RELEASE_FILES[$checksumsKey]['assets'].Keys | ? { $_ -match $Regex } | Select-Object -First 1
    if ($file) {
        $sha = $global:GDIV_RELEASE_FILES[$checksumsKey]['assets'][$file]['sha']
        $shaAlgo = $global:GDIV_RELEASE_FILES[$checksumsKey]['assets'][$file]['shaAlgo']
        $downloadBaseUrl = $global:GDIV_RELEASE_FILES[$checksumsKey]['downloadBaseUrl']
        $file, $sha, $shaAlgo, $downloadBaseUrl
    }else {
        "No file among release files in $( $global:GDIV_RELEASE_FILES[$checksumsKey]['releaseUrl'] ) matching regex: $Regex" | Write-Warning
    }
}
