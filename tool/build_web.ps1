<#
.SYNOPSIS
    Builds the Flutter web release that GitHub Pages will serve.

.DESCRIPTION
    GitHub Pages serves a project from https://<user>.github.io/<repo>/,
    so the app has to be built with a matching --base-href. The repo name
    defaults to this folder's name, which is what the deploy workflow uses.

.PARAMETER RepoName
    GitHub repository name. Defaults to the current folder name.

.PARAMETER Profile
    Build in profile mode instead of release.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File tool/build_web.ps1
    powershell -ExecutionPolicy Bypass -File tool/build_web.ps1 -RepoName my-student-record
#>
[CmdletBinding()]
param(
    [string]$RepoName,
    [switch]$Profile
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($RepoName)) {
    $RepoName = Split-Path -Leaf $projectRoot
}

Push-Location $projectRoot
try {
    $mode = if ($Profile) { '--profile' } else { '--release' }
    $baseHref = "/$RepoName/"

    Write-Host "Building student_record for https://<user>.github.io$baseHref" -ForegroundColor Cyan

    & flutter build web $mode --no-web-resources-cdn --base-href $baseHref
    if ($LASTEXITCODE -ne 0) {
        throw "flutter build web failed with exit code $LASTEXITCODE"
    }

    $web = Join-Path $projectRoot 'build\web'

    # GitHub Pages must not run Jekyll over the output.
    New-Item -ItemType File -Path (Join-Path $web '.nojekyll') -Force | Out-Null

    # Flutter web uses hash routing; 404.html is just a safety net.
    Copy-Item (Join-Path $web 'index.html') (Join-Path $web '404.html') -Force

    Write-Host ''
    Write-Host 'Build ready. Test it locally with:' -ForegroundColor Green
    Write-Host '  node tool/serve_web.js' -ForegroundColor Green
}
finally {
    Pop-Location
}