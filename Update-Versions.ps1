# This script is to update versions in version.json, create PR(s) for each bumped version, merge PRs, and release
# It may be run manually or as a cron
# Use -WhatIf for dry run
[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(HelpMessage="Whether to clone a temporary repo before opening PRs. Useful in development")]
    [switch]$CloneTempRepo
,
    [Parameter(HelpMessage="Whether to open a PR for each updated version in version.json")]
    [switch]$PR
,
    [Parameter(HelpMessage="Whether to merge each PR one after another (note that this is not GitHub merge queue which cannot handle merge conflicts). The queue ensures each PR is rebased to prevent merge conflicts")]
    [switch]$AutoMergeQueue
,
    [Parameter(HelpMessage="Whether to create a tagged release and closing milestone, after merging all PRs")]
    [switch]$AutoRelease
,
    [Parameter(HelpMessage="-AutoRelease tag convention")]
    [ValidateSet('calver', 'semver')]
    [string]$AutoReleaseTagConvention = 'calver'
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Install modules
@(
    'Generate-DockerImageVariantsHelpers'
    'Powershell-Yaml'
) | % {
    if (! (Get-InstalledModule $_ -ErrorAction SilentlyContinue) ) {
        Install-Module $_ -Scope CurrentUser -Force
    }
}
# Override with development module if it exists
if (Test-Path ../Generate-DockerImageVariantsHelpers/src/Generate-DockerImageVariantsHelpers) {
    Import-module ../Generate-DockerImageVariantsHelpers/src/Generate-DockerImageVariantsHelpers -Force
}

try {
    if ($CloneTempRepo) {
        $repo = Clone-TempRepo
        Push-Location $repo
    }

    $env:GITHUB_TOKEN = if ($env:GITHUB_TOKEN) { $env:GITHUB_TOKEN } else { (Get-Content ~/.git-credentials -Encoding utf8 -Force) -split "`n" | % { if ($_ -match '^https://[^:]+:([^:]+)@github.com') { $matches[1] } } | Select-Object -First 1 }

    # Get my versions from generate/definitions/versions.json
    $versions = Get-Content $PSScriptRoot/generate/definitions/versions.json -Encoding utf8 | ConvertFrom-Json
    # Get new versions
    $versionsNew = & {
        $content = (Invoke-WebRequest https://sourceforge.net/p/isync/isync/ref/master/tags/).Content
        $matches = [regex]::Matches($content, '/p/isync/isync/ci/v[^/]+/tree/')
        $matches -replace '/p/isync/isync/ci/v([^/]+)/tree/', '$1' | Sort-Object { [version]$_ } -Descending
    }
    # Get changed versions
    $versionsChanged = Get-VersionsChanged -Versions $versions -VersionsNew $versionsNew -AsObject -Descending
    # Update versions.json, and open PRs with CI disabled
    $prs = Update-DockerImageVariantsVersions -VersionsChanged $versionsChanged -CommitPreScriptblock { Move-Item .github .github.disabled -Force } -PR:$PR -WhatIf:$WhatIfPreference
    # Update versions.json, update PRs with CI, merge PRs one at a time, release and close milestone
    $return = Update-DockerImageVariantsVersions -VersionsChanged $versionsChanged -PR:$PR -AutoMergeQueue:$AutoMergeQueue -AutoRelease:$AutoRelease -AutoReleaseTagConvention $AutoReleaseTagConvention -WhatIf:$WhatIfPreference
}catch {
    throw
}finally {
    if ($CloneTempRepo) {
        Pop-Location
    }
}

