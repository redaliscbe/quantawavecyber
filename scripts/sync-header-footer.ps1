# Sync header and footer from index.html to all other .html files
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\sync-header-footer.ps1

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $scriptDir

Write-Host "Reading canonical index.html..."
$indexPath = Join-Path $scriptDir '..\index.html'
if (-not (Test-Path $indexPath)) { Write-Error "index.html not found at $indexPath"; exit 1 }
$index = Get-Content -Raw -Path $indexPath

$headerMatch = [regex]::Match($index, '<a class="skip-to-content".*?(?=<main\b)', [System.Text.RegularExpressions.RegexOptions]::Singleline)
if (-not $headerMatch.Success) { Write-Error "Header anchor to <main> not found in index.html"; exit 1 }
$header = $headerMatch.Value.Trim() + "`n"

$footerMatch = [regex]::Match($index, '<footer\b.*</html>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
if (-not $footerMatch.Success) { Write-Error "Footer to </html> not found in index.html"; exit 1 }
$footer = $footerMatch.Value.Trim()

Write-Host "Header and footer extracted. Applying to other HTML files..."
Get-ChildItem -Path (Join-Path $scriptDir '..') -Filter *.html -File | ForEach-Object {
    if ($_.Name -ieq 'index.html') { return }
    Write-Host "Processing: $($_.Name)"
    $path = $_.FullName
    $content = Get-Content -Raw -Path $path
    $orig = $content

    # Replace header: everything before first <main with canonical header
    $mainIdx = $content.IndexOf('<main')
    if ($mainIdx -ge 0) {
        $rest = $content.Substring($mainIdx)
        $content = $header + $rest
    } else {
        # try to insert after <body>
        $bodyIdx = $content.IndexOf('<body')
        if ($bodyIdx -ge 0) {
            $bodyEnd = $content.IndexOf('>', $bodyIdx)
            if ($bodyEnd -ge 0) {
                $afterBody = $content.Substring($bodyEnd + 1)
                $content = $content.Substring(0, $bodyEnd + 1) + "`n" + $header + "`n" + $afterBody
            } else {
                $content = $header + "`n" + $content
            }
        } else {
            $content = $header + "`n" + $content
        }
    }

    # Replace footer: find first <footer and replace until end with canonical footer
    $footerIdx = $content.IndexOf('<footer')
    if ($footerIdx -ge 0) {
        $content = $content.Substring(0, $footerIdx) + "`n" + $footer
    } else {
        # append before </body> if present
        $bodyClose = $content.IndexOf('</body>')
        if ($bodyClose -ge 0) {
            $content = $content.Substring(0, $bodyClose) + "`n" + $footer + "`n" + $content.Substring($bodyClose)
        } else {
            $content = $content + "`n" + $footer
        }
    }

    # Backup original
    Copy-Item -Path $path -Destination ($path + '.bak') -Force
    Set-Content -Path $path -Value $content -NoNewline
    Write-Host "Updated: $($_.Name)"
}

Write-Host "All done. Backups created with .bak extension for each modified file."