<#
.SYNOPSIS
    Stow-like symlinker: mirrors this repo into the TF2 tf/ directory.

.DESCRIPTION
    For each entry in the repo (recursively):
      - Target doesn't exist          -> symlink the whole file/folder (tree folding).
      - Target is a real directory    -> descend into it and link its children.
      - Target already links to us    -> skip.
      - Anything else                 -> skipped with a warning (existing file is left alone).
    Names matching regexes in .stow-local-ignore are skipped.

    Creating symlinks requires Developer Mode or an elevated shell
    (PowerShell 7+ is recommended for unprivileged symlinks in Developer Mode).

.EXAMPLE
    .\mksymlinks.ps1 -WhatIf
.EXAMPLE
    .\mksymlinks.ps1 -TfDir 'D:\SteamLibrary\steamapps\common\Team Fortress 2\tf'
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$TfDir = 'C:\Program Files (x86)\Steam\steamapps\common\Team Fortress 2\tf'
)

$ErrorActionPreference = 'Stop'
$SourceDir = $PSScriptRoot

if (-not (Test-Path -LiteralPath $TfDir -PathType Container)) {
    throw "Target directory not found: $TfDir"
}
$TfDir = (Resolve-Path -LiteralPath $TfDir).ProviderPath

$ignorePatterns = @('\.stow-local-ignore', 'mksymlinks\.ps1')
$ignoreFile = Join-Path $SourceDir '.stow-local-ignore'
if (Test-Path -LiteralPath $ignoreFile) {
    $ignorePatterns += Get-Content -LiteralPath $ignoreFile | Where-Object { $_.Trim() -and $_ -notmatch '^\s*#' }
}

function Test-Ignored([string]$Name) {
    foreach ($p in $ignorePatterns) {
        if ($Name -match "^(?:$($p.Trim()))$") { return $true }
    }
    return $false
}

$actions = [System.Collections.Generic.List[object]]::new()
$skipped = [System.Collections.Generic.List[string]]::new()

function Build-Plan([string]$Src, [string]$Dst) {
    foreach ($item in Get-ChildItem -LiteralPath $Src -Force) {
        if (Test-Ignored $item.Name) { continue }

        $link = Join-Path $Dst $item.Name
        $existing = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue

        if (-not $existing) {
            $actions.Add([pscustomobject]@{ Link = $link; Source = $item.FullName })
        }
        elseif ($existing.LinkType) {
            $current = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($Dst, @($existing.Target)[0]))
            if ($current.TrimEnd('\') -ne $item.FullName.TrimEnd('\')) {
                $skipped.Add("$link is a $($existing.LinkType) to '$current'")
            }
        }
        elseif ($item.PSIsContainer -and $existing.PSIsContainer) {
            Build-Plan $item.FullName $link
        }
        else {
            $skipped.Add("$link already exists")
        }
    }
}

Build-Plan $SourceDir $TfDir

foreach ($s in $skipped) {
    Write-Warning "SKIP: $s"
}

if (-not $actions.Count) {
    Write-Host 'Nothing to link.'
    exit 0
}

foreach ($a in $actions) {
    if ($PSCmdlet.ShouldProcess($a.Link, "Symlink -> $($a.Source)")) {
        New-Item -ItemType SymbolicLink -Path $a.Link -Target $a.Source | Out-Null
        Write-Host "LINK: $($a.Link) -> $($a.Source)"
    }
}
