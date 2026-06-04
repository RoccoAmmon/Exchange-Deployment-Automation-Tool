# Detaillierte Installation

**Vollständiger Installationsleitfaden mit allen Schritten und Optionen**

---

## 📋 Inhaltsverzeichnis

1. [Vorbereitung](#vorbereitung)
2. [Installation Schritt-für-Schritt](#installation-schritt-für-schritt)
3. [AD-Vorbereitung](#ad-vorbereitung)
4. [Exchange Setup](#exchange-setup)
5. [Post-Installation](#post-installation)
6. [Validierung](#validierung)

---

## 🔧 Vorbereitung

### Phase 1: Hardware & Netzwerk

#### 1.1 Systemanforderungen überprüfen

```powershell
# RAM prüfen (mindestens 8 GB, empfohlen 16+ GB)
[int]$RAMgb = (Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB
Write-Host "RAM: $RAMgb GB"
if ($RAMgb -lt 8) { Write-Warning "Unzureichend RAM!" }

# Speicherplatz prüfen (mindestens 200 GB)
$disk = Get-Volume -DriveLetter C
$freegb = $disk.SizeRemaining / 1GB
Write-Host "Freier Speicher (C:): $([math]::Round($freegb, 2)) GB"
if ($freegb -lt 200) { Write-Warning "Unzureichend Speicherplatz!" }

# CPU-Kerne
$cpuCores = (Get-WmiObject Win32_Processor).NumberOfCores
Write-Host "CPU-Kerne: $cpuCores"

# OS-Version
Get-WmiObject Win32_OperatingSystem | Select-Object Caption, Version
```

#### 1.2 Netzwerk-Verbindung testen

```powershell
# DNS-Auflösung testen
Resolve-DnsName google.com
Resolve-DnsName $env:USERDNSDOMAIN

# Verbindung zu DC testen
Test-NetConnection -ComputerName (Get-ADDomainController).HostName -Port 389

# Domain-Membership prüfen
Get-ComputerInfo | Select-Object CsName, CsDomain
```

#### 1.3 PowerShell & .NET prüfen

```powershell
# PowerShell-Version (mindestens 5.1)
$PSVersionTable.PSVersion

# .NET Framework-Versionen
Get-ChildItem "HKLM:\Software\Microsoft\NET Framework Setup\NDP" -Recurse | 
  Get-ItemProperty -Name Version -ErrorAction SilentlyContinue

# Oder: DirectRelease-Wert prüfen
(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -Name Release).Release
# 461808+ = .NET 4.7.2+
```

### Phase 2: Active Directory Validierung

```powershell
# AD-Zugriff testen
Get-ADDomain

# Forest-Funktionales Level prüfen
Get-ADForest | Select-Object ForestMode

# Domain Admin Mitgliedschaft prüfen
([adsisearcher]"objectguid=$([System.guid]::Parse((whoami /user /uh /fo csv | select -last 1 | % { $_ -split ',' | select -first 1 }).Trim('""')).toString())").FindOne().Properties['memberof']
```

### Phase 3: Exchange-Installationsmittel vorbereiten

```powershell
# ISO-Datei bereitstellen (Exchange 2019 Beispiel)
# Pfad: D:\ex2019cu.iso

# ISO mounten
Mount-DiskImage -ImagePath "D:\ex2019cu.iso" -PassThru | Get-Volume

# Oder: ISO auf Festplatte extrahieren
7z x "D:\ex2019cu.iso" -o"D:\ExchangeMedia"
```

---

## ⚙️ Installation Schritt-für-Schritt

### Schritt 1: Repository & Skript vorbereiten

```powershell
# In Zielverzeichnis navigieren (oder WorkingDirectory)
cd C:\

# Repository klonen
git clone https://github.com/RoccoAmmon/Exchange-Deployment-Automation-Tool.git

# In Verzeichnis wechseln
cd Exchange-Deployment-Automation-Tool

# Datei-Eigenschaften überprüfen
Get-ChildItem *.ps1 | Select-Object Name, Length, LastWriteTime
```

### Schritt 2: Execution Policy setzen

```powershell
# NUR für diesen Prozess (keine Änderung am System)
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Oder: Nur für CurrentUser (persistent, aber nicht admin-weit)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### Schritt 3: Skript mit Admin-Rechten ausführen

```powershell
# Option 1: Direkt im Admin-PowerShell
.\Exchange-Deployment-Automation-Tool.ps1

# Option 2: Mit ausdrücklichen Admin-Berechtigungen
Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList @(
    '-NoProfile'
    '-ExecutionPolicy', 'Bypass'
    '-File', (Get-Location).Path + '\Exchange-Deployment-Automation-Tool.ps1'
) -WorkingDirectory (Get-Location).Path

# Option 3: Mit Parametern
.\Exchange-Deployment-Automation-Tool.ps1 -ForceLang "de"
```

---

## 🌳 AD-Vorbereitung

Diese Phase wird optional vom Skript durchgeführt.

### Phase 3: ForestPrep

```powershell
# ForestPrep wird automatisch durchgeführt für:
# - Neues Exchange-Schema-Update
# - Erste Exchange-Installation in Forest

# Was ForestPrep macht:
# 1. Schema erweitern für Exchange-Objekte
# 2. Neue Schema-Partitionen erstellen
# 3. Active Directory updaten
# 4. Replikation zu allen DCs
```

**Dauer:** 5-15 Minuten (abhängig von Replikation)

### Phase 4: DomainPrep

```powershell
# DomainPrep für jede Domain durchführen

# Was DomainPrep macht:
# 1. Domain-Sicherheitsgruppen erstellen
# 2. Berechtigungen auf OU setzen
# 3. Kontainerberechtigungen konfigurieren
# 4. Delegierte Gruppen erstellen
```

**Dauer:** 3-10 Minuten pro Domain

### Validierung nach AD-Prep

```powershell
# Replikation prüfen
repadmin /replsummary

# Exchange-Sicherheitsgruppen prüfen
Get-ADGroup -Filter "Name -like 'Exchange*'" | Select-Object Name

# Schema-Erweiterung validieren
$schema = Get-ADObject -Filter 'Name -eq "msExchProductId"' -SearchBase (Get-ADRootDSE).schemaNamingContext
if ($schema) { Write-Host "✅ Exchange-Schema vorhanden" } else { Write-Host "❌ Schema fehlt" }
```

---

## 📦 Exchange Setup

Das Skript führt automatisch durch:

### Phase 5: Voraussetzungen installieren

```powershell
# Automatisch installiert:
# 1. .NET Framework 4.7.2+
# 2. Visual C++ Redistributable
# 3. KB-Updates (Security, Servicing Stack)
# 4. Windows Features (wenn nötig)
```

**Dauer:** 10-30 Minuten (abhängig von Updates)

### Phase 6: Exchange Installation

```powershell
# Automatische Antwortdatei wird erstellt
# Setup wird gestartet mit:
# - /Mode:Install (neue Installation)
# - /IAcceptExchangeServerLicenseTerms
# - /Organization:Name (automatisch)

# Keine manuelle Interaktion nötig!
```

**Dauer:** 20-60 Minuten (abhängig von Hardware)

---

## ✅ Post-Installation

### Phase 7: Services & Validierung

```powershell
# Exchange-Services starten
Start-Service MSExchangeIS
Start-Service MSExchangeTransport
Start-Service MSExchangeADAccess

# Services prüfen
Get-Service MS* | Where-Object {$_.StartType -eq "Automatic"} | Select-Object Name, Status

# Health-Check
Test-ExchangeHealth
```

### Phase 8: Zertifikate konfigurieren

```powershell
# Selbstsigniertes Zertifikat prüfen
Get-ExchangeCertificate | Where-Object Status -eq "Valid" | Select-Object Thumbprint, Subject

# HTTPS aktivieren für ECP & OWA
Enable-ExchangeCertificate -Thumbprint <Thumbprint> -Services IIS, SMTP

# oder: Neues Zertifikat anfordern
New-ExchangeCertificate -FriendlyName "Exchange" -SubjectName "cn=mail.domain.com"
```

### Phase 9: Koexistenz konfigurieren (optional)

Falls Sie auch Exchange 2016/2013 haben:

```powershell
# Routing-Gruppen-Connector prüfen
Get-ForeignConnector | Select-Object Name, SourceTransportServers

# Koexistenz-Header setzen
Set-ExchangeOrganization -InternalHostName mail.domain.com -ExternalHostName mail.domain.com
```

---

## 🔍 Validierung

### Schritt 1: Basic Services

```powershell
# Alle kritischen Services sollten "Running" sein
$services = @(
    "MSExchangeIS",
    "MSExchangeTransport", 
    "MSExchangeADAccess",
    "MSExchangeServiceHost",
    "W3SVC"
)

$services | ForEach-Object {
    $svc = Get-Service $_ -ErrorAction SilentlyContinue
    Write-Host "$_ : $($svc.Status)"
}
```

### Schritt 2: ECP & OWA Zugriff

```powershell
# ECP (Exchange Control Panel)
Start-Process "https://localhost/ecp"

# OWA (Outlook Web Access)
Start-Process "https://localhost/owa"

# Beide sollten erreichbar sein (HTTPS-Warnung ignorieren für Self-Signed)
```

### Schritt 3: Datenbank & Speicher

```powershell
# Mailbox-Datenbanken prüfen
Get-MailboxDatabase | Select-Object Name, Server, Recovery

# Speichergruppen (wenn zutreffend)
Get-StorageGroup | Select-Object Name, LogFolderPath, SystemFolderPath
```

### Schritt 4: Logs überprüfen

```powershell
# Skript-Logs
Get-ChildItem "C:\ScriptLog\Exchange-Deployment-*.log" | 
  ForEach-Object { Get-Content $_.FullName -Tail 20 }

# Exchange Setup Logs
Get-ChildItem "C:\ExchangeSetupLogs\" | Sort-Object LastWriteTime -Descending | Select-Object -First 5

# Event Logs
Get-EventLog -LogName Application -Source "MSExchange*" -Newest 20 | 
  Select-Object TimeGenerated, EventID, Message
```

---

## ✨ Erfolgreiche Installation

✅ Alle Services laufen
✅ ECP & OWA erreichbar
✅ Mailbox-Datenbanken aktiv
✅ Keine kritischen Fehler in Logs
✅ AD-Integrationen funktionieren

---

## 🆘 Nächste Schritte

- [Troubleshooting](Troubleshooting) - Wenn Probleme auftreten
- [FAQ](FAQ) - Häufig gestellte Fragen
- [Best Practices](Best-Practices) - Production-Empfehlungen

---

**Version**: 1.0 | **Aktualisiert**: Juni 2026
