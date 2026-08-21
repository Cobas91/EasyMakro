# EasyMakro

Ein WoW Classic Era Addon (getestet auf Client-Version 1.15.9), das das
Erstellen von Zauber-Makros per Mausklick statt per Handarbeit ermöglicht.

Kein Nachschlagen von `/cast`-Syntax, Mouseover-Bedingungen oder
`/petattack`/`/startattack` mehr: EasyMakro zeigt dir alle aktuell
erlernten Zauber (inklusive Begleiter-Zauber) sowie nützliche Befehle in
einer Liste. Per Checkbox wählst du aus, wie das Makro funktionieren soll,
und EasyMakro erstellt daraus ein **echtes WoW-Makro** (inklusive Icon und
Tooltip via `#showtooltip`), das du direkt aus dem Addon-Fenster in deine
Aktionsleiste ziehen kannst.

Die Oberfläche folgt automatisch der Sprache deines WoW-Clients
(`GetLocale()`); aktuell vollständig übersetzt sind Deutsch (`deDE`) und
Englisch (Standard-Fallback für alle anderen Clients).

## Beispiel

Schlangenbiss (Hunter) soll auf das aktuelle Ziel gewirkt werden, aber auf
das Ziel unter dem Mauszeiger ausweichen, sobald man über ein anderes Ziel
mouseovert:

1. `/em` oder `/easymakro` öffnet die Oberfläche.
2. "Schlangenbiss" in der Liste anklicken.
3. Häkchen bei **Mouseover-Ziel verwenden (Gegner)** setzen.
4. Auf **Makro erstellen** klicken.

Erzeugt wird:

```
#showtooltip Schlangenbiss
/cast [@mouseover,harm,nodead][] Schlangenbiss
```

## Funktionen

- Liste aller aktuell erlernten (aktiven) Zauber des Charakters und seines
  Begleiters.
- Zusätzliche Befehle: Auto-Attack, Pet-Attack, Pet folgen, Zauber
  abbrechen, Ziel folgen.
- Checkboxen für:
  - Mouseover-Ziel (Gegner)
  - Mouseover-Ziel (Freund/Heilung)
  - Fallback auf sich selbst
  - Auto-Attack (`/startattack`) davor einfügen
  - Pet zum Angriff schicken (`/petattack`) davor einfügen
  - Laufenden Zauber vorher abbrechen (`/stopcasting`)
  - Makro nur für diesen Charakter statt allgemein speichern
- Live-Vorschau des generierten Makrotexts.
- Übersicht aller mit EasyMakro erstellten Makros: anklicken lädt sie
  zurück in den Editor, per Drag landen sie direkt auf einer Aktionsleiste.

## Installation (Entwicklung/Test)

```powershell
scripts\Build.ps1
```

Kopiert den Ordner `EasyMakro` in
`D:\Games\World of Warcraft\_classic_era_\Interface\AddOns` und baut
zusätzlich ein releasefertiges Zip in `dist\`. Mit `-SkipZip` bzw.
`-SkipInstall` lässt sich jeweils ein Schritt überspringen.

## Release-Paket für CurseForge bauen

```powershell
scripts\Build.ps1 -SkipInstall
```

Erzeugt `dist\EasyMakro-<version>.zip` mit dem Ordner `EasyMakro` auf
oberster Ebene, genau wie von CurseForge erwartet.

Bei jedem auf GitHub veröffentlichten Release baut der Workflow
[`.github/workflows/release-zip.yml`](.github/workflows/release-zip.yml)
automatisch dieselbe Zip, hängt sie als Release-Asset an **und lädt sie
direkt ins bestehende CurseForge-Projekt hoch** (via
[`itsmeow/curseforge-upload`](https://github.com/itsmeow/curseforge-upload)).
Für einen neuen Release reicht also `gh release create vX.Y.Z --title ...
--notes ...` (Version vorher in `EasyMakro/EasyMakro.toc` hochzählen) -
Zip, GitHub-Asset und CurseForge-Upload passieren danach von selbst.

Voraussetzung: Das Repo-Secret `CURSEFORGE_TOKEN` muss gesetzt sein
(API-Token von [curseforge.com/account/api-tokens](https://www.curseforge.com/account/api-tokens)):

```bash
gh secret set CURSEFORGE_TOKEN
```

## Slash-Befehle

- `/easymakro`
- `/em`

## Lizenz

MIT, siehe [LICENSE](LICENSE).
