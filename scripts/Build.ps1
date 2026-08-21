<#
.SYNOPSIS
    Baut EasyMakro: kopiert das Addon ins WoW-AddOns-Verzeichnis zum Testen
    und/oder packt es als releasefertige .zip fuer CurseForge.

.PARAMETER SkipInstall
    Ueberspringt das Kopieren in den WoW-AddOns-Ordner.

.PARAMETER SkipZip
    Ueberspringt das Erstellen der .zip-Datei.

.PARAMETER WowAddonsPath
    Pfad zum AddOns-Ordner der WoW-Installation. Default ist der
    _classic_era_-Ordner des Nutzers.
#>
param(
    [switch]$SkipInstall,
    [switch]$SkipZip,
    [string]$WowAddonsPath = "D:\Games\World of Warcraft\_classic_era_\Interface\AddOns"
)

$ErrorActionPreference = "Stop"

$RepoRoot   = Split-Path -Parent $PSScriptRoot
$AddonName  = "EasyMakro"
$AddonSrc   = Join-Path $RepoRoot $AddonName
$DistDir    = Join-Path $RepoRoot "dist"
$TocPath    = Join-Path $AddonSrc "$AddonName.toc"

if (-not (Test-Path $AddonSrc)) {
    throw "Addon-Quellordner nicht gefunden: $AddonSrc"
}

# Version aus der .toc lesen
$version = "0.0.0"
$tocLine = Select-String -Path $TocPath -Pattern '^\s*##\s*Version:\s*(.+)\s*$' | Select-Object -First 1
if ($tocLine) {
    $version = $tocLine.Matches[0].Groups[1].Value.Trim()
}
Write-Host "EasyMakro Version: $version" -ForegroundColor Cyan

# --- In den WoW AddOns-Ordner installieren (zum Testen) ---------------------
if (-not $SkipInstall) {
    if (-not (Test-Path $WowAddonsPath)) {
        Write-Warning "WoW AddOns-Ordner nicht gefunden: $WowAddonsPath (Installation uebersprungen)"
    } else {
        $target = Join-Path $WowAddonsPath $AddonName
        Write-Host "Installiere nach: $target"
        # robocopy /MIR spiegelt den Ordner (loescht auch entfernte Dateien)
        robocopy $AddonSrc $target /MIR /NFL /NDL /NJH /NJS | Out-Null
        if ($LASTEXITCODE -ge 8) {
            throw "robocopy ist mit Exit-Code $LASTEXITCODE fehlgeschlagen."
        }
        Write-Host "Installation abgeschlossen." -ForegroundColor Green
    }
}

# --- CurseForge-Zip bauen -----------------------------------------------
if (-not $SkipZip) {
    if (-not (Test-Path $DistDir)) {
        New-Item -ItemType Directory -Path $DistDir | Out-Null
    }

    $zipPath = Join-Path $DistDir "$AddonName-$version.zip"
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }

    $stagingDir = Join-Path $env:TEMP "EasyMakroBuild_$([guid]::NewGuid())"
    $stagingAddonDir = Join-Path $stagingDir $AddonName
    New-Item -ItemType Directory -Path $stagingAddonDir -Force | Out-Null

    Copy-Item -Path (Join-Path $AddonSrc '*') -Destination $stagingAddonDir -Recurse -Force

    Compress-Archive -Path $stagingAddonDir -DestinationPath $zipPath -CompressionLevel Optimal
    Remove-Item $stagingDir -Recurse -Force

    Write-Host "Zip erstellt: $zipPath" -ForegroundColor Green
    Write-Host "Diese Datei kannst du direkt auf CurseForge hochladen (enthaelt den Ordner '$AddonName' auf oberster Ebene)."
}
