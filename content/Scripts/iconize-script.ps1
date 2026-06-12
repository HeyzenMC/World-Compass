# ============================================================
# PFADE ANPASSEN:
$vaultPath = "C:\Obsidian\Compass"   # <-- hier deinen Vault-Pfad eintragen
# ============================================================

$iconizeData = "$vaultPath\.obsidian\plugins\obsidian-icon-folder\data.json"

# Skript pausiert am Ende damit du die Ausgabe lesen kannst
trap {
    Write-Host "`nFEHLER: $_" -ForegroundColor Red
    Read-Host "`nEnter drücken zum Schließen"
    exit 1
}

# Prüfen ob data.json existiert
if (-not (Test-Path $iconizeData)) {
    Write-Host "FEHLER: data.json nicht gefunden unter: $iconizeData" -ForegroundColor Red
    Read-Host "Enter drücken zum Schließen"
    exit 1
}

Write-Host "Lese Iconize-Daten..." -ForegroundColor Cyan
$data = Get-Content $iconizeData -Raw | ConvertFrom-Json

$found = 0
$skipped = 0
$updated = 0

# Alle Einträge außer "settings" durchgehen
$data.PSObject.Properties | Where-Object { $_.Name -ne "settings" } | ForEach-Object {
    $key   = $_.Name
    $icon  = $_.Value

    # Nur Ordner-Einträge (kein .md am Ende)
    if ($key -like "*.md") {
        Write-Host "  [übersprungen - ist eine Datei] $key" -ForegroundColor DarkGray
        $skipped++
        return
    }

    # Ordnername = letzter Teil des Pfades
    $folderName = Split-Path $key -Leaf

    # Pfad zur Folder Note aufbauen (Forward-Slash → Backslash)
    $relPath = $key.Replace("/", "\")
    $notePath = "$vaultPath\$relPath\$folderName.md"

    Write-Host "`nOrdner: $key  →  Icon: $icon" -ForegroundColor Yellow
    Write-Host "  Suche Note: $notePath"

    if (-not (Test-Path $notePath)) {
        Write-Host "  [nicht gefunden]" -ForegroundColor Red
        $skipped++
        return
    }

    $found++
    $content = Get-Content $notePath -Raw -Encoding UTF8

    # Frontmatter vorhanden?
    if ($content -match "(?s)^---\r?\n(.*?)\r?\n---") {
        $frontmatter = $Matches[1]

        if ($frontmatter -match "(?m)^icon\s*:") {
            # Icon-Property ersetzen
            $newContent = $content -replace "(?m)^icon\s*:.*$", "icon: $icon"
            Write-Host "  [icon-Property aktualisiert]" -ForegroundColor Green
        } else {
            # Icon-Property ans Ende des Frontmatters einfügen
            $newContent = $content -replace "(?s)(^---\r?\n)(.*?)(\r?\n---)", "`$1`$2`nicon: $icon`$3"
            Write-Host "  [icon-Property hinzugefügt]" -ForegroundColor Green
        }
    } else {
        # Kein Frontmatter → neu anlegen
        $newContent = "---`nicon: $icon`n---`n" + $content
        Write-Host "  [neues Frontmatter angelegt]" -ForegroundColor Green
    }

    # Datei speichern (UTF-8 ohne BOM)
    [System.IO.File]::WriteAllText($notePath, $newContent, [System.Text.UTF8Encoding]::new($false))
    $updated++
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "Fertig! Aktualisiert: $updated  |  Gefunden: $found  |  Übersprungen: $skipped" -ForegroundColor Cyan
Write-Host "============================================================"
Read-Host "`nEnter drücken zum Schließen"