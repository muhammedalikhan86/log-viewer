# =============================================================================
# graph.ps1 - rebuild the knowledge graph(s) for this repository
#
# Standard script, copied in by init-adlc-repo / plugin-init-adlc-repo from
# ~/.claude/skills/init-adlc-repo/templates/graph.ps1. Do not edit the copy to add
# a component or a root: this script has no list of its own. It reads
# .claude/SKILLS.md every time it runs:
#
#   * Plugin repo - the `components:` table. Each row's `code` roots are one
#     component's graph; the output folder is the `graphify-out` binding with
#     {component} substituted (default graphify-out/<component>).
#   * Single-component repo - no `components:` table. The roots are the
#     `graphify-directories` binding (falling back to `source-code-directory`),
#     the output folder is `graphify-out` (default graphify-out). One graph.
#
# Usage (Windows PowerShell 5.1 or PowerShell 7, from anywhere):
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/graph.ps1
#       every component (plugin repo) or the one graph (single-component repo)
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/graph.ps1 -Component <name>
#       one component. This is the exact command plugin-orchestrator-development-pattern
#       runs in its Graphify step.
#   ... -Component <name> -Root <root>[,<root>]
#       only those of the component's roots, when its graph.json already exists
#       (graphify update merges, so the other roots' nodes stay). The stamp still
#       lists every root. Without a graph.json every root is built.
#   ... -DryRun
#       parse .claude/SKILLS.md and print what would be built; builds nothing,
#       writes nothing, does not need graphify on PATH.
#
# Exit codes: 0 = built (or skipped: no roots on disk yet, or -DryRun);
#             1 = unknown component, unknown -Root, graphify missing, no or
#                 unreadable .claude/SKILLS.md, a root that is the repo root,
#                 graphify failed, or graphify wrote no GRAPH_REPORT.md.
#
# Three things worth knowing:
#
#   1. GRAPHIFY_OUT is the lever. graphify reads it once at import time and
#      every writer honours it, so setting it per component gives one graph per
#      component. It MUST be absolute: a relative value resolves against the
#      path being scanned, not the working directory, and scatters stray
#      graphify-out/ folders through the code roots.
#
#   2. `graphify update` is deliberate, not `/graphify`. `update` re-extracts
#      code deterministically with no LLM and no API cost, which is what a build
#      step can honestly promise. The first root builds the graph; each later
#      root merges into it. Run the `/graphify` skill by hand when the richer
#      inferred edges and named communities are wanted.
#
#   3. Only GRAPH_REPORT.md is committed (see the knowledge-graph block in
#      .gitignore). It is stamped with the commit it was built at, so staleness
#      is checkable: if the stamp's SHA is not HEAD and `git diff --name-only
#      <sha>..HEAD` touches the component's roots, the report is stale. A stamp
#      ending "+ uncommitted working tree" was built from uncommitted changes in
#      those roots - the orchestrator builds just before it commits, and treats
#      such a stamp as fresh when the only later commit is the one it was built for.
#
# A component whose roots are not on disk yet is skipped with a note, not a
# failure: SKILLS.md can declare a component before its code is scaffolded.
#
# Keep this file ASCII-only: Windows PowerShell 5.1 reads a BOM-less script as
# the ANSI code page.
# =============================================================================

[CmdletBinding()]
param(
    # One component name, or empty for all of them. In a single-component repo
    # it only labels the stamp (default: the repo folder's name).
    [string] $Component = '',

    # Only these roots of -Component, when its graph.json already exists.
    [string[]] $Root = @(),

    # Parse and report; build nothing.
    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Fail([string] $message) {
    Write-Host $message -ForegroundColor Red
    exit 1
}

# Native git under $ErrorActionPreference = 'Stop' throws on any stderr line in
# Windows PowerShell 5.1, so run it with a local 'Continue'.
function Invoke-Git {
    $ErrorActionPreference = 'Continue'
    $out = & git @args 2>$null
    return @($out)
}

# "./apps/shell/" -> "apps/shell"; "." and "./" -> "."
function ConvertTo-RootPath([string] $path) {
    $p = $path.Trim().Trim('"').Trim("'").Trim() -replace '\\', '/'
    while ($p.StartsWith('./')) { $p = $p.Substring(2) }
    $p = $p.TrimEnd('/')
    if ($p -eq '' -or $p -eq '.') { return '.' }
    return $p
}

# Every list item on a line: `- "a" - "b"`, `- a`, `["a", "b"]`.
function Get-Items([string] $text) {
    $items = @()
    $t = $text.Trim()
    if ($t.StartsWith('[')) {
        foreach ($part in ($t.Trim('[', ']') -split ',')) {
            if ($part.Trim()) { $items += (ConvertTo-RootPath $part) }
        }
        return $items
    }
    foreach ($m in [regex]::Matches($t, '(?:^|\s)-\s+(?:"([^"]+)"|''([^'']+)''|([^\s"'']+))')) {
        $v = if ($m.Groups[1].Success) { $m.Groups[1].Value } elseif ($m.Groups[2].Success) { $m.Groups[2].Value } else { $m.Groups[3].Value }
        $items += (ConvertTo-RootPath $v)
    }
    return $items
}

# First `key: value` binding anywhere in the file; '' when absent.
function Get-Binding([string[]] $lines, [string] $key) {
    foreach ($line in $lines) {
        if ($line -match ('^\s*' + [regex]::Escape($key) + ':\s*(.*?)\s*$')) {
            return $Matches[1].Trim().Trim('"').Trim("'")
        }
    }
    return ''
}

# A binding that may be a scalar or a block list on the lines below it.
function Get-ListBinding([string[]] $lines, [string] $key) {
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match ('^(\s*)' + [regex]::Escape($key) + ':\s*(.*?)\s*$')) {
            $indent = $Matches[1].Length
            $rest = $Matches[2]
            if ($rest -ne '') {
                if ($rest.StartsWith('[') -or $rest -match '^-\s') { return @(Get-Items $rest) }
                return @(ConvertTo-RootPath $rest)
            }
            $items = @()
            for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                if ($lines[$j] -match '^(\s*)-\s+') {
                    if ($Matches[1].Length -lt $indent) { break }
                    $items += @(Get-Items $lines[$j])
                }
                elseif ($lines[$j].Trim() -eq '') { continue }
                else { break }
            }
            return $items
        }
    }
    return @()
}

# The `components:` table. Accepts the inline form the init skill writes
#     shell: code: - "./apps/shell" - "./services/Shell.Api"
# and the block form
#     shell:
#       code:
#         - "./apps/shell"
# Ends at the first blank line or the first line that is neither.
function Get-ComponentTable([string[]] $lines) {
    $table = New-Object System.Collections.Specialized.OrderedDictionary
    $start = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*components:\s*$') { $start = $i; break }
    }
    if ($start -lt 0) { return $null }

    $compIndent = -1
    $current = $null
    $inCode = $false
    for ($i = $start + 1; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line.Trim() -eq '') { if ($table.Count) { break } else { continue } }
        if ($line -match '^(\s*)-\s+') {
            if ($current -and $inCode) { $table[$current] += @(Get-Items $line); continue }
            break
        }
        if ($line -notmatch '^(\s*)([A-Za-z0-9][\w.-]*):\s*(.*?)\s*$') { break }
        $indent = $Matches[1].Length
        $key = $Matches[2]
        $rest = $Matches[3]
        if ($compIndent -lt 0) { $compIndent = $indent }

        if ($indent -le $compIndent -and $key -ne 'code') {
            if ($indent -lt $compIndent) { break }
            $current = $key
            $inCode = $false
            if (-not $table.Contains($current)) { $table[$current] = @() }
            if ($rest -match '^code:\s*(.*)$') {
                $inCode = $true
                $table[$current] += @(Get-Items $Matches[1])
            }
        }
        elseif ($key -eq 'code' -and $current) {
            $inCode = $true
            $table[$current] += @(Get-Items $rest)
        }
        else {
            # Another key under a component (not `code`): ignore it and its list.
            $inCode = $false
        }
    }
    return $table
}

# --- Read the bindings --------------------------------------------------------

$skillsPath = Join-Path $RepoRoot '.claude/SKILLS.md'
if (-not (Test-Path $skillsPath)) {
    Fail "No .claude/SKILLS.md at $RepoRoot - this script reads its components and roots from there."
}
$lines = [System.IO.File]::ReadAllText($skillsPath, $Utf8NoBom) -split '\r?\n'

$Components = New-Object System.Collections.Specialized.OrderedDictionary
$outTemplate = Get-Binding $lines 'graphify-out'
$table = Get-ComponentTable $lines

if ($null -ne $table) {
    $mode = 'plugin'
    if ($table.Count -eq 0) { Fail '.claude/SKILLS.md has a components: table with no rows.' }
    foreach ($name in $table.Keys) {
        if (@($table[$name]).Count -eq 0) { Fail "Component '$name' in the components: table has no code roots." }
        $Components[$name] = @($table[$name] | Select-Object -Unique)
    }
    if (-not $outTemplate) { $outTemplate = './graphify-out/{component}' }
    if ($outTemplate -notmatch '\{component\}') {
        Fail "graphify-out ('$outTemplate') has no {component} placeholder; a plugin repo needs one graph per component."
    }
}
else {
    $mode = 'single'
    $roots = @(Get-ListBinding $lines 'graphify-directories')
    if ($roots.Count -eq 0) { $roots = @(Get-ListBinding $lines 'source-code-directory') }
    if ($roots.Count -eq 0) {
        Fail '.claude/SKILLS.md binds neither a components: table, graphify-directories nor source-code-directory.'
    }
    $label = if ($Component) { $Component } else { (Split-Path -Leaf $RepoRoot).ToLowerInvariant() -replace '\s+', '-' }
    $Components[$label] = @($roots | Select-Object -Unique)
    if (-not $outTemplate) { $outTemplate = './graphify-out' }
    $Component = $label
}

# Never the repo root: it would pull docs/ and everything else into a code graph.
foreach ($name in $Components.Keys) {
    if (@($Components[$name]) -contains '.') {
        Fail "[$name] a code root is the repo root ('./'). Bind graphify-directories (or the component's code roots) to the code folders instead."
    }
}

if ($Component -and -not $Components.Contains($Component)) {
    Write-Host "Unknown component '$Component'." -ForegroundColor Red
    Write-Host "Known (from .claude/SKILLS.md): $(@($Components.Keys) -join ', ')"
    exit 1
}

$RootFilter = @($Root | ForEach-Object { $_ -split ',' } | Where-Object { $_.Trim() } | ForEach-Object { ConvertTo-RootPath $_ })
if ($RootFilter.Count -and -not $Component) { Fail '-Root needs -Component (or a single-component repo).' }
if ($RootFilter.Count) {
    foreach ($r in $RootFilter) {
        if (@($Components[$Component]) -notcontains $r) {
            Fail "-Root '$r' is not a code root of '$Component' ($(@($Components[$Component]) -join ', '))."
        }
    }
}

$graphify = Get-Command graphify -ErrorAction SilentlyContinue
if (-not $graphify -and -not $DryRun) {
    Write-Host 'graphify is not on PATH.' -ForegroundColor Red
    Write-Host 'Install it with:  uv tool install --upgrade graphifyy'
    exit 1
}

# --- Build ---------------------------------------------------------------------

$targets = if ($Component) { @($Component) } else { @($Components.Keys) }
$built = 0
$skipped = @()
$failed = @()

if ($DryRun) {
    Write-Host "DRY RUN - mode: $mode; SKILLS.md: $skillsPath; graphify on PATH: $([bool]$graphify)" -ForegroundColor Cyan
}

foreach ($name in $targets) {
    $declared = @($Components[$name])
    $roots = @($declared | Where-Object { Test-Path $_ })
    $missing = @($declared | Where-Object { -not (Test-Path $_) })
    $out = (ConvertTo-RootPath ($outTemplate -replace '\{component\}', $name))
    $graphJson = Join-Path $out 'graph.json'

    # Which roots to run: all of them, unless -Root narrowed it and a graph
    # already exists to merge into.
    $run = $roots
    if ($RootFilter.Count) {
        if (Test-Path $graphJson) { $run = @($roots | Where-Object { $RootFilter -contains $_ }) }
        else { Write-Host "[$name] no $graphJson yet - building every root, not just -Root." -ForegroundColor DarkYellow }
    }

    if ($DryRun) {
        Write-Host ''
        Write-Host "[$name] -> $out/GRAPH_REPORT.md" -ForegroundColor Cyan
        Write-Host "        roots on disk:   $(if ($roots.Count) { $roots -join ', ' } else { '(none - would skip)' })"
        if ($missing.Count) { Write-Host "        roots not on disk: $($missing -join ', ')" -ForegroundColor DarkYellow }
        foreach ($r in $run) { Write-Host "        would run: graphify update $r   (GRAPHIFY_OUT=<abs>/$out)" }
        continue
    }

    if ($roots.Count -eq 0) {
        Write-Host "[$name] skipped - no source roots on disk yet ($($declared -join ', '))" -ForegroundColor DarkYellow
        $skipped += $name
        continue
    }
    if ($missing.Count) { Write-Host "[$name] not on disk yet, left out: $($missing -join ', ')" -ForegroundColor DarkYellow }

    New-Item -ItemType Directory -Force -Path $out | Out-Null
    Write-Host ''
    Write-Host "[$name] -> $out/GRAPH_REPORT.md" -ForegroundColor Cyan

    $ok = $true
    try {
        # Absolute, deliberately - see note 1 in the header.
        $env:GRAPHIFY_OUT = (Resolve-Path $out).Path
        foreach ($r in $run) {
            Write-Host "        $r"
            & graphify update $r
            if ($LASTEXITCODE -ne 0) {
                Write-Host "[$name] graphify update failed on $r (exit $LASTEXITCODE)" -ForegroundColor Red
                $ok = $false
                break
            }
        }
    }
    finally {
        Remove-Item Env:\GRAPHIFY_OUT -ErrorAction SilentlyContinue
    }
    if (-not $ok) { $failed += $name; continue }

    $report = Join-Path $out 'GRAPH_REPORT.md'
    if (-not (Test-Path $report)) {
        Write-Host "[$name] graphify exited 0 but wrote no GRAPH_REPORT.md" -ForegroundColor Red
        $failed += $name
        continue
    }

    # Stamp the report - see note 3 in the header.
    $sha = (Invoke-Git rev-parse HEAD | Select-Object -First 1)
    if (-not $sha) { $sha = 'no-commit-yet' } else { $sha = $sha.Trim() }
    # '--' quoted: bare, PowerShell eats it as its own end-of-parameters marker.
    $dirty = @(Invoke-Git status --porcelain '--' @roots)
    $builtAt = if ($dirty.Count) { "$sha + uncommitted working tree" } else { $sha }
    $stamp = @(
        "> Component: $name"
        "> Built at commit: $builtAt   Date: $(Get-Date -Format 'yyyy-MM-dd')"
        "> Code roots: $($roots -join ', ')"
        ''
    ) -join "`n"

    # Read and write UTF-8 without a BOM: 5.1 reads a BOM-less file as ANSI and
    # writes a BOM for "utf8", and a BOM ahead of the first `>` breaks the
    # blockquote. Replace an existing stamp rather than stacking a second one.
    $path = (Resolve-Path $report).Path
    $body = [System.IO.File]::ReadAllText($path, $Utf8NoBom) -replace ('^' + [char]0xFEFF), ''
    $body = [regex]::Replace($body, '(?m)\A(> (Component|Built at commit|Code roots):.*\r?\n)+\r?\n?', '')
    [System.IO.File]::WriteAllText($path, $stamp + $body, $Utf8NoBom)
    Write-Host "[$name] stamped at $($sha.Substring(0, [Math]::Min(8, $sha.Length)))" -ForegroundColor Green
    $built++
}

if ($DryRun) { Write-Host ''; Write-Host 'DRY RUN - nothing built or written.' -ForegroundColor Cyan; exit 0 }

Write-Host ''
Write-Host "Built $built graph(s)." -ForegroundColor Green
if ($skipped.Count) { Write-Host "Skipped (no source yet): $($skipped -join ', ')" -ForegroundColor DarkYellow }
if ($failed.Count) {
    Write-Host "Failed: $($failed -join ', ')" -ForegroundColor Red
    exit 1
}
Write-Host 'Only GRAPH_REPORT.md is committed; everything else under graphify-out is gitignored.'
exit 0
