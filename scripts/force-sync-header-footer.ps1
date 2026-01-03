# Force-sync exact header (from <a class="skip-to-content" ... up to <main) and footer (from <footer... to </html>) from index.html into all other .html files.
# Backups (.bak) created for each modified file.
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\force-sync-header-footer.ps1

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $scriptDir
$root = Resolve-Path ".." | Select-Object -ExpandProperty Path
$indexPath = Join-Path $root 'index.html'
if (-not (Test-Path $indexPath)) { Write-Error "index.html not found"; exit 1 }
$index = Get-Content -Raw -Path $indexPath

# Extract header: from <a class="skip-to-content" up to (but not including) first <main
$headerRegex = [regex]::new('(?is)(<a\s+class="skip-to-content".*?)(?=<main\b)')
$headerMatch = $headerRegex.Match($index)
if (-not $headerMatch.Success) { Write-Error "Could not extract header from index.html"; exit 1 }
$header = $headerMatch.Groups[1].Value.Trim()

# Extract footer: from first <footer to </html>
$footerRegex = [regex]::new('(?is)(<footer\b.*</html>)')
$footerMatch = $footerRegex.Match($index)
if (-not $footerMatch.Success) { Write-Error "Could not extract footer from index.html"; exit 1 }
$footer = $footerMatch.Groups[1].Value.Trim()

Write-Host "Canonical header and footer extracted. Applying to files..."
Get-ChildItem -Path $root -Filter *.html -File | ForEach-Object {
    if ($_.Name -ieq 'index.html') { return }
    $path = $_.FullName
    Write-Host "Processing: $($_.Name)"
    $content = Get-Content -Raw -Path $path

    # Replace header: everything up to <main with canonical header
    $mainIdx = $content.IndexOf('<main')
    if ($mainIdx -ge 0) {
        $rest = $content.Substring($mainIdx)
        $newContent = $header + "`n" + $rest
    } else {
        # fallback: replace up to first <body>
        $bodyIdx = $content.IndexOf('<body')
        if ($bodyIdx -ge 0) {
            $bodyEnd = $content.IndexOf('>', $bodyIdx)
            if ($bodyEnd -ge 0) {
                $afterBody = $content.Substring($bodyEnd + 1)
                $newContent = $content.Substring(0, $bodyEnd + 1) + "`n" + $header + "`n" + $afterBody
            } else {
                $newContent = $header + "`n" + $content
            }
        } else {
            $newContent = $header + "`n" + $content
        }
    }

    # Replace footer: find first <footer and replace to end with canonical footer
    $footerIdx = $newContent.IndexOf('<footer')
    if ($footerIdx -ge 0) {
        $finalContent = $newContent.Substring(0, $footerIdx) + "`n" + $footer
    } else {
        $bodyClose = $newContent.IndexOf('</body>')
        if ($bodyClose -ge 0) {
            $finalContent = $newContent.Substring(0, $bodyClose) + "`n" + $footer + "`n" + $newContent.Substring($bodyClose)
        } else {
            $finalContent = $newContent + "`n" + $footer
        }
    }

    if ($finalContent -ne $content) {
        Copy-Item -Path $path -Destination ($path + '.bak') -Force
        Set-Content -Path $path -Value $finalContent -NoNewline
        Write-Host "Updated: $($_.Name)"
    } else {
        Write-Host "No changes needed: $($_.Name)"
    }
}

Write-Host "Header/footer sync complete. Backups created with .bak extension."