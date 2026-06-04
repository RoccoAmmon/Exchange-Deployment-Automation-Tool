# Quick Start Guide

**Schneller Einstieg in das Exchange-Deployment-Automation-Tool**

---

## ⚡ 5-Minuten-Einstieg

### Schritt 1: Repository vorbereiten
```powershell
# Repository klonen
git clone https://github.com/RoccoAmmon/Exchange-Deployment-Automation-Tool.git
cd Exchange-Deployment-Automation-Tool

# Aktuellen Status überprüfen
git status
```

### Schritt 2: PowerShell-Einstellungen
```powershell
# Execution Policy für aktuellen Prozess setzen (keine Admin-UAC nötig)
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
```

### Schritt 3: Skript ausführen
```powershell
# WICHTIG: Rechtsklick auf Exchange-Deployment-Automation-Tool.ps1
# → "Mit PowerShell ausführen" (Admin-Rechte!)
```

**Oder direkt in PowerShell (als Administrator):**
```powershell
.\Exchange-Deployment-Automation-Tool.ps1
```

### Schritt 4: Dem Assistenten folgen
Das Skript führt Sie interaktiv durch:
1. ✅ Systemvalidierung
2. ✅ AD-Vorbereitung (optional)
3. ✅ Exchange-Parameter eingeben
4. ✅ Automatische Installation
5. ✅ Konfiguration abschließen

---

## 🎯 Häufigste Szenarios

### Szenario 1: Neue Exchange-Installation in Lab

```powershell
# 1. Repository klonen
git clone https://github.com/RoccoAmmon/Exchange-Deployment-Automation-Tool.git

# 2. Skript starten (als Administrator)
cd Exchange-Deployment-Automation-Tool
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\Exchange-Deployment-Automation-Tool.ps1

# 3. Folgende Eingaben machen:
# - Exchange Version: 2019
# - AD Vorbereitung: Ja (für neue Domain)
# - Server-Name: EXCH01
# - Organisation: TestLab

# 4. Automatischer Prozess startet - abwarten!
```

### Szenario 2: Nur AD-Vorbereitung

Wenn Sie nur AD-Vorbereitung durchführen möchten (ForestPrep/DomainPrep):

```powershell
# Skript starten und bei der Frage antworten:
# "AD-Vorbereitung durchführen? [J/N]" → "J"
```

### Szenario 3: Exchange in bestehender Umgebung

```powershell
# Skript starten und antworten:
# "AD-Vorbereitung durchführen? [J/N]" → "N"
# → Nur Exchange wird installiert
```

---

## 📊 Systemvoraussetzungen - Quick Check

| Anforderung | Minimum | Empfohlen |
|---|---|---|
| **OS** | Windows Server 2016 | Windows Server 2019+ |
| **RAM** | 8 GB | 16 GB |
| **CPU** | 4 vCPU | 8 vCPU |
| **HDD** | 200 GB | 300+ GB |
| **PowerShell** | 5.1 | 5.1+ |
| **Admin** | ✅ Erforderlich | ✅ Erforderlich |

**Schnell prüfen:**
```powershell
# RAM prüfen
(Get-WmiObject Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1GB

# OS-Version
[System.Environment]::OSVersion.VersionString

# PowerShell-Version
$PSVersionTable.PSVersion

# Freier Speicherplatz (C:)
(Get-Volume C).SizeRemaining / 1GB
```

---

## ⚠️ Häufige Probleme beim Start

### Problem: "Administrator-Rechte erforderlich"

✅ **Lösung:**
```powershell
# Methode 1: Rechtsklick → Mit PowerShell ausführen
# Methode 2: PowerShell als Admin starten
Start-Process -FilePath "powershell.exe" -Verb RunAs
```

### Problem: "ExecutionPolicy blocked"

✅ **Lösung:**
```powershell
# Nur für diesen Prozess (keine Änderung am System)
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\Exchange-Deployment-Automation-Tool.ps1
```

### Problem: ".NET Framework zu alt"

✅ **Lösung:**
Das Skript installiert .NET Framework 4.7.2+ automatisch. Keine manuelle Aktion nötig.

### Problem: "Fehler bei AD-Vorbereitung"

✅ **Lösung:**
1. Sicherstellen, dass Sie Domain Admin sind
2. DC-Verbindung testen: `Get-ADDomain`
3. Forest Functional Level prüfen
4. Siehe [Troubleshooting-Guide](Troubleshooting)

---

## 📝 Logs & Debugging

Das Skript erstellt automatisch Logs:

```powershell
# Standard Log-Pfad
C:\ScriptLog\

# Aktuelle Logs anzeigen
Get-ChildItem C:\ScriptLog | Sort-Object LastWriteTime -Descending

# Log lesen
Get-Content "C:\ScriptLog\Exchange-Deployment-*.log" -Tail 50
```

**Logs sind hilfreich für:**
- 🔍 Fehleranalyse
- 📊 Installationsstatus
- 🐛 Debugging und Support

---

## ✅ Nach der Installation

### Schritt 1: Exchange validieren
```powershell
# Exchange Test ausführen
Test-ExchangeHealth

# Services prüfen
Get-Service MSExchangeIS, MSExchangeTransport
```

### Schritt 2: Erste Konfiguration
```powershell
# Exchange Admin Center öffnen
Start-Process "https://localhost/ecp"

# Oder: Exchange Management Shell öffnen
Start-Process "$EXINSTALL\Bin\RemoteExchange.ps1"
```

### Schritt 3: Dokumentation
Vollständige Konfiguration: Siehe [Detaillierte Installation](Detaillierte-Installation)

---

## 🔗 Nächste Schritte

Nach erfolgreicher Installation:

1. **[Konfigurationsoptionen](Konfigurationsoptionen)** - Fortgeschrittene Einstellungen
2. **[Best Practices](Best-Practices)** - Empfehlungen für Production
3. **[FAQ](FAQ)** - Häufig gestellte Fragen
4. **[Troubleshooting](Troubleshooting)** - Lösungen für Probleme

---

## 📞 Support

- 🐛 **Bugs**: [Issues](https://github.com/RoccoAmmon/Exchange-Deployment-Automation-Tool/issues)
- 💬 **Fragen**: [Discussions](https://github.com/RoccoAmmon/Exchange-Deployment-Automation-Tool/discussions)
- 📚 **Doku**: [Wiki](https://github.com/RoccoAmmon/Exchange-Deployment-Automation-Tool/wiki)

---

**Status**: ✅ Production Ready | **Version**: 1.0 | **Aktualisiert**: Juni 2026
