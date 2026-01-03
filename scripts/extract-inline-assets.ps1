# Extract inline <style> blocks into css/inline.css and inline <script> (non-JSON-LD) into js/main.js
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\extract-inline-assets.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $root
$root = Resolve-Path ".." | Select-Object -ExpandProperty Path

$cssTarget = Join-Path $root 'css\inline.css'
$jsTarget = Join-Path $root 'js\main.js'

if (-not (Test-Path $cssTarget)) { New-Item -Path $cssTarget -ItemType File -Force | Out-Null }
if (-not (Test-Path $jsTarget)) { New-Item -Path $jsTarget -ItemType File -Force | Out-Null }

Get-ChildItem -Path $root -Filter *.html -File | ForEach-Object {
    if ($_.Name -ieq 'index.html') { return }
    Write-Host "Processing: $($_.Name)"
    $path = $_.FullName
    $content = Get-Content -Raw -Path $path

    $modified = $false

    # Extract <style> blocks
    $styleRegex = [regex]::new('(?is)<style[^>]*>(.*?)</style>')
    $styleMatches = $styleRegex.Matches($content)
    foreach ($m in $styleMatches) {
        $css = $m.Groups[1].Value.Trim()
        if ($css.Length -gt 0) {
            Add-Content -Path $cssTarget -Value "/* from $($_.Name) */`n$css`n"
            $modified = $true
        }
    }
    if ($styleMatches.Count -gt 0) {
        $content = $styleRegex.Replace($content, '')
    }

    # Extract inline <script> blocks that are NOT JSON-LD and do NOT have src attribute
    $scriptRegex = [regex]::new('(?is)<script(?![^>]*\bsrc=)(?![^>]*application/ld\+json)[^>]*>(.*?)</script>')
    $scriptMatches = $scriptRegex.Matches($content)
    foreach ($m in $scriptMatches) {
        $js = $m.Groups[1].Value.Trim()
        if ($js.Length -gt 0) {
            Add-Content -Path $jsTarget -Value "/* from $($_.Name) */`n$js`n"
            $modified = $true
        }
    }
    if ($scriptMatches.Count -gt 0) {
        $content = $scriptRegex.Replace($content, '')
    }

    if ($modified) {
        Copy-Item -Path $path -Destination ($path + '.bak') -Force
        Set-Content -Path $path -Value $content -NoNewline
        Write-Host "Updated (extracted assets): $($_.Name)"
    } else {
        Write-Host "No inline assets found in: $($_.Name)"
    }
}

Write-Host "Extraction complete. Appended CSS to $cssTarget and JS to $jsTarget. Backups created with .bak extension."