# Force extract remaining inline <style> and non-JSON-LD <script> blocks into css/inline.css and js/main.js
# Writes a log to scripts/extract-log.txt
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\force-extract-inline.ps1

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $scriptDir
$root = Resolve-Path ".." | Select-Object -ExpandProperty Path
$log = Join-Path $scriptDir 'extract-log.txt'
Remove-Item -Path $log -ErrorAction SilentlyContinue

$cssTarget = Join-Path $root 'css\inline.css'
$jsTarget = Join-Path $root 'js\main.js'
if (-not (Test-Path $cssTarget)) { New-Item -Path $cssTarget -ItemType File -Force | Out-Null }
if (-not (Test-Path $jsTarget)) { New-Item -Path $jsTarget -ItemType File -Force | Out-Null }

Add-Content -Path $log -Value "Extraction run: $(Get-Date -Format o)"

Get-ChildItem -Path $root -Filter *.html -File | ForEach-Object {
    if ($_.Name -ieq 'index.html') { return }
    $path = $_.FullName
    $content = Get-Content -Raw -Path $path
    $fileChanged = $false
    $entry = "\n-- Processing: $($_.Name) --"
    Add-Content -Path $log -Value $entry

    # Extract style blocks (match with attributes too)
    $styleRegex = [regex]::new('(?is)<style[^>]*>(.*?)</style>')
    $styles = $styleRegex.Matches($content)
    if ($styles.Count -gt 0) {
        foreach ($m in $styles) {
            $css = $m.Groups[1].Value.Trim()
            if ($css.Length -gt 0) {
                Add-Content -Path $cssTarget -Value "/* from $($_.Name) */`n$css`n"
                Add-Content -Path $log -Value "  extracted <style> ($([math]::Min(200,$css.Length)) chars)"
                $fileChanged = $true
            }
        }
        $content = $styleRegex.Replace($content, '')
    } else { Add-Content -Path $log -Value "  no <style> found" }

    # Extract inline scripts excluding JSON-LD
    $scriptRegex = [regex]::new('(?is)<script(?![^>]*\bsrc=)(?![^>]*application/ld\+json)[^>]*>(.*?)</script>')
    $scripts = $scriptRegex.Matches($content)
    if ($scripts.Count -gt 0) {
        foreach ($m in $scripts) {
            $js = $m.Groups[1].Value.Trim()
            if ($js.Length -gt 0) {
                Add-Content -Path $jsTarget -Value "/* from $($_.Name) */`n$js`n"
                Add-Content -Path $log -Value "  extracted <script> ($([math]::Min(200,$js.Length)) chars)"
                $fileChanged = $true
            }
        }
        $content = $scriptRegex.Replace($content, '')
    } else { Add-Content -Path $log -Value "  no inline <script> found (non-JSON-LD)" }

    if ($fileChanged) {
        Copy-Item -Path $path -Destination ($path + '.bak') -Force
        Set-Content -Path $path -Value $content -NoNewline
        Add-Content -Path $log -Value "  file updated and backup created"
    } else {
        Add-Content -Path $log -Value "  no changes made"
    }
}
Add-Content -Path $log -Value "Extraction complete: $(Get-Date -Format o)"
Write-Host "Force extraction complete. See scripts/extract-log.txt for details."