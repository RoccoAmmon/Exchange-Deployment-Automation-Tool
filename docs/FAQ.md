# FAQ - Häufig Gestellte Fragen

**Antworten auf die wichtigsten Fragen zum Exchange-Deployment-Automation-Tool**

---

## 🎯 Allgemeine Fragen

### F: Für welche Exchange-Versionen eignet sich das Tool?
**A:** Das Tool unterstützt:
- ✅ Exchange Server 2016
- ✅ Exchange Server 2019  
- ✅ Exchange Server Standard Edition (SE)

Für Exchange 2013 oder älter siehe [Archiv-Versionen](#archiv).

---

### F: Kann ich das Tool in Produktionsumgebungen verwenden?
**A:** **Ja, absolut!** Das Tool ist production-ready mit:
- ✅ Umfassender Fehlerbehandlung
- ✅ Validierung nach jedem Schritt
- ✅ Detailliertem Logging
- ✅ Backup-Empfehlungen

**Empfehlungen für Production:**
1. Zuerst in Lab/Test testen
2. Vollständiges Backup vor Ausführung
3. Change-Window planen (30-120 Minuten je nach Hardware)
4. Support-Kontakt bereithalten

---

### F: Benötige ich Administratorrechte?
**A:** **Ja, unbedingt!** Das Tool benötigt:
- ✅ Lokale Administrator-Rechte auf dem Server
- ✅ Schema Admin-Rechte (für ForestPrep)
- ✅ Domain Admin-Rechte (für DomainPrep)
- ✅ Enterprise Admin-Rechte (empfohlen)

---

### F: Kann ich das Tool mit Parametern automatisieren?
**A:** Aktuell **teilweise**. Das Tool ist interaktiv mit Prompts.

**Geplant für v2.0:**
- Vollständig unbeaufsichtigte Ausführung
- Parameter für alle Eingaben
- ConfigFile-Support
- Silent-Mode

Aktuelle Lösung: Parameter-Datei ausfüllen vor der Ausführung.

---

## 🚀 Installation & Performance

### F: Wie lange dauert die gesamte Installation?
**A:** Abhängig von Hardware:

| Komponente | Dauer |
|---|---|
| Systemvalidierung | 2-5 Min |
| ForestPrep | 5-15 Min |
| DomainPrep | 3-10 Min |
| Voraussetzungen | 10-30 Min |
| Exchange Setup | 20-60 Min |
| Post-Installation | 5-10 Min |
| **GESAMT** | **45-130 Min** |

**Tipps für schnellere Installation:**
- Server mit SSD (nicht HDD)
- 16 GB RAM minimum
- 8+ vCPU
- Schnelle Netzverbindung
- Lokale ISO (nicht über Netzwerk)

---

### F: Kann ich die Installation unterbrechen?
**A:** **Nicht empfohlen!**

Wenn unterbrochen:
1. Alle Prozesse laufen weiter
2. Das Skript kann es nicht erkennen
3. Neuen Versuch starten wird Konflikte erzeugen

**Besser:** Den Prozess beenden und Logs prüfen.

---

### F: Was sind die Mindestsystem-Anforderungen?
**A:** 
| Ressource | Minimum | Empfohlen |
|---|---|---|
| **OS** | Windows Server 2016 | Windows Server 2019+ |
| **RAM** | 8 GB | 16+ GB |
| **CPU** | 4 vCPU | 8+ vCPU |
| **HDD** | 200 GB | 300+ GB SSD |
| **PowerShell** | 5.1 | 5.1+ |

---

## 🔧 Konfiguration

### F: Kann ich Exchange auf eine andere Partition installieren?
**A:** **Ja!** Das Tool unterstützt flexible Pfade.

Vor Skript-Start konfigurieren:

```powershell
# Im Skript (oder als Parameter in v2.0)
$exchangePath = "E:\Exchange"  # Statt C:\Program Files
$databasePath = "D:\ExchangeDB"
$logPath = "F:\ExchangeLogs"
```

**Empfehlung:** Separate Partition für Datenbanken/Logs (Performance!)

---

### F: Kann ich die Datenbank-Namen ändern?
**A:** **Ja, manuell nach Installation**

```powershell
# Nach Installation:
# Datenbank umbenennen
Rename-MailboxDatabase -Identity "Mailbox Database" -NewName "DB01-Production"

# Oder vor Installation (konfigurieren im Skript)
# $databaseName = "DB01"
```

---

### F: Wie konfiguriere ich Zertifikate?
**A:** Das Tool installiert zunächst ein selbstsigniertes Zertifikat.

**Nach Installation:**

```powershell
# Neues Zertifikat anfordern (CSR)
$cert = New-ExchangeCertificate -FriendlyName "Exchange" `
  -SubjectName "cn=mail.yourdomain.com" `
  -DomainName mail.yourdomain.com, autodiscover.yourdomain.com

# Bei kaufem Zertifikat: Importieren
Import-ExchangeCertificate -FileData ([Byte[]]$(Get-Content -Path "C:\certs\server.cer" -Encoding Byte -ReadCount 0))

# Zertifikat aktivieren
Enable-ExchangeCertificate -Thumbprint <Thumbprint> -Services IIS, SMTP
```

---

## 🌍 Active Directory

### F: Muss ich ForestPrep/DomainPrep manuell machen?
**A:** **Nein!** Das Tool kann es automatisch machen.

**Optionen:**
- ✅ Automatisch (das Tool macht es)
- ⚠️ Manuell vorab (falls du es lieber machst)
- ⚠️ Von anderen Servern (Enterprise Admin-Server)

Das Tool erkennt, ob es bereits gemacht wurde.

---

### F: Kann ich mehrere Domains vorbereiten?
**A:** **Ja!** Das Tool führt DomainPrep für alle Domains durch.

```powershell
# Das Skript fragt nach:
# "DomainPrep für zusätzliche Domains durchführen? [J/N]"
# Dann können alle Domains konfiguriert werden
```

---

### F: Funktioniert das Tool mit mehreren Forests?
**A:** **Teilweise.** Aktuell optimiert für einzelnen Forest.

**Für mehrere Forests:**
- ForestPrep auf jedem Forest separat ausführen
- DomainPrep für Domains in jedem Forest

---

## 🐛 Fehlerbehandlung

### F: Was wenn Setup fehlschlägt?
**A:** 

1. **Logs prüfen:**
   ```powershell
   Get-ChildItem "C:\ScriptLog\Exchange-Deployment-*.log" -Tail 50
   ```

2. **Siehe [Troubleshooting](Troubleshooting) Guide**

3. **GitHub Issue erstellen:**
   - Mit Logs und Fehlernachricht
   - Systeminfo
   - Schritt, bei dem es fehlschlägt

---

### F: Kann ich das Setup "neu starten"?
**A:** **Mit Vorsicht!**

```powershell
# Option 1: Nur Exchange Setup wiederholen
# (wenn nur Exchange-Installation fehlschlägt)
cd "D:\ExchangeMedia" (oder gemountete ISO)
.\Setup.exe /Mode:Install /IAcceptExchangeServerLicenseTerms /Organization:"YourOrg"

# Option 2: Komplettes Skript neu starten
# (meist keine Problem, da es Existenz prüft)
.\Exchange-Deployment-Automation-Tool.ps1
```

---

### F: Sind die Logs persistent?
**A:** **Ja!** Alle Logs bleiben unter `C:\ScriptLog\`

```powershell
# Logs archivieren
Compress-Archive -Path "C:\ScriptLog\*" -DestinationPath "C:\Logs_Backup_$(Get-Date -Format 'yyyyMMdd').zip"
```

---

## 📦 Updates & Versioning

### F: Wie update ich auf neue Versionen?
**A:**

```powershell
# Git Pull zum Updaten
cd Exchange-Deployment-Automation-Tool
git pull origin main

# Oder: Neu klonen
git clone https://github.com/RoccoAmmon/Exchange-Deployment-Automation-Tool.git --branch main
```

---

### F: Ist das Tool versioniert?
**A:** **Ja!** Siehe [CHANGELOG.md](../CHANGELOG.md)

Aktuelle Version: **1.0** (Juni 2026)

---

## 🔐 Sicherheit

### F: Sind meine Passwörter sicher?
**A:** **Ja!**
- ❌ Keine hartcodierten Passwörter im Code
- ✅ Alle Eingaben werden verschlüsselt
- ✅ Logs enthalten keine Passwörter
- ✅ Nur lokale Ausführung mit Admin-Rechten

---

### F: Welche Berechtigungen benötigt das Tool?
**A:**

**Lokal:**
- Administrator-Rechte
- Dateisystem-Zugriff

**Active Directory:**
- Schema Admins (ForestPrep)
- Domain Admins (DomainPrep)
- Enterprise Admins (empfohlen)

---

## 📚 Dokumentation

### F: Wo finde ich weitere Hilfe?
**A:**

| Frage | Ressource |
|---|---|
| Grundlagen | [Quick Start Guide](Quick-Start-Guide) |
| Detailliert | [Detaillierte Installation](Detaillierte-Installation) |
| Fehler | [Troubleshooting](Troubleshooting) |
| Best Practices | [Best Practices](Best-Practices) |
| Code-Fragen | [Issues](https://github.com/RoccoAmmon/Exchange-Deployment-Automation-Tool/issues) |

---

### F: Kann ich zur Dokumentation beitragen?
**A:** **Ja, gerne!**

Pull Requests sind willkommen für:
- ✅ Dokumentations-Verbesserungen
- ✅ Typo-Fixes
- ✅ Neue FAQ-Einträge
- ✅ Beispiele & Tipps

---

## 💡 Best Practices

### F: Wie prepare ich die beste Umgebung?
**A:** Siehe [Best Practices](Best-Practices) Guide

Schnell-Tipps:
1. Lab/Test vor Production
2. Vollständiges Backup
3. Change-Window planen
4. Supportperson bereithalten
5. Logs archivieren

---

### F: Was nach der Installation?
**A:**

```powershell
# 1. Services validieren
Get-Service MS* | Select-Object Name, Status

# 2. Datenbanken prüfen
Get-MailboxDatabase | Select-Object Name, Mounted

# 3. ECP/OWA testen
Start-Process "https://localhost/ecp"

# 4. Erste Mailbox erstellen
New-Mailbox -Name "Test.User" -DisplayName "Test User" -Database "Mailbox Database"

# 5. Logs archivieren
Compress-Archive -Path "C:\ScriptLog\*" -DestinationPath "C:\Logs_$(Get-Date -Format 'yyyyMMdd').zip"
```

---

## ❓ Weitere Fragen?

- 💬 [GitHub Discussions](https://github.com/RoccoAmmon/Exchange-Deployment-Automation-Tool/discussions)
- 🐛 [GitHub Issues](https://github.com/RoccoAmmon/Exchange-Deployment-Automation-Tool/issues)
- 📚 [Wiki](https://github.com/RoccoAmmon/Exchange-Deployment-Automation-Tool/wiki)

---

**Version**: 1.0 | **Aktualisiert**: Juni 2026
