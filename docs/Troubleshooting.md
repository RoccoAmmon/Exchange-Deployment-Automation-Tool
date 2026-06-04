# Troubleshooting

**Lösungen für häufige Probleme und Fehler**

---

## 🔧 Häufige Probleme

### Admin-Berechtigungen

#### Problem: "Dieser Vorgang erfordert Administrator-Berechtigungen"

```powershell
# ❌ Problem
.\Exchange-Deployment-Automation-Tool.ps1
# Fehler: Access Denied

# ✅ Lösung 1: Rechtsklick auf .ps1
# Rechtsklick → Mit PowerShell ausführen

# ✅ Lösung 2: Administrator-Shell
Start-Process -FilePath "powershell.exe" -Verb RunAs

# ✅ Lösung 3: RunAs-Befehl
runas /user:%username% "powershell.exe -ExecutionPolicy Bypass -File Exchange-Deployment-Automation-Tool.ps1"
```

---

### Execution Policy

#### Problem: "File cannot be loaded because running scripts is disabled"

```powershell
# ❌ Problem
.\Exchange-Deployment-Automation-Tool.ps1
# Fehler: Cannot be loaded because running scripts is disabled on this system

# ✅ Lösung 1: Execution Policy für Prozess
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\Exchange-Deployment-Automation-Tool.ps1

# ✅ Lösung 2: Execution Policy dauerhaft (nicht empfohlen)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# ✅ Lösung 3: PowerShell Bypass-Flag
powershell.exe -ExecutionPolicy Bypass -File Exchange-Deployment-Automation-Tool.ps1
```

---

### .NET Framework

#### Problem: ".NET Framework zu alt"

```powershell
# ❌ Problem
Exchange Setup schlägt fehl: ".NET Framework 4.7.2 erforderlich"

# ✅ Diagnose: Aktuelle Version prüfen
(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -Name Release).Release
# 461808+ = .NET 4.7.2+
# 394802+ = .NET 4.6.2

# ✅ Lösung: Automatisch installiert
# Das Skript installiert erforderliche Versionen automatisch
# Neustart kann erforderlich sein

# ✅ Manual: Manuell installieren
# https://www.microsoft.com/en-us/download/details.aspx?id=53344
```

---

### Active Directory - Vorbereitung

#### Problem: "ForestPrep schlägt fehl"

```powershell
# ❌ Problem
ForestPrep Error: "The schema object class ... does not exist"

# ✅ Diagnose: AD-Zugriff prüfen
Get-ADDomain
Get-ADForest | Select-Object ForestMode
Get-ADRootDSE

# ✅ Diagnose: Schema-Admin-Rechte
# Benutzer muss in folgenden Gruppen sein:
# - Schema Admins
# - Enterprise Admins

# Gruppenmitgliedschaft prüfen:
([adsisearcher]"samaccountname=$env:USERNAME").FindOne().Properties['memberof']

# ✅ Lösung: Berechtigungen erhöhen
# ForestPrep muss mit Schema Admin-Rechten laufen
# Mit Account ausführen, der in Schema Admins ist
```

#### Problem: "DomainPrep schlägt fehl"

```powershell
# ❌ Problem
DomainPrep Error: "Insufficient access rights"

# ✅ Diagnose: Domain Admin prüfen
# Benutzer muss Domain Admin sein

# Mitgliedschaft prüfen:
Get-ADPrincipalGroupMembership $env:USERNAME | Select-Object Name

# ✅ Lösung: Mit Domain Admin-Konto ausführen
# DomainPrep muss mit Domain Admin-Rechten laufen
```

#### Problem: "Schema-Replikation fehlgeschlagen"

```powershell
# ❌ Problem
ForestPrep erfolgreich, aber Fehler bei Setup: "Schema kennt Exchange-Klassen nicht"

# ✅ Ursache: Replikation nicht abgeschlossen
# Replikation kann 15-60 Minuten dauern

# ✅ Diagnose: Replikationsstatus prüfen
repadmin /replsummary
repadmin /showrepl

# ✅ Lösung: Auf Replikation warten oder erzwingen
# Manual: Replikation erzwingen
repadmin /syncall /e

# Mit Warten kombinieren
while ((repadmin /replsummary | Select-String "Error").Count -gt 0) {
    Write-Host "Replikation läuft... $(Get-Date)"
    Start-Sleep -Seconds 30
}
Write-Host "Replikation abgeschlossen"
```

---

### Exchange Installation

#### Problem: "Exchange Setup schlägt mit Error fehl"

```powershell
# ❌ Problem
Exchange Setup.exe fehlgeschlagen

# ✅ Diagnose: Setup-Logs prüfen
Get-ChildItem "C:\ExchangeSetupLogs\" | Sort-Object LastWriteTime -Descending
Get-Content "C:\ExchangeSetupLogs\ExchangeSetup.log" -Tail 50

# ✅ Häufige Ursachen:
# 1. Fehlende Voraussetzungen (KB Updates, .NET)
# 2. Speicherplatz voll
# 3. Netzwerk-/DNS-Probleme
# 4. AD-Replikation nicht abgeschlossen
# 5. Antivirus blockiert Installation

# ✅ Lösung: Siehe spezifische Fehler unten
```

#### Problem: "Speicherplatz voll während Setup"

```powershell
# ❌ Problem
Exchange Setup: "Insufficient disk space"

# ✅ Diagnose: Freier Speicher prüfen
Get-Volume | Where-Object DriveLetter | Select-Object DriveLetter, SizeRemaining, @{
    N='FreeGB'; E={[math]::Round($_.SizeRemaining / 1GB, 2)}
}

# ✅ Lösung: Speicherplatz freigeben
# Mindestens 200 GB freier Speicher erforderlich
# 300+ GB empfohlen für Installationen und Updates

# Speicherplatz freigeben:
# 1. Alte Windows Updates löschen
Disk Cleanup
# oder: cleanmgr.exe

# 2. Temporäre Dateien
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

# 3. Unbenötigte Anwendungen entfernen
Get-Package | ? {$_.Name -like "* Visual*"} | Uninstall-Package
```

#### Problem: "Antivirus blockiert Installation"

```powershell
# ❌ Problem
Setup fehlgeschlagen: "Access Denied" bei Datei-Zugriff

# ✅ Diagnose: Antivirus-Logs prüfen
# Windows Defender Event Log:
Get-WinEvent -LogName "Microsoft-Windows-Windows Defender/Operational" -MaxEvents 20 | 
  Select-Object TimeCreated, Id, Message

# ✅ Lösung: Antivirus ausnahmen
# Windows Defender Ausnahmen:
# 1. Ganze Exchange-Installationslaufwerk
# 2. Mailbox-Datenbank-Pfade
# 3. Transaction-Log-Pfade
# 4. Prozesse: EdgeTransport.exe, MSExchangeIS.exe

# Beispiel:
Add-MpPreference -ExclusionPath "D:\ExchangeDB"
Add-MpPreference -ExclusionPath "E:\ExchangeLogs"
Add-MpPreference -ExclusionProcess "EdgeTransport.exe"
```

---

### Services & Funktionalität

#### Problem: "Services starten nicht"

```powershell
# ❌ Problem
Get-Service MSExchangeIS
# Status: Stopped

# ✅ Diagnose: Service-Details
Get-Service MSExchangeIS | Select-Object *
Get-Service MSExchangeIS | Get-EventLog -ErrorAction SilentlyContinue

# ✅ Diagnose: Event Logs
Get-EventLog -LogName Application -Source "MSExchange*" -Newest 10 | 
  Select-Object TimeGenerated, EventID, Message

# ✅ Lösung: Services manuell starten
Start-Service MSExchangeIS
Start-Service MSExchangeTransport
Start-Service MSExchangeADAccess

# ✅ Lösung: Abhängigkeiten prüfen
Get-Service MSExchangeIS | Select-Object -ExpandProperty DependentServices
```

#### Problem: "ECP/OWA nicht erreichbar"

```powershell
# ❌ Problem
https://localhost/ecp → Fehler

# ✅ Diagnose: IIS-Status
Get-Service W3SVC | Select-Object Status

# ✅ Diagnose: IIS Application Pools
Get-WebAppPoolState -Name "*" | Select-Object Name, Value

# ✅ Diagnose: HTTPS-Zertifikat
Get-ExchangeCertificate | Where-Object {$_.Services -like "*IIS*"} | 
  Select-Object Thumbprint, Subject, Status

# ✅ Lösung 1: IIS neu starten
Restart-Service W3SVC
Restart-Service WAS

# ✅ Lösung 2: Application Pools neu starten
Restart-WebAppPool -Name "MSExchangeBackendAppPool"
Restart-WebAppPool -Name "MSExchangeFrontendAppPool"

# ✅ Lösung 3: HTTPS-Zertifikat konfigurieren
Get-ExchangeCertificate -thumbprint <Thumbprint> | Enable-ExchangeCertificate -Services IIS -Confirm:$false
```

#### Problem: "Mailbox-Datenbank nicht sichtbar"

```powershell
# ❌ Problem
Get-MailboxDatabase
# Keine Ausgabe oder Fehler

# ✅ Diagnose: Datenbank-Status
Get-MailboxDatabase | Select-Object Name, Server, State

# ✅ Diagnose: Mount-Status
Get-MailboxDatabase | Select-Object Name, Mounted

# ✅ Lösung: Datenbank mounten
Mount-Database -Identity "Mailbox Database"

# ✅ Lösung: Services prüfen
Get-Service MSExchangeIS | Restart-Service -Force
Start-Sleep -Seconds 5
Mount-Database -Identity "Mailbox Database"
```

---

## 🔍 Erweiterte Diagnostik

### Skript-Logs analysieren

```powershell
# Log-Dateien auflisten
Get-ChildItem "C:\ScriptLog\Exchange-Deployment-*.log" | 
  Sort-Object LastWriteTime -Descending

# Letzten 100 Zeilen anzeigen
Get-Content "C:\ScriptLog\Exchange-Deployment-*.log" -Tail 100

# Fehler filtern
Select-String "ERROR" "C:\ScriptLog\Exchange-Deployment-*.log"

# Spezifische Phase analysieren
Select-String "AD-Vorbereitung|ForestPrep|DomainPrep" "C:\ScriptLog\Exchange-Deployment-*.log"
```

### Event Logs durchsuchen

```powershell
# Fehler der letzten Stunde
Get-EventLog -LogName Application -After (Get-Date).AddHours(-1) | 
  Where-Object {$_.EntryType -eq "Error"}

# Exchange Setup Fehler
Get-WinEvent -FilterHashtable @{
    LogName = "Application"
    StartTime = (Get-Date).AddDays(-1)
    Level = 2  # Error
} | Where-Object Message -Like "*Exchange*" | Select-Object TimeCreated, Message

# Speichern für Analyse
Get-WinEvent -FilterHashtable @{
    LogName = "Application"
    StartTime = (Get-Date).AddDays(-1)
} | Export-Csv "C:\EventLogs_$(Get-Date -Format 'yyyyMMdd').csv"
```

---

## 📞 Wenn alles nicht hilft

1. **Logs sammeln:**
   ```powershell
   # Alle relevanten Logs exportieren
   mkdir "C:\Support-Logs"
   Copy-Item "C:\ScriptLog\*" "C:\Support-Logs\"
   Copy-Item "C:\ExchangeSetupLogs\*" "C:\Support-Logs\"
   Get-EventLog -LogName Application -Newest 1000 | Export-Csv "C:\Support-Logs\EventLog.csv"
   ```

2. **System-Info sammeln:**
   ```powershell
   # Systemdiagnose exportieren
   systeminfo > "C:\Support-Logs\systeminfo.txt"
   Get-ComputerInfo > "C:\Support-Logs\computerinfo.txt"
   ```

3. **Issue erstellen:**
   - Auf GitHub: [Issues](https://github.com/RoccoAmmon/Exchange-Deployment-Automation-Tool/issues)
   - Mit Support-Logs anhängen
   - Detaillierte Fehlerbeschreibung

---

**Version**: 1.0 | **Aktualisiert**: Juni 2026
