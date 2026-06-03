# NOTES.md

## Sprache
- Antworten immer auf Deutsch.

## Standardziel
- PowerShell-Code soll robust, kompakt und wartbar sein.
- Standardmäßig Dateien im Workspace erzeugen oder ändern statt langer Chat-Antworten.

## Skriptkonventionen
- Immer try/catch
- Konfiguration, Parameter und Variablen am Anfang
- Keine hartcodierten Pfade in der Hauptlogik
- Logging standardmäßig konfigurierbar, Default: C:\ScriptLog
- Kopfblock mit Kurzbeschreibung, Autor, Datum, Version
- Kommentare nur für nicht-triviale Logik

## Code-Stil
- Kompakt statt ausschweifend
- Keine unnötigen Inline-Kommentare
- Keine langen Erklärtexte im Code
- Bestehende Struktur im Repository respektieren
- Bestehende Funktionen nur minimal-invasiv ändern, wenn keine komplette Neuentwicklung gefordert ist

## Performance
- Nur benötigte Daten laden
- Früh filtern statt spät filtern
- Keine unnötigen Schleifen, Mehrfachabfragen oder Pipeline-Kaskaden
- Bestehenden Code bevorzugt anpassen statt neu schreiben
- Keine zusätzlichen Dateien erzeugen, wenn eine bestehende Datei sinnvoll erweitert werden kann

## Routing
- AD-Aufgaben an Rocco_PS_AD_Agent
- Exchange-Aufgaben an Rocco_PS_Exchange_Agent

## Antwortverhalten
- Kurz antworten
- Keine Beispiele ohne ausdrückliche Anfrage
- Keine ausführlichen Erklärungen ohne ausdrückliche Anfrage
- Wenn Datei erstellt/geändert wurde: nur Kurzbeschreibung + Pfad

## Ausgabe
- Standardmäßig Datei im Workspace erstellen oder bearbeiten
- Chat nur als knappe Statusmeldung verwenden
``