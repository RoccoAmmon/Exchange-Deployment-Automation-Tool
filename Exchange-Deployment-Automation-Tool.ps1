# ============================================================
# AUTO-ELEVATION
# ============================================================
param([switch]$Elevated, [string]$ForceLang = "")

function Test-IsAdmin {
    try {
        $cu = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        return $cu.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch { return $false }
}

if (-not (Test-IsAdmin)) {
    if ($Elevated) {
        Write-Host "FEHLER / ERROR: Admin-Rechte konnten nicht ermittelt werden." -ForegroundColor Red
        Read-Host "ENTER"
        exit 1
    }
    if ($psISE -or $Host.Name -match 'ISE') {
        Write-Host "WARNUNG: Bitte NICHT in der ISE ausfuehren!" -ForegroundColor Yellow
        Write-Host "Rechtsklick auf .ps1 -> 'Mit PowerShell ausfuehren'" -ForegroundColor Cyan
        Read-Host "ENTER"
        exit 1
    }
    $scriptPath = $MyInvocation.MyCommand.Path
    if (-not $scriptPath) { $scriptPath = $PSCommandPath }
    try {
        $argList = @('-NoProfile','-ExecutionPolicy','Bypass','-File',('"' + $scriptPath + '"'),'-Elevated')
        if ($ForceLang) { $argList += @('-ForceLang', $ForceLang) }
        Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList $argList -WorkingDirectory (Get-Location).Path -ErrorAction Stop
        exit 0
    } catch {
        Write-Host ("Eskalations-Fehler: " + $_) -ForegroundColor Red
        Read-Host "ENTER"
        exit 1
    }
}

Write-Host "==================================================" -ForegroundColor Green
Write-Host " Microsoft Exchange SE - Konfigurations-Center" -ForegroundColor Green
Write-Host " User: $env:USERDOMAIN\$env:USERNAME" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Start-Sleep -Milliseconds 600

<#
.SYNOPSIS
    Exchange-Deployment-Automation-Tool – Vollautomatisierte Installation von Microsoft Exchange Server

.DESCRIPTION
    Umfassendes PowerShell-Skript zur VOLLAUTOMATISIERTEN Installation und Konfiguration von 
    Microsoft Exchange Server 2016, 2019 und Standard Edition (SE).
    
    Das Skript automatisiert den gesamten Deployment-Workflow in einer kontinuierlichen Ausführung:
    - Systemvalidierung (OS, RAM, Speicher, .NET Framework, Netzwerk)
    - Active Directory Vorbereitung (ForestPrep, DomainPrep)
    - Automatische Installation aller Voraussetzungen (.NET, KB-Updates, VC++ Runtime)
    - Unbeaufsichtigtes Exchange Setup mit automatischer Antwortdatei-Generierung
    - Post-Installation Konfiguration (Services, Zertifikate, Koexistenz)

.FEATURES
    ✓ Vollautomatisierung – Keine manuelle Intervention erforderlich
    ✓ Multi-Version Support – Exchange 2016, 2019, Standard Edition
    ✓ Enterprise-ready – ForestPrep, DomainPrep, DAG-Vorbereitung
    ✓ Robuste Fehlerbehandlung – Umfassende Validierung & Error-Handling
    ✓ Detailliertes Logging – Alle Operationen dokumentiert in C:\ScriptLog\
    ✓ Mehrsprachig – Deutsch (DE) & Englisch (EN) mit Auto-Detection
    ✓ Admin-Auto-Elevation – Automatische UAC-Eskalation mit RunAs
    ✓ Production-Ready – Getestet in Lab, Test und Production

.ANWENDUNGSFÄLLE
    • Laborumgebungen – Schnelle Test-Deployments
    • Testumgebungen – Reproduzierbare Konfigurationen
    • Production Deployments – Enterprise-Grade Automation
    • VM-Provisioning – Automatisierte Skalierung
    • Migrationen – Schnelle Koexistenz-Setup
    • physische Server – Zuverlässige Installations-Automation

.SYSTEMVORAUSSETZUNGEN
    OS:             Windows Server 2016 oder höher
    PowerShell:     5.1+
    RAM:            Minimum 8 GB (empfohlen: 16+ GB)
    CPU:            Minimum 4 vCPU (empfohlen: 8+)
    Speicher:       Minimum 200 GB freier Speicherplatz (empfohlen: 300+ GB)
    Admin-Rechte:   Erforderlich (Auto-Elevation)
    .NET Framework: 4.7.2+ (wird automatisch installiert)
    Netzwerk:       AD-Verbindung, DNS, Internetzugang

.PARAMETER
    -Elevated
        Interner Parameter für Auto-Elevation (automatisch gesetzt)

    -ForceLang
        Erzwingt eine bestimmte Sprache: "de" für Deutsch, "en" für English
        Standard: Auto-Detection basierend auf Systemsprache

.BEISPIELE
    # Standardausführung (Auto-Elevation mit Deutsch/English Auto-Detection)
    .\Exchange-Deployment-Automation-Tool.ps1

    # Erzwinge Deutsch
    .\Exchange-Deployment-Automation-Tool.ps1 -ForceLang "de"

    # Erzwinge English
    .\Exchange-Deployment-Automation-Tool.ps1 -ForceLang "en"

    # Mit Rechtsklick "Mit PowerShell ausführen" (empfohlen)
    # -> Automatische Admin-Elevation + Sprach-Auto-Detection

.WORKFLOW
    1. SYSTEMVALIDIERUNG
       - OS-Version Prüfung
       - RAM/CPU/HDD Validierung
       - .NET Framework Check
       - AD/DNS Verbindung
       - Prerequisites Status

    2. ACTIVE DIRECTORY VORBEREITUNG (Optional)
       - ForestPrep (Schema-Erweiterung)
       - DomainPrep (Security-Gruppen, Berechtigungen)
       - Replikations-Warten
       - Multi-Domain Support

    3. VORAUSSETZUNGEN-INSTALLATION
       - .NET Framework 4.7.2+
       - Visual C++ Redistributables
       - Windows KB-Updates
       - Feature Installation (HTTP, IIS, etc.)

    4. EXCHANGE SETUP
       - Automatische Antwortdatei-Generierung
       - Unbeaufsichtigtes Setup.exe
       - Komponenten-Installation
       - Installationsstatus Überwachung

    5. POST-INSTALLATION KONFIGURATION
       - Exchange Services Konfiguration
       - SSL/TLS Zertifikate Setup
       - Koexistenz mit älteren Versionen
       - Erste Database Validierung

.AUSGABE
    • Interaktive Konsolen-Ausgabe mit farblicher Formatierung
    • Detaillierte Log-Dateien: C:\ScriptLog\Exchange-Deployment-*.log
    • Event-Log Integration: Application -> MSExchange*
    • Validierungs-Reports nach jedem Schritt

.FEHLERBEHANDLUNG
    • Umfassende Try/Catch Blöcke
    • Automatische Fehler-Logging
    • Aussagekräftige Fehlermeldungen (DE/EN)
    • Validierung nach kritischen Operationen
    • Rollback-Möglichkeiten (wo anwendbar)

.SICHERHEIT
    ✓ Admin-Berechtigungen erforderlich
    ✓ UAC-Eskalation automatisiert
    ✓ Keine hartcodierten Passwörter
    ✓ Sichere Fehlerbehandlung
    ✓ Input-Validierung

.LIZENZ
    MIT License – Kostenlos, veränderbar, kommerziell nutzbar

.AUTOR
    Rocco Ammon (rocco@sva-system.de)
    SVA System Vertrieb Alexander GmbH

.VERSION
    1.0 (Production Ready) – Juni 2026

.REPOSITORY
    https://github.com/RoccoAmmon/Exchange-Deployment-Automation-Tool

.WIKI
    https://github.com/RoccoAmmon/Exchange-Deployment-Automation-Tool/wiki

.SUPPORT
    Issues:      https://github.com/RoccoAmmon/Exchange-Deployment-Automation-Tool/issues
    Discussions: https://github.com/RoccoAmmon/Exchange-Deployment-Automation-Tool/discussions
    Dokumentation: https://github.com/RoccoAmmon/Exchange-Deployment-Automation-Tool/wiki

.HINWEISE
    • Zuerst in LAB/TEST testen!
    • Vor Ausführung: Vollständiges BACKUP erstellen
    • Windows Updates VOR der Ausführung durchführen
    • Installationsmedium (ISO) bereitstellen
    • Mindestens 60-90 Minuten Zeit einplanen
    • Support-Kanal (Email/Chat) bereithalten

.CHANGELOG
    1.0 (2026-06-04)
    - Initial Release
    - Exchange 2016, 2019, SE Support
    - ForestPrep/DomainPrep automatisiert
    - Umfangreiche Dokumentation & Wiki
    - Production-ready

#>

#region ============================ GLOBALE VARIABLEN ============================

# Assemblies ZUERST laden!
try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    [System.Windows.Forms.Application]::EnableVisualStyles()
} catch {
    Write-Host "Fehler beim Laden der GUI-Assemblies: $_" -ForegroundColor Red
    Read-Host "ENTER"
    exit 1
}

$Global:LogPath          = "C:\ScriptLog"
$Global:LogFile          = Join-Path $Global:LogPath "ExchangeSE_GUI_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$Global:ConfigPath       = Join-Path $Global:LogPath "Config"
$Global:ConfigFile       = Join-Path $Global:ConfigPath "ExchangeFullConfig.json"
$Global:ExchangeBinPath  = "C:\Program Files\Microsoft\Exchange Server\V15\bin"
$Global:RemoteExchangeScript = Join-Path $Global:ExchangeBinPath "RemoteExchange.ps1"
$Global:DefaultInstallPath   = "C:\Program Files\Microsoft\Exchange Server\V15"
$Global:ExchangeSetupLog     = "C:\ExchangeSetupLogs\ExchangeSetup.log"
$Global:DefaultDBPath    = "D:\ExchangeDatabases"
$Global:DefaultLogDBPath = "E:\ExchangeLogs"
$Global:DefaultTempPath  = "C:\ExchangeInstall\Temp"
$Global:DetectedISOs       = @()
$Global:ADStatusLoaded     = $false
$Global:PrereqStatusLoaded = $false
$Global:FormWidth          = 1150
$Global:FormHeight         = 820

$Global:ColorBackground = [System.Drawing.Color]::FromArgb(245, 247, 250)
$Global:ColorPanel      = [System.Drawing.Color]::FromArgb(255, 255, 255)
$Global:ColorPanelAlt   = [System.Drawing.Color]::FromArgb(235, 240, 247)
$Global:ColorAccent     = [System.Drawing.Color]::FromArgb(0, 120, 215)
$Global:ColorAccent2    = [System.Drawing.Color]::FromArgb(16, 137, 62)
$Global:ColorWarning    = [System.Drawing.Color]::FromArgb(202, 120, 12)
$Global:ColorError      = [System.Drawing.Color]::FromArgb(196, 43, 28)
$Global:ColorText       = [System.Drawing.Color]::FromArgb(32, 32, 32)
$Global:ColorTextDim    = [System.Drawing.Color]::FromArgb(100, 100, 100)
$Global:ColorInputBg    = [System.Drawing.Color]::FromArgb(255, 255, 255)
$Global:ColorBorder     = [System.Drawing.Color]::FromArgb(200, 205, 215)

$Global:FontDefault = New-Object System.Drawing.Font("Segoe UI", 9)
$Global:FontBold    = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$Global:FontHeader  = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$Global:FontMono    = New-Object System.Drawing.Font("Consolas", 9)
#endregion

#region ============================ SPRACHEN / I18N ============================
$Global:Texts = @{
    DE = @{
        AppTitle="Microsoft Exchange SE - Konfigurations-Center"; AppSubtitle="v3.6  |  Rocco Ammon, SVA"
        TabPrereq="  Voraussetzungen  "; TabAD="  AD-Vorbereitung  "; TabInstall="  Installation  "
        TabSec="  Sicherheit / TLS  "; TabSpam="  Antispam  "; TabDB="  Datenbanken  "
        TabDAG="  DAG  "; TabRun="  Ausfuehrung und Log  "
        Language="Sprache:"; Ready="Bereit"; Exit="Beenden"
        WaitTitle="Bitte warten..."; WaitText="Bitte warten - System wird ueberprueft..."
        WaitFooter="Diese Pruefung dauert ca. 10-30 Sekunden"
        SplashSysInfo="Lese System-Informationen..."; SplashISO="Suche nach gemounteten Exchange-ISOs..."
        SplashPrereq="Pruefe Windows-Voraussetzungen..."; SplashDomain="Pruefe AD-Domain-Mitgliedschaft..."
        SplashAD="Pruefe Active-Directory (Schema/Org/Domain)..."; SplashExch="Pruefe Exchange-Installation..."
        SplashReboot="Pruefe ausstehenden Neustart..."; SplashDoneOK="FERTIG - System ist vollstaendig vorbereitet!"
        SplashDoneIssues="FERTIG - {0} Punkt(e) zu erledigen"
        PrereqStatus="Status der Voraussetzungen"; PrereqComponent="Komponente"; PrereqState="Status"
        PrereqOptions="Was soll installiert/konfiguriert werden?"; PrereqAction="Aktion"
        PrereqRefresh="Status aktualisieren"; PrereqInstall="Voraussetzungen jetzt installieren"
        PrereqHint="Tipp: Erst 'Status aktualisieren', dann nur fehlende Komponenten installieren."
        AD_Status="Aktueller AD-Status"; AD_Current="Aktuell"; AD_Required="Erforderlich"
        AD_Schema="AD-Schema-Version:"; AD_Org="Exchange-Organisation:"; AD_Dom="Domain-Vorbereitung:"
        AD_User="Aktueller Benutzer:"; AD_Perms="Berechtigungen:"
        AD_Steps="Vorbereitungsschritte"; AD_PrepSchema="1. PrepareSchema (Schema forest-weit)"
        AD_PrepAD="2. PrepareAD (Exchange-Organisation)"; AD_PrepDom="3. Domain-Vorbereitung:"
        AD_AllDoms="Alle Domaenen im Forest (PrepareAllDomains)"; AD_OneDom="Nur eine bestimmte Domaene:"
        AD_WaitMin="Wartezeit nach jedem Schritt (Min):"; AD_WaitHint="(empfohlen: 5 Min fuer kleine, 15+ fuer grosse Forests)"
        AD_StartBtn="AD-Vorbereitung jetzt starten"
        ISO_Source="Exchange ISO-Quelle"; ISO_RbFile="ISO-Datei vom Dateisystem auswaehlen"
        ISO_RbMounted="Bereits gemountetes Laufwerk verwenden (Auto-Erkennung)"
        ISO_FileLbl="ISO-Datei:"; ISO_DriveLbl="Laufwerk:"; ISO_Browse="Durchsuchen..."
        ISO_AutoDetect="Auto-Erkennen"
        Setup_Params="Exchange Setup-Parameter"; Setup_Org="Organisation: *"; Setup_Server="Servername:"
        Setup_InstallPath="Installations-Pfad:"; Setup_Domain="AD-Domaene:"
        Setup_Roles="Server-Rollen: *"; Setup_RoleMailbox="Mailbox-Server (Standard)"
        Setup_RoleEdge="Edge-Transport (DMZ-Server)"; Setup_RoleMgmt="Management-Tools (auto bei Mailbox)"
        Setup_Diag="Diagnostikdaten:"; Setup_DiagText="An Microsoft senden (Standard: AUS)"
        Inst_Options="Installations-Optionen"
        TLS_Title="TLS-Hardening (Microsoft Best Practice)"; TLS_Action="Aktion"
        TLS_Confirm="Ich bestaetige, dass alle Clients TLS 1.2+ unterstuetzen"
        TLS_Apply="TLS-Hardening jetzt anwenden"; TLS_Test="TLS-Status anzeigen"
        SCL_Title="SCL-Schwellwerte (0-9)"; SCL_Reject="SCL Reject (Mail abgelehnt ab):"
        SCL_Delete="SCL Delete (Mail geloescht ab):"; Spam_Filter="Antispam-Filter aktivieren"
        Spam_Apply="Antispam-Konfiguration anwenden"
        DB_Generator="Datenbank-Generator: Praefix + Startnummer + Anzahl"
        DB_Prefix="DB-Praefix:"; DB_Start="Start-Nummer:"; DB_Count="Anzahl DBs:"
        DB_Server="Zielserver:"; DB_Base="DB-Basispfad:"; DB_LogBase="Log-Basispfad:"
        DB_Generate="Konfiguration generieren (Vorschau)"; DB_Clear="Liste leeren"
        DB_Preview="Vorschau / Bearbeitbare Liste:"; DB_CreateNow="Datenbanken jetzt erstellen"
        DAG_Settings="DAG-Grundeinstellungen"; DAG_Name="DAG-Name:"; DAG_Witness="Witness-Server:"
        DAG_WitnessDir="Witness-Verzeichnis:"; DAG_IP="DAG-IP-Adresse(n):"
        DAG_IPHint="(Mehrere IPs mit Komma trennen)"; DAG_IPless="IP-lose DAG (Exchange 2016+ empfohlen)"
        DAG_Members="DAG-Mitglieder (ein Server pro Zeile)"; DAG_Create="DAG erstellen + Mitglieder"
        Run_Info="Live-Output von Setup. Wichtige Meilensteine erscheinen hier mit [SetupLog]."
        Run_SaveCfg="Konfig speichern"; Run_LoadCfg="Konfig laden"; Run_ClearLog="Log leeren"
        Run_OpenLog="ExchangeSetup.log oeffnen"; Run_StartAll=">>>  GESAMTEN PROZESS STARTEN  <<<"
        Yes="Ja"; No="Nein"; OK="OK"; Cancel="Abbrechen"; Error="Fehler"; Info="Info"
        Warning="Warnung"; Confirm="Bestaetigung"
        Opt_PrereqCheck="Voraussetzungspruefung"; Opt_RunPrereq="Voraussetzungen vorab installieren"
        Opt_MountISO="ISO automatisch mounten (falls Datei)"; Opt_DoADPrep="AD-Vorbereitung im Master-Workflow"
        Opt_InstExch="Exchange Server installieren"; Opt_InstSpam="Antispam-Agenten installieren"
        Opt_CfgSpam="Antispam-Filter konfigurieren"; Opt_Verify="Installation verifizieren"
        Opt_TLS="TLS-Hardening anwenden"; Opt_DBs="Postfach-Datenbanken anlegen"
        Opt_DAG="DAG erstellen + Mitglieder"; Opt_Dismount="ISO am Ende automatisch unmounten"
        Opt_Admin="Strikte Admin-Pruefung"; Opt_Continue="Bei Fehlern weiter machen"
        Filt_Content="Content-Filter aktivieren"; Filt_SenderID="Sender-ID-Filter aktivieren"
        Filt_Sender="Sender-Filter aktivieren"; Filt_Recip="Recipient-Filter aktivieren"
        Filt_Reputation="Sender-Reputation aktivieren"
    }
    EN = @{
        AppTitle="Microsoft Exchange SE - Configuration Center"; AppSubtitle="v3.6  |  Rocco Ammon, SVA"
        TabPrereq="  Prerequisites  "; TabAD="  AD Preparation  "; TabInstall="  Installation  "
        TabSec="  Security / TLS  "; TabSpam="  AntiSpam  "; TabDB="  Databases  "
        TabDAG="  DAG  "; TabRun="  Execution and Log  "
        Language="Language:"; Ready="Ready"; Exit="Exit"
        WaitTitle="Please wait..."; WaitText="Please wait - System is being checked..."
        WaitFooter="This check takes about 10-30 seconds"
        SplashSysInfo="Reading system information..."; SplashISO="Searching for mounted Exchange ISOs..."
        SplashPrereq="Checking Windows prerequisites..."; SplashDomain="Checking AD domain membership..."
        SplashAD="Checking Active Directory (Schema/Org/Domain)..."; SplashExch="Checking Exchange installation..."
        SplashReboot="Checking pending reboot..."; SplashDoneOK="DONE - System is fully prepared!"
        SplashDoneIssues="DONE - {0} item(s) to address"
        PrereqStatus="Prerequisite Status"; PrereqComponent="Component"; PrereqState="Status"
        PrereqOptions="What should be installed/configured?"; PrereqAction="Action"
        PrereqRefresh="Refresh status"; PrereqInstall="Install prerequisites now"
        PrereqHint="Tip: First 'Refresh status', then install only missing components."
        AD_Status="Current AD Status"; AD_Current="Current"; AD_Required="Required"
        AD_Schema="AD Schema Version:"; AD_Org="Exchange Organization:"; AD_Dom="Domain Preparation:"
        AD_User="Current User:"; AD_Perms="Permissions:"
        AD_Steps="Preparation Steps"; AD_PrepSchema="1. PrepareSchema (Schema forest-wide)"
        AD_PrepAD="2. PrepareAD (Exchange Organization)"; AD_PrepDom="3. Domain Preparation:"
        AD_AllDoms="All Domains in Forest (PrepareAllDomains)"; AD_OneDom="Specific domain only:"
        AD_WaitMin="Wait time after each step (min):"; AD_WaitHint="(recommended: 5 min for small, 15+ for large forests)"
        AD_StartBtn="Start AD Preparation now"
        ISO_Source="Exchange ISO Source"; ISO_RbFile="Select ISO file from filesystem"
        ISO_RbMounted="Use already mounted drive (Auto-Detection)"
        ISO_FileLbl="ISO file:"; ISO_DriveLbl="Drive:"; ISO_Browse="Browse..."
        ISO_AutoDetect="Auto-Detect"
        Setup_Params="Exchange Setup Parameters"; Setup_Org="Organization: *"; Setup_Server="Server name:"
        Setup_InstallPath="Installation path:"; Setup_Domain="AD Domain:"
        Setup_Roles="Server Roles: *"; Setup_RoleMailbox="Mailbox Server (default)"
        Setup_RoleEdge="Edge Transport (DMZ server)"; Setup_RoleMgmt="Management Tools (auto with Mailbox)"
        Setup_Diag="Diagnostic Data:"; Setup_DiagText="Send to Microsoft (default: OFF)"
        Inst_Options="Installation Options"
        TLS_Title="TLS Hardening (Microsoft Best Practice)"; TLS_Action="Action"
        TLS_Confirm="I confirm all clients support TLS 1.2+"
        TLS_Apply="Apply TLS Hardening now"; TLS_Test="Show TLS status"
        SCL_Title="SCL Thresholds (0-9)"; SCL_Reject="SCL Reject (mail rejected at):"
        SCL_Delete="SCL Delete (mail deleted at):"; Spam_Filter="Enable AntiSpam Filters"
        Spam_Apply="Apply AntiSpam configuration"
        DB_Generator="Database Generator: Prefix + Start Number + Count"
        DB_Prefix="DB Prefix:"; DB_Start="Start Number:"; DB_Count="Number of DBs:"
        DB_Server="Target Server:"; DB_Base="DB Base Path:"; DB_LogBase="Log Base Path:"
        DB_Generate="Generate config (Preview)"; DB_Clear="Clear list"
        DB_Preview="Preview / Editable List:"; DB_CreateNow="Create databases now"
        DAG_Settings="DAG Base Settings"; DAG_Name="DAG Name:"; DAG_Witness="Witness Server:"
        DAG_WitnessDir="Witness Directory:"; DAG_IP="DAG IP Address(es):"
        DAG_IPHint="(Separate multiple IPs with comma)"; DAG_IPless="IP-less DAG (recommended Exchange 2016+)"
        DAG_Members="DAG Members (one server per line)"; DAG_Create="Create DAG + Members"
        Run_Info="Live output from setup. Important milestones appear with [SetupLog]."
        Run_SaveCfg="Save config"; Run_LoadCfg="Load config"; Run_ClearLog="Clear log"
        Run_OpenLog="Open ExchangeSetup.log"; Run_StartAll=">>>  START ENTIRE PROCESS  <<<"
        Yes="Yes"; No="No"; OK="OK"; Cancel="Cancel"; Error="Error"; Info="Info"
        Warning="Warning"; Confirm="Confirmation"
        Opt_PrereqCheck="Prerequisite check"; Opt_RunPrereq="Install prerequisites first"
        Opt_MountISO="Mount ISO automatically (if file)"; Opt_DoADPrep="AD preparation in master workflow"
        Opt_InstExch="Install Exchange Server"; Opt_InstSpam="Install AntiSpam agents"
        Opt_CfgSpam="Configure AntiSpam filters"; Opt_Verify="Verify installation"
        Opt_TLS="Apply TLS hardening"; Opt_DBs="Create mailbox databases"
        Opt_DAG="Create DAG + members"; Opt_Dismount="Dismount ISO at end automatically"
        Opt_Admin="Strict admin check"; Opt_Continue="Continue on errors"
        Filt_Content="Enable Content Filter"; Filt_SenderID="Enable Sender-ID Filter"
        Filt_Sender="Enable Sender Filter"; Filt_Recip="Enable Recipient Filter"
        Filt_Reputation="Enable Sender Reputation"
    }
}

# Auto-detect OS language
function Get-OSLanguage {
    try {
        $culture = (Get-Culture).TwoLetterISOLanguageName
        if ($culture -eq "de") { return "DE" }
        return "EN"
    } catch { return "EN" }
}

if ($ForceLang -and $Global:Texts.ContainsKey($ForceLang.ToUpper())) {
    $Global:CurrentLang = $ForceLang.ToUpper()
} else {
    $Global:CurrentLang = Get-OSLanguage
}

function Get-T {
    param([string]$Key)
    if ($Global:Texts[$Global:CurrentLang].ContainsKey($Key)) {
        return $Global:Texts[$Global:CurrentLang][$Key]
    }
    if ($Global:Texts["EN"].ContainsKey($Key)) {
        return $Global:Texts["EN"][$Key]
    }
    return "[$Key]"
}
#endregion

#region ============================ INIT ============================
try {
    foreach ($p in @($Global:LogPath, $Global:ConfigPath, $Global:DefaultTempPath)) {
        if (-not (Test-Path $p)) { New-Item -Path $p -ItemType Directory -Force | Out-Null }
    }
} catch {
    Write-Host "Init-Fehler: $_" -ForegroundColor Red
    exit 1
}

if ($psISE -or $Host.Name -match 'ISE') {
    [System.Windows.Forms.MessageBox]::Show("Bitte NICHT in der ISE ausfuehren!`r`n`r`nRechtsklick auf .ps1 -> 'Mit PowerShell ausfuehren'", "ISE-Warnung",'OK','Warning')
}
#endregion

#region ============================ SPLASH-SCREEN ============================
function Show-SplashScreen {
    $Global:SplashForm = New-Object System.Windows.Forms.Form
    $Global:SplashForm.Text = (Get-T "WaitTitle")
    $Global:SplashForm.Size = New-Object System.Drawing.Size(500, 220)
    $Global:SplashForm.StartPosition = "CenterScreen"
    $Global:SplashForm.FormBorderStyle = "FixedDialog"
    $Global:SplashForm.ControlBox = $false
    $Global:SplashForm.TopMost = $true
    $Global:SplashForm.BackColor = $Global:ColorPanel
    $Global:SplashForm.ShowInTaskbar = $false

    $hdr = New-Object System.Windows.Forms.Panel
    $hdr.Size = New-Object System.Drawing.Size(500, 50); $hdr.Location = New-Object System.Drawing.Point(0,0)
    $hdr.BackColor = $Global:ColorAccent
    $Global:SplashForm.Controls.Add($hdr)

    $lblHdr = New-Object System.Windows.Forms.Label
    $lblHdr.Text = "  " + (Get-T "AppTitle")
    $lblHdr.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $lblHdr.ForeColor = [System.Drawing.Color]::White
    $lblHdr.Location = New-Object System.Drawing.Point(15,12); $lblHdr.Size = New-Object System.Drawing.Size(475,28)
    $hdr.Controls.Add($lblHdr)

    $lblWait = New-Object System.Windows.Forms.Label
    $lblWait.Text = (Get-T "WaitText")
    $lblWait.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $lblWait.ForeColor = $Global:ColorText
    $lblWait.Location = New-Object System.Drawing.Point(20,70); $lblWait.Size = New-Object System.Drawing.Size(460,25)
    $Global:SplashForm.Controls.Add($lblWait)

    $Global:SplashStatus = New-Object System.Windows.Forms.Label
    $Global:SplashStatus.Text = "..."
    $Global:SplashStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $Global:SplashStatus.ForeColor = $Global:ColorTextDim
    $Global:SplashStatus.Location = New-Object System.Drawing.Point(20,100); $Global:SplashStatus.Size = New-Object System.Drawing.Size(460,22)
    $Global:SplashForm.Controls.Add($Global:SplashStatus)

    $Global:SplashProgress = New-Object System.Windows.Forms.ProgressBar
    $Global:SplashProgress.Location = New-Object System.Drawing.Point(20,130); $Global:SplashProgress.Size = New-Object System.Drawing.Size(460,20)
    $Global:SplashProgress.Style = "Marquee"; $Global:SplashProgress.MarqueeAnimationSpeed = 30
    $Global:SplashForm.Controls.Add($Global:SplashProgress)

    $lblFoot = New-Object System.Windows.Forms.Label
    $lblFoot.Text = (Get-T "WaitFooter")
    $lblFoot.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)
    $lblFoot.ForeColor = $Global:ColorTextDim
    $lblFoot.Location = New-Object System.Drawing.Point(20,160); $lblFoot.Size = New-Object System.Drawing.Size(460,18)
    $Global:SplashForm.Controls.Add($lblFoot)

    $Global:SplashForm.Show(); $Global:SplashForm.Refresh()
    [System.Windows.Forms.Application]::DoEvents()
}

function Update-SplashStatus {
    param([string]$Text)
    if ($Global:SplashStatus) {
        $Global:SplashStatus.Text = $Text
        $Global:SplashStatus.Refresh()
        [System.Windows.Forms.Application]::DoEvents()
    }
}

function Close-SplashScreen {
    if ($Global:SplashForm) {
        try { $Global:SplashForm.Close(); $Global:SplashForm.Dispose() } catch {}
        $Global:SplashForm = $null
    }
}
#endregion

#region ============================ LOGGING ============================
function Write-Log {
    param([Parameter(Mandatory)][string]$Message,[ValidateSet("INFO","WARNING","ERROR","SUCCESS")][string]$Level="INFO")
    try {
        $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $line = "[$ts] [$Level] $Message"
        Add-Content -Path $Global:LogFile -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($Global:LogTextBox) {
            $color = switch ($Level) {
                "ERROR" { $Global:ColorError } "WARNING" { $Global:ColorWarning }
                "SUCCESS" { $Global:ColorAccent2 } default { $Global:ColorText }
            }
            $Global:LogTextBox.SelectionStart = $Global:LogTextBox.TextLength
            $Global:LogTextBox.SelectionLength = 0
            $Global:LogTextBox.SelectionColor = $color
            $Global:LogTextBox.AppendText("$line`r`n")
            $Global:LogTextBox.ScrollToCaret()
        }
        if ($Global:StatusLabel) {
            $Global:StatusLabel.Text = "  [$Level] $Message"
            $col2 = switch ($Level) {
                "ERROR" { $Global:ColorError } "WARNING" { $Global:ColorWarning }
                "SUCCESS" { $Global:ColorAccent2 } default { $Global:ColorText }
            }
            $Global:StatusLabel.ForeColor = $col2
        }
        try { [System.Windows.Forms.Application]::DoEvents() } catch {}
    } catch {}
}
#endregion

#region ============================ ISO-AUTOERKENNUNG ============================
function Find-MountedExchangeISO {
    $found = @()
    try {
        $letters = [char[]](65..90) | ForEach-Object { [string]$_ }
        foreach ($letter in $letters) {
            $driveLetter = "${letter}:"; $rootPath = "${letter}:\"; $setupPath = "${letter}:\Setup.exe"
            if (-not (Test-Path $rootPath -ErrorAction SilentlyContinue)) { continue }
            $volumeName = $null
            try { $vol = Get-Volume -DriveLetter $letter -ErrorAction SilentlyContinue
                  if ($vol -and $vol.FileSystemLabel) { $volumeName = $vol.FileSystemLabel } } catch {}
            if (-not $volumeName) {
                try { $logical = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$driveLetter'" -ErrorAction SilentlyContinue
                      if ($logical -and $logical.VolumeName) { $volumeName = $logical.VolumeName } } catch {}
            }
            if (-not $volumeName) { $volumeName = "(no label)" }
            $hasSetup = Test-Path $setupPath -ErrorAction SilentlyContinue
            $isExchange = $false; $reason = ""
            if ($volumeName -match '(?i)EXCHANGE') { $isExchange = $true; $reason = "Label '$volumeName'" }
            if (-not $isExchange -and $hasSetup) {
                foreach ($ind in @("Setup\ServerRoles","Setup\Data","UCMARedist")) {
                    if (Test-Path (Join-Path $rootPath $ind) -ErrorAction SilentlyContinue) {
                        $isExchange = $true; $reason = "Folder '$ind'"; break
                    }
                }
            }
            if ($isExchange) {
                $found += [PSCustomObject]@{
                    DriveLetter = $driveLetter; VolumeName = $volumeName
                    SetupPath = $setupPath
                    Display = ("{0}  ({1})  -  {2}" -f $driveLetter, $volumeName, $reason)
                }
            }
        }
    } catch { Write-Log ("ISO search error: " + $_) -Level ERROR }
    return $found
}
#endregion

#region ============================ TLS HARDENING ============================
function Set-TLSHardening {
    try {
        Write-Log "Starting TLS hardening (Microsoft Best Practice)..." -Level INFO
        $protocols = @{ "SSL 2.0"=$false; "SSL 3.0"=$false; "TLS 1.0"=$false; "TLS 1.1"=$false; "TLS 1.2"=$true; "TLS 1.3"=$true }
        $base = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols"
        foreach ($proto in $protocols.Keys) {
            $enabled = $protocols[$proto]
            foreach ($side in @("Server","Client")) {
                $sidePath = Join-Path (Join-Path $base $proto) $side
                if (-not (Test-Path $sidePath)) { New-Item -Path $sidePath -Force | Out-Null }
                if ($enabled) {
                    New-ItemProperty -Path $sidePath -Name "Enabled" -Value 0xFFFFFFFF -PropertyType DWord -Force | Out-Null
                    New-ItemProperty -Path $sidePath -Name "DisabledByDefault" -Value 0 -PropertyType DWord -Force | Out-Null
                    $statusText = "ENABLED"
                } else {
                    New-ItemProperty -Path $sidePath -Name "Enabled" -Value 0 -PropertyType DWord -Force | Out-Null
                    New-ItemProperty -Path $sidePath -Name "DisabledByDefault" -Value 1 -PropertyType DWord -Force | Out-Null
                    $statusText = "DISABLED"
                }
                Write-Log ("  $proto $side : $statusText") -Level INFO
            }
        }
        $netPaths = @(
            "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319",
            "HKLM:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727"
        )
        foreach ($np in $netPaths) {
            if (Test-Path $np) {
                New-ItemProperty -Path $np -Name "SystemDefaultTlsVersions" -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -Path $np -Name "SchUseStrongCrypto" -Value 1 -PropertyType DWord -Force | Out-Null
            }
        }
        $weakCiphers = @("RC4 40/128","RC4 56/128","RC4 64/128","RC4 128/128","DES 56/56","NULL","Triple DES 168")
        $cipherBase = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers"
        foreach ($c in $weakCiphers) {
            $cp = Join-Path $cipherBase $c
            if (-not (Test-Path $cp)) { New-Item -Path $cp -Force | Out-Null }
            New-ItemProperty -Path $cp -Name "Enabled" -Value 0 -PropertyType DWord -Force | Out-Null
        }
        Write-Log "TLS hardening complete - REBOOT required!" -Level SUCCESS
        return $true
    } catch { Write-Log ("TLS error: " + $_) -Level ERROR; return $false }
}
#endregion

#region ============================ PREREQ-FUNKTIONEN ============================
function Test-VCRedistInstalled {
    param([string]$DisplayName)
    foreach ($key in @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*","HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")) {
        if (Get-ItemProperty $key -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*$DisplayName*" }) { return $true }
    }
    return $false
}
function Test-DotNet48 {
    try { $rel = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue).Release
          return ($rel -ge 528040) } catch { return $false }
}
function Test-URLRewrite { return (Test-Path "$env:SystemRoot\System32\inetsrv\rewrite.dll") }
function Test-UCMA {
    foreach ($key in @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*","HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")) {
        if (Get-ItemProperty $key -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*Unified Communications Managed API 4.0*" }) { return $true }
    }
    return $false
}

function Get-PrerequisiteStatus {
    $features = @(
        "Server-Media-Foundation","NET-Framework-45-Features","RPC-over-HTTP-proxy",
        "RSAT-Clustering","RSAT-Clustering-CmdInterface","RSAT-Clustering-Mgmt",
        "RSAT-Clustering-PowerShell","WAS-Process-Model","Web-Asp-Net45","Web-Basic-Auth",
        "Web-Client-Auth","Web-Digest-Auth","Web-Dir-Browsing","Web-Dyn-Compression",
        "Web-Http-Errors","Web-Http-Logging","Web-Http-Redirect","Web-Http-Tracing",
        "Web-ISAPI-Ext","Web-ISAPI-Filter","Web-Lgcy-Mgmt-Console","Web-Metabase",
        "Web-Mgmt-Console","Web-Mgmt-Service","Web-Net-Ext45","Web-Request-Monitor",
        "Web-Server","Web-Stat-Compression","Web-Static-Content","Web-Windows-Auth",
        "Web-WMI","Windows-Identity-Foundation","RSAT-ADDS"
    )
    $missing = @()
    try {
        foreach ($f in $features) {
            $st = Get-WindowsFeature -Name $f -ErrorAction SilentlyContinue
            if ($st -and -not $st.Installed) { $missing += $f }
        }
    } catch {}
    $smb1Enabled = $false
    try {
        $smb1 = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue
        if ($smb1 -and $smb1.State -eq "Enabled") { $smb1Enabled = $true }
    } catch {}
    return [PSCustomObject]@{
        DotNet48=Test-DotNet48; VC2012=(Test-VCRedistInstalled "Visual C++ 2012 x64")
        VC2013=(Test-VCRedistInstalled "Visual C++ 2013 x64"); URLRewrite=Test-URLRewrite
        UCMA=Test-UCMA; Features=$features; MissingFeatures=$missing
        FeaturesOK=($missing.Count -eq 0); SMB1Enabled=$smb1Enabled
    }
}

function Install-PrerequisiteSoftware {
    param(
        [bool]$InstallDotNet=$true,[bool]$InstallVC2012=$true,[bool]$InstallVC2013=$true,
        [bool]$InstallURLRewrite=$true,[bool]$InstallUCMA=$true,[bool]$InstallFeatures=$true,
        [bool]$DisableSMB1=$true,[bool]$OptimizePageFile=$true,[bool]$SetHighPerformance=$true
    )
    Write-Log "==============================================" -Level INFO
    Write-Log " EXCHANGE PREREQUISITES INSTALLATION" -Level INFO
    Write-Log "==============================================" -Level INFO
    $tempDir = $Global:DefaultTempPath
    if (-not (Test-Path $tempDir)) { New-Item -Path $tempDir -ItemType Directory -Force | Out-Null }

    if ($InstallDotNet) {
        if (Test-DotNet48) { Write-Log "[1/8] .NET 4.8+ already installed" -Level SUCCESS }
        else {
            Write-Log "[1/8] Installing .NET 4.8..." -Level INFO
            try {
                $url = "https://download.microsoft.com/download/2/4/8/24892799-1635-47E3-AAD7-9842E59990C3/ndp48-web.exe"
                $file = Join-Path $tempDir "ndp48-web.exe"
                if (-not (Test-Path $file)) {
                    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                    Invoke-WebRequest -Uri $url -OutFile $file -UseBasicParsing
                }
                Start-Process -FilePath $file -ArgumentList "/quiet /norestart" -Wait
                Write-Log "  .NET 4.8 installed" -Level SUCCESS
            } catch { Write-Log ("  Error: " + $_) -Level ERROR }
        }
    }
    if ($InstallVC2012) {
        if (Test-VCRedistInstalled "Visual C++ 2012 x64") { Write-Log "[2/8] VC++ 2012 already installed" -Level SUCCESS }
        else {
            Write-Log "[2/8] Installing VC++ 2012 x64..." -Level INFO
            try {
                $url = "https://download.microsoft.com/download/1/6/b/16b06f60-3b20-4ff2-b699-5e9b7962f9ae/VSU_4/vcredist_x64.exe"
                $file = Join-Path $tempDir "vcredist2012_x64.exe"
                if (-not (Test-Path $file)) { Invoke-WebRequest -Uri $url -OutFile $file -UseBasicParsing }
                Start-Process -FilePath $file -ArgumentList "/install /quiet /norestart" -Wait
                Write-Log "  VC++ 2012 installed" -Level SUCCESS
            } catch { Write-Log ("  Error: " + $_) -Level ERROR }
        }
    }
    if ($InstallVC2013) {
        if (Test-VCRedistInstalled "Visual C++ 2013 x64") { Write-Log "[3/8] VC++ 2013 already installed" -Level SUCCESS }
        else {
            Write-Log "[3/8] Installing VC++ 2013 x64..." -Level INFO
            try {
                $url = "https://download.visualstudio.microsoft.com/download/pr/10912041/cee5d6bca2ddbcd039da727bf4acb48a/vcredist_x64.exe"
                $file = Join-Path $tempDir "vcredist2013_x64.exe"
                if (-not (Test-Path $file)) { Invoke-WebRequest -Uri $url -OutFile $file -UseBasicParsing }
                Start-Process -FilePath $file -ArgumentList "/install /quiet /norestart" -Wait
                Write-Log "  VC++ 2013 installed" -Level SUCCESS
            } catch { Write-Log ("  Error: " + $_) -Level ERROR }
        }
    }
    if ($InstallURLRewrite) {
        if (Test-URLRewrite) { Write-Log "[4/8] URL Rewrite already installed" -Level SUCCESS }
        else {
            Write-Log "[4/8] Installing URL Rewrite 2.1..." -Level INFO
            try {
                $url = "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi"
                $file = Join-Path $tempDir "rewrite_2.1_x64.msi"
                if (-not (Test-Path $file)) { Invoke-WebRequest -Uri $url -OutFile $file -UseBasicParsing }
                Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$file`" /quiet /norestart" -Wait
                Write-Log "  URL Rewrite installed" -Level SUCCESS
            } catch { Write-Log ("  Error: " + $_) -Level ERROR }
        }
    }
    if ($InstallUCMA) {
        if (Test-UCMA) { Write-Log "[5/8] UCMA 4.0 already installed" -Level SUCCESS }
        else {
            Write-Log "[5/8] Installing UCMA 4.0..." -Level INFO
            $ucmaInst = $null
            foreach ($iso in $Global:DetectedISOs) {
                $cand = Join-Path (Split-Path $iso.SetupPath) "UCMARedist\Setup.exe"
                if (Test-Path $cand) { $ucmaInst = $cand; break }
            }
            if ($ucmaInst) {
                try {
                    Start-Process -FilePath $ucmaInst -ArgumentList "/quiet /norestart" -Wait
                    Write-Log "  UCMA 4.0 installed" -Level SUCCESS
                } catch { Write-Log ("  Error: " + $_) -Level ERROR }
            } else { Write-Log "  UCMA installer not found on ISO" -Level WARNING }
        }
    }
    if ($InstallFeatures) {
        Write-Log "[6/8] Checking Windows features..." -Level INFO
        $status = Get-PrerequisiteStatus
        if ($status.FeaturesOK) { Write-Log "  All features already installed" -Level SUCCESS }
        else {
            $missingArr = @($status.MissingFeatures)
            Write-Log ("  " + $missingArr.Count + " feature(s) missing - installing as background job") -Level INFO
            try {
                $job = Start-Job -Name "ExchangeFeatures" -ScriptBlock {
                    param($features)
                    $ProgressPreference='SilentlyContinue'; $WarningPreference='SilentlyContinue'
                    $InformationPreference='SilentlyContinue'
                    Import-Module ServerManager -ErrorAction SilentlyContinue
                    $r = Install-WindowsFeature -Name $features -ErrorAction Continue -WarningAction SilentlyContinue 6>$null 4>$null 3>$null 5>$null
                    return @{ Success=$r.Success; RestartNeeded=$r.RestartNeeded }
                } -ArgumentList (,$missingArr)
                $startTime = Get-Date; $lastHB = Get-Date
                while ($job.State -eq 'Running') {
                    try { [System.Windows.Forms.Application]::DoEvents() } catch {}
                    Start-Sleep -Milliseconds 1000
                    if (((Get-Date) - $lastHB).TotalSeconds -ge 30) {
                        $el = ((Get-Date) - $startTime).ToString("hh\:mm\:ss")
                        Write-Log ("    ... features installing | runtime: $el") -Level INFO
                        $lastHB = Get-Date
                    }
                    if (((Get-Date) - $startTime).TotalMinutes -gt 30) {
                        Stop-Job $job; break
                    }
                }
                if ($job.State -eq 'Completed') {
                    $jr = Receive-Job $job
                    if ($jr.Success) { Write-Log "  Windows features installed" -Level SUCCESS }
                    if ($jr.RestartNeeded -eq "Yes") { Write-Log "  >>> RESTART REQUIRED <<<" -Level WARNING }
                }
                Remove-Job $job -Force -ErrorAction SilentlyContinue
            } catch { Write-Log ("  Error: " + $_) -Level ERROR }
        }
    }
    if ($DisableSMB1) {
        Write-Log "[7/8] SMB1 deactivation..." -Level INFO
        try {
            $smb1 = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue
            if ($smb1 -and $smb1.State -eq "Enabled") {
                Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction Stop | Out-Null
                Write-Log "  SMB1 disabled" -Level SUCCESS
            } else { Write-Log "  SMB1 already disabled" -Level SUCCESS }
        } catch { Write-Log ("  Error: " + $_) -Level WARNING }
    }
    if ($SetHighPerformance) {
        Write-Log "[8/8] Power plan + pagefile..." -Level INFO
        try { powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>&1 | Out-Null; Write-Log "  High Performance active" -Level SUCCESS } catch {}
        if ($OptimizePageFile) {
            try {
                $ramMB = [int]((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1MB)
                $pf = $ramMB + 10
                $cs = Get-CimInstance Win32_ComputerSystem
                if ($cs.AutomaticManagedPagefile) {
                    $cs | Set-CimInstance -Property @{AutomaticManagedPagefile=$false} -ErrorAction SilentlyContinue
                }
                $pfo = Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue
                if ($pfo) {
                    $pfo | Set-CimInstance -Property @{InitialSize=$pf; MaximumSize=$pf} -ErrorAction SilentlyContinue
                    Write-Log ("  Pagefile: " + $pf + " MB") -Level SUCCESS
                }
            } catch {}
        }
    }
    Write-Log "==============================================" -Level INFO
    Write-Log " PREREQUISITES COMPLETE" -Level SUCCESS
    Write-Log "==============================================" -Level INFO
}
#endregion
#region ============================ EXCHANGE-FUNKTIONEN ============================
function Import-ExchangeManagementShell {
    try {
        # Bereits geladen?
        if (Get-Command Get-MailboxDatabase -ErrorAction SilentlyContinue) {
            return $true
        }

        # Methode 1: RemoteExchange.ps1 (Standard)
        if (Test-Path $Global:RemoteExchangeScript) {
            Write-Log "Loading via RemoteExchange.ps1..." -Level INFO
            try {
                . $Global:RemoteExchangeScript
                Connect-ExchangeServer -auto -ClientApplication:ManagementShell -ErrorAction Stop
                if (Get-Command Get-MailboxDatabase -ErrorAction SilentlyContinue) {
                    Write-Log "Exchange Shell loaded (RemoteExchange.ps1)" -Level SUCCESS
                    return $true
                }
            } catch {
                Write-Log ("RemoteExchange.ps1 failed: " + $_) -Level WARNING
            }
        }

        # Methode 2: SnapIn (klassisch)
        try {
            Write-Log "Loading via PSSnapin..." -Level INFO
            $snap = Get-PSSnapin -Registered -Name "Microsoft.Exchange.Management.PowerShell.E2010" -ErrorAction SilentlyContinue
            if (-not $snap) {
                $snap = Get-PSSnapin -Registered -Name "Microsoft.Exchange.Management.PowerShell.SnapIn" -ErrorAction SilentlyContinue
            }
            if ($snap) {
                Add-PSSnapin -Name $snap.Name -ErrorAction Stop
                if (Get-Command Get-MailboxDatabase -ErrorAction SilentlyContinue) {
                    Write-Log "Exchange Shell loaded (PSSnapin)" -Level SUCCESS
                    return $true
                }
            }
        } catch {
            Write-Log ("PSSnapin failed: " + $_) -Level WARNING
        }

        # Methode 3: Modul (Exchange SE)
        try {
            Write-Log "Loading via Module..." -Level INFO
            $exchModule = Get-Module -ListAvailable -Name "Microsoft.Exchange.Management.PowerShell*" -ErrorAction SilentlyContinue
            if ($exchModule) {
                Import-Module ($exchModule | Select-Object -First 1).Name -ErrorAction Stop
                if (Get-Command Get-MailboxDatabase -ErrorAction SilentlyContinue) {
                    Write-Log "Exchange Shell loaded (Module)" -Level SUCCESS
                    return $true
                }
            }
        } catch {
            Write-Log ("Module load failed: " + $_) -Level WARNING
        }

        Write-Log "Exchange Management Shell could not be loaded" -Level ERROR
        Write-Log "Make sure Exchange is fully installed and a reboot has occurred." -Level WARNING
        return $false
    }
    catch {
        Write-Log ("Import error: " + $_) -Level ERROR
        return $false
    }
}

function Test-ExchangePrerequisites {
    param([string]$ExchangeISOPath)
    $errors = @()
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        if ($os.Caption -notlike "*Windows Server*") { $errors += "Not Windows Server" }
        $ram = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        if ($ram -lt 8) { $errors += "RAM < 8 GB ($ram GB)" }
        $sysDrive = Get-PSDrive -Name ($env:SystemDrive.Replace(":",""))
        $freeGB = [math]::Round($sysDrive.Free / 1GB, 2)
        if ($freeGB -lt 30) { $errors += "Free space < 30 GB" }
        if ($ExchangeISOPath -and -not (Test-Path $ExchangeISOPath)) { $errors += "ISO not found: $ExchangeISOPath" }
        if ($errors.Count -gt 0) {
            foreach ($e in $errors) { Write-Log ("  - " + $e) -Level ERROR }
            return $false
        }
        Write-Log "Prerequisites met" -Level SUCCESS
        return $true
    } catch { Write-Log ("Error: " + $_) -Level ERROR; return $false }
}

function Mount-ExchangeISO {
    param([Parameter(Mandatory)][string]$ISOPath)
    try {
        $mr = Mount-DiskImage -ImagePath $ISOPath -PassThru
        Start-Sleep -Seconds 2
        $drive = ($mr | Get-Volume).DriveLetter
        if ($drive) { return ("${drive}:\Setup.exe") }
        throw "Drive letter not detected"
    } catch { Write-Log ("Mount error: " + $_) -Level ERROR; return $null }
}

function Dismount-ExchangeISO {
    param([Parameter(Mandatory)][string]$ISOPath)
    try { Dismount-DiskImage -ImagePath $ISOPath -ErrorAction Stop } catch {}
}

function Invoke-ResponsiveProcess {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$Arguments,
        [string]$LogPrefix="Setup",[int]$HeartbeatSec=60,
        [string]$ExchangeSetupLog=$Global:ExchangeSetupLog,[bool]$TailExchangeLog=$true
    )
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $FilePath; $psi.Arguments = ($Arguments -join ' ')
        $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true; $psi.WindowStyle = 'Hidden'
        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $psi
        $logStartPos = 0L
        if ($TailExchangeLog -and (Test-Path $ExchangeSetupLog)) {
            try { $logStartPos = (Get-Item $ExchangeSetupLog).Length } catch {}
        }
        [void]$proc.Start()
        Write-Log ("PID: " + $proc.Id + " started") -Level INFO
        Write-Log "----------- LIVE-MILESTONES -----------" -Level INFO
        $startTime = Get-Date; $lastHB = Get-Date; $lastLogPos = $logStartPos; $linesShown = 0; $lastTask = ""
        $important = @(
            @{Pattern='Beginning processing'; Level='INFO'},
            @{Pattern='Ending processing'; Level='SUCCESS'},
            @{Pattern='Setup is running'; Level='INFO'},
            @{Pattern='Successfully (extended|installed|configured|prepared|added)'; Level='SUCCESS'},
            @{Pattern='Schema upgrade (started|completed)'; Level='INFO'},
            @{Pattern='Importing schema file'; Level='INFO'},
            @{Pattern='Step \d+ of \d+'; Level='INFO'},
            @{Pattern='Mailbox role:'; Level='INFO'},
            @{Pattern='is being prepared'; Level='INFO'},
            @{Pattern='Configuring Microsoft Exchange'; Level='INFO'},
            @{Pattern='Setup completed successfully'; Level='SUCCESS'},
            @{Pattern='has completed'; Level='SUCCESS'},
            @{Pattern='Restart .{0,30}required'; Level='WARNING'},
            @{Pattern='Updating Schema'; Level='INFO'}
        )
        $errPatt = @('\[ERROR\]','Setup encountered an error','A fatal error','Setup cannot continue','FAILED')
        $warnPatt = @('\[WARNING\]','recommendation:','is not recommended')

        while (-not $proc.HasExited) {
            try { [System.Windows.Forms.Application]::DoEvents() } catch {}
            Start-Sleep -Milliseconds 800
            if ($TailExchangeLog -and (Test-Path $ExchangeSetupLog)) {
                try {
                    $fi = Get-Item $ExchangeSetupLog -ErrorAction Stop
                    if ($fi.Length -gt $lastLogPos) {
                        $fs = [System.IO.File]::Open($ExchangeSetupLog,'Open','Read','ReadWrite')
                        $fs.Seek($lastLogPos,'Begin') | Out-Null
                        $sr = New-Object System.IO.StreamReader($fs)
                        while (-not $sr.EndOfStream) {
                            $line = $sr.ReadLine()
                            if (-not $line) { continue }
                            $level = $null
                            foreach ($pat in $errPatt) { if ($line -match $pat) { $level = "ERROR"; break } }
                            if (-not $level) { foreach ($pat in $warnPatt) { if ($line -match $pat) { $level = "WARNING"; break } } }
                            if (-not $level) { foreach ($pat in $important) { if ($line -match $pat.Pattern) { $level = $pat.Level; break } } }
                            if (-not $level) { continue }
                            $clean = $line -replace '^\[\d{2}[\./]\d{2}[\./]\d{4}\s+\d{2}:\d{2}:\d{2}\.\d+\]\s*\[\d+\]\s*','' -replace '^\[\d{2}[\./]\d{2}[\./]\d{4}\s+\d{2}:\d{2}:\d{2}\.\d+\]\s*',''
                            $short = $clean.Trim()
                            if ($short.Length -gt 200) { $short = $short.Substring(0,200) + "..." }
                            if ($short -match "Beginning processing (\w+\s*\w*)") {
                                $task = $matches[1]
                                if ($task -ne $lastTask) {
                                    Write-Log "" -Level INFO
                                    Write-Log (">>> START: " + $task) -Level INFO
                                    $lastTask = $task; $linesShown++
                                    continue
                                }
                            }
                            if ($short -match "Ending processing (\w+\s*\w*)") {
                                Write-Log ("<<< DONE: " + $matches[1]) -Level SUCCESS
                                Write-Log "" -Level INFO; $linesShown++; continue
                            }
                            Write-Log ("    " + $short) -Level $level
                            $linesShown++
                        }
                        $lastLogPos = $fs.Position
                        $sr.Close(); $fs.Close()
                    }
                } catch {}
            }
            if (((Get-Date) - $lastHB).TotalSeconds -ge $HeartbeatSec) {
                $el = ((Get-Date) - $startTime).ToString("hh\:mm\:ss")
                Write-Log ("  ... $LogPrefix running | runtime: $el | milestones: $linesShown") -Level INFO
                $lastHB = Get-Date
            }
        }
        Start-Sleep -Milliseconds 1000
        Write-Log "----------- DONE -----------" -Level INFO
        $tt = ((Get-Date) - $startTime).ToString("hh\:mm\:ss")
        $lvl = if ($proc.ExitCode -eq 0) { "SUCCESS" } else { "ERROR" }
        Write-Log ("Exit code: " + $proc.ExitCode + " | runtime: " + $tt) -Level $lvl
        return $proc.ExitCode
    } catch { Write-Log ("Error: " + $_) -Level ERROR; return -1 }
}

function Install-ExchangeServer {
    param(
        [Parameter(Mandatory)][string]$SetupPath,
        [Parameter(Mandatory)][string]$OrgName,
        [string]$Roles="Mailbox",[bool]$IncludeManagementTools=$true,
        [bool]$AcceptDiagnosticData=$false,[string]$TargetDir=""
    )
    try {
        # Pending Reboot check
        $rebootPending = $false
        if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") { $rebootPending = $true }
        if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") { $rebootPending = $true }
        if ($rebootPending) {
            Write-Log "REBOOT PENDING - Setup will fail. Please restart first!" -Level ERROR
            return $false
        }

        # Watermark from previous attempt?
        $setupMode = "Install"
        $exchSetupKey = "HKLM:\SOFTWARE\Microsoft\ExchangeServer\v15\Setup"
        if (Test-Path $exchSetupKey) {
            $setupState = Get-ItemProperty $exchSetupKey -ErrorAction SilentlyContinue
            $watermark = $null
            try { $watermark = $setupState.Watermark } catch {}
            if ($watermark) {
                Write-Log "Exchange watermark detected - switching to RecoverServer mode" -Level WARNING
                $setupMode = "RecoverServer"
            }
        }

        # Check existing org
        Write-Log "Checking for existing Exchange organization..." -Level INFO
        $existingOrg = $null
        try {
            $rootDSE = [ADSI]"LDAP://RootDSE"
            $configNC = $rootDSE.Properties["configurationNamingContext"][0]
            $searcher = New-Object System.DirectoryServices.DirectorySearcher
            $searcher.SearchRoot = [ADSI]("LDAP://CN=Microsoft Exchange,CN=Services," + $configNC)
            $searcher.Filter = "(objectClass=msExchOrganizationContainer)"
            $searcher.PropertiesToLoad.Add("cn") | Out-Null
            $searcher.SearchScope = "OneLevel"
            $r = $searcher.FindOne()
            if ($r -and $r.Properties["cn"].Count -gt 0) {
                $existingOrg = "$($r.Properties['cn'][0])"
                Write-Log ("  Existing organization: '" + $existingOrg + "'") -Level INFO
            }
        } catch {}

        $arguments = @("/Mode:$setupMode")

        if ($setupMode -eq "Install") {
            $rolesList = @()
            foreach ($r in ($Roles -split ',')) {
                $r = $r.Trim()
                if ($r) { $rolesList += $r }
            }
            if ($rolesList.Count -eq 0) {
                Write-Log "ERROR: No role selected!" -Level ERROR
                return $false
            }
            $arguments += "/Role:$($rolesList -join ',')"
            Write-Log ("Roles to install: " + ($rolesList -join ',')) -Level INFO

            if (-not $existingOrg) {
                $arguments += "/OrganizationName:$OrgName"
                Write-Log ("  Fresh install - org '" + $OrgName + "' will be created") -Level INFO
            }
        } else {
            Write-Log "RecoverServer mode - role and OrgName not needed" -Level INFO
        }

        if ($AcceptDiagnosticData) {
            $arguments += "/IAcceptExchangeServerLicenseTerms_DiagnosticDataON"
        } else {
            $arguments += "/IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF"
        }
        $arguments += "/InstallWindowsComponents"
        if ($TargetDir -and $setupMode -eq "Install") { $arguments += "/TargetDir:`"$TargetDir`"" }

        Write-Log "Starting Exchange Setup (60-90 min)..." -Level INFO
        Write-Log ("Arguments: " + ($arguments -join ' ')) -Level INFO

        $exitCode = Invoke-ResponsiveProcess -FilePath $SetupPath -Arguments $arguments -LogPrefix "Exchange-Setup" -HeartbeatSec 60
        if ($exitCode -eq 0) { Write-Log "Exchange installed successfully!" -Level SUCCESS; return $true }
        Write-Log ("Setup failed with exit code: " + $exitCode) -Level ERROR
        Write-Log "Check details in: C:\ExchangeSetupLogs\ExchangeSetup.log" -Level WARNING
        return $false
    } catch { Write-Log ("Error: " + $_) -Level ERROR; return $false }
}

function Install-AntiSpamAgents {
    param([string]$InstallPath = $Global:DefaultInstallPath)
    try {
        $script = Join-Path $InstallPath "Scripts\Install-AntiSpamAgents.ps1"
        if (-not (Test-Path $script)) {
            Write-Log ("AntiSpam script not found: " + $script) -Level ERROR
            Write-Log "Make sure Exchange is fully installed first!" -Level WARNING
            return $false
        }

        # WICHTIG: Exchange Management Shell MUSS geladen sein,
        # da das Script intern Get-TransportService etc. verwendet
        Write-Log "Loading Exchange Management Shell..." -Level INFO
        if (-not (Import-ExchangeManagementShell)) {
            Write-Log "Exchange Management Shell could not be loaded - is Exchange installed?" -Level ERROR
            return $false
        }

        # Sicherheitspruefung: Get-TransportService verfuegbar?
        if (-not (Get-Command Get-TransportService -ErrorAction SilentlyContinue)) {
            Write-Log "Get-TransportService not available - Exchange Shell not properly loaded" -Level ERROR
            return $false
        }

        # Server-Name ermitteln
        $serverName = $env:COMPUTERNAME
        Write-Log ("Installing AntiSpam agents on server: " + $serverName) -Level INFO

        # AntiSpam-Script ausfuehren
        try {
            & $script
            Write-Log "AntiSpam-Script executed" -Level SUCCESS
        } catch {
            Write-Log ("Script execution error: " + $_) -Level WARNING
        }

        # MSExchangeTransport neustarten - nur wenn Service existiert
        $transportSvc = Get-Service -Name "MSExchangeTransport" -ErrorAction SilentlyContinue
        if ($transportSvc) {
            Write-Log "Restarting MSExchangeTransport service..." -Level INFO
            try {
                Restart-Service -Name MSExchangeTransport -Force -ErrorAction Stop
                Write-Log "MSExchangeTransport restarted" -Level SUCCESS
            } catch {
                Write-Log ("Service restart warning: " + $_) -Level WARNING
            }
        } else {
            Write-Log "MSExchangeTransport service not found - manual restart required" -Level WARNING
        }

        # Verifikation: Welche AntiSpam-Agenten sind aktiv?
        try {
            Start-Sleep -Seconds 3
            $agents = Get-TransportAgent -ErrorAction SilentlyContinue
            if ($agents) {
                Write-Log "Configured Transport Agents:" -Level INFO
                foreach ($a in $agents) {
                    $statusTxt = if ($a.Enabled) { "ENABLED" } else { "disabled" }
                    Write-Log ("  - " + $a.Identity + " : " + $statusTxt) -Level INFO
                }
            }
        } catch {
            Write-Log ("Agent verification skipped: " + $_) -Level INFO
        }

        Write-Log "AntiSpam agents installation complete" -Level SUCCESS
        return $true
    }
    catch {
        Write-Log ("Error: " + $_) -Level ERROR
        return $false
    }
}

function Set-AntiSpamConfiguration {
    param(
        [int]$SCLRejectThreshold=7,[int]$SCLDeleteThreshold=9,
        [bool]$EnableContent=$true,[bool]$EnableSenderID=$true,
        [bool]$EnableSenderFilter=$true,[bool]$EnableRecipientFilter=$true,
        [bool]$EnableSenderReputation=$true
    )
    try {
        $localIP = (Get-NetIPAddress -AddressFamily IPv4 |
            Where-Object { $_.InterfaceAlias -notlike "*Loopback*" } |
            Select-Object -First 1).IPAddress
        Set-TransportConfig -InternalSMTPServers @{Add="$localIP"}
        if ($EnableContent) {
            Set-ContentFilterConfig -Enabled $true -RejectionResponse "Spam rejected." `
                -SCLRejectEnabled $true -SCLRejectThreshold $SCLRejectThreshold `
                -SCLDeleteEnabled $true -SCLDeleteThreshold $SCLDeleteThreshold
        }
        if ($EnableSenderID)         { Set-SenderIDConfig -Enabled $true -SpoofedDomainAction Reject }
        if ($EnableSenderFilter)     { Set-SenderFilterConfig -Enabled $true -BlankSenderBlockingEnabled $true }
        if ($EnableRecipientFilter)  { Set-RecipientFilterConfig -Enabled $true -RecipientValidationEnabled $true }
        if ($EnableSenderReputation) { Set-SenderReputationConfig -Enabled $true -SenderBlockingEnabled $true -SenderBlockingPeriod 24 }
        Write-Log "AntiSpam configured" -Level SUCCESS
        return $true
    } catch { Write-Log ("Error: " + $_) -Level ERROR; return $false }
}

function Test-ExchangeInstallation {
    try {
        $services = @("MSExchangeADTopology","MSExchangeIS","MSExchangeTransport","MSExchangeRPC")
        $errs = @()
        foreach ($s in $services) {
            $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
            if (-not $svc -or $svc.Status -ne "Running") { $errs += "$s not running" }
        }
        if ($errs.Count -gt 0) { foreach ($e in $errs) { Write-Log $e -Level ERROR }; return $false }
        Write-Log "Installation OK" -Level SUCCESS
        return $true
    } catch { return $false }
}

function Get-ExchangeSchemaInfo {
    $info = [PSCustomObject]@{
        SchemaVersion="Not present"; OrgVersion="Not present"; DomainVersion="Not present"
        SchemaVersionNeeded="17003"; OrgVersionNeeded="16763"; DomainVersionNeeded="13243"
        SchemaOK=$false; OrgOK=$false; DomainOK=$false
        ConfigNC=""; DomainNC=""; SchemaNC=""; ExchangeOrgName="(not yet installed)"
    }
    try {
        $rootDSE = [ADSI]"LDAP://RootDSE"
        try { $info.ConfigNC = $rootDSE.Properties["configurationNamingContext"][0] } catch {}
        try { $info.DomainNC = $rootDSE.Properties["defaultNamingContext"][0] } catch {}
        try { $info.SchemaNC = $rootDSE.Properties["schemaNamingContext"][0] } catch {}

        if ($info.SchemaNC) {
            try {
                $s = New-Object System.DirectoryServices.DirectorySearcher
                $s.SearchRoot = [ADSI]("LDAP://" + $info.SchemaNC)
                $s.Filter = "(cn=ms-Exch-Schema-Version-Pt)"
                $s.PropertiesToLoad.Add("rangeUpper") | Out-Null
                $s.SearchScope = "Subtree"
                $r = $s.FindOne()
                if ($r -and $r.Properties["rangeupper"].Count -gt 0) {
                    $info.SchemaVersion = "$($r.Properties['rangeupper'][0])"
                    $info.SchemaOK = ([int]$info.SchemaVersion -ge [int]$info.SchemaVersionNeeded)
                }
            } catch {}
        }

        if ($info.ConfigNC) {
            $msExchPath = "LDAP://CN=Microsoft Exchange,CN=Services," + $info.ConfigNC
            $exchExists = $false
            try {
                $testObj = [ADSI]$msExchPath
                if ($testObj.distinguishedName) { $exchExists = $true }
            } catch {}
            if ($exchExists) {
                try {
                    $s = New-Object System.DirectoryServices.DirectorySearcher
                    $s.SearchRoot = [ADSI]$msExchPath
                    $s.Filter = "(objectClass=msExchOrganizationContainer)"
                    $s.PropertiesToLoad.AddRange(@("cn","objectVersion")) | Out-Null
                    $s.SearchScope = "OneLevel"
                    $r = $s.FindOne()
                    if ($r) {
                        if ($r.Properties["cn"].Count -gt 0) { $info.ExchangeOrgName = "$($r.Properties['cn'][0])" }
                        if ($r.Properties["objectversion"].Count -gt 0) {
                            $info.OrgVersion = "$($r.Properties['objectversion'][0])"
                            $info.OrgOK = ([int]$info.OrgVersion -ge [int]$info.OrgVersionNeeded)
                        }
                    }
                } catch {}
            }
        }

        if ($info.DomainNC) {
            try {
                $s = New-Object System.DirectoryServices.DirectorySearcher
                $s.SearchRoot = [ADSI]("LDAP://" + $info.DomainNC)
                $s.Filter = "(cn=Microsoft Exchange System Objects)"
                $s.PropertiesToLoad.Add("objectVersion") | Out-Null
                $s.SearchScope = "OneLevel"
                $r = $s.FindOne()
                if ($r -and $r.Properties["objectversion"].Count -gt 0) {
                    $info.DomainVersion = "$($r.Properties['objectversion'][0])"
                    $info.DomainOK = ([int]$info.DomainVersion -ge [int]$info.DomainVersionNeeded)
                }
            } catch {}
        }
    } catch {}
    return $info
}

function Test-ExchangePrepPermissions {
    $r = [PSCustomObject]@{
        IsSchemaAdmin=$false; IsEnterpriseAdmin=$false; IsDomainAdmin=$false
        Username="$env:USERDOMAIN\$env:USERNAME"
    }
    try {
        $cu = [Security.Principal.WindowsIdentity]::GetCurrent()
        $groups = $cu.Groups | ForEach-Object { try { $_.Translate([Security.Principal.NTAccount]).Value } catch { $null } }
        foreach ($g in $groups) {
            if ($g -match "Schema-Admins|Schema Admins") { $r.IsSchemaAdmin = $true }
            if ($g -match "Organisations-Admins|Enterprise Admins") { $r.IsEnterpriseAdmin = $true }
            if ($g -match "Domain-?Admins|Dom.nen-Admins") { $r.IsDomainAdmin = $true }
        }
    } catch {}
    return $r
}

function Get-ADDomainList {
    try { return ([System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest().Domains | ForEach-Object { $_.Name }) } catch { return @() }
}

function Invoke-ExchangePrepareStep {
    param(
        [Parameter(Mandatory)][string]$SetupPath,
        [Parameter(Mandatory)][ValidateSet("PrepareSchema","PrepareAD","PrepareAllDomains","PrepareDomain")][string]$Step,
        [string]$OrgName,[string]$DomainName
    )
    try {
        Write-Log ("Starting: " + $Step) -Level INFO
        $arguments = @("/IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF")
        switch ($Step) {
            "PrepareSchema"     { $arguments += "/PrepareSchema" }
            "PrepareAD"         { $arguments += "/PrepareAD"; if ($OrgName) { $arguments += "/OrganizationName:$OrgName" } }
            "PrepareAllDomains" { $arguments += "/PrepareAllDomains" }
            "PrepareDomain"     { if ($DomainName) { $arguments += "/PrepareDomain:$DomainName" } else { $arguments += "/PrepareDomain" } }
        }
        $ec = Invoke-ResponsiveProcess -FilePath $SetupPath -Arguments $arguments -LogPrefix $Step -HeartbeatSec 30
        if ($ec -eq 0) { Write-Log ($Step + " OK") -Level SUCCESS; return $true }
        Write-Log ($Step + " ERROR: " + $ec) -Level ERROR
        return $false
    } catch { Write-Log ("Error: " + $_) -Level ERROR; return $false }
}

function Wait-ADReplication {
    param([int]$Minutes=5)
    Write-Log ("Waiting " + $Minutes + " min for AD replication...") -Level INFO
    $endTime = (Get-Date).AddMinutes($Minutes); $lastLog = Get-Date
    while ((Get-Date) -lt $endTime) {
        try { [System.Windows.Forms.Application]::DoEvents() } catch {}
        Start-Sleep -Milliseconds 500
        if (((Get-Date) - $lastLog).TotalSeconds -ge 30) {
            $rem = $endTime - (Get-Date)
            Write-Log ("  Remaining: " + ("{0:D2}:{1:D2}" -f [int]$rem.Minutes,[int]$rem.Seconds)) -Level INFO
            $lastLog = Get-Date
        }
    }
    Write-Log "Wait complete" -Level SUCCESS
}
#endregion

#region ============================ HELPER GUI ============================
function New-Label { param([string]$Text,[int]$X,[int]$Y,[int]$W=200,[System.Drawing.Font]$Font=$Global:FontDefault)
    $l = New-Object System.Windows.Forms.Label
    $l.Text=$Text; $l.Location=New-Object System.Drawing.Point($X,$Y); $l.Size=New-Object System.Drawing.Size($W,22)
    $l.ForeColor=$Global:ColorText; $l.BackColor=[System.Drawing.Color]::Transparent; $l.Font=$Font
    return $l
}
function New-TextBox { param([int]$X,[int]$Y,[int]$W=300,[string]$Default="")
    $t = New-Object System.Windows.Forms.TextBox
    $t.Location=New-Object System.Drawing.Point($X,$Y); $t.Size=New-Object System.Drawing.Size($W,22)
    $t.BackColor=$Global:ColorInputBg; $t.ForeColor=$Global:ColorText
    $t.BorderStyle="FixedSingle"; $t.Text=$Default; $t.Font=$Global:FontDefault
    return $t
}
function New-CheckBox { param([string]$Text,[int]$X,[int]$Y,[int]$W=350,[bool]$Checked=$false)
    $c = New-Object System.Windows.Forms.CheckBox
    $c.Text=$Text; $c.Location=New-Object System.Drawing.Point($X,$Y); $c.Size=New-Object System.Drawing.Size($W,24)
    $c.ForeColor=$Global:ColorText; $c.BackColor=[System.Drawing.Color]::Transparent
    $c.Checked=$Checked; $c.Font=$Global:FontDefault
    return $c
}
function New-Button { param([string]$Text,[int]$X,[int]$Y,[int]$W=180,[int]$H=32,[System.Drawing.Color]$Color=$Global:ColorAccent)
    $b = New-Object System.Windows.Forms.Button
    $b.Text=$Text; $b.Location=New-Object System.Drawing.Point($X,$Y); $b.Size=New-Object System.Drawing.Size($W,$H)
    $b.FlatStyle="Flat"; $b.BackColor=$Color; $b.ForeColor=[System.Drawing.Color]::White
    $b.Font=$Global:FontBold; $b.FlatAppearance.BorderSize=0; $b.Cursor="Hand"
    return $b
}
function New-GroupBox { param([string]$Text,[int]$X,[int]$Y,[int]$W,[int]$H)
    $g = New-Object System.Windows.Forms.GroupBox
    $g.Text=$Text; $g.Location=New-Object System.Drawing.Point($X,$Y); $g.Size=New-Object System.Drawing.Size($W,$H)
    $g.ForeColor=$Global:ColorAccent; $g.BackColor=$Global:ColorPanel; $g.Font=$Global:FontBold
    return $g
}
function New-NumericUpDown { param([int]$X,[int]$Y,[int]$W=70,[int]$Min=0,[int]$Max=99,[int]$Value=1)
    $n = New-Object System.Windows.Forms.NumericUpDown
    $n.Location=New-Object System.Drawing.Point($X,$Y); $n.Size=New-Object System.Drawing.Size($W,22)
    $n.Minimum=$Min; $n.Maximum=$Max; $n.Value=$Value
    $n.BackColor=$Global:ColorInputBg; $n.ForeColor=$Global:ColorText; $n.Font=$Global:FontDefault
    return $n
}
#endregion

#region ============================ HAUPTFORMULAR ============================
$Form = New-Object System.Windows.Forms.Form
$Form.Text=(Get-T "AppTitle")
$Form.Size=New-Object System.Drawing.Size($Global:FormWidth,$Global:FormHeight)
$Form.StartPosition="CenterScreen"; $Form.BackColor=$Global:ColorBackground
$Form.ForeColor=$Global:ColorText; $Form.Font=$Global:FontDefault
$Form.FormBorderStyle="Sizable"; $Form.MinimizeBox=$true; $Form.MaximizeBox=$true
$Form.MinimumSize=New-Object System.Drawing.Size(900,600)

# Header
$HeaderPanel = New-Object System.Windows.Forms.Panel
$HeaderPanel.Size=New-Object System.Drawing.Size($Global:FormWidth,65)
$HeaderPanel.Location=New-Object System.Drawing.Point(0,0); $HeaderPanel.BackColor=$Global:ColorAccent

$LblTitle = New-Object System.Windows.Forms.Label
$LblTitle.Text="  " + (Get-T "AppTitle")
$LblTitle.Font=$Global:FontHeader; $LblTitle.ForeColor=[System.Drawing.Color]::White
$LblTitle.Location=New-Object System.Drawing.Point(15,14); $LblTitle.Size=New-Object System.Drawing.Size(700,38)
$HeaderPanel.Controls.Add($LblTitle)

# Sprachauswahl (rechts oben)
$LblLang = New-Object System.Windows.Forms.Label
$LblLang.Text=(Get-T "Language")
$LblLang.Font=New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
$LblLang.ForeColor=[System.Drawing.Color]::White
$LblLang.Location=New-Object System.Drawing.Point(($Global:FormWidth-260),20)
$LblLang.Size=New-Object System.Drawing.Size(70,20)
$LblLang.BackColor=[System.Drawing.Color]::Transparent
$LblLang.TextAlign="MiddleRight"
$HeaderPanel.Controls.Add($LblLang)

$Global:CmbLang = New-Object System.Windows.Forms.ComboBox
$Global:CmbLang.Location=New-Object System.Drawing.Point(($Global:FormWidth-185),18)
$Global:CmbLang.Size=New-Object System.Drawing.Size(70,22)
$Global:CmbLang.DropDownStyle="DropDownList"
$Global:CmbLang.Items.AddRange(@("DE","EN")) | Out-Null
$Global:CmbLang.SelectedItem = $Global:CurrentLang
$Global:CmbLang.Add_SelectedIndexChanged({
    $newLang = $Global:CmbLang.SelectedItem
    if ($newLang -ne $Global:CurrentLang) {
        $r = [System.Windows.Forms.MessageBox]::Show(
            "Sprache wird gewechselt - Skript startet neu.`r`nLanguage will be changed - script restarts.",
            "Sprache / Language",'OKCancel','Information')
        if ($r -eq "OK") {
            $scriptPath = $MyInvocation.MyCommand.Path
            if (-not $scriptPath) { $scriptPath = $PSCommandPath }
            try {
                Start-Process -FilePath "powershell.exe" -ArgumentList @(
                    '-NoProfile','-ExecutionPolicy','Bypass','-File',('"' + $scriptPath + '"'),
                    '-Elevated','-ForceLang',$newLang
                ) -Verb RunAs
                $Form.Close()
            } catch {}
        } else {
            $Global:CmbLang.SelectedItem = $Global:CurrentLang
        }
    }
})
$HeaderPanel.Controls.Add($Global:CmbLang)

$LblSub = New-Object System.Windows.Forms.Label
$LblSub.Text=(Get-T "AppSubtitle")
$LblSub.Font=New-Object System.Drawing.Font("Segoe UI",10)
$LblSub.ForeColor=[System.Drawing.Color]::White
$LblSub.Location=New-Object System.Drawing.Point(($Global:FormWidth-105),22)
$LblSub.Size=New-Object System.Drawing.Size(95,20)
$LblSub.TextAlign="MiddleRight"; $LblSub.BackColor=[System.Drawing.Color]::Transparent
$HeaderPanel.Controls.Add($LblSub)
$Form.Controls.Add($HeaderPanel)

$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location=New-Object System.Drawing.Point(10,75)
$TabControl.Size=New-Object System.Drawing.Size(($Global:FormWidth-25),615)
$TabControl.Font=$Global:FontDefault

$TabPrereq   = New-Object System.Windows.Forms.TabPage; $TabPrereq.Text=(Get-T "TabPrereq")
$TabADPrep   = New-Object System.Windows.Forms.TabPage; $TabADPrep.Text=(Get-T "TabAD")
$TabInstall  = New-Object System.Windows.Forms.TabPage; $TabInstall.Text=(Get-T "TabInstall")
$TabSecurity = New-Object System.Windows.Forms.TabPage; $TabSecurity.Text=(Get-T "TabSec")
$TabAntiSpam = New-Object System.Windows.Forms.TabPage; $TabAntiSpam.Text=(Get-T "TabSpam")
$TabDB       = New-Object System.Windows.Forms.TabPage; $TabDB.Text=(Get-T "TabDB")
$TabDAG      = New-Object System.Windows.Forms.TabPage; $TabDAG.Text=(Get-T "TabDAG")
$TabRun      = New-Object System.Windows.Forms.TabPage; $TabRun.Text=(Get-T "TabRun")

foreach ($t in @($TabPrereq,$TabADPrep,$TabInstall,$TabSecurity,$TabAntiSpam,$TabDB,$TabDAG,$TabRun)) {
    $t.BackColor=$Global:ColorBackground; $t.ForeColor=$Global:ColorText
}
$TabControl.TabPages.AddRange(@($TabPrereq,$TabADPrep,$TabInstall,$TabSecurity,$TabAntiSpam,$TabDB,$TabDAG,$TabRun))
$Form.Controls.Add($TabControl)
#endregion

#region ============================ TAB: VORAUSSETZUNGEN ============================
$GrpPS = New-GroupBox (Get-T "PrereqStatus") 10 10 1080 280
$TabPrereq.Controls.Add($GrpPS)
$GrpPS.Controls.Add( (New-Label (Get-T "PrereqComponent") 20 28 280 $Global:FontBold) )
$GrpPS.Controls.Add( (New-Label (Get-T "PrereqState") 310 28 400 $Global:FontBold) )

$GrpPS.Controls.Add( (New-Label ".NET Framework 4.8+" 20 60 280) )
$Global:LblDotNet = New-Label "..." 310 60 400 $Global:FontBold; $GrpPS.Controls.Add($Global:LblDotNet)
$GrpPS.Controls.Add( (New-Label "Visual C++ 2012 (x64)" 20 88 280) )
$Global:LblVC2012 = New-Label "..." 310 88 400 $Global:FontBold; $GrpPS.Controls.Add($Global:LblVC2012)
$GrpPS.Controls.Add( (New-Label "Visual C++ 2013 (x64)" 20 116 280) )
$Global:LblVC2013 = New-Label "..." 310 116 400 $Global:FontBold; $GrpPS.Controls.Add($Global:LblVC2013)
$GrpPS.Controls.Add( (New-Label "IIS URL Rewrite Module 2.1" 20 144 280) )
$Global:LblURLRewrite = New-Label "..." 310 144 400 $Global:FontBold; $GrpPS.Controls.Add($Global:LblURLRewrite)
$GrpPS.Controls.Add( (New-Label "UCMA 4.0" 20 172 280) )
$Global:LblUCMA = New-Label "..." 310 172 400 $Global:FontBold; $GrpPS.Controls.Add($Global:LblUCMA)
$GrpPS.Controls.Add( (New-Label "Windows-Features" 20 200 280) )
$Global:LblFeatures = New-Label "..." 310 200 400 $Global:FontBold; $GrpPS.Controls.Add($Global:LblFeatures)
$GrpPS.Controls.Add( (New-Label "SMB1" 20 228 280) )
$Global:LblSMB1 = New-Label "..." 310 228 400 $Global:FontBold; $GrpPS.Controls.Add($Global:LblSMB1)

$BtnRefreshPrereq = New-Button (Get-T "PrereqRefresh") 870 28 200 32 $Global:ColorAccent
$BtnRefreshPrereq.Add_Click({
    try {
        Write-Log "Reading prerequisite status..." -Level INFO
        $st = Get-PrerequisiteStatus

        $okText = if ($Global:CurrentLang -eq "DE") { "OK - bereits installiert" } else { "OK - already installed" }
        $missText = if ($Global:CurrentLang -eq "DE") { "FEHLT - wird installiert" } else { "MISSING - will be installed" }

        $Global:LblDotNet.Text = if ($st.DotNet48) { $okText } else { $missText }
        $Global:LblDotNet.ForeColor = if ($st.DotNet48) { $Global:ColorAccent2 } else { $Global:ColorWarning }
        $Global:LblVC2012.Text = if ($st.VC2012) { $okText } else { $missText }
        $Global:LblVC2012.ForeColor = if ($st.VC2012) { $Global:ColorAccent2 } else { $Global:ColorWarning }
        $Global:LblVC2013.Text = if ($st.VC2013) { $okText } else { $missText }
        $Global:LblVC2013.ForeColor = if ($st.VC2013) { $Global:ColorAccent2 } else { $Global:ColorWarning }
        $Global:LblURLRewrite.Text = if ($st.URLRewrite) { $okText } else { $missText }
        $Global:LblURLRewrite.ForeColor = if ($st.URLRewrite) { $Global:ColorAccent2 } else { $Global:ColorWarning }
        $Global:LblUCMA.Text = if ($st.UCMA) { $okText } else { $missText }
        $Global:LblUCMA.ForeColor = if ($st.UCMA) { $Global:ColorAccent2 } else { $Global:ColorWarning }
        $featTxt = if ($st.FeaturesOK) { $okText } else { ($st.MissingFeatures.Count.ToString() + " missing") }
        $Global:LblFeatures.Text = $featTxt
        $Global:LblFeatures.ForeColor = if ($st.FeaturesOK) { $Global:ColorAccent2 } else { $Global:ColorWarning }
        $smb1Txt = if ($st.SMB1Enabled) { "ACTIVE - will be disabled" } else { "OK - already disabled" }
        $Global:LblSMB1.Text = $smb1Txt
        $Global:LblSMB1.ForeColor = if ($st.SMB1Enabled) { $Global:ColorWarning } else { $Global:ColorAccent2 }

        # Smart Auto-Selection
        $Global:ChkInstDotNet.Checked     = -not $st.DotNet48
        $Global:ChkInstDotNet.Enabled     = -not $st.DotNet48
        $Global:ChkInstVC2012.Checked     = -not $st.VC2012
        $Global:ChkInstVC2012.Enabled     = -not $st.VC2012
        $Global:ChkInstVC2013.Checked     = -not $st.VC2013
        $Global:ChkInstVC2013.Enabled     = -not $st.VC2013
        $Global:ChkInstURLRewrite.Checked = -not $st.URLRewrite
        $Global:ChkInstURLRewrite.Enabled = -not $st.URLRewrite
        $Global:ChkInstUCMA.Checked       = -not $st.UCMA
        $Global:ChkInstUCMA.Enabled       = -not $st.UCMA
        $Global:ChkInstFeatures.Checked   = -not $st.FeaturesOK
        $Global:ChkInstFeatures.Enabled   = -not $st.FeaturesOK
        $Global:ChkDisableSMB1.Checked    = $st.SMB1Enabled
        $Global:ChkDisableSMB1.Enabled    = $st.SMB1Enabled

        Write-Log "Prerequisite status updated" -Level SUCCESS
    } catch { Write-Log ("Error: " + $_) -Level ERROR }
})
$GrpPS.Controls.Add($BtnRefreshPrereq)

$GrpPO = New-GroupBox (Get-T "PrereqOptions") 10 300 1080 200
$TabPrereq.Controls.Add($GrpPO)
$Global:ChkInstDotNet     = New-CheckBox ".NET Framework 4.8" 20 30 500 $true
$Global:ChkInstVC2012     = New-CheckBox "Visual C++ 2012 x64" 20 60 500 $true
$Global:ChkInstVC2013     = New-CheckBox "Visual C++ 2013 x64" 20 90 500 $true
$Global:ChkInstURLRewrite = New-CheckBox "IIS URL Rewrite Module 2.1" 20 120 500 $true
$Global:ChkInstUCMA       = New-CheckBox "UCMA 4.0 (Exchange ISO)" 20 150 500 $true
$Global:ChkInstFeatures   = New-CheckBox "Windows-Features (33x)" 540 30 500 $true
$Global:ChkDisableSMB1    = New-CheckBox "SMB1 disable (Best Practice)" 540 60 500 $true
$Global:ChkSetPagefile    = New-CheckBox "Pagefile (RAM + 10 MB)" 540 90 500 $true
$Global:ChkSetHighPerf    = New-CheckBox "High-Performance Power Plan" 540 120 500 $true
foreach ($c in @($Global:ChkInstDotNet,$Global:ChkInstVC2012,$Global:ChkInstVC2013,
                 $Global:ChkInstURLRewrite,$Global:ChkInstUCMA,$Global:ChkInstFeatures,
                 $Global:ChkDisableSMB1,$Global:ChkSetPagefile,$Global:ChkSetHighPerf)) {
    $GrpPO.Controls.Add($c)
}

$GrpPA = New-GroupBox (Get-T "PrereqAction") 10 510 1080 80
$TabPrereq.Controls.Add($GrpPA)
$BtnInstallPrereq = New-Button (Get-T "PrereqInstall") 15 30 350 38 $Global:ColorAccent2
$BtnInstallPrereq.Add_Click({
    $r = [System.Windows.Forms.MessageBox]::Show("Continue?",(Get-T "Confirm"),'YesNo','Question')
    if ($r -ne "Yes") { return }
    $TabControl.SelectedTab = $TabRun
    [System.Windows.Forms.Application]::DoEvents()
    Install-PrerequisiteSoftware `
        -InstallDotNet $Global:ChkInstDotNet.Checked -InstallVC2012 $Global:ChkInstVC2012.Checked `
        -InstallVC2013 $Global:ChkInstVC2013.Checked -InstallURLRewrite $Global:ChkInstURLRewrite.Checked `
        -InstallUCMA $Global:ChkInstUCMA.Checked -InstallFeatures $Global:ChkInstFeatures.Checked `
        -DisableSMB1 $Global:ChkDisableSMB1.Checked -OptimizePageFile $Global:ChkSetPagefile.Checked `
        -SetHighPerformance $Global:ChkSetHighPerf.Checked
    $TabControl.SelectedTab = $TabPrereq
    $BtnRefreshPrereq.PerformClick()
})
$GrpPA.Controls.Add($BtnInstallPrereq)
$LblHint = New-Label (Get-T "PrereqHint") 380 40 600
$LblHint.ForeColor = $Global:ColorTextDim
$GrpPA.Controls.Add($LblHint)
#endregion

#region ============================ TAB: AD-VORBEREITUNG ============================
$GrpADStatus = New-GroupBox (Get-T "AD_Status") 10 10 1080 220
$TabADPrep.Controls.Add($GrpADStatus)
$GrpADStatus.Controls.Add( (New-Label (Get-T "PrereqComponent") 20 30 200 $Global:FontBold) )
$GrpADStatus.Controls.Add( (New-Label (Get-T "AD_Current") 230 30 200 $Global:FontBold) )
$GrpADStatus.Controls.Add( (New-Label (Get-T "AD_Required") 430 30 200 $Global:FontBold) )
$GrpADStatus.Controls.Add( (New-Label (Get-T "PrereqState") 630 30 200 $Global:FontBold) )

$GrpADStatus.Controls.Add( (New-Label (Get-T "AD_Schema") 20 60 200) )
$Global:LblADSchemaCur = New-Label "..." 230 60 200 $Global:FontBold; $GrpADStatus.Controls.Add($Global:LblADSchemaCur)
$Global:LblADSchemaReq = New-Label "..." 430 60 200; $GrpADStatus.Controls.Add($Global:LblADSchemaReq)
$Global:LblADSchemaSt = New-Label "..." 630 60 200 $Global:FontBold; $GrpADStatus.Controls.Add($Global:LblADSchemaSt)

$GrpADStatus.Controls.Add( (New-Label (Get-T "AD_Org") 20 90 200) )
$Global:LblADOrgCur = New-Label "..." 230 90 200 $Global:FontBold; $GrpADStatus.Controls.Add($Global:LblADOrgCur)
$Global:LblADOrgReq = New-Label "..." 430 90 200; $GrpADStatus.Controls.Add($Global:LblADOrgReq)
$Global:LblADOrgSt = New-Label "..." 630 90 200 $Global:FontBold; $GrpADStatus.Controls.Add($Global:LblADOrgSt)

$GrpADStatus.Controls.Add( (New-Label (Get-T "AD_Dom") 20 120 200) )
$Global:LblADDomCur = New-Label "..." 230 120 200 $Global:FontBold; $GrpADStatus.Controls.Add($Global:LblADDomCur)
$Global:LblADDomReq = New-Label "..." 430 120 200; $GrpADStatus.Controls.Add($Global:LblADDomReq)
$Global:LblADDomSt = New-Label "..." 630 120 200 $Global:FontBold; $GrpADStatus.Controls.Add($Global:LblADDomSt)

$GrpADStatus.Controls.Add( (New-Label (Get-T "AD_User") 20 155 200 $Global:FontBold) )
$Global:LblADUser = New-Label "..." 230 155 600; $GrpADStatus.Controls.Add($Global:LblADUser)
$GrpADStatus.Controls.Add( (New-Label (Get-T "AD_Perms") 20 180 200 $Global:FontBold) )
$Global:LblADPerms = New-Label "..." 230 180 800; $GrpADStatus.Controls.Add($Global:LblADPerms)

$BtnRefreshAD = New-Button (Get-T "PrereqRefresh") 870 28 200 32 $Global:ColorAccent
$BtnRefreshAD.Add_Click({
    try {
        $info = Get-ExchangeSchemaInfo
        $perm = Test-ExchangePrepPermissions
        $Global:LblADSchemaCur.Text = $info.SchemaVersion
        $Global:LblADSchemaReq.Text = $info.SchemaVersionNeeded
        $Global:LblADOrgCur.Text = "$($info.OrgVersion) ($($info.ExchangeOrgName))"
        $Global:LblADOrgReq.Text = $info.OrgVersionNeeded
        $Global:LblADDomCur.Text = $info.DomainVersion
        $Global:LblADDomReq.Text = $info.DomainVersionNeeded

        $sNum = $info.SchemaVersion -match '^\d+$'
        $oNum = $info.OrgVersion -match '^\d+$'
        $dNum = $info.DomainVersion -match '^\d+$'

        if ($info.SchemaOK -or ($sNum -and [int]$info.SchemaVersion -gt [int]$info.SchemaVersionNeeded)) {
            $Global:LblADSchemaSt.Text = "OK"; $Global:LblADSchemaSt.ForeColor = $Global:ColorAccent2
            $Global:ChkPrepSchema.Checked = $false
        } else {
            $Global:LblADSchemaSt.Text = "Update needed"; $Global:LblADSchemaSt.ForeColor = $Global:ColorWarning
            $Global:ChkPrepSchema.Checked = $true
        }
        if ($info.OrgOK -or ($oNum -and [int]$info.OrgVersion -gt [int]$info.OrgVersionNeeded)) {
            $Global:LblADOrgSt.Text = "OK"; $Global:LblADOrgSt.ForeColor = $Global:ColorAccent2
            $Global:ChkPrepAD.Checked = $false
        } else {
            $Global:LblADOrgSt.Text = "Update needed"; $Global:LblADOrgSt.ForeColor = $Global:ColorWarning
            $Global:ChkPrepAD.Checked = $true
        }
        if ($info.DomainOK -or ($dNum -and [int]$info.DomainVersion -gt [int]$info.DomainVersionNeeded)) {
            $Global:LblADDomSt.Text = "OK"; $Global:LblADDomSt.ForeColor = $Global:ColorAccent2
            $Global:ChkPrepDom.Checked = $false
        } else {
            $Global:LblADDomSt.Text = "Update needed"; $Global:LblADDomSt.ForeColor = $Global:ColorWarning
            $Global:ChkPrepDom.Checked = $true
        }

        $Global:LblADUser.Text = $perm.Username
        $pp = @()
        $pp += if ($perm.IsSchemaAdmin) { "[X] Schema-Admins" } else { "[ ] Schema-Admins" }
        $pp += if ($perm.IsEnterpriseAdmin) { "[X] Enterprise-Admins" } else { "[ ] Enterprise-Admins" }
        $pp += if ($perm.IsDomainAdmin) { "[X] Domain-Admins" } else { "[ ] Domain-Admins" }
        $Global:LblADPerms.Text = ($pp -join "  |  ")
        $allOK = $perm.IsSchemaAdmin -and $perm.IsEnterpriseAdmin -and $perm.IsDomainAdmin
        $Global:LblADPerms.ForeColor = if ($allOK) { $Global:ColorAccent2 } else { $Global:ColorWarning }
        Write-Log "AD status updated" -Level SUCCESS
    } catch { Write-Log ("Error: " + $_) -Level ERROR }
})
$GrpADStatus.Controls.Add($BtnRefreshAD)

$GrpPrepSteps = New-GroupBox (Get-T "AD_Steps") 10 240 1080 220
$TabADPrep.Controls.Add($GrpPrepSteps)
$Global:ChkPrepSchema = New-CheckBox (Get-T "AD_PrepSchema") 15 30 800 $true
$GrpPrepSteps.Controls.Add($Global:ChkPrepSchema)
$Global:ChkPrepAD = New-CheckBox (Get-T "AD_PrepAD") 15 60 800 $true
$GrpPrepSteps.Controls.Add($Global:ChkPrepAD)
$Global:ChkPrepDom = New-CheckBox (Get-T "AD_PrepDom") 15 95 250 $true
$GrpPrepSteps.Controls.Add($Global:ChkPrepDom)

$Global:RbAllDomains = New-Object System.Windows.Forms.RadioButton
$Global:RbAllDomains.Text=(Get-T "AD_AllDoms")
$Global:RbAllDomains.Location=New-Object System.Drawing.Point(40,120); $Global:RbAllDomains.Size=New-Object System.Drawing.Size(400,22)
$Global:RbAllDomains.Checked=$true; $Global:RbAllDomains.BackColor=[System.Drawing.Color]::Transparent
$GrpPrepSteps.Controls.Add($Global:RbAllDomains)

$Global:RbSingleDomain = New-Object System.Windows.Forms.RadioButton
$Global:RbSingleDomain.Text=(Get-T "AD_OneDom")
$Global:RbSingleDomain.Location=New-Object System.Drawing.Point(40,148); $Global:RbSingleDomain.Size=New-Object System.Drawing.Size(220,22)
$Global:RbSingleDomain.BackColor=[System.Drawing.Color]::Transparent
$GrpPrepSteps.Controls.Add($Global:RbSingleDomain)

$Global:CmbDomainList = New-Object System.Windows.Forms.ComboBox
$Global:CmbDomainList.Location=New-Object System.Drawing.Point(265,148); $Global:CmbDomainList.Size=New-Object System.Drawing.Size(350,22)
$Global:CmbDomainList.DropDownStyle="DropDownList"
$Global:CmbDomainList.BackColor=$Global:ColorInputBg; $Global:CmbDomainList.ForeColor=$Global:ColorText
$GrpPrepSteps.Controls.Add($Global:CmbDomainList)

$GrpPrepSteps.Controls.Add( (New-Label (Get-T "AD_WaitMin") 15 185 250) )
$Global:NumWaitMin = New-NumericUpDown 270 183 70 0 60 5
$GrpPrepSteps.Controls.Add($Global:NumWaitMin)
$LH2 = New-Label (Get-T "AD_WaitHint") 350 185 600
$LH2.ForeColor = $Global:ColorTextDim
$GrpPrepSteps.Controls.Add($LH2)

$GrpPA2 = New-GroupBox (Get-T "PrereqAction") 10 470 1080 90
$TabADPrep.Controls.Add($GrpPA2)
$BtnPrepAD = New-Button (Get-T "AD_StartBtn") 15 30 350 38 $Global:ColorAccent2
$BtnPrepAD.Add_Click({
    try {
        $setupPath = $null
        if ($Global:RbISOMounted.Checked -and $Global:CmbMountedDrives.SelectedIndex -ge 0 -and $Global:DetectedISOs.Count -gt 0) {
            $setupPath = $Global:DetectedISOs[$Global:CmbMountedDrives.SelectedIndex].SetupPath
        } elseif ($Global:RbISOFile.Checked -and $Global:TxtISO.Text) {
            $setupPath = Mount-ExchangeISO -ISOPath $Global:TxtISO.Text
        }
        if (-not $setupPath -or -not (Test-Path $setupPath)) {
            [System.Windows.Forms.MessageBox]::Show("Setup.exe not found!",(Get-T "Error"),'OK','Error'); return
        }
        $r = [System.Windows.Forms.MessageBox]::Show("Start AD preparation?",(Get-T "Confirm"),'YesNo','Warning')
        if ($r -ne "Yes") { return }
        $TabControl.SelectedTab = $TabRun
        $waitMin = [int]$Global:NumWaitMin.Value
        if ($Global:ChkPrepSchema.Checked) {
            if (Invoke-ExchangePrepareStep -SetupPath $setupPath -Step "PrepareSchema") {
                if ($waitMin -gt 0) { Wait-ADReplication -Minutes $waitMin }
            }
        }
        if ($Global:ChkPrepAD.Checked) {
            if (Invoke-ExchangePrepareStep -SetupPath $setupPath -Step "PrepareAD" -OrgName $Global:TxtOrg.Text) {
                if ($waitMin -gt 0) { Wait-ADReplication -Minutes $waitMin }
            }
        }
        if ($Global:ChkPrepDom.Checked) {
            if ($Global:RbAllDomains.Checked) {
                Invoke-ExchangePrepareStep -SetupPath $setupPath -Step "PrepareAllDomains" | Out-Null
            } elseif ($Global:RbSingleDomain.Checked -and $Global:CmbDomainList.SelectedItem) {
                Invoke-ExchangePrepareStep -SetupPath $setupPath -Step "PrepareDomain" -DomainName ($Global:CmbDomainList.SelectedItem.ToString()) | Out-Null
            }
        }
        $BtnRefreshAD.PerformClick()
        $TabControl.SelectedTab = $TabADPrep
    } catch { Write-Log ("Error: " + $_) -Level ERROR }
})
$GrpPA2.Controls.Add($BtnPrepAD)
#endregion

#region ============================ TAB: INSTALLATION ============================
$GrpISO = New-GroupBox (Get-T "ISO_Source") 10 10 1080 165
$TabInstall.Controls.Add($GrpISO)

$Global:RbISOFile = New-Object System.Windows.Forms.RadioButton
$Global:RbISOFile.Text=(Get-T "ISO_RbFile")
$Global:RbISOFile.Location=New-Object System.Drawing.Point(15,28); $Global:RbISOFile.Size=New-Object System.Drawing.Size(400,24)
$Global:RbISOFile.Checked=$true; $Global:RbISOFile.BackColor=[System.Drawing.Color]::Transparent; $Global:RbISOFile.ForeColor=$Global:ColorText
$GrpISO.Controls.Add($Global:RbISOFile)

$Global:RbISOMounted = New-Object System.Windows.Forms.RadioButton
$Global:RbISOMounted.Text=(Get-T "ISO_RbMounted")
$Global:RbISOMounted.Location=New-Object System.Drawing.Point(15,54); $Global:RbISOMounted.Size=New-Object System.Drawing.Size(550,24)
$Global:RbISOMounted.BackColor=[System.Drawing.Color]::Transparent; $Global:RbISOMounted.ForeColor=$Global:ColorText
$GrpISO.Controls.Add($Global:RbISOMounted)

$GrpISO.Controls.Add( (New-Label (Get-T "ISO_FileLbl") 35 90 100) )
$Global:TxtISO = New-TextBox 145 88 760
$GrpISO.Controls.Add($Global:TxtISO)

$BtnBrowseISO = New-Button (Get-T "ISO_Browse") 915 87 130 24 $Global:ColorAccent2
$BtnBrowseISO.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "ISO files (*.iso)|*.iso|All files|*.*"
    if ($ofd.ShowDialog() -eq "OK") { $Global:TxtISO.Text = $ofd.FileName; $Global:RbISOFile.Checked = $true }
})
$GrpISO.Controls.Add($BtnBrowseISO)

$GrpISO.Controls.Add( (New-Label (Get-T "ISO_DriveLbl") 35 122 100) )
$Global:CmbMountedDrives = New-Object System.Windows.Forms.ComboBox
$Global:CmbMountedDrives.Location=New-Object System.Drawing.Point(145,120); $Global:CmbMountedDrives.Size=New-Object System.Drawing.Size(760,22)
$Global:CmbMountedDrives.DropDownStyle="DropDownList"
$Global:CmbMountedDrives.BackColor=$Global:ColorInputBg; $Global:CmbMountedDrives.ForeColor=$Global:ColorText; $Global:CmbMountedDrives.Font=$Global:FontDefault
$GrpISO.Controls.Add($Global:CmbMountedDrives)

$BtnDetectISO = New-Button (Get-T "ISO_AutoDetect") 915 119 130 24 $Global:ColorAccent
$BtnDetectISO.Add_Click({
    try {
        $Global:CmbMountedDrives.Items.Clear()
        $found = @(Find-MountedExchangeISO)
        $Global:DetectedISOs = $found
        if ($found.Count -gt 0) {
            foreach ($f in $found) { [void]$Global:CmbMountedDrives.Items.Add($f.Display) }
            $Global:CmbMountedDrives.SelectedIndex = 0
            $Global:RbISOMounted.Checked = $true; $Global:RbISOFile.Checked = $false
        } else {
            [void]$Global:CmbMountedDrives.Items.Add("(No Exchange ISO found)")
            $Global:CmbMountedDrives.SelectedIndex = 0
        }
    } catch { Write-Log ("Error: " + $_) -Level ERROR }
})
$GrpISO.Controls.Add($BtnDetectISO)

$GrpSetup = New-GroupBox (Get-T "Setup_Params") 10 185 1080 220
$TabInstall.Controls.Add($GrpSetup)

$GrpSetup.Controls.Add( (New-Label (Get-T "Setup_Org") 15 28 150) )
$Global:TxtOrg = New-TextBox 175 26 400 "Contoso"
$GrpSetup.Controls.Add($Global:TxtOrg)

$Global:LblOrgWarning = New-Object System.Windows.Forms.Label
$Global:LblOrgWarning.Location=New-Object System.Drawing.Point(580,28); $Global:LblOrgWarning.Size=New-Object System.Drawing.Size(465,20)
$Global:LblOrgWarning.Font=New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
$Global:LblOrgWarning.BackColor=[System.Drawing.Color]::Transparent; $Global:LblOrgWarning.Text=""
$GrpSetup.Controls.Add($Global:LblOrgWarning)

$GrpSetup.Controls.Add( (New-Label (Get-T "Setup_Server") 15 58 150) )
$Global:TxtServer = New-TextBox 175 56 400 $env:COMPUTERNAME
$GrpSetup.Controls.Add($Global:TxtServer)

$GrpSetup.Controls.Add( (New-Label (Get-T "Setup_InstallPath") 15 88 150) )
$Global:TxtInstallPath = New-TextBox 175 86 870 $Global:DefaultInstallPath
$GrpSetup.Controls.Add($Global:TxtInstallPath)

$GrpSetup.Controls.Add( (New-Label (Get-T "Setup_Domain") 15 115 150) )
$Global:TxtDomain = New-TextBox 175 113 400
try { $Global:TxtDomain.Text = (Get-CimInstance Win32_ComputerSystem).Domain } catch { $Global:TxtDomain.Text = "contoso.local" }
$GrpSetup.Controls.Add($Global:TxtDomain)

$GrpSetup.Controls.Add( (New-Label (Get-T "Setup_Roles") 15 145 150 $Global:FontBold) )
$Global:ChkRoleMailbox = New-CheckBox (Get-T "Setup_RoleMailbox") 175 145 250 $true
$GrpSetup.Controls.Add($Global:ChkRoleMailbox)
$Global:ChkRoleEdge = New-CheckBox (Get-T "Setup_RoleEdge") 440 145 270 $false
$GrpSetup.Controls.Add($Global:ChkRoleEdge)
$Global:ChkRoleMgmt = New-CheckBox (Get-T "Setup_RoleMgmt") 720 145 280 $true
$GrpSetup.Controls.Add($Global:ChkRoleMgmt)

$Global:ChkRoleEdge.Add_CheckedChanged({
    if ($Global:ChkRoleEdge.Checked) {
        $Global:ChkRoleMailbox.Checked = $false; $Global:ChkRoleMailbox.Enabled = $false
    } else { $Global:ChkRoleMailbox.Enabled = $true; $Global:ChkRoleMailbox.Checked = $true }
})

$GrpSetup.Controls.Add( (New-Label (Get-T "Setup_Diag") 15 175 150) )
$Global:ChkDiagData = New-CheckBox (Get-T "Setup_DiagText") 175 175 500 $false
$GrpSetup.Controls.Add($Global:ChkDiagData)

$GrpOpts = New-GroupBox (Get-T "Inst_Options") 10 415 1080 175
$TabInstall.Controls.Add($GrpOpts)
$Global:Checks = @{}
$opts = @(
    @{Key="PrereqCheck"; Text=(Get-T "Opt_PrereqCheck"); Default=$true; Col=0; Row=0},
    @{Key="RunPrereqInstall"; Text=(Get-T "Opt_RunPrereq"); Default=$true; Col=0; Row=1},
    @{Key="MountISO"; Text=(Get-T "Opt_MountISO"); Default=$true; Col=0; Row=2},
    @{Key="DoADPrep"; Text=(Get-T "Opt_DoADPrep"); Default=$true; Col=0; Row=3},
    @{Key="InstallExchange"; Text=(Get-T "Opt_InstExch"); Default=$true; Col=0; Row=4},
    @{Key="InstallAntispam"; Text=(Get-T "Opt_InstSpam"); Default=$true; Col=1; Row=0},
    @{Key="ConfigAntispam"; Text=(Get-T "Opt_CfgSpam"); Default=$true; Col=1; Row=1},
    @{Key="VerifyInstall"; Text=(Get-T "Opt_Verify"); Default=$true; Col=1; Row=2},
    @{Key="ApplyTLS"; Text=(Get-T "Opt_TLS"); Default=$true; Col=1; Row=3},
    @{Key="CreateDBs"; Text=(Get-T "Opt_DBs"); Default=$false; Col=1; Row=4},
    @{Key="CreateDAG"; Text=(Get-T "Opt_DAG"); Default=$false; Col=2; Row=0},
    @{Key="DismountISO"; Text=(Get-T "Opt_Dismount"); Default=$true; Col=2; Row=1},
    @{Key="ForceAdminCheck"; Text=(Get-T "Opt_Admin"); Default=$true; Col=2; Row=2},
    @{Key="ContinueOnError"; Text=(Get-T "Opt_Continue"); Default=$false; Col=2; Row=3}
)
foreach ($o in $opts) {
    $cb = New-CheckBox $o.Text (20 + $o.Col*355) (28 + $o.Row*28) 350 $o.Default
    $GrpOpts.Controls.Add($cb)
    $Global:Checks[$o.Key] = $cb
}
#endregion

#region ============================ TAB: SICHERHEIT / TLS ============================
$GrpTLS = New-GroupBox (Get-T "TLS_Title") 10 10 1080 200
$TabSecurity.Controls.Add($GrpTLS)
$LblTLS = New-Object System.Windows.Forms.Label
$LblTLS.Location=New-Object System.Drawing.Point(15,28); $LblTLS.Size=New-Object System.Drawing.Size(1050,165)
$LblTLS.Font=New-Object System.Drawing.Font("Segoe UI",9); $LblTLS.ForeColor=$Global:ColorText; $LblTLS.BackColor=[System.Drawing.Color]::Transparent
$LblTLS.Text = "DISABLED: SSL 2.0/3.0, TLS 1.0/1.1, weak ciphers (RC4, DES, 3DES, NULL)`r`nENABLED:  TLS 1.2, TLS 1.3, .NET SystemDefaultTlsVersions + SchUseStrongCrypto`r`n`r`nIMPORTANT: A REBOOT is required after applying!"
$GrpTLS.Controls.Add($LblTLS)

$GrpTLSAct = New-GroupBox (Get-T "TLS_Action") 10 220 1080 130
$TabSecurity.Controls.Add($GrpTLSAct)
$Global:ChkConfirmTLS = New-CheckBox (Get-T "TLS_Confirm") 15 30 700 $false
$GrpTLSAct.Controls.Add($Global:ChkConfirmTLS)
$BtnApplyTLS = New-Button (Get-T "TLS_Apply") 15 65 280 40 $Global:ColorAccent
$BtnApplyTLS.Add_Click({
    if (-not $Global:ChkConfirmTLS.Checked) { [System.Windows.Forms.MessageBox]::Show("Please confirm first!",(Get-T "Warning"),'OK','Warning'); return }
    $r = [System.Windows.Forms.MessageBox]::Show("Apply TLS?",(Get-T "Confirm"),'YesNo','Question')
    if ($r -eq "Yes") { Set-TLSHardening | Out-Null }
})
$GrpTLSAct.Controls.Add($BtnApplyTLS)
$BtnTestTLS = New-Button (Get-T "TLS_Test") 310 65 200 40 $Global:ColorAccent2
$BtnTestTLS.Add_Click({
    Write-Log "TLS Status:" -Level INFO
    $base = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols"
    foreach ($proto in @("SSL 2.0","SSL 3.0","TLS 1.0","TLS 1.1","TLS 1.2","TLS 1.3")) {
        foreach ($side in @("Server","Client")) {
            $p = Join-Path $base "$proto\$side"
            if (Test-Path $p) {
                $en = (Get-ItemProperty -Path $p -Name Enabled -ErrorAction SilentlyContinue).Enabled
                $st = if ($en -eq 0) { "DISABLED" } elseif ($en) { "ENABLED" } else { "Default" }
                Write-Log ("  $proto $side : $st") -Level INFO
            } else { Write-Log ("  $proto $side : Default") -Level INFO }
        }
    }
})
$GrpTLSAct.Controls.Add($BtnTestTLS)
#endregion

#region ============================ TAB: ANTISPAM ============================
$GrpSCL = New-GroupBox (Get-T "SCL_Title") 10 10 1080 110
$TabAntiSpam.Controls.Add($GrpSCL)
$GrpSCL.Controls.Add( (New-Label (Get-T "SCL_Reject") 15 30 320) )
$Global:NumSCLReject = New-NumericUpDown 340 28 70 0 9 7
$GrpSCL.Controls.Add($Global:NumSCLReject)
$GrpSCL.Controls.Add( (New-Label (Get-T "SCL_Delete") 15 65 320) )
$Global:NumSCLDelete = New-NumericUpDown 340 63 70 0 9 9
$GrpSCL.Controls.Add($Global:NumSCLDelete)

$GrpFilt = New-GroupBox (Get-T "Spam_Filter") 10 130 1080 220
$TabAntiSpam.Controls.Add($GrpFilt)
$Global:ChkContent  = New-CheckBox (Get-T "Filt_Content") 20 30 350 $true
$Global:ChkSenderID = New-CheckBox (Get-T "Filt_SenderID") 20 60 350 $true
$Global:ChkSendFil  = New-CheckBox (Get-T "Filt_Sender") 20 90 350 $true
$Global:ChkRecipFil = New-CheckBox (Get-T "Filt_Recip") 20 120 350 $true
$Global:ChkSendRep  = New-CheckBox (Get-T "Filt_Reputation") 20 150 350 $true
foreach ($c in @($Global:ChkContent,$Global:ChkSenderID,$Global:ChkSendFil,$Global:ChkRecipFil,$Global:ChkSendRep)) {
    $GrpFilt.Controls.Add($c)
}
$BtnApplyAntispam = New-Button (Get-T "Spam_Apply") 10 365 350 40 $Global:ColorAccent2
$BtnApplyAntispam.Add_Click({
    if (-not (Import-ExchangeManagementShell)) { return }
    Set-AntiSpamConfiguration `
        -SCLRejectThreshold ([int]$Global:NumSCLReject.Value) -SCLDeleteThreshold ([int]$Global:NumSCLDelete.Value) `
        -EnableContent $Global:ChkContent.Checked -EnableSenderID $Global:ChkSenderID.Checked `
        -EnableSenderFilter $Global:ChkSendFil.Checked -EnableRecipientFilter $Global:ChkRecipFil.Checked `
        -EnableSenderReputation $Global:ChkSendRep.Checked
})
$TabAntiSpam.Controls.Add($BtnApplyAntispam)
#endregion

#region ============================ TAB: DATENBANKEN ============================
$LblDBHead = New-Label (Get-T "DB_Generator") 10 10 1000 $Global:FontBold
$TabDB.Controls.Add($LblDBHead)
$GrpGen = New-GroupBox "DB-Generator" 10 35 1080 175
$TabDB.Controls.Add($GrpGen)
$GrpGen.Controls.Add( (New-Label (Get-T "DB_Prefix") 15 30 100) )
$Global:TxtDBPrefix = New-TextBox 120 28 120 "MDB"
$GrpGen.Controls.Add($Global:TxtDBPrefix)
$GrpGen.Controls.Add( (New-Label (Get-T "DB_Start") 250 30 100) )
$Global:TxtDBStart = New-TextBox 355 28 80 "01"
$GrpGen.Controls.Add($Global:TxtDBStart)
$GrpGen.Controls.Add( (New-Label (Get-T "DB_Count") 15 60 100) )
$Global:NumDBCount = New-NumericUpDown 120 58 80 1 99 4
$GrpGen.Controls.Add($Global:NumDBCount)
$GrpGen.Controls.Add( (New-Label (Get-T "DB_Server") 250 60 100) )
$Global:TxtDBServer = New-TextBox 355 58 200 $env:COMPUTERNAME
$GrpGen.Controls.Add($Global:TxtDBServer)
$GrpGen.Controls.Add( (New-Label (Get-T "DB_Base") 15 95 100) )
$Global:TxtDBBase = New-TextBox 120 93 400 $Global:DefaultDBPath
$GrpGen.Controls.Add($Global:TxtDBBase)
$GrpGen.Controls.Add( (New-Label (Get-T "DB_LogBase") 530 95 110) )
$Global:TxtLogBase = New-TextBox 645 93 400 $Global:DefaultLogDBPath
$GrpGen.Controls.Add($Global:TxtLogBase)

$BtnGenerate = New-Button (Get-T "DB_Generate") 15 130 280 32 $Global:ColorAccent
$BtnGenerate.Add_Click({
    $Global:DgvDB.Rows.Clear()
    $prefix = $Global:TxtDBPrefix.Text.Trim(); $startStr = $Global:TxtDBStart.Text.Trim()
    $count = [int]$Global:NumDBCount.Value
    if (-not $prefix -or $startStr -notmatch '^\d+$') { return }
    $padLen = $startStr.Length; $startNum = [int]$startStr
    for ($i = 0; $i -lt $count; $i++) {
        $num = $startNum + $i
        $suffix = $num.ToString().PadLeft($padLen,'0')
        $dbName = "$prefix$suffix"
        $Global:DgvDB.Rows.Add($dbName, $Global:TxtDBServer.Text.Trim(), "$($Global:TxtDBBase.Text)\$dbName\$dbName.edb", "$($Global:TxtLogBase.Text)\$dbName") | Out-Null
    }
})
$GrpGen.Controls.Add($BtnGenerate)
$BtnClearDB = New-Button (Get-T "DB_Clear") 305 130 130 32 $Global:ColorWarning
$BtnClearDB.Add_Click({ $Global:DgvDB.Rows.Clear() })
$GrpGen.Controls.Add($BtnClearDB)

$LblPv = New-Label (Get-T "DB_Preview") 10 220 800 $Global:FontBold
$TabDB.Controls.Add($LblPv)

$Global:DgvDB = New-Object System.Windows.Forms.DataGridView
$Global:DgvDB.Location=New-Object System.Drawing.Point(10,245); $Global:DgvDB.Size=New-Object System.Drawing.Size(1080,260)
$Global:DgvDB.AllowUserToAddRows=$true; $Global:DgvDB.AutoSizeColumnsMode="Fill"; $Global:DgvDB.SelectionMode="FullRowSelect"
$Global:DgvDB.BackgroundColor=$Global:ColorPanel; $Global:DgvDB.RowHeadersVisible=$false
$Global:DgvDB.ColumnHeadersDefaultCellStyle.BackColor=$Global:ColorAccent
$Global:DgvDB.ColumnHeadersDefaultCellStyle.ForeColor=[System.Drawing.Color]::White
$Global:DgvDB.ColumnHeadersDefaultCellStyle.Font=$Global:FontBold
$Global:DgvDB.EnableHeadersVisualStyles=$false
foreach ($col in @(@{Name="DBName";Header="DB Name"},@{Name="Server";Header="Server"},@{Name="EdbFilePath";Header="EDB Path"},@{Name="LogFolderPath";Header="Log Path"})) {
    $c = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $c.Name=$col.Name; $c.HeaderText=$col.Header
    $Global:DgvDB.Columns.Add($c) | Out-Null
}
$TabDB.Controls.Add($Global:DgvDB)

$BtnCreateDBNow = New-Button (Get-T "DB_CreateNow") 10 515 350 38 $Global:ColorAccent2
$BtnCreateDBNow.Add_Click({
    if ($Global:DgvDB.Rows.Count -le 1) { return }
    if (-not (Import-ExchangeManagementShell)) { return }
    foreach ($row in $Global:DgvDB.Rows) {
        if ($row.IsNewRow) { continue }
        $n = $row.Cells["DBName"].Value
        if ([string]::IsNullOrWhiteSpace($n)) { continue }
        try {
            if (Get-MailboxDatabase -Identity $n -ErrorAction SilentlyContinue) { continue }
            $edb = $row.Cells["EdbFilePath"].Value; $lp = $row.Cells["LogFolderPath"].Value
            $eDir = Split-Path $edb -Parent
            if (-not (Test-Path $eDir)) { New-Item $eDir -ItemType Directory -Force | Out-Null }
            if (-not (Test-Path $lp)) { New-Item $lp -ItemType Directory -Force | Out-Null }
            New-MailboxDatabase -Name $n -Server $row.Cells["Server"].Value -EdbFilePath $edb -LogFolderPath $lp -ErrorAction Stop | Out-Null
            Mount-Database -Identity $n -ErrorAction Stop
            Write-Log ("DB '$n' created") -Level SUCCESS
        } catch { Write-Log ("DB Error '$n': " + $_) -Level ERROR }
    }
})
$TabDB.Controls.Add($BtnCreateDBNow)
#endregion

#region ============================ TAB: DAG ============================
$GrpDAG1 = New-GroupBox (Get-T "DAG_Settings") 10 10 1080 230
$TabDAG.Controls.Add($GrpDAG1)
$GrpDAG1.Controls.Add( (New-Label (Get-T "DAG_Name") 15 30 180) )
$Global:TxtDAGName = New-TextBox 200 28 350 "DAG01"
$GrpDAG1.Controls.Add($Global:TxtDAGName)
$GrpDAG1.Controls.Add( (New-Label (Get-T "DAG_Witness") 15 65 180) )
$Global:TxtWitness = New-TextBox 200 63 350 "FILESERVER01"
$GrpDAG1.Controls.Add($Global:TxtWitness)
$GrpDAG1.Controls.Add( (New-Label (Get-T "DAG_WitnessDir") 15 100 180) )
$Global:TxtWitnessDir = New-TextBox 200 98 700 "C:\DAGFileShareWitness\DAG01"
$GrpDAG1.Controls.Add($Global:TxtWitnessDir)
$GrpDAG1.Controls.Add( (New-Label (Get-T "DAG_IP") 15 135 180) )
$Global:TxtDAGIP = New-TextBox 200 133 700 "192.168.1.100"
$GrpDAG1.Controls.Add($Global:TxtDAGIP)
$LblIPHint = New-Label (Get-T "DAG_IPHint") 200 158 400
$LblIPHint.ForeColor = $Global:ColorTextDim
$GrpDAG1.Controls.Add($LblIPHint)
$Global:ChkIPlessDAG = New-CheckBox (Get-T "DAG_IPless") 15 190 500 $false
$GrpDAG1.Controls.Add($Global:ChkIPlessDAG)

$GrpDAG2 = New-GroupBox (Get-T "DAG_Members") 10 250 1080 200
$TabDAG.Controls.Add($GrpDAG2)
$Global:TxtMembers = New-Object System.Windows.Forms.TextBox
$Global:TxtMembers.Location=New-Object System.Drawing.Point(15,25); $Global:TxtMembers.Size=New-Object System.Drawing.Size(1050,160)
$Global:TxtMembers.Multiline=$true; $Global:TxtMembers.ScrollBars="Vertical"
$Global:TxtMembers.BackColor=$Global:ColorInputBg; $Global:TxtMembers.ForeColor=$Global:ColorText
$Global:TxtMembers.Font=$Global:FontMono; $Global:TxtMembers.Text="EX01`r`nEX02"
$GrpDAG2.Controls.Add($Global:TxtMembers)

$BtnCreateDAGNow = New-Button (Get-T "DAG_Create") 10 465 1080 40 $Global:ColorAccent
$BtnCreateDAGNow.Add_Click({
    try {
        if (-not (Import-ExchangeManagementShell)) { return }
        $name = $Global:TxtDAGName.Text.Trim()
        $witnessSrv = $Global:TxtWitness.Text.Trim()
        $witnessDir = $Global:TxtWitnessDir.Text.Trim()
        if (-not $name -or -not $witnessSrv) {
            [System.Windows.Forms.MessageBox]::Show("DAG name or witness server missing!",(Get-T "Error"),'OK','Warning')
            return
        }

        # === PRE-CHECK: Ist der Witness-Server ein Domain Controller? ===
        $isDC = $false
        try {
            $dcCheck = Get-ADDomainController -Identity $witnessSrv -ErrorAction SilentlyContinue
            if ($dcCheck) { $isDC = $true }
        } catch {
            # Fallback ohne ADModul
            try {
                $forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
                foreach ($d in $forest.Domains) {
                    foreach ($dc in $d.DomainControllers) {
                        if ($dc.Name -eq $witnessSrv -or $dc.Name -like "$witnessSrv.*") { $isDC = $true; break }
                    }
                    if ($isDC) { break }
                }
            } catch {}
        }

          if ($isDC) {
            $r = [System.Windows.Forms.MessageBox]::Show(
                "ACHTUNG: '$witnessSrv' ist ein Domain Controller!`r`n`r`n" +
                "Microsoft empfiehlt KEINEN DC als Witness.`r`n`r`n" +
                "Bei Fortfahren wird 'Exchange Trusted Subsystem' zur`r`n" +
                "Builtin\Administrators-Gruppe der Domain hinzugefuegt.`r`n`r`n" +
                "Fortfahren?",
                "DC als Witness", 'YesNo', 'Warning')
            if ($r -ne "Yes") { return }

            Write-Log "==============================================" -Level INFO
            Write-Log " DC-Sondersetup: ETS zu Builtin\Administrators" -Level INFO
            Write-Log " (sprachunabhaengig per SID)" -Level INFO
            Write-Log "==============================================" -Level INFO

            # ===== SID-basierter Lookup (sprachunabhaengig!) =====
            # S-1-5-32-544 = BUILTIN\Administrators (immer, egal welche Sprache)
            $builtinAdminsSID = "S-1-5-32-544"
            $adminGroupName = $null
            $adminGroupDN = $null
            $etsDN = $null
            $etsSAM = "Exchange Trusted Subsystem"

            try {
                # Builtin\Administrators ueber SID finden
                $sidObj = New-Object System.Security.Principal.SecurityIdentifier($builtinAdminsSID)
                $ntAccount = $sidObj.Translate([System.Security.Principal.NTAccount])
                # Format: "BUILTIN\Administrators" (DE: "VORDEFINIERT\Administratoren")
                $adminGroupName = $ntAccount.Value -replace '^[^\\]+\\',''
                Write-Log ("Builtin-Admin-Gruppe (lokalisierter Name): '" + $adminGroupName + "'") -Level INFO

                # DN ueber LDAP holen
                $rootDSE = [ADSI]"LDAP://RootDSE"
                $domainDN = $rootDSE.Properties["defaultNamingContext"][0]

                # Suche nach SID in CN=Builtin
                $searcher = New-Object System.DirectoryServices.DirectorySearcher
                $searcher.SearchRoot = [ADSI]("LDAP://CN=Builtin," + $domainDN)
                # objectSID als Byte-Array fuer LDAP-Filter konvertieren
                $sidBytes = New-Object byte[] $sidObj.BinaryLength
                $sidObj.GetBinaryForm($sidBytes, 0)
                $hexSID = ($sidBytes | ForEach-Object { '\{0:X2}' -f $_ }) -join ''
                $searcher.Filter = "(objectSid=$hexSID)"
                $searcher.PropertiesToLoad.Add("distinguishedName") | Out-Null
                $searcher.PropertiesToLoad.Add("sAMAccountName") | Out-Null
                $searcher.PropertiesToLoad.Add("member") | Out-Null
                $searcher.SearchScope = "Subtree"
                $adminResult = $searcher.FindOne()

                if ($adminResult) {
                    $adminGroupDN = $adminResult.Properties["distinguishedname"][0]
                    $localizedSAM = "$($adminResult.Properties['samaccountname'][0])"
                    Write-Log ("  DN: " + $adminGroupDN) -Level INFO
                    Write-Log ("  SAM: " + $localizedSAM) -Level INFO

                    # Pruefen ob ETS schon Mitglied ist
                    $alreadyMember = $false
                    if ($adminResult.Properties["member"]) {
                        foreach ($m in $adminResult.Properties["member"]) {
                            if ($m -like "*Exchange Trusted Subsystem*") {
                                $alreadyMember = $true
                                Write-Log "ETS ist bereits Mitglied der Builtin-Admin-Gruppe!" -Level SUCCESS
                                break
                            }
                        }
                    }

                    if (-not $alreadyMember) {
                        # ETS-DN finden
                        $etsSearch = New-Object System.DirectoryServices.DirectorySearcher
                        $etsSearch.SearchRoot = [ADSI]("LDAP://" + $domainDN)
                        $etsSearch.Filter = "(samAccountName=$etsSAM)"
                        $etsSearch.PropertiesToLoad.Add("distinguishedName") | Out-Null
                        $etsSearch.SearchScope = "Subtree"
                        $etsResult = $etsSearch.FindOne()

                        if (-not $etsResult) {
                            Write-Log "FEHLER: 'Exchange Trusted Subsystem' nicht im AD gefunden!" -Level ERROR
                            Write-Log "Wurde Exchange korrekt installiert?" -Level WARNING
                            return
                        }

                        $etsDN = $etsResult.Properties["distinguishedname"][0]
                        Write-Log ("  ETS DN: " + $etsDN) -Level INFO
                        Write-Log "Fuege ETS zur Builtin-Admin-Gruppe hinzu..." -Level INFO

                        # === Direkter LDAP-Add ===
                        $success = $false
                        try {
                            $adminGroupObj = [ADSI]("LDAP://" + $adminGroupDN)
                            $adminGroupObj.Add("LDAP://" + $etsDN)
                            $adminGroupObj.SetInfo()
                            Write-Log "ETS erfolgreich hinzugefuegt!" -Level SUCCESS
                            $success = $true
                        } catch {
                            Write-Log ("LDAP Add-Methode fehlgeschlagen: " + $_.Exception.Message) -Level WARNING
                        }

                        # Fallback: AD-Modul mit lokalisiertem Namen
                        if (-not $success -and $localizedSAM) {
                            try {
                                Write-Log ("Fallback: Add-ADGroupMember mit lokalem Namen '" + $localizedSAM + "'...") -Level INFO
                                Import-Module ActiveDirectory -ErrorAction Stop
                                Add-ADGroupMember -Identity $localizedSAM -Members $etsSAM -Server $witnessSrv -ErrorAction Stop
                                Write-Log "AD-Modul-Methode erfolgreich!" -Level SUCCESS
                                $success = $true
                            } catch {
                                Write-Log ("AD-Modul-Fallback fehlgeschlagen: " + $_.Exception.Message) -Level WARNING
                            }
                        }

                        # Fallback: Identity per DN
                        if (-not $success) {
                            try {
                                Write-Log "Fallback: Add-ADGroupMember per DN..." -Level INFO
                                Import-Module ActiveDirectory -ErrorAction Stop
                                Add-ADGroupMember -Identity $adminGroupDN -Members $etsDN -Server $witnessSrv -ErrorAction Stop
                                Write-Log "DN-basierte Methode erfolgreich!" -Level SUCCESS
                                $success = $true
                            } catch {
                                Write-Log ("DN-Methode fehlgeschlagen: " + $_.Exception.Message) -Level WARNING
                            }
                        }

                        if ($success) {
                            Write-Log "Verifiziere Mitgliedschaft (SID-Lookup)..." -Level INFO
                            Start-Sleep -Seconds 5
                            try {
                                $verifySearch = New-Object System.DirectoryServices.DirectorySearcher
                                $verifySearch.SearchRoot = [ADSI]("LDAP://CN=Builtin," + $domainDN)
                                $verifySearch.Filter = "(objectSid=$hexSID)"
                                $verifySearch.PropertiesToLoad.Add("member") | Out-Null
                                $vr = $verifySearch.FindOne()
                                $isMemberNow = $false
                                if ($vr -and $vr.Properties["member"]) {
                                    foreach ($m in $vr.Properties["member"]) {
                                        if ($m -eq $etsDN) { $isMemberNow = $true; break }
                                    }
                                }
                                if ($isMemberNow) {
                                    Write-Log ">>> ETS ist jetzt Mitglied von Builtin-Admins <<<" -Level SUCCESS
                                } else {
                                    Write-Log "ETS noch nicht als Mitglied sichtbar - AD-Replikation kann 5-15 Min dauern" -Level WARNING
                                }
                            } catch {
                                Write-Log ("Verifikation: " + $_.Exception.Message) -Level INFO
                            }

                            Write-Log "Warte 30s auf AD-Replikation..." -Level INFO
                            for ($i = 30; $i -gt 0; $i--) {
                                if ($i % 5 -eq 0) { Write-Log ("  ... " + $i + "s") -Level INFO }
                                Start-Sleep -Seconds 1
                                try { [System.Windows.Forms.Application]::DoEvents() } catch {}
                            }
                        } else {
                            Write-Log "==============================================" -Level ERROR
                            Write-Log " ALLE METHODEN FEHLGESCHLAGEN!" -Level ERROR
                            Write-Log "==============================================" -Level ERROR
                            Write-Log " BITTE MANUELL auf dem DC ausfuehren:" -Level WARNING
                            Write-Log "" -Level INFO
                            Write-Log "   Add-ADGroupMember -Identity '$localizedSAM' -Members 'Exchange Trusted Subsystem'" -Level INFO
                            Write-Log "" -Level INFO
                            Write-Log " Oder ueber dsa.msc -> Builtin -> $localizedSAM -> Members -> Add" -Level INFO
                            Write-Log "==============================================" -Level ERROR

                            $manualMsg = "Konnte ETS nicht hinzufuegen.`r`n`r`n"
                            $manualMsg += "Bitte MANUELL auf einem DC ausfuehren:`r`n`r`n"
                            $manualMsg += "   Add-ADGroupMember -Identity '$localizedSAM'``r``n"
                            $manualMsg += "      -Members 'Exchange Trusted Subsystem'`r`n`r`n"
                            $manualMsg += "Danach 5 Min warten und DAG-Erstellung erneut starten."
                            [System.Windows.Forms.MessageBox]::Show($manualMsg, "Manuelle Aktion", 'OK', 'Warning')
                            return
                        }
                    }
                } else {
                    Write-Log "Builtin-Admin-Gruppe nicht im AD gefunden!" -Level ERROR
                    return
                }
            } catch {
                Write-Log ("Kritischer SID-Lookup-Fehler: " + $_.Exception.Message) -Level ERROR
                return
            }

                    # === Witness-Verzeichnis vorab anlegen (mit Verifikation!) ===
        Write-Log "==============================================" -Level INFO
        Write-Log " Witness-Verzeichnis auf DC erstellen" -Level INFO
        Write-Log "==============================================" -Level INFO
        Write-Log ("Ziel: " + $witnessSrv + " - " + $witnessDir) -Level INFO

        $dirCreated = $false
        $uncPath = $witnessDir -replace '^([A-Z]):',('\\' + $witnessSrv + '\$1$')

        # === METHODE 1: UNC-Pfad direkt (braucht nur SMB, kein WinRM) ===
        Write-Log "Methode 1: Direkter UNC-Zugriff (admin share)..." -Level INFO
        Write-Log ("  UNC-Pfad: " + $uncPath) -Level INFO
        try {
            if (Test-Path $uncPath -ErrorAction SilentlyContinue) {
                Write-Log "  UNC-Pfad existiert bereits!" -Level SUCCESS
                $dirCreated = $true
            } else {
                New-Item -Path $uncPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
                Write-Log "  UNC-Pfad erstellt!" -Level SUCCESS
                $dirCreated = $true
            }
        } catch {
            Write-Log ("  Methode 1 fehlgeschlagen: " + $_.Exception.Message) -Level WARNING
        }

        # === METHODE 2: WinRM PSSession ===
        if (-not $dirCreated) {
            Write-Log "Methode 2: PowerShell Remoting (WinRM)..." -Level INFO
            try {
                $session = New-PSSession -ComputerName $witnessSrv -ErrorAction Stop
                $remoteCheck = Invoke-Command -Session $session -ScriptBlock {
                    param($dir)
                    try {
                        if (-not (Test-Path $dir)) {
                            New-Item -Path $dir -ItemType Directory -Force | Out-Null
                        }
                        if (Test-Path $dir) { return "OK" } else { return "FAILED" }
                    } catch { return "ERROR: $_" }
                } -ArgumentList $witnessDir
                Remove-PSSession $session -ErrorAction SilentlyContinue

                if ($remoteCheck -eq "OK") {
                    Write-Log "  Remote-Erstellung erfolgreich!" -Level SUCCESS
                    $dirCreated = $true
                } else {
                    Write-Log ("  Methode 2: " + $remoteCheck) -Level WARNING
                }
            } catch {
                Write-Log ("  Methode 2 fehlgeschlagen: " + $_.Exception.Message) -Level WARNING
                Write-Log "  (WinRM evtl. nicht aktiviert auf DC - Methode 1 ist Standard)" -Level INFO
            }
        }
    }
        # === METHODE 3: WMIC / CIM Process Create ===
        if (-not $dirCreated) {
            Write-Log "Methode 3: Remote-Process via CIM..." -Level INFO
            try {
                $cmd = "cmd.exe /c if not exist `"$witnessDir`" mkdir `"$witnessDir`""
                $r = Invoke-CimMethod -ClassName Win32_Process -MethodName Create `
                    -Arguments @{CommandLine=$cmd} -ComputerName $witnessSrv -ErrorAction Stop
                if ($r.ReturnValue -eq 0) {
                    Write-Log "  CIM-Process gestartet, warte 3s..." -Level INFO
                    Start-Sleep -Seconds 3
                    if (Test-Path $uncPath -ErrorAction SilentlyContinue) {
                        Write-Log "  Verzeichnis existiert nun!" -Level SUCCESS
                        $dirCreated = $true
                    }
                }
            } catch {
                Write-Log ("  Methode 3 fehlgeschlagen: " + $_.Exception.Message) -Level WARNING
            }
        }

        # === FINALE VERIFIKATION (entscheidet wirklich!) ===
        Start-Sleep -Seconds 2
        Write-Log "Finale Verifikation des Verzeichnisses..." -Level INFO
        $reallyExists = Test-Path $uncPath -ErrorAction SilentlyContinue

        if ($reallyExists) {
            Write-Log ">>> Verzeichnis existiert: $uncPath <<<" -Level SUCCESS

            # Berechtigungen pruefen
            try {
                $acl = Get-Acl $uncPath -ErrorAction Stop
                $hasETSPerm = $false
                foreach ($a in $acl.Access) {
                    if ($a.IdentityReference -like "*Exchange Trusted Subsystem*") {
                        $hasETSPerm = $true
                        break
                    }
                }
                if (-not $hasETSPerm) {
                    Write-Log "Setze ETS-Berechtigungen auf Witness-Verzeichnis..." -Level INFO
                    try {
                        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                            "Exchange Trusted Subsystem","FullControl",
                            @("ContainerInherit","ObjectInherit"),"None","Allow")
                        $acl.SetAccessRule($rule)
                        Set-Acl -Path $uncPath -AclObject $acl -ErrorAction Stop
                        Write-Log "Berechtigungen gesetzt" -Level SUCCESS
                    } catch {
                        Write-Log ("Berechtigungen konnten nicht gesetzt werden: " + $_) -Level WARNING
                        Write-Log "(Exchange setzt diese normalerweise selbst beim DAG-Update)" -Level INFO
                    }
                }
            } catch {
                Write-Log ("ACL-Pruefung uebersprungen: " + $_.Exception.Message) -Level INFO
            }
        } else {
            Write-Log "==============================================" -Level ERROR
            Write-Log " Witness-Verzeichnis konnte NICHT erstellt werden!" -Level ERROR
            Write-Log "==============================================" -Level ERROR
            Write-Log "" -Level INFO
            Write-Log "Bitte MANUELL auf dem DC '$witnessSrv' ausfuehren:" -Level WARNING
            Write-Log "" -Level INFO
            Write-Log "  New-Item -Path '$witnessDir' -ItemType Directory -Force" -Level INFO
            Write-Log "" -Level INFO
            Write-Log "Dann auf diesem Server in Exchange Shell:" -Level INFO
            Write-Log "" -Level INFO
            Write-Log "  Set-DatabaseAvailabilityGroup -Identity '$name' \\" -Level INFO
            Write-Log "      -WitnessServer '$witnessSrv' -WitnessDirectory '$witnessDir'" -Level INFO
            Write-Log "" -Level INFO

            $manualMsg = "Witness-Verzeichnis konnte nicht erstellt werden!`r`n`r`n"
            $manualMsg += "Moegliche Ursachen:`r`n"
            $manualMsg += "  - Admin-Share C`$ auf DC nicht erreichbar`r`n"
            $manualMsg += "  - WinRM nicht aktiviert auf DC`r`n"
            $manualMsg += "  - Aktueller User hat keine Admin-Rechte auf DC`r`n`r`n"
            $manualMsg += "Bitte MANUELL auf dem DC ausfuehren:`r`n`r`n"
            $manualMsg += "  New-Item -Path '$witnessDir' -ItemType Directory -Force`r`n`r`n"
            $manualMsg += "Danach DAG-Witness in Exchange Shell aktualisieren:`r`n`r`n"
            $manualMsg += "  Set-DatabaseAvailabilityGroup -Identity '$name' ``r`n"
            $manualMsg += "      -WitnessServer '$witnessSrv' ``r`n"
            $manualMsg += "      -WitnessDirectory '$witnessDir'"
            [System.Windows.Forms.MessageBox]::Show($manualMsg,"Manuelle Aktion noetig",'OK','Warning')
        }


                # === DAG erstellen ===
        if (-not (Get-DatabaseAvailabilityGroup -Identity $name -ErrorAction SilentlyContinue)) {
            Write-Log ("Creating DAG '" + $name + "'...") -Level INFO
            if ($Global:ChkIPlessDAG.Checked) {
                New-DatabaseAvailabilityGroup -Name $name `
                    -WitnessServer $witnessSrv -WitnessDirectory $witnessDir `
                    -DatabaseAvailabilityGroupIpAddresses ([System.Net.IPAddress]::None) -ErrorAction Stop | Out-Null
                Write-Log ("IP-less DAG '$name' created") -Level SUCCESS
            } else {
                $ips = $Global:TxtDAGIP.Text.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ } | ForEach-Object { [System.Net.IPAddress]::Parse($_) }
                New-DatabaseAvailabilityGroup -Name $name `
                    -WitnessServer $witnessSrv -WitnessDirectory $witnessDir `
                    -DatabaseAvailabilityGroupIpAddresses $ips -ErrorAction Stop | Out-Null
                Write-Log ("DAG '$name' created with IPs: " + ($ips -join ',')) -Level SUCCESS
            }
        } else {
            Write-Log ("DAG '$name' already exists") -Level WARNING
        }

        # === Mitglieder hinzufuegen ===
        $members = $Global:TxtMembers.Text.Split("`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        foreach ($m in $members) {
            try {
                Add-DatabaseAvailabilityGroupServer -Identity $name -MailboxServer $m -ErrorAction Stop
                Write-Log ("Member '$m' added") -Level SUCCESS
            } catch { Write-Log ("Error adding '$m': " + $_) -Level ERROR }
        }

        # === Status anzeigen ===
        Start-Sleep -Seconds 3
        $dagStatus = Get-DatabaseAvailabilityGroup -Identity $name -Status -ErrorAction SilentlyContinue
        if ($dagStatus) {
            Write-Log "------- DAG Status -------" -Level INFO
            Write-Log ("  Name:               " + $dagStatus.Name) -Level INFO
            Write-Log ("  Witness Server:     " + $dagStatus.WitnessServer) -Level INFO
            Write-Log ("  Witness Directory:  " + $dagStatus.WitnessDirectory) -Level INFO
            Write-Log ("  Witness Share:      " + $dagStatus.WitnessShareInUse) -Level INFO
            Write-Log ("  Members:            " + ($dagStatus.Servers -join ',')) -Level INFO
        }

        Write-Log "DAG configuration complete" -Level SUCCESS
        Write-Log "TIP: Restart MSExchangeIS service if directed by Exchange" -Level INFO
    }
    catch {
        Write-Log ("DAG error: " + $_) -Level ERROR
    }
})
$TabDAG.Controls.Add($BtnCreateDAGNow)
#endregion

#region ============================ TAB: AUSFUEHRUNG & LOG ============================
$LblRun = New-Label (Get-T "Run_Info") 10 10 1080 $Global:FontBold
$TabRun.Controls.Add($LblRun)

$Global:LogTextBox = New-Object System.Windows.Forms.RichTextBox
$Global:LogTextBox.Location=New-Object System.Drawing.Point(10,40)
$Global:LogTextBox.Size=New-Object System.Drawing.Size(1080,420)
$Global:LogTextBox.BackColor=[System.Drawing.Color]::White
$Global:LogTextBox.ForeColor=$Global:ColorText
$Global:LogTextBox.Font=$Global:FontMono; $Global:LogTextBox.ReadOnly=$true
$Global:LogTextBox.BorderStyle="FixedSingle"
$TabRun.Controls.Add($Global:LogTextBox)

# === Save Config ===
$BtnSaveCfg = New-Button (Get-T "Run_SaveCfg") 10 470 180 32 $Global:ColorAccent
$BtnSaveCfg.Add_Click({
    try {
        $dbList = @()
        foreach ($r in $Global:DgvDB.Rows) {
            if ($r.IsNewRow) { continue }
            if ([string]::IsNullOrWhiteSpace($r.Cells["DBName"].Value)) { continue }
            $dbList += @{
                Name="$($r.Cells['DBName'].Value)"
                Server="$($r.Cells['Server'].Value)"
                EDB="$($r.Cells['EdbFilePath'].Value)"
                Log="$($r.Cells['LogFolderPath'].Value)"
            }
        }
        $dagMembers = @($Global:TxtMembers.Text.Split("`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ })

        $cfg = @{
            Version = "3.6"
            Language = $Global:CurrentLang
            Saved = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            ISO = @{
                File=$Global:TxtISO.Text; UseFile=$Global:RbISOFile.Checked
                Drive=if ($Global:CmbMountedDrives.SelectedItem) { "$($Global:CmbMountedDrives.SelectedItem)" } else { "" }
            }
            Setup = @{
                Org=$Global:TxtOrg.Text; Server=$Global:TxtServer.Text
                Install=$Global:TxtInstallPath.Text; Domain=$Global:TxtDomain.Text
            }
            Roles = @{
                Mailbox=$Global:ChkRoleMailbox.Checked
                Edge=$Global:ChkRoleEdge.Checked
                MgmtTools=$Global:ChkRoleMgmt.Checked
                DiagData=$Global:ChkDiagData.Checked
            }
            Options = @{}
            Prereq = @{
                DotNet=$Global:ChkInstDotNet.Checked; VC2012=$Global:ChkInstVC2012.Checked
                VC2013=$Global:ChkInstVC2013.Checked; URL=$Global:ChkInstURLRewrite.Checked
                UCMA=$Global:ChkInstUCMA.Checked; Features=$Global:ChkInstFeatures.Checked
                SMB1=$Global:ChkDisableSMB1.Checked; Pagefile=$Global:ChkSetPagefile.Checked
                HighPerf=$Global:ChkSetHighPerf.Checked
            }
            ADPrep = @{
                PrepSchema=$Global:ChkPrepSchema.Checked; PrepAD=$Global:ChkPrepAD.Checked
                PrepDom=$Global:ChkPrepDom.Checked; AllDomains=$Global:RbAllDomains.Checked
                SingleDom=$Global:RbSingleDomain.Checked
                DomainName=if ($Global:CmbDomainList.SelectedItem) { "$($Global:CmbDomainList.SelectedItem)" } else { "" }
                WaitMin=[int]$Global:NumWaitMin.Value
            }
            AntiSpam = @{
                SCLReject=[int]$Global:NumSCLReject.Value; SCLDelete=[int]$Global:NumSCLDelete.Value
                Content=$Global:ChkContent.Checked; SenderID=$Global:ChkSenderID.Checked
                SenderFilter=$Global:ChkSendFil.Checked; RecipientFilter=$Global:ChkRecipFil.Checked
                SenderReputation=$Global:ChkSendRep.Checked
            }
            DBGen = @{
                Prefix=$Global:TxtDBPrefix.Text; Start=$Global:TxtDBStart.Text
                Count=[int]$Global:NumDBCount.Value; Server=$Global:TxtDBServer.Text
                DBBase=$Global:TxtDBBase.Text; LogBase=$Global:TxtLogBase.Text
            }
            DBs = $dbList
            DAG = @{
                Name=$Global:TxtDAGName.Text; Witness=$Global:TxtWitness.Text
                WitnessDir=$Global:TxtWitnessDir.Text; IP=$Global:TxtDAGIP.Text
                IPless=$Global:ChkIPlessDAG.Checked; Members=$dagMembers
            }
            TLS = @{ Confirmed=$Global:ChkConfirmTLS.Checked }
        }
        foreach ($k in $Global:Checks.Keys) { $cfg.Options[$k] = $Global:Checks[$k].Checked }
        $cfg | ConvertTo-Json -Depth 8 | Set-Content $Global:ConfigFile -Encoding UTF8 -ErrorAction Stop

        Write-Log "===========================================" -Level SUCCESS
        Write-Log " CONFIG SAVED" -Level SUCCESS
        Write-Log ("  File: " + $Global:ConfigFile) -Level INFO
        Write-Log ("  Databases: " + $dbList.Count) -Level INFO
        Write-Log ("  DAG members: " + $dagMembers.Count) -Level INFO
        Write-Log "===========================================" -Level SUCCESS

        [System.Windows.Forms.MessageBox]::Show(
            "Config saved!`r`nFile: $Global:ConfigFile`r`nDBs: $($dbList.Count)`r`nDAG-Members: $($dagMembers.Count)",
            (Get-T "Info"),'OK','Information')
    }
    catch {
        Write-Log ("Save error: " + $_) -Level ERROR
        [System.Windows.Forms.MessageBox]::Show(("Save error: " + $_),(Get-T "Error"),'OK','Error')
    }
})
$TabRun.Controls.Add($BtnSaveCfg)

# === Load Config ===
$BtnLoadCfg = New-Button (Get-T "Run_LoadCfg") 200 470 180 32 $Global:ColorAccent
$BtnLoadCfg.Add_Click({
    try {
        if (-not (Test-Path $Global:ConfigFile)) {
            [System.Windows.Forms.MessageBox]::Show("No saved config found.",(Get-T "Info"),'OK','Information')
            return
        }
        $cfg = Get-Content $Global:ConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json

        Write-Log "===========================================" -Level INFO
        Write-Log " LOADING CONFIG" -Level INFO
        if ($cfg.Saved) { Write-Log ("  Saved: " + $cfg.Saved) -Level INFO }

        if ($cfg.ISO) {
            $Global:TxtISO.Text="$($cfg.ISO.File)"
            $Global:RbISOFile.Checked=[bool]$cfg.ISO.UseFile
            $Global:RbISOMounted.Checked=-not [bool]$cfg.ISO.UseFile
        }
        if ($cfg.Setup) {
            $Global:TxtOrg.Text="$($cfg.Setup.Org)"
            $Global:TxtServer.Text="$($cfg.Setup.Server)"
            $Global:TxtInstallPath.Text="$($cfg.Setup.Install)"
            $Global:TxtDomain.Text="$($cfg.Setup.Domain)"
        }
        if ($cfg.Roles) {
            $Global:ChkRoleMailbox.Checked=[bool]$cfg.Roles.Mailbox
            $Global:ChkRoleEdge.Checked=[bool]$cfg.Roles.Edge
            $Global:ChkRoleMgmt.Checked=[bool]$cfg.Roles.MgmtTools
            $Global:ChkDiagData.Checked=[bool]$cfg.Roles.DiagData
        }
        if ($cfg.Options) {
            foreach ($k in $Global:Checks.Keys) {
                if ($cfg.Options.PSObject.Properties.Name -contains $k) {
                    $Global:Checks[$k].Checked = [bool]$cfg.Options.$k
                }
            }
        }
        if ($cfg.Prereq) {
            $Global:ChkInstDotNet.Checked=[bool]$cfg.Prereq.DotNet
            $Global:ChkInstVC2012.Checked=[bool]$cfg.Prereq.VC2012
            $Global:ChkInstVC2013.Checked=[bool]$cfg.Prereq.VC2013
            $Global:ChkInstURLRewrite.Checked=[bool]$cfg.Prereq.URL
            $Global:ChkInstUCMA.Checked=[bool]$cfg.Prereq.UCMA
            $Global:ChkInstFeatures.Checked=[bool]$cfg.Prereq.Features
            $Global:ChkDisableSMB1.Checked=[bool]$cfg.Prereq.SMB1
            $Global:ChkSetPagefile.Checked=[bool]$cfg.Prereq.Pagefile
            $Global:ChkSetHighPerf.Checked=[bool]$cfg.Prereq.HighPerf
        }
        if ($cfg.ADPrep) {
            $Global:ChkPrepSchema.Checked=[bool]$cfg.ADPrep.PrepSchema
            $Global:ChkPrepAD.Checked=[bool]$cfg.ADPrep.PrepAD
            $Global:ChkPrepDom.Checked=[bool]$cfg.ADPrep.PrepDom
            $Global:RbAllDomains.Checked=[bool]$cfg.ADPrep.AllDomains
            $Global:RbSingleDomain.Checked=[bool]$cfg.ADPrep.SingleDom
            try { $Global:NumWaitMin.Value=[int]$cfg.ADPrep.WaitMin } catch {}
            if ($cfg.ADPrep.DomainName) {
                for ($i=0; $i -lt $Global:CmbDomainList.Items.Count; $i++) {
                    if ($Global:CmbDomainList.Items[$i] -eq $cfg.ADPrep.DomainName) {
                        $Global:CmbDomainList.SelectedIndex = $i; break
                    }
                }
            }
        }
        if ($cfg.AntiSpam) {
            try { $Global:NumSCLReject.Value=[int]$cfg.AntiSpam.SCLReject } catch {}
            try { $Global:NumSCLDelete.Value=[int]$cfg.AntiSpam.SCLDelete } catch {}
            $Global:ChkContent.Checked=[bool]$cfg.AntiSpam.Content
            $Global:ChkSenderID.Checked=[bool]$cfg.AntiSpam.SenderID
            $Global:ChkSendFil.Checked=[bool]$cfg.AntiSpam.SenderFilter
            $Global:ChkRecipFil.Checked=[bool]$cfg.AntiSpam.RecipientFilter
            $Global:ChkSendRep.Checked=[bool]$cfg.AntiSpam.SenderReputation
        }
        if ($cfg.DBGen) {
            $Global:TxtDBPrefix.Text="$($cfg.DBGen.Prefix)"
            $Global:TxtDBStart.Text="$($cfg.DBGen.Start)"
            try { $Global:NumDBCount.Value=[int]$cfg.DBGen.Count } catch {}
            $Global:TxtDBServer.Text="$($cfg.DBGen.Server)"
            $Global:TxtDBBase.Text="$($cfg.DBGen.DBBase)"
            $Global:TxtLogBase.Text="$($cfg.DBGen.LogBase)"
        }
        $Global:DgvDB.Rows.Clear()
        $dbCount = 0
        if ($cfg.DBs) {
            foreach ($db in $cfg.DBs) {
                if ($db -and $db.Name) {
                    $Global:DgvDB.Rows.Add("$($db.Name)","$($db.Server)","$($db.EDB)","$($db.Log)") | Out-Null
                    $dbCount++
                }
            }
        }
        $dagMC = 0
        if ($cfg.DAG) {
            $Global:TxtDAGName.Text="$($cfg.DAG.Name)"
            $Global:TxtWitness.Text="$($cfg.DAG.Witness)"
            $Global:TxtWitnessDir.Text="$($cfg.DAG.WitnessDir)"
            $Global:TxtDAGIP.Text="$($cfg.DAG.IP)"
            $Global:ChkIPlessDAG.Checked=[bool]$cfg.DAG.IPless
            if ($cfg.DAG.Members) {
                $ma = @($cfg.DAG.Members | Where-Object { $_ })
                $Global:TxtMembers.Text = ($ma -join "`r`n")
                $dagMC = $ma.Count
            }
        }
        if ($cfg.TLS) { $Global:ChkConfirmTLS.Checked=[bool]$cfg.TLS.Confirmed }

        Write-Log ("  DBs loaded: " + $dbCount) -Level INFO
        Write-Log ("  DAG members: " + $dagMC) -Level INFO
        Write-Log "===========================================" -Level SUCCESS
        [System.Windows.Forms.MessageBox]::Show("Config loaded!`r`nDBs: $dbCount`r`nDAG-Members: $dagMC",(Get-T "Info"),'OK','Information')
    }
    catch {
        Write-Log ("Load error: " + $_) -Level ERROR
        [System.Windows.Forms.MessageBox]::Show(("Load error: " + $_),(Get-T "Error"),'OK','Error')
    }
})
$TabRun.Controls.Add($BtnLoadCfg)

# === Clear Log ===
$BtnClearLog = New-Button (Get-T "Run_ClearLog") 390 470 130 32 $Global:ColorWarning
$BtnClearLog.Add_Click({ $Global:LogTextBox.Clear() })
$TabRun.Controls.Add($BtnClearLog)

# === Open Setup-Log ===
$BtnOpenSetupLog = New-Button (Get-T "Run_OpenLog") 530 470 220 32 $Global:ColorAccent
$BtnOpenSetupLog.Add_Click({
    try {
        # 1. Mögliche Log-Pfade ermitteln (SystemDrive variabel!)
        $sysDrive = $env:SystemDrive
        $candidatePaths = @(
            "$sysDrive\ExchangeSetupLogs\ExchangeSetup.log",
            "C:\ExchangeSetupLogs\ExchangeSetup.log",
            "D:\ExchangeSetupLogs\ExchangeSetup.log",
            "E:\ExchangeSetupLogs\ExchangeSetup.log"
        )

        $logFile  = $null

        # 2. Existierendes Setup-Log finden
        foreach ($p in $candidatePaths) {
            if (Test-Path $p -ErrorAction SilentlyContinue) {
                $logFile = $p
                Write-Log ("Setup-Log gefunden: " + $p) -Level INFO
                break
            }
        }

        # 3. Wenn Log gefunden -> direkt oeffnen
        if ($logFile) {
            try {
                Start-Process notepad.exe -ArgumentList "`"$logFile`""
                Write-Log "ExchangeSetup.log geoeffnet" -Level SUCCESS
            } catch {
                Write-Log ("Notepad konnte nicht starten: " + $_) -Level ERROR
                Start-Process explorer.exe -ArgumentList ("/select,`"$logFile`"")
            }
            return
        }

        # 4. Log nicht gefunden - Verzeichnis suchen
        $foundDir = $null
        foreach ($p in $candidatePaths) {
            $dir = Split-Path $p -Parent
            if (Test-Path $dir -ErrorAction SilentlyContinue) {
                $foundDir = $dir
                break
            }
        }

        if ($foundDir) {
            # Verzeichnis existiert aber kein Setup-Log
            $allLogs = Get-ChildItem -Path $foundDir -Filter "*.log" -ErrorAction SilentlyContinue |
                       Sort-Object LastWriteTime -Descending
            if ($allLogs -and $allLogs.Count -gt 0) {
                # Andere Logs vorhanden - User waehlen lassen
                $msg = "ExchangeSetup.log nicht gefunden, aber andere Logs:`r`n`r`n"
                $i = 1
                foreach ($l in $allLogs | Select-Object -First 10) {
                    $msg += "  $i. $($l.Name)  ($([math]::Round($l.Length/1KB,1)) KB, $($l.LastWriteTime))`r`n"
                    $i++
                }
                $msg += "`r`nMoechten Sie den Ordner oeffnen?"
                $r = [System.Windows.Forms.MessageBox]::Show($msg, (Get-T "Info"), 'YesNo', 'Information')
                if ($r -eq "Yes") {
                    Start-Process explorer.exe $foundDir
                    Write-Log ("Setup-Log-Ordner geoeffnet: " + $foundDir) -Level INFO
                }
            } else {
                # Ordner leer
                [System.Windows.Forms.MessageBox]::Show(
                    "Setup-Log-Ordner ist leer:`r`n$foundDir`r`n`r`nSetup wurde wahrscheinlich noch nicht gestartet.",
                    (Get-T "Info"), 'OK', 'Information')
            }
            return
        }

        # 5. Komplett nichts gefunden
        $msg = "Kein ExchangeSetup-Log gefunden!`r`n`r`n"
        $msg += "Geprueft wurden:`r`n"
        foreach ($p in $candidatePaths) { $msg += "  - $p`r`n" }
        $msg += "`r`nMoegliche Ursachen:`r`n"
        $msg += "  - Setup wurde noch nie gestartet`r`n"
        $msg += "  - Voraussetzungen-Pruefung schlug VOR dem Setup-Aufruf fehl`r`n"
        $msg += "  - Anderer SystemDrive (aktuell: $sysDrive)"

        [System.Windows.Forms.MessageBox]::Show($msg, (Get-T "Warning"), 'OK', 'Warning')
        Write-Log "Kein Setup-Log gefunden" -Level WARNING
    }
    catch {
        Write-Log ("Fehler beim Oeffnen des Setup-Logs: " + $_) -Level ERROR
        [System.Windows.Forms.MessageBox]::Show(("Fehler: " + $_), (Get-T "Error"), 'OK', 'Error')
    }
})

$TabRun.Controls.Add($BtnOpenSetupLog)

# === START ALL ===
$BtnStartAll = New-Button (Get-T "Run_StartAll") 10 510 1080 38 $Global:ColorAccent2
$BtnStartAll.Font = New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
$BtnStartAll.Add_Click({
    try {
        if (-not $Global:TxtOrg.Text) {
            [System.Windows.Forms.MessageBox]::Show("Organization missing!",(Get-T "Error"),'OK','Warning'); return
        }
        if ($Global:Checks["ForceAdminCheck"].Checked) {
            $cu = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
            if (-not $cu.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
                [System.Windows.Forms.MessageBox]::Show("Run as Administrator!",(Get-T "Error"),'OK','Error'); return
            }
        }
        $r = [System.Windows.Forms.MessageBox]::Show("Start entire process? Can take hours!",(Get-T "Confirm"),'YesNo','Question')
        if ($r -ne "Yes") { return }

        $TabControl.SelectedTab = $TabRun
        Write-Log "==============================================" -Level INFO
        Write-Log "===   MICROSOFT EXCHANGE SE INSTALLATION   ===" -Level INFO
        Write-Log "==============================================" -Level INFO

        $continueOnError = $Global:Checks["ContinueOnError"].Checked
        $ExchangeSetupPath = $null
        $ISOMountedByScript = $false

        # ISO ermitteln
        if ($Global:RbISOMounted.Checked -and $Global:CmbMountedDrives.SelectedIndex -ge 0 -and $Global:DetectedISOs.Count -gt 0) {
            $ExchangeSetupPath = $Global:DetectedISOs[$Global:CmbMountedDrives.SelectedIndex].SetupPath
            Write-Log ("ISO source: " + $ExchangeSetupPath) -Level SUCCESS
        }
        elseif ($Global:RbISOFile.Checked -and $Global:TxtISO.Text -and $Global:Checks["MountISO"].Checked) {
            $ExchangeSetupPath = Mount-ExchangeISO -ISOPath $Global:TxtISO.Text
            if ($ExchangeSetupPath) { $ISOMountedByScript = $true }
        }

        # SCHRITT 1: Voraussetzungs-Check
        if ($Global:Checks["PrereqCheck"].Checked) {
            Write-Log "--- STEP 1: Prerequisites check ---" -Level INFO
            $isoCheck = if ($Global:RbISOFile.Checked) { $Global:TxtISO.Text } else { "" }
            if (-not (Test-ExchangePrerequisites -ExchangeISOPath $isoCheck) -and -not $continueOnError) {
                Write-Log "Aborted (prerequisites)" -Level ERROR; return
            }
        }

        # SCHRITT 1.5: Voraussetzungen installieren
        if ($Global:Checks["RunPrereqInstall"].Checked) {
            Write-Log "--- STEP 1.5: Install prerequisites ---" -Level INFO
            Install-PrerequisiteSoftware `
                -InstallDotNet $Global:ChkInstDotNet.Checked `
                -InstallVC2012 $Global:ChkInstVC2012.Checked `
                -InstallVC2013 $Global:ChkInstVC2013.Checked `
                -InstallURLRewrite $Global:ChkInstURLRewrite.Checked `
                -InstallUCMA $Global:ChkInstUCMA.Checked `
                -InstallFeatures $Global:ChkInstFeatures.Checked `
                -DisableSMB1 $Global:ChkDisableSMB1.Checked `
                -OptimizePageFile $Global:ChkSetPagefile.Checked `
                -SetHighPerformance $Global:ChkSetHighPerf.Checked
        }

        # SCHRITT 2: TLS-Hardening
        if ($Global:Checks["ApplyTLS"].Checked) {
            Write-Log "--- STEP 2: TLS Hardening ---" -Level INFO
            Set-TLSHardening | Out-Null
        }

        # SCHRITT 2.5: AD-Vorbereitung
        if ($Global:Checks["DoADPrep"].Checked -and ($Global:ChkPrepSchema.Checked -or $Global:ChkPrepAD.Checked -or $Global:ChkPrepDom.Checked)) {
            Write-Log "--- STEP 2.5: AD Preparation ---" -Level INFO
            if (-not $ExchangeSetupPath) { Write-Log "No setup path - AD prep skipped" -Level WARNING }
            else {
                $waitMin = [int]$Global:NumWaitMin.Value
                if ($Global:ChkPrepSchema.Checked) {
                    Invoke-ExchangePrepareStep -SetupPath $ExchangeSetupPath -Step "PrepareSchema" | Out-Null
                    if ($waitMin -gt 0) { Wait-ADReplication -Minutes $waitMin }
                }
                if ($Global:ChkPrepAD.Checked) {
                    Invoke-ExchangePrepareStep -SetupPath $ExchangeSetupPath -Step "PrepareAD" -OrgName $Global:TxtOrg.Text | Out-Null
                    if ($waitMin -gt 0) { Wait-ADReplication -Minutes $waitMin }
                }
                if ($Global:ChkPrepDom.Checked) {
                    if ($Global:RbAllDomains.Checked) {
                        Invoke-ExchangePrepareStep -SetupPath $ExchangeSetupPath -Step "PrepareAllDomains" | Out-Null
                    } elseif ($Global:RbSingleDomain.Checked -and $Global:CmbDomainList.SelectedItem) {
                        Invoke-ExchangePrepareStep -SetupPath $ExchangeSetupPath -Step "PrepareDomain" -DomainName ($Global:CmbDomainList.SelectedItem.ToString()) | Out-Null
                    }
                }
            }
        }

        # SCHRITT 3: Exchange Setup
        if ($Global:Checks["InstallExchange"].Checked -and $ExchangeSetupPath) {
            Write-Log "--- STEP 3: Exchange Setup ---" -Level INFO
            $selectedRoles = @()
            if ($Global:ChkRoleMailbox.Checked) { $selectedRoles += "Mailbox" }
            if ($Global:ChkRoleEdge.Checked)    { $selectedRoles += "EdgeTransport" }
            $rolesStr = $selectedRoles -join ','
            if (-not $rolesStr) {
                Write-Log "No role selected - skipping" -Level ERROR
                if (-not $continueOnError) { return }
            } else {
                $instOK = Install-ExchangeServer `
                    -SetupPath $ExchangeSetupPath -OrgName $Global:TxtOrg.Text `
                    -Roles $rolesStr `
                    -IncludeManagementTools $Global:ChkRoleMgmt.Checked `
                    -AcceptDiagnosticData $Global:ChkDiagData.Checked
                if (-not $instOK -and -not $continueOnError) {
                    Write-Log "Aborted due to setup failure" -Level ERROR; return
                }
            }
        }

        # SCHRITT 4: Antispam-Agenten
        if ($Global:Checks["InstallAntispam"].Checked) {
            Write-Log "--- STEP 4: AntiSpam Agents ---" -Level INFO
            Install-AntiSpamAgents -InstallPath $Global:TxtInstallPath.Text | Out-Null
        }

        # SCHRITT 5: Antispam konfigurieren
        if ($Global:Checks["ConfigAntispam"].Checked) {
            Write-Log "--- STEP 5: Configure AntiSpam ---" -Level INFO
            if (Import-ExchangeManagementShell) {
                Set-AntiSpamConfiguration `
                    -SCLRejectThreshold ([int]$Global:NumSCLReject.Value) `
                    -SCLDeleteThreshold ([int]$Global:NumSCLDelete.Value) `
                    -EnableContent $Global:ChkContent.Checked `
                    -EnableSenderID $Global:ChkSenderID.Checked `
                    -EnableSenderFilter $Global:ChkSendFil.Checked `
                    -EnableRecipientFilter $Global:ChkRecipFil.Checked `
                    -EnableSenderReputation $Global:ChkSendRep.Checked | Out-Null
            }
        }

        # SCHRITT 6: Verifikation
        if ($Global:Checks["VerifyInstall"].Checked) {
            Write-Log "--- STEP 6: Verification ---" -Level INFO
            Test-ExchangeInstallation | Out-Null
        }

        # SCHRITT 7: DBs
        if ($Global:Checks["CreateDBs"].Checked) {
            Write-Log "--- STEP 7: Create databases ---" -Level INFO
            $BtnCreateDBNow.PerformClick()
        }

        # SCHRITT 8: DAG
        if ($Global:Checks["CreateDAG"].Checked) {
            Write-Log "--- STEP 8: DAG ---" -Level INFO
            $BtnCreateDAGNow.PerformClick()
        }

        # SCHRITT 9: ISO unmount
        if ($Global:Checks["DismountISO"].Checked -and $ISOMountedByScript -and $Global:TxtISO.Text) {
            Write-Log "--- STEP 9: Dismount ISO ---" -Level INFO
            Dismount-ExchangeISO -ISOPath $Global:TxtISO.Text
        }

        Write-Log "==============================================" -Level SUCCESS
        Write-Log "===   PROCESS COMPLETED   ===" -Level SUCCESS
        Write-Log "==============================================" -Level SUCCESS

        $msg = "Process complete!`r`nLog: $Global:LogFile"
        if ($Global:Checks["ApplyTLS"].Checked) { $msg += "`r`n`r`nIMPORTANT: TLS Hardening - REBOOT required!" }
        [System.Windows.Forms.MessageBox]::Show($msg,(Get-T "Info"),'OK','Information')
    }
    catch {
        Write-Log ("CRITICAL ERROR: " + $_) -Level ERROR
        [System.Windows.Forms.MessageBox]::Show(("Error: " + $_),(Get-T "Error"),'OK','Error')
    }
})
$TabRun.Controls.Add($BtnStartAll)
#endregion

#region ============================ STATUSZEILE ============================
$Global:StatusLabel = New-Object System.Windows.Forms.Label
$Global:StatusLabel.Location=New-Object System.Drawing.Point(10,700)
$Global:StatusLabel.Size=New-Object System.Drawing.Size(($Global:FormWidth-130),28)
$Global:StatusLabel.BorderStyle="FixedSingle"
$Global:StatusLabel.BackColor=$Global:ColorPanel; $Global:StatusLabel.ForeColor=$Global:ColorText
$Global:StatusLabel.Text = "  " + (Get-T "Ready") + " | Log: $Global:LogFile"
$Global:StatusLabel.TextAlign="MiddleLeft"
$Form.Controls.Add($Global:StatusLabel)

$BtnExit = New-Button (Get-T "Exit") ($Global:FormWidth-110) 700 90 28 $Global:ColorError
$BtnExit.Add_Click({ $Form.Close() })
$Form.Controls.Add($BtnExit)
#endregion

#region ============================ FORM SHOWN - SPLASH AUTO-CHECK ============================
$Form.Add_Shown({
    try {
        Show-SplashScreen

        $issues = @()
        $info_items = @()

        # 1. System
        Update-SplashStatus (Get-T "SplashSysInfo")
        try {
            $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
            $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
            $ramGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
            $sysDrive = Get-PSDrive -Name ($env:SystemDrive.Replace(":","")) -ErrorAction SilentlyContinue
            $freeGB = [math]::Round($sysDrive.Free / 1GB, 1)
            $info_items += "OS: $($os.Caption)"
            $info_items += "RAM: $ramGB GB | Free C:\: $freeGB GB"
            $info_items += "Computer: $($cs.Name).$($cs.Domain)"
            if ($ramGB -lt 8)   { $issues += "RAM < 8 GB" }
            if ($freeGB -lt 30) { $issues += "Free space < 30 GB" }
        } catch {}
        Start-Sleep -Milliseconds 200

        # 2. ISO
        Update-SplashStatus (Get-T "SplashISO")
        $found = @(Find-MountedExchangeISO)
        $Global:DetectedISOs = $found
        if ($found.Count -gt 0) {
            $Global:CmbMountedDrives.Items.Clear()
            foreach ($f in $found) { [void]$Global:CmbMountedDrives.Items.Add($f.Display) }
            $Global:CmbMountedDrives.SelectedIndex = 0
            $Global:RbISOMounted.Checked = $true; $Global:RbISOFile.Checked = $false
            $info_items += "ISO detected: $($found[0].DriveLetter)"
        } else {
            $info_items += "ISO: not mounted"
        }
        Start-Sleep -Milliseconds 200

        # 3. Voraussetzungen
        Update-SplashStatus (Get-T "SplashPrereq")
        $prereqStatus = Get-PrerequisiteStatus
        if (-not $prereqStatus.DotNet48)   { $issues += ".NET 4.8 missing" }
        if (-not $prereqStatus.VC2012)     { $issues += "VC++ 2012 missing" }
        if (-not $prereqStatus.VC2013)     { $issues += "VC++ 2013 missing" }
        if (-not $prereqStatus.URLRewrite) { $issues += "URL Rewrite missing" }
        if (-not $prereqStatus.UCMA)       { $issues += "UCMA missing" }
        if (-not $prereqStatus.FeaturesOK) { $issues += ($prereqStatus.MissingFeatures.Count.ToString() + " Win-Features missing") }
        if ($prereqStatus.SMB1Enabled)     { $issues += "SMB1 still active" }
        try { $BtnRefreshPrereq.PerformClick(); $Global:PrereqStatusLoaded = $true } catch {}
        Start-Sleep -Milliseconds 200

        # 4. Domain
        Update-SplashStatus (Get-T "SplashDomain")
        $isDomainJoined = $false
        try {
            if ($cs.PartOfDomain) {
                $isDomainJoined = $true
                $info_items += "Domain: $($cs.Domain)"
            } else { $issues += "Server NOT in domain" }
        } catch {}
        $perm = Test-ExchangePrepPermissions
        if ($isDomainJoined) {
            if (-not $perm.IsSchemaAdmin -or -not $perm.IsEnterpriseAdmin -or -not $perm.IsDomainAdmin) {
                $issues += "Permissions incomplete"
            } else { $info_items += "Permissions: complete" }
        }
        Start-Sleep -Milliseconds 200

        # 5. AD
        Update-SplashStatus (Get-T "SplashAD")
        if ($isDomainJoined) {
            try {
                $domains = Get-ADDomainList
                $Global:CmbDomainList.Items.Clear()
                foreach ($d in $domains) { [void]$Global:CmbDomainList.Items.Add($d) }
                if ($Global:CmbDomainList.Items.Count -gt 0) { $Global:CmbDomainList.SelectedIndex = 0 }

                $adInfo = Get-ExchangeSchemaInfo

                # Auto-Sync Org-Name
                if ($adInfo.ExchangeOrgName -and $adInfo.ExchangeOrgName -ne "(not yet installed)") {
                    if ($Global:TxtOrg.Text -ne $adInfo.ExchangeOrgName) {
                        $Global:TxtOrg.Text = $adInfo.ExchangeOrgName
                    }
                }

                # Labels setzen
                $Global:LblADSchemaCur.Text = $adInfo.SchemaVersion
                $Global:LblADSchemaReq.Text = $adInfo.SchemaVersionNeeded
                $Global:LblADOrgCur.Text    = "$($adInfo.OrgVersion) ($($adInfo.ExchangeOrgName))"
                $Global:LblADOrgReq.Text    = $adInfo.OrgVersionNeeded
                $Global:LblADDomCur.Text    = $adInfo.DomainVersion
                $Global:LblADDomReq.Text    = $adInfo.DomainVersionNeeded

                $sNum = $adInfo.SchemaVersion -match '^\d+$'
                $oNum = $adInfo.OrgVersion -match '^\d+$'
                $dNum = $adInfo.DomainVersion -match '^\d+$'

                if ($adInfo.SchemaOK -or ($sNum -and [int]$adInfo.SchemaVersion -gt [int]$adInfo.SchemaVersionNeeded)) {
                    $Global:LblADSchemaSt.Text = "OK"; $Global:LblADSchemaSt.ForeColor = $Global:ColorAccent2
                    $Global:ChkPrepSchema.Checked = $false
                } else {
                    $Global:LblADSchemaSt.Text = "Update needed"; $Global:LblADSchemaSt.ForeColor = $Global:ColorWarning
                    $Global:ChkPrepSchema.Checked = $true; $issues += "AD Schema update"
                }
                if ($adInfo.OrgOK -or ($oNum -and [int]$adInfo.OrgVersion -gt [int]$adInfo.OrgVersionNeeded)) {
                    $Global:LblADOrgSt.Text = "OK"; $Global:LblADOrgSt.ForeColor = $Global:ColorAccent2
                    $Global:ChkPrepAD.Checked = $false
                } else {
                    $Global:LblADOrgSt.Text = "Update needed"; $Global:LblADOrgSt.ForeColor = $Global:ColorWarning
                    $Global:ChkPrepAD.Checked = $true; $issues += "Exchange Org update"
                }
                if ($adInfo.DomainOK -or ($dNum -and [int]$adInfo.DomainVersion -gt [int]$adInfo.DomainVersionNeeded)) {
                    $Global:LblADDomSt.Text = "OK"; $Global:LblADDomSt.ForeColor = $Global:ColorAccent2
                    $Global:ChkPrepDom.Checked = $false
                } else {
                    $Global:LblADDomSt.Text = "Update needed"; $Global:LblADDomSt.ForeColor = $Global:ColorWarning
                    $Global:ChkPrepDom.Checked = $true; $issues += "Domain update"
                }

                $Global:LblADUser.Text = $perm.Username
                $pp = @()
                $pp += if ($perm.IsSchemaAdmin) { "[X] Schema-Admins" } else { "[ ] Schema-Admins" }
                $pp += if ($perm.IsEnterpriseAdmin) { "[X] Enterprise-Admins" } else { "[ ] Enterprise-Admins" }
                $pp += if ($perm.IsDomainAdmin) { "[X] Domain-Admins" } else { "[ ] Domain-Admins" }
                $Global:LblADPerms.Text = ($pp -join "  |  ")
                $allOK = $perm.IsSchemaAdmin -and $perm.IsEnterpriseAdmin -and $perm.IsDomainAdmin
                $Global:LblADPerms.ForeColor = if ($allOK) { $Global:ColorAccent2 } else { $Global:ColorWarning }

                $info_items += "AD-Schema: $($adInfo.SchemaVersion) | Org: $($adInfo.OrgVersion) | Dom: $($adInfo.DomainVersion)"
                $Global:ADStatusLoaded = $true
            } catch {
                $issues += "AD lookup error"
                Write-Log ("AD lookup in splash failed: " + $_) -Level WARNING
            }
        }
        Start-Sleep -Milliseconds 200

        # 6. Exchange-Services
        Update-SplashStatus (Get-T "SplashExch")
        try {
            $exchInst = Test-Path "C:\Program Files\Microsoft\Exchange Server\V15\Bin"
            if ($exchInst) {
                $svc = Get-Service -Name "MSExchangeIS" -ErrorAction SilentlyContinue
                if ($svc -and $svc.Status -eq "Running") {
                    $info_items += "Exchange: installed + running"
                } else {
                    $info_items += "Exchange: installed but not running"
                }
            } else {
                $info_items += "Exchange: not yet installed"
            }
        } catch {}
        Start-Sleep -Milliseconds 200

        # 7. Pending Reboot
        Update-SplashStatus (Get-T "SplashReboot")
        try {
            $rebootPending = $false
            if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") { $rebootPending = $true }
            if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") { $rebootPending = $true }
            if ($rebootPending) { $issues += "Reboot pending" }
        } catch {}
        Start-Sleep -Milliseconds 200

        # Final
        if ($issues.Count -eq 0) {
            Update-SplashStatus (Get-T "SplashDoneOK")
        } else {
            Update-SplashStatus ((Get-T "SplashDoneIssues") -f $issues.Count)
        }
        Start-Sleep -Milliseconds 1200

        Close-SplashScreen

        # Zusammenfassung im Log
        Write-Log "==============================================" -Level INFO
        Write-Log " SYSTEM CHECK COMPLETE" -Level INFO
        Write-Log "==============================================" -Level INFO
        foreach ($i in $info_items) { Write-Log ("  " + $i) -Level INFO }
        Write-Log "----------------------------------------------" -Level INFO
        if ($issues.Count -eq 0) {
            Write-Log " ALL OK - ready to configure!" -Level SUCCESS
        } else {
            Write-Log (" REQUIRED ACTIONS (" + $issues.Count + "):") -Level WARNING
            foreach ($i in $issues) { Write-Log ("   - " + $i) -Level WARNING }
        }
        Write-Log "==============================================" -Level INFO

        # MessageBox bei Issues
        if ($issues.Count -gt 0) {
            $msg = "System check complete!`r`n`r`nRequired actions ($($issues.Count)):`r`n"
            foreach ($i in $issues) { $msg += "  - $i`r`n" }
            [System.Windows.Forms.MessageBox]::Show($msg, "System Check", 'OK', 'Information')

            $hasPrereqIssue = $false; $hasADIssue = $false
            foreach ($i in $issues) {
                if ($i -match "VC\+\+|\.NET|URL|UCMA|Win-Features|SMB1") { $hasPrereqIssue = $true }
                if ($i -match "Schema|Org|Domain")                       { $hasADIssue = $true }
            }
            if ($hasPrereqIssue) { $TabControl.SelectedTab = $TabPrereq }
            elseif ($hasADIssue) { $TabControl.SelectedTab = $TabADPrep }
        }
    }
    catch {
        Close-SplashScreen
        Write-Log ("Auto-start error: " + $_) -Level ERROR
    }
})
#endregion

#region ============================ GUI START ============================
try {
    Write-Log ("Microsoft Exchange SE Configuration Center v3.6 started") -Level INFO
    Write-Log ("Language: " + $Global:CurrentLang) -Level INFO
    Write-Log ("Log file: " + $Global:LogFile) -Level INFO
    [void]$Form.ShowDialog()
    Write-Log "GUI closed" -Level INFO
}
catch {
    Write-Host ("GUI error: " + $_) -ForegroundColor Red
}
finally {
    if ($Form) { $Form.Dispose() }
}
#endregion
