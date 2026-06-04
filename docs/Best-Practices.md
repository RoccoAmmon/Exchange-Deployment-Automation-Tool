# Best Practices

**Empfehlungen für sichere und optimale Exchange-Deployment-Installationen**

---

## 📋 Inhaltsverzeichnis

1. [Vor der Installation](#vor-der-installation)
2. [Während der Installation](#während-der-installation)
3. [Nach der Installation](#nach-der-installation)
4. [Production-Betrieb](#production-betrieb)
5. [Sicherheit](#sicherheit)
6. [Performance](#performance)

---

## 🔧 Vor der Installation

### 1. Planung & Test

```powershell
# ✅ Do: Laborumgebung zuerst testen
# 1. VM mit identischer Konfiguration erstellen
# 2. Installation komplett durchlaufen
# 3. Validierung & Tests
# 4. Probleme dokumentieren
# 5. Lösungen implementieren
# 6. Dokumentation aktualisieren

# ❌ Don't: Direkt in Production installieren
```

### 2. Backup & Snapshots

```powershell
# ✅ Do: Vor Installation
# 1. VM-Snapshot erstellen (falls VM)
# 2. Systemlaufwerk sichern
# 3. Konfiguration dokumentieren
# 4. Wiederherstellungs-Plan testen

# Beispiel: VM-Snapshot
Get-VM -Name "EXCH01" | Checkpoint-VM -SnapshotName "Pre-Exchange-Installation_$(Get-Date -Format 'yyyyMMdd')"

# ❌ Don't: Ohne Backup starten
```

### 3. Hardware-Planung

```powershell
# ✅ Do: Ausreichende Ressourcen bereitstellen
# Exchange 2019/SE Empfehlungen:
# - RAM: 16 GB minimum, 32 GB+ optimal
# - CPU: 8 vCPU, modern architecture
# - HDD: 300+ GB SSD (nicht HDD!)
# - IOPS: 150+ pro Datenbank

$ram = (Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB
$cpu = (Get-WmiObject Win32_Processor).NumberOfCores

Write-Host "RAM: $ram GB" 
Write-Host "Cores: $cpu"

if ($ram -lt 16) { Write-Warning "RAM unter Empfehlung" }
if ($cpu -lt 8) { Write-Warning "CPU unter Empfehlung" }
```

### 4. Netzwerk-Vorbereitung

```powershell
# ✅ Do: Netzwerk validieren
# 1. DNS-Auflösung prüfen
Resolve-DnsName mail.domain.com
Resolve-DnsName autodiscover.domain.com

# 2. DC-Verbindung testen
Test-NetConnection -ComputerName (Get-ADDomainController).HostName -Port 389

# 3. Firewall-Regeln vorbereiten
# Ports: 25 (SMTP), 143 (IMAP), 587, 993, 995, 443 (HTTPS)

# 4. Proxy/Firewall checken
# Exchange sollte direkt erreichbar sein
```

### 5. AD-Vorbereitung checken

```powershell
# ✅ Do: AD-Status validieren
# 1. Forest Functional Level
Get-ADForest | Select-Object ForestMode
# Sollte 2012+ sein für Exchange 2019

# 2. Schema-Version
(Get-ADRootDSE).domainFunctionality
(Get-ADRootDSE).forestFunctionality

# 3. Domain-Replikation
repadmin /replsummary

# 4. Exchange-Gruppen prüfen (falls Migration)
Get-ADGroup -Filter "Name -like 'Exchange*'" 

# ❌ Don't: AD-Probleme ignorieren
```

---

## ⚙️ Während der Installation

### 1. Dokumentation

```powershell
# ✅ Do: Alles dokumentieren
# 1. Start-Zeit und Erwartung
$StartTime = Get-Date
Write-Host "Installation gestartet: $StartTime"

# 2. Screenshots machen
# - Admin-Check bestätigung
# - Parameter-Eingaben
# - Setup-Fortschritt

# 3. Fehler notieren
# - Fehlercode
# - Zeitstempel
# - Fehler-Kontext

# ❌ Don't: Annahmen machen über Fortschritt
```

### 2. Monitoring

```powershell
# ✅ Do: Prozess überwachen
# Terminal-Fenster offen lassen
# Logs in Echtzeit überwachen

# Logs live folgen (in zweitem Terminal)
Get-Content -Path "C:\ScriptLog\Exchange-Deployment-*.log" -Wait

# Event Logs überwachen
Get-WinEvent -LogName Application -MaxEvents 1000 -FilterXPath "*[System[(EventID=1000 or EventID=1001)]]" | 
  Sort-Object TimeCreated -Descending | 
  Select-Object TimeCreated, Id, Message | 
  Format-Table -AutoSize
```

### 3. Ressourcen-Monitoring

```powershell
# ✅ Do: Ressourcen während Installation überwachen
# CPU, RAM, Disk I/O

# Task Manager öffnen
Invoke-Item "taskmgr.exe"

# Oder: PowerShell Monitoring
while ($true) {
    $cpu = (Get-WmiObject -Class Win32_Processor).LoadPercentage
    $ram = ((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory - (Get-WmiObject Win32_OperatingSystem).FreePhysicalMemory) / 1GB
    
    Clear-Host
    Write-Host "CPU: $cpu %"
    Write-Host "RAM: $([math]::Round($ram, 2)) GB"
    
    Start-Sleep -Seconds 10
}
```

### 4. Fehlerbehandlung

```powershell
# ✅ Do: Bei Fehler sofort handeln
# 1. Screenshot machen
# 2. Fehler-Log kopieren
# 3. Kontext notieren
# 4. Support-Ressourcen konsultieren

# ✅ Do: Nicht panisch Neustart durchführen
# - Installation kann beschädigt werden
# - Besser: Logs analysieren

# ❌ Don't: Einfach ignorieren und weitermachen
```

---

## ✅ Nach der Installation

### 1. Sofort-Validierung (in den ersten 30 Minuten)

```powershell
# ✅ Do: Schnelle Validierung durchführen

# 1. Services validieren
$services = @("MSExchangeIS", "MSExchangeTransport", "MSExchangeADAccess", "W3SVC")
$services | ForEach-Object {
    $svc = Get-Service $_ -ErrorAction SilentlyContinue
    Write-Host "$_`: $($svc.Status)"
}

# 2. Datenbanken prüfen
Get-MailboxDatabase | Select-Object Name, Mounted, Server

# 3. ECP Test
$testECP = Test-NetConnection -ComputerName localhost -Port 443 -WarningAction SilentlyContinue
Write-Host "ECP reachbar: $($testECP.TcpTestSucceeded)"
```

### 2. Extended-Validierung (nach 1-2 Stunden)

```powershell
# ✅ Do: Umfassende Validierung
# 1. Exchange Health Check
Test-ExchangeHealth

# 2. Datenbank Integrity
Test-MailboxDatabaseIntegrity -Identity "Mailbox Database" -Verbose

# 3. Client Zugriff testen
# - IMAP/POP3 (falls aktiviert)
# - SMTP
# - HTTPS

# 4. AD-Integration
Get-OrganizationConfig | Select-Object Name, ExchangeVersion
Get-Recipient -ResultSize 10 | Select-Object Name, RecipientType
```

### 3. Logs archivieren

```powershell
# ✅ Do: Logs für Referenz archivieren

# Alle Logs komprimieren
$zipPath = "C:\Logs_Exchange_Installation_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
Compress-Archive -Path "C:\ScriptLog\", "C:\ExchangeSetupLogs\" -DestinationPath $zipPath -Verbose

Write-Host "Logs archiviert zu: $zipPath"

# ❌ Don't: Logs löschen
# Sie werden für Troubleshooting benötigt
```

---

## 🚀 Production-Betrieb

### 1. Redundanz & Hochverfügbarkeit

```powershell
# ✅ Do: Exchange-Server redundant auslegen
# Für Production:
# - Mindestens 2 Exchange-Server
# - Lastverteilung
# - Failover-Plan

# Mailbox-Server in DAG (Mailbox Database Availability Group)
# - Gibt es nur in Standard Edition Multi-Server
# - Nur in Enterprise Edition in Exchange 2019+

# ❌ Don't: Single-Server ohne Backup planen
```

### 2. Monitoring & Alerting

```powershell
# ✅ Do: Proaktives Monitoring einrichten

# 1. Exchange Health Monitoring
New-HealthReport -Identity Exchange-Servers -Frequency "Daily" -Recipients admin@domain.com

# 2. Disk Space Monitoring
$diskCheck = {
    Get-Volume | ForEach-Object {
        $free = [math]::Round($_.SizeRemaining / 1GB, 2)
        if ($free -lt 50) {
            Write-Host "WARNUNG: Drive $($_.DriveLetter): Nur $free GB verfügbar"
        }
    }
}
& $diskCheck

# 3. Service Monitoring
Get-Service MS* | Where-Object {$_.StartType -eq "Automatic" -and $_.Status -ne "Running"}

# ❌ Don't: Blind betreiben ohne Monitoring
```

### 3. Backup & Recovery

```powershell
# ✅ Do: Regelmäßiges Backup durchführen

# 1. VM-Snapshots (falls VM)
Get-VM | Checkpoint-VM -SnapshotName "Daily_$(Get-Date -Format 'yyyyMMdd')"

# 2. Configuration Backup
Export-MailboxDatabase -Identity "Mailbox Database" -ConfigFile "C:\Backups\DB_Config.xml"

# 3. Test der Recovery
# - Regelmäßig Restore-Prozess testen
# - Recovery Time Objective (RTO) dokumentieren
# - Recovery Point Objective (RPO) definieren
```

### 4. Update & Patching

```powershell
# ✅ Do: Update-Plan haben

# 1. Cumulative Updates prüfen
# https://docs.microsoft.com/en-us/exchange/new-features/updates

# 2. Update-Fenster planen
# - Nach Business Hours
# - Mit Test im Lab zuerst
# - Rollback-Plan bereit

# 3. Updates installieren
# - CU nacheinander
# - Zwischen Updates validieren
```

---

## 🔐 Sicherheit

### 1. Zertifikat-Management

```powershell
# ✅ Do: Gültige Zertifikate verwenden
# 1. Wildcard oder Multi-Domain Zertifikat
# 2. Von vertrautem CA
# 3. Hinreichende Key-Länge (2048 bit minimum)

# Zertifikat prüfen
Get-ExchangeCertificate | Where-Object {$_.Services -like "*IIS*"} | 
  Select-Object Thumbprint, Subject, Issuer, NotAfter

# Zertifikat erneuern vor Ablauf
if ((Get-ExchangeCertificate | Where-Object Status -eq "Valid").NotAfter -lt (Get-Date).AddDays(30)) {
    Write-Warning "Zertifikat läuft bald ab!"
}

# ❌ Don't: Selbstsignierte Zertifikate in Production verwenden
```

### 2. Authentifizierung & Authorization

```powershell
# ✅ Do: Starke Authentifizierung erzwingen
# 1. MFA (Multi-Factor Authentication) aktivieren
# 2. Moderne Authentication (OAuth)
# 3. Conditional Access Policies

Set-OrganizationConfig -OAuth2ClientProfileEnabled $true

# ✅ Do: RBAC (Role-Based Access Control) nutzen
# 1. Rollen definieren
# 2. Minimal-Berechtigungen
# 3. Audit-Trail

Get-ManagementRoleAssignment | Select-Object RoleAssignee, Role

# ❌ Don't: Admin-Accounts für tägliche Arbeit verwenden
```

### 3. Daten-Schutz

```powershell
# ✅ Do: Transport-Verschlüsselung aktivieren
# 1. TLS für externe Verbindungen
# 2. SMTP-Relay verschlüsseln

Set-TransportConfig -TLSReceiveConfiguration Mandatory

# ✅ Do: Datenbank-Verschlüsselung prüfen
# 1. BitLocker für Systemlaufwerk
# 2. Sichere Speicher-Pfade

# ❌ Don't: Unverschlüsselte E-Mails versenden
```

### 4. Audit & Compliance

```powershell
# ✅ Do: Audit-Logging aktivieren
# 1. Mailbox Audit enablen
Set-Mailbox -Identity "user@domain.com" -AuditEnabled $true -AuditLogAgeLimit 90

# 2. Admin Audit Log
Get-AdminAuditLogConfig | Select-Object UnifiedAuditLogIngestionEnabled

# 3. Regelmäßig Logs prüfen
Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-1) -EndDate (Get-Date) | Select-Object -First 100
```

---

## ⚡ Performance

### 1. Storage-Optimierung

```powershell
# ✅ Do: Optimale Storage-Struktur

# 1. Separate Laufwerke für:
# - OS (C:)
# - Exchange Binaries (D:)  
# - Mailbox Database (E:) ← WICHTIG: SSD!
# - Transaction Logs (F:) ← WICHTIG: Schnell!
# - Backups (G:)

# 2. RAID-Level
# - Datenbank: RAID 5 oder 6 (3+ Festplatten)
# - Logs: RAID 1 (2 Festplatten)
# - System: RAID 1 (2 Festplatten)

# 3. Festplatte formatieren
Format-Volume -DriveLetter D -FileSystem NTFS -AllocationUnitSize 4096 -Confirm:$false
```

### 2. Memory-Tuning

```powershell
# ✅ Do: RAM-Nutzung optimieren
# 1. Ausreichend RAM (16+ GB)
# 2. Pagefile auf schneller Platte
# 3. Exchange kann bis 100 GB RAM nutzen

# Aktuell verwendeter RAM
$exchangeRAM = (Get-Process | Where-Object Name -like "MSExchange*" | Measure-Object WorkingSet -Sum).Sum / 1GB
Write-Host "Exchange nutzt: $exchangeRAM GB RAM"
```

### 3. Database-Optimierung

```powershell
# ✅ Do: Datenbank-Performance optimieren

# 1. Database Maintenance Schedule
# Nightly: Full Backup
# Weekly: Incremental Backup

# 2. Database Size monitoring
Get-MailboxDatabase | Select-Object Name, @{
    N='SizeGB'; E={(Get-ChildItem (($_ | Get-MailboxDatabasePath).DataPath) -Recurse | Measure-Object -Property Length -Sum).Sum / 1GB}
}

# 3. Log File Truncation
# Nach erfolgreicherem Backup automatisch
```

---

## 📊 Monitoring Checklist

```powershell
# ✅ Täglich prüfen:
# [ ] Services laufen
# [ ] Datenbanken gemountet
# [ ] Speicherplatz verfügbar (>50 GB frei)
# [ ] Logs ohne Fehler

# ✅ Wöchentlich prüfen:
# [ ] Health Check
# [ ] Backup erfolgreich
# [ ] Replikation OK
# [ ] Keine kritischen Events

# ✅ Monatlich prüfen:
# [ ] Performance-Report
# [ ] Updates verfügbar
# [ ] Capacity Planning
# [ ] Recovery-Test
```

---

## 🔗 Referenzen

- [Microsoft Exchange Best Practices](https://docs.microsoft.com/en-us/exchange/)
- [Exchange Server Sizing](https://docs.microsoft.com/en-us/exchange/plan-and-deploy/sizing-exchange-deployments)
- [Exchange Security](https://docs.microsoft.com/en-us/exchange/security-and-compliance)

---

**Version**: 1.0 | **Aktualisiert**: Juni 2026
