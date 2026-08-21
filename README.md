# EasyMakro

Ein WoW Classic Era Addon (getestet auf Client-Version 1.15.9), das das
Erstellen von Zauber-Makros per Mausklick statt per Handarbeit ermoeglicht.

Kein Nachschlagen von `/cast`-Syntax, Mouseover-Bedingungen oder
`/petattack`/`/startattack` mehr: EasyMakro zeigt dir alle aktuell
erlernten Zauber (inklusive Begleiter-Zauber) sowie nuetzliche Befehle in
einer Liste. Per Checkbox waehlst du aus, wie das Makro funktionieren soll,
und EasyMakro erstellt daraus ein **echtes WoW-Makro** (inklusive Icon und
Tooltip via `#showtooltip`), das du wie gewohnt aus dem Makro-Fenster in
deine Aktionsleiste ziehen kannst.

## Beispiel

Schlangenbiss (Hunter) soll auf das aktuelle Ziel gewirkt werden, aber auf
das Ziel unter dem Mauszeiger ausweichen, sobald man ueber ein anderes Ziel
mouseovert:

1. `/em` oder `/easymakro` oeffnet die Oberflaeche.
2. "Schlangenbiss" in der Liste anklicken.
3. Haekchen bei **Mouseover-Ziel verwenden (Gegner)** setzen.
4. Auf **Makro erstellen** klicken.

Erzeugt wird:

```
#showtooltip Schlangenbiss
/cast [@mouseover,harm,nodead][] Schlangenbiss
```

## Funktionen

- Liste aller aktuell erlernten (aktiven) Zauber des Charakters und seines
  Begleiters.
- Zusaetzliche Befehle: Auto-Attack, Pet-Attack, Pet folgen, Zauber
  abbrechen, Ziel folgen.
- Checkboxen fuer:
  - Mouseover-Ziel (Gegner)
  - Mouseover-Ziel (Freund/Heilung)
  - Fallback auf sich selbst
  - Auto-Attack (`/startattack`) davor einfuegen
  - Pet zum Angriff schicken (`/petattack`) davor einfuegen
  - Laufenden Zauber vorher abbrechen (`/stopcasting`)
  - Makro nur fuer diesen Charakter statt allgemein speichern
- Live-Vorschau des generierten Makrotexts.
- Uebersicht aller mit EasyMakro erstellten Makros inklusive Bearbeiten und
  Loeschen.

## Installation (Entwicklung/Test)

```powershell
scripts\Build.ps1
```

Kopiert den Ordner `EasyMakro` in
`D:\Games\World of Warcraft\_classic_era_\Interface\AddOns` und baut
zusaetzlich ein releasefertiges Zip in `dist\`. Mit `-SkipZip` bzw.
`-SkipInstall` laesst sich jeweils ein Schritt ueberspringen.

## Release-Paket fuer CurseForge bauen

```powershell
scripts\Build.ps1 -SkipInstall
```

Erzeugt `dist\EasyMakro-<version>.zip` mit dem Ordner `EasyMakro` auf
oberster Ebene, genau wie von CurseForge erwartet.

## Slash-Befehle

- `/easymakro`
- `/em`

## Lizenz

MIT, siehe [LICENSE](LICENSE).
