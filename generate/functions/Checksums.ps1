# Version 0.1.1
# Global cache for checksums
function Set-Checksums($k, $url) {
    $global:CHECKSUMS = if (Get-Variable -Scope Global -Name CHECKSUMS -ErrorAction SilentlyContinue) { $global:CHECKSUMS } else { @{} }
    $global:CHECKSUMS[$k] = if ($global:CHECKSUMS[$k]) { $global:CHECKSUMS[$k] } else {
        $r = Invoke-WebRequest $url
        $c = if ($r.headers['Content-Type'] -eq 'text/plain') { $r.Content } else { [System.Text.Encoding]::UTF8.GetString($r.Content) }
        $c -split "`n"
    }
}
function Get-ChecksumsFile ($k, $keyword) {
    $file = $global:CHECKSUMS[$k] | ? { $_ -match $keyword } | % { $_ -split "\s" } | Select-Object -Last 1 | % { $_.TrimStart('*') }
    if ($file) {
        $file
    }else {
        "No file among $k checksums matching regex: $keyword" | Write-Warning
    }
}
function Get-ChecksumsSha ($k, $keyword) {
    $sha = $global:CHECKSUMS[$k] | ? { $_ -match $keyword } | % { $_ -split "\s" } | Select-Object -First 1
    if ($sha) {
        $sha
    }else {
        "No sha among $k checksums matching regex: $keyword" | Write-Warning
    }
}
