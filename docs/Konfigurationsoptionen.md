# Konfigurationsoptionen

**Detaillierte Übersicht aller Konfigurationsparameter**

---

## 📋 Inhaltsverzeichnis

1. [Exchange-Installation](#exchange-installation)
2. [Pfade & Storage](#pfade--storage)
3. [Datenbanken](#datenbanken)
4. [Network & Zertifikate](#network--zertifikate)
5. [AD-Vorbereitung](#ad-vorbereitung)
6. [Logging & Debugging](#logging--debugging)

---

## 📦 Exchange-Installation

### Exchange-Version auswählen

```powershell
# Unterstützte Versionen
$ExchangeVersion = "2019"    # 2016, 2019, SE (Standard Edition)

# Auswirkungen auf Installation:
# - 2016: Ältere Features, EOL 2020
# - 2019: Aktuell, unterstützt bis 2024
# - SE (2019): Kostenlos für bis zu 50 User
```

### Installationspfad

```powershell
# Standard (C-Laufwerk)
$ExchangePath = "C:\Program Files\Microsoft\Exchange Server\V15"

# Benutzerdefinierter Pfad
$ExchangePath = "D:\Exchange"  # Separate Partition für bessere Performance

# Empfehlung: Separate SSD für optimale Performance
```

### Organization Name

```powershell
# Erforderlich für Exchange-Setup
$OrgName = "Contoso"

# Wichtig: 
# - Kann nach Installation nicht geändert werden!
# - Standard: Domänenname oder Unternehmensname
# - Max. 64 Zeichen
# - Keine Sonderzeichen außer Bindestrich & Unterstrich

# Beispiele
$OrgName = "Acme-Corporation"
$OrgName = "SVA_System"
$OrgName = "Contoso"
```

---

## 📁 Pfade & Storage

### Installationspfade

```powershell
# Standard (automatisch gesetzt)
$ExchangePath = "C:\Program Files\Microsoft\Exchange Server\V15"

# Bin-Verzeichnis (Programme)
$BinPath = "$ExchangePath\bin"

# Scripts-Verzeichnis
$ScriptsPath = "$ExchangePath\Scripts"

# Logging-Verzeichnis (Installation)
$LogPath = "$ExchangePath\Logging"
```

### Benutzerdefinierte Pfade (für bessere Performance)

```powershell
# ✅ Empfohlene Struktur (Multi-Drive)

# Laufwerk C: OS & Binaries
$ExchangePath = "C:\Program Files\Microsoft\Exchange Server\V15"

# Laufwerk D: Binaries (optional, wenn schneller)
# (Wird während Installation festgelegt)

# Laufwerk E: Mailbox Database (SCHNELLE SSD!)
$DatabasePath = "E:\ExchangeDB"
$DBName = "DB01"  # oder "Mailbox Database"

# Laufwerk F: Transaction Logs (SEHR WICHTIG: Schnell!)
$LogPath = "F:\ExchangeLogs"

# Laufwerk G: Backups
$BackupPath = "G:\ExchangeBackups"
```

### Pfad-Richtlinien

```powershell
# ✅ Do's:
# - Separate Laufwerke für DB und Logs
# - SSD für Datenbank und Logs
# - RAID 1 für Logs (Redundanz/Speed)
# - Ausreichend Speicherplatz (300+ GB insgesamt)

# ❌ Don'ts:
# - DB und Logs auf gleichem Laufwerk
# - Externe USB-Laufwerke
# - Netzwerk-Freigaben für DB/Logs
# - Zu kleine Partitionen (<100 GB)
```

---

## 🗄️ Datenbanken

### Mailbox Database

```powershell
# Standardmäßig erstellte Datenbank
$DatabaseName = "Mailbox Database"

# Benutzerdefinierte Namen
$DatabaseName = "DB01-Production"
$DatabaseName = "DB01-Users"
$DatabaseName = "DB02-Executives"

# Pfad für Datenbank
$DBDataPath = "E:\ExchangeDB\$DatabaseName"
$DBEDBPath = "$DBDataPath\$DatabaseName.edb"

# Transaction Log Pfad
$DBLogPath = "F:\ExchangeLogs\$DatabaseName"
```

### Datenbank-Größe planen

```powershell
# Pro Mailbox (durchschnittlich)
# - 1 User mit 2 GB Mailbox = 2 GB auf Disk
# - Mit Transaction Logs: + 50 %

# Beispiel-Kalkulation für 100 Benutzer
$userCount = 100
$mailboxSize = 5  # GB pro Benutzer
$txLogFactor = 1.5
$totalSize = $userCount * $mailboxSize * $txLogFactor

Write-Host "Geschätzter Bedarf: $totalSize GB"
# Für Wachstum + 50% hinzufügen!
$recommendedSize = $totalSize * 1.5
Write-Host "Empfohlen: $recommendedSize GB"
```

### Datenbank-Limits

```powershell
# Standard-Limits
$issueWarningQuota = 2GB        # Warnung ab 2 GB
$prohibitSendQuota = 2.3GB      # Kein Send ab 2.3 GB
$prohibitSendReceiveQuota = 2.5GB  # Kein Receive ab 2.5 GB

# Pro Benutzer konfigurierbar
Set-Mailbox -Identity "user@domain.com" `
    -IssueWarningQuota $issueWarningQuota `
    -ProhibitSendQuota $prohibitSendQuota `
    -ProhibitSendReceiveQuota $prohibitSendReceiveQuota
```

---

## 🌐 Network & Zertifikate

### FQDN (Fully Qualified Domain Name)

```powershell
# Standard FQDN
$FQDN = "mail.domain.com"
$FQDN = "autodiscover.domain.com"

# Dies wird für ECP, OWA, Autodiscover verwendet
# Muss in DNS auflösbar sein!
```

### Zertifikat-Konfiguration

```powershell
# Selbstsigniertes Zertifikat (nach Installation)
$CertSubject = "CN=mail.domain.com"
$CertFriendlyName = "Exchange Server"

# Domains im Zertifikat
$CertDomains = @(
    "mail.domain.com",
    "autodiscover.domain.com",
    "*.domain.com"
)

# Zertifikat aktivieren
Enable-ExchangeCertificate -Thumbprint <Thumbprint> -Services IIS, SMTP
```

### HTTPS/TLS-Konfiguration

```powershell
# TLS-Anforderungen
$TLSVersion = "1.2"  # Minimum

# Sichere TLS-Cipher deaktivieren
Set-ExchangeServer -Identity <ServerName> `
    -RemotePowerShellEnabled $true

# SMTP-Verschlüsselung
Set-TransportConfig -TLSReceiveConfiguration Mandatory
```

---

## 🌳 AD-Vorbereitung

### ForestPrep-Optionen

```powershell
# ForestPrep ausführen?
$RunForestPrep = $true

# ForestPrep macht:
# - Schema erweitern
# - Neue Schema-Partitionen
# - AD aktualisieren
# - Replikation starten

# Wartet bis ForestPrep abgeschlossen ist
# (Replikation kann 15-60 Min dauern)
```

### DomainPrep-Optionen

```powershell
# DomainPrep ausführen?
$RunDomainPrep = $true

# Domains für DomainPrep
$DomainsForDomainPrep = @(
    "domain.local",
    "subdomain.domain.local"
)

# DomainPrep macht pro Domain:
# - Sicherheitsgruppen erstellen
# - Berechtigungen setzen
# - Delegierte Gruppen
```

### Berechtigungs-Anforderungen

```powershell
# Für ForestPrep
# - Schema Admins
# - Enterprise Admins

# Für DomainPrep
# - Domain Admins

# Prüfen:
$adminGroups = Get-ADPrincipalGroupMembership $env:USERNAME
$adminGroups | Select-Object Name
```

---

## 📝 Logging & Debugging

### Log-Pfade

```powershell
# Standard-Pfad für Skript-Logs
$ScriptLogPath = "C:\ScriptLog"

# Benutzerdefinierter Pfad
$ScriptLogPath = "D:\Logs\Exchange-Setup"

# Stelle sicher, dass Verzeichnis vorhanden ist
if (-not (Test-Path $ScriptLogPath)) {
    New-Item -Path $ScriptLogPath -ItemType Directory -Force | Out-Null
}
```

### Log-Ausgabe-Level

```powershell
# Logging-Optionen
$LogLevel = "Verbose"  # Oder: "Debug", "Information", "Warning", "Error"

# Verbose: Alle Details
# Debug: Noch mehr Details (für Troubleshooting)
# Information: Nur wichtige Meldungen
# Warning: Nur Warnungen und Fehler
# Error: Nur Fehler
```

### Log-Rotation

```powershell
# Alte Logs archivieren (optional)
$LogArchivePath = "D:\Logs\Archive"

# Logs älter als 30 Tage archivieren
Get-ChildItem "C:\ScriptLog\*.log" | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} |
    Compress-Archive -DestinationPath "$LogArchivePath\Logs_$(Get-Date -Format 'yyyyMMdd').zip"
```

### Debugging-Optionen

```powershell
# Debug-Mode aktivieren (sehr verbose)
$DebugPreference = "Continue"

# Auch für alle Sub-Skripte
Set-PSDebug -Trace 2  # Trace Level 2

# Später wieder deaktivieren
Set-PSDebug -Trace 0
$DebugPreference = "SilentlyContinue"
```

---

## ⚙️ Erweiterte Optionen (Geplant für v2.0)

```powershell
# Diese Parameter werden noch nicht unterstützt, sind aber geplant:

# Parameter-basierte Konfiguration
.\Exchange-Deployment-Automation-Tool.ps1 `
    -ExchangeVersion "2019" `
    -DatabasePath "E:\ExchangeDB" `
    -LogPath "F:\ExchangeLogs" `
    -OrganizationName "Contoso" `
    -RunForestPrep $true `
    -RunDomainPrep $true `
    -Silent  # Komplett unbeaufsichtigt

# Config-File unterstützen
.\Exchange-Deployment-Automation-Tool.ps1 -ConfigFile "config.json"
```

---

## 🔍 Konfiguration validieren

```powershell
# Vor der Installation prüfen:

# 1. Pfade existieren
Test-Path $ExchangePath
Test-Path $DatabasePath
Test-Path $LogPath

# 2. Speicherplatz
Get-Volume | Where-Object DriveLetter | Select-Object DriveLetter, SizeRemaining

# 3. AD-Verbindung
Get-ADDomain
Get-ADForest

# 4. Netzwerk
Resolve-DnsName mail.domain.com
Test-NetConnection -ComputerName mail.domain.com -Port 443

# 5. Zertifikate (falls vorhanden)
Get-ChildItem "Cert:\LocalMachine\My" | Select-Object Subject, Thumbprint, NotAfter
```

---

## 📚 Weitere Konfigurationsressourcen

- [Microsoft Exchange Server Deployment](https://docs.microsoft.com/en-us/exchange/plan-and-deploy/deployment)
- [Exchange Mailbox Database](https://docs.microsoft.com/en-us/exchange/architecture/mailbox-servers/mailbox-databases)
- [Exchange Transport Rules](https://docs.microsoft.com/en-us/exchange/security-and-compliance/mail-flow-rules/mail-flow-rules)

---

**Version**: 1.0 | **Aktualisiert**: Juni 2026
