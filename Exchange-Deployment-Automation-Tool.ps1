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
    - Live-Fortschrittsanzeige mit 14 Installationsphasen (Setup-Task + OK) & Live-Setup-Log
    - Post-Installation Konfiguration (Services, Zertifikate, Koexistenz)

.FEATURES
    ✓ Vollautomatisierung – Keine manuelle Intervention erforderlich
    ✓ Multi-Version Support – Exchange 2016, 2019, Standard Edition
    ✓ Enterprise-ready – ForestPrep, DomainPrep, DAG-Vorbereitung
    ✓ Robuste Fehlerbehandlung – Umfassende Validierung & Error-Handling
    ✓ Detailliertes Logging – Alle Operationen dokumentiert in C:\ScriptLog\
    ✓ Mehrsprachig – Deutsch (DE) & Englisch (EN) mit Auto-Detection
    ✓ Admin-Auto-Elevation – Automatische UAC-Eskalation mit RunAs
    ✓ AntiSpam-Steuerung – Agents einzeln aktivierbar/deaktivierbar (Sender-ID immer aus)
    ✓ DB-Generator – Postfach-Datenbanken mit editierbarer Vorschau (EDB-/Log-Pfade pro Zeile)
    ✓ URL-Übernahme – Interne/externe URLs vom bestehenden Exchange auslesen & auf den neuen übernehmen (Autodiscover als SCP – nur ein Feld)
    ✓ Zertifikats-Center – PFX-Import, AD-CS-Anforderung oder selbstsigniertes Zertifikat (freie SAN-Liste, SAN aus URLs ableiten, volle Fensterhöhe)
    ✓ AD-Prep-Verifikation – Automatische Ergebniskontrolle direkt nach jedem Adprep-Lauf
    ✓ Responsive GUI – Frei skalierbares Fenster (Vollbild/maximiert); alle Felder & Schriften skalieren proportional mit
    ✓ Live-Fortschrittsanzeige – 14 Installationsphasen (Setup-Task + OK) mit ProgressBar & Phasentext
    ✓ Live-Setup-Log – Phasen-Zuordnung aus dem Setup-Log, Restzeit-Schätzung
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
       - Automatische Ergebniskontrolle (Schema, Org, DomainPrep, Replikation)

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
       - URL-Übernahme vom Alt-Exchange
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
    Rocco Ammon

.VERSION
    1.4 (Production Ready) – September 2026

.REPOSITORY
    https://gitlab.com/RoccoAmmon/Exchange-Deployment-Automation-Tool

.WIKI
    https://gitlab.com/RoccoAmmon/Exchange-Deployment-Automation-Tool/-/wiki

.SUPPORT
    Issues:      https://gitlab.com/RoccoAmmon/Exchange-Deployment-Automation-Tool/-/issues
    Diskussionen: https://gitlab.com/RoccoAmmon/Exchange-Deployment-Automation-Tool/-/issues
    Dokumentation: https://gitlab.com/RoccoAmmon/Exchange-Deployment-Automation-Tool/-/wiki

.HINWEISE
    • Zuerst in LAB/TEST testen!
    • Vor Ausführung: Vollständiges BACKUP erstellen
    • Windows Updates VOR der Ausführung durchführen
    • Installationsmedium (ISO) bereitstellen
    • Mindestens 60-90 Minuten Zeit einplanen
    • Support-Kanal (Email/Chat) bereithalten

.CHANGELOG
    1.4 (2026-09-28)
    - Tab "URLs & Zertifikate" in zwei Reiter geteilt: "URLs" und "Zertifikate"
      (Zertifikats-Layout neu gesetzt - keine ueberlappenden Texte mehr)
    - URLs aus einer einzigen Domain erzeugen: Basis-Domain eingeben (z. B. mail.test.de),
      Haekchen "externe URLs = interne", Button "URLs vervollstaendigen" ergaenzt die
      Exchange-Standardpfade (/owa, /ecp, /EWS/Exchange.asmx, /mapi, /oab,
      /Microsoft-Server-ActiveSync, /autodiscover/autodiscover.xml); live beim Tippen
    - Interne/externe URLs (OWA, ECP, EWS, ActiveSync, Autodiscover,
      MAPI, OAB) weiterhin vom bestehenden Exchange auslesbar und anwendbar
    - PowerShell-VD wird NICHT angefasst: die Zeile in der URL-Tabelle ist nur
      sichtbar (read-only, Tooltip), wird weder erzeugt noch gesetzt und bleibt
      damit wie vom Exchange-Setup angelegt (http://SERVER/powershell)
    - Zertifikats-Funktionen: PFX-Import mit Dialog, AD-CS-Anforderung oder selbstsigniertes
      Zertifikat mit frei definierbarer SAN-Liste und optionaler Aktivierung
      (IIS, SMTP, IMAP, POP)
    - Automatische AD-Prep-Ergebniskontrolle direkt nach dem Adprep (Schema, Org, DomainPrep
      pro Forest-Domain, Berechtigungen, Schema-Replikation über alle DCs)
    - AD-Status-Gruppe (Schema/Org/Domain, Benutzer, Berechtigungen) wird nach jedem
      Adprep-Lauf und nach jedem Ergebnis-Check automatisch neu gefuellt - das
      manuelle Klicken auf "Status aktualisieren" entfaellt
    - Sicherheitsgate vor der Exchange-Installation: STEP 3 prueft vor dem Setup,
      ob alle AD-Pruefpunkte OK sind, und verhindert die Installation andernfalls
      (Meldung mit den nicht OK Pruefpunkten, Abbruch des Laufs)
    - Neue Workflow-Optionen: "Zertifikat erstellen" und "URLs setzen"
    - Config-Export/-Import um URLs und Zertifikatsparameter erweitert
    - Splash-Screen füllt die URLs beim Start automatisch vor und prüft das AD-Prep-Ergebnis
    - Layout-Überarbeitung: alle Tabs ohne Überlauf/Überlappung (u. a. AD-, Install-,
      Datenbanken-, DAG-, TLS- und der neue URL-Tab)
    - ISO-Mount/Dismount automatisiert: die Optionen "ISO automatisch mounten" und
      "ISO am Ende automatisch unmounten" wurden entfernt - die ISO wird gemountet,
      sobald ein Schritt sie braucht, und NACH JEDEM Lauf (auch bei Abbruch) wieder
      freigegeben; manuell gemountete Laufwerke bleiben unangetastet
    - Bugfix: "Exchange installieren" ohne die alte Mount-Option übersprang STEP 3
      stillschweigend (leerer Setup-Pfad) - jetzt wird die ISO bei Bedarf immer
      gemountet und fehlende Setup-Pfade werden sichtbar protokolliert
    - Installationsanzeige zeigt die echten 14 Setup-Phasen (Start-PreConfiguration,
      Start-PreSetup, Start-PreFileCopy, install-msipackage, install-LanguageFiles,
      Start-PostFileCopy, install-Languages, Install-AdminToolsRole,
      Install-BridgeheadRole, Install-ClientAccessRole, Install-MailboxRole,
      Install-FrontendTransportRole, Install-CafeRole, Start-PostSetup): pro Phase
      genau zwei Zeilen - "[ n/14] <Task> (<Label>) ..." beim Start und
      "[ n/14] <Task> OK" am Ende, bei Abbruch "[ n/14] <Task> FEHLER (Setup-Exit n)";
      am Ende steht "Phasen-Report: n von 14 Punkten mit OK quittiert"; Untertasks
      (start-setupservice, Write-ExchangeSetupLog, new-perfCounters ...) erzeugen
      waehrend des Setups keine eigenen START/DONE-Zeilen mehr, Performance-Counter-
      Zeilen und die harmlose Warnung "... did not exist, this is not an error"
      werden ebenfalls gefiltert
    - Bugfix: die Fortschrittsanzeige sprang sofort auf 13/13 - die Fuzzy-Muster
      ("Configur", "Service", "Transport", ...) trafen fast jede Logzeile, und
      "Finished executing" (kommt nach jedem Phasenwechsel) setzte den Balken
      sofort auf Maximum; jetzt bewegen nur exakte Task-Namen den Fortschritt
      (Get-SetupPhaseIndex, Start-SetupPhase, Complete-SetupPhase)
    - Autodiscover-SCP wird beim Anwenden der URLs mitgesetzt: die interne
      Autodiscover-URL geht zusaetzlich ueber Set-ClientAccessService
      -AutoDiscoverServiceInternalUri nach Active Directory (Outlook bezieht
      genau diesen SCP-Eintrag)
    - Bugfix: "URLs anwenden" fragte interaktiv nach "Identity:" und blieb
      haengen - Set-OwaVirtualDirectory & Co. wurden ohne -Identity aufgerufen;
      jetzt wird die Identity vom geholten VD-Objekt uebergeben (Fallback
      RECHNER\Name), ohne Identity wird der Dienst mit protokolliertem Fehler
      uebersprungen, und -Confirm:$false verhindert weitere Rueckfragen
    - Bugfix: Set-AutodiscoverVirtualDirectory meldete "kein Parameter, der dem
      Parameternamen 'InternalUrl' entspricht" - diese URL-Parameter gibt es nur
      in Exchange 2010 (ab 2013 fehlen sie); jetzt werden per Get-Command nur die
      verfuegbaren URL-Parameter uebergeben, sonst wird der Schritt mit Log-Hinweis
      uebersprungen (die Autodiscover-URL laeuft ueber den SCP)
    - Autodiscover-Zeile in der URL-Tabelle hat nur noch EIN Feld: Autodiscover
      besitzt keine interne/externe Trennung, eingetragen wird ausschliesslich
      die SCP-URI (AutoDiscoverServiceInternalUri); die externe Spalte wird in
      dieser Zeile nicht angelegt (Tooltip URL_AdTip erklaert das), "URLs
      vervollstaendigen" erzeugt dort nur die interne URL, und alle Lese-/
      Schreibzugriffe auf die Dienst-Tabelle laufen ueber die neuen Helper
      Get-/Set-UrlFieldValue, die ein fehlendes Feld pruefen
    - Zertifikatsreiter komplett neu aufgebaut und nutzt jetzt das ganze Fenster:
      drei Gruppen ueber die volle TabPage-Hoehe (Status mit "Status aktualisieren",
      Parameter mit vergrössertem SAN-Feld 750x112 und neuem Button "SAN aus URLs
      ableiten", Aktionen mit drei grossen Buttons) statt einer 284-px-Gruppe,
      die oben in der GUI hing und darunter Leerraum liess
    - Bugfix: Modus "Von der AD-Zertifikatsstelle (CA) ausstellen" scheiterte mit
      "kein Parameter, der dem Parameternamen 'DNSName' entspricht" - das Cmdlet
      heisst -DomainName (SAN-Liste), nicht -DNSName; zusaetzlich -Force gegen die
      interaktive SMTP-Rueckfrage beim Erzeugen, und -DomainController
      $env:COMPUTERNAME entfiel (der Parameter erwartet einen DC-FQDN, nicht den
      Exchange-Serversnamen)
    - Modus "AD-Zertifikatsstelle" fordert jetzt WIRKLICH bei der CA an:
      New-ExchangeCertificate -GenerateRequest -> UTF-16-Requestdatei ->
      certreq -submit (CA-Suche in AD ueber CN=Enrollment Services, neue Funktion
      Get-EnterpriseCaConfig) -> certreq -accept -> Import-ExchangeCertificate ->
      Enable-ExchangeCertificate; neues Eingabefeld "CA-Template:" (Standard
      WebServer, Config-Schluessel Cert.Template) und Parameter -CAConfig;
      Fehler (keine CA, certreq-Exit-Code als Hex, leerer Import) landen mit
      Grund im Log, die Temporaerdateien werden immer entfernt
    - Bugfix: Publish-SelfSignedCertificateToExchange endete mit
      "Pfadformat wird nicht unterstuetzt" - der X509Certificate2-Konstruktor
      bekam einen Cert:\-Provider-Pfad (erwartet eine echte Datei); jetzt das
      Objekt direkt nutzen, Fallback: neue Funktion Get-LocalStoreCertificate
      (Store-API per Thumbprint)
    - Bugfix: nach Zertifikatserstellung "Fehler beim Formatieren einer
      Zeichenfolge: Der Index ... Argumentenliste" - MessageBox::Show mit
      "-f a, b, c" zerriss die Argumentliste (erstes Komma beendet das erste
      Argument, {1} blieb leer); Status-Text wird vorberechnet und alle
      Cert_Active-Stellen nutzen die sichere -f @(...)-Form
    - Bugfix: Root-Store-Eintrag warf "kein Parameter, der dem Parameternamen
      'CertStoreLocation' entspricht" - Export-Certificate exportiert nur in
      eine Datei (-FilePath); jetzt Store-API ueber die neue Funktion
      Add-LocalStoreCertificate (LocalMachine\Root: Open/Add/Close, keine
      Temporaerdatei)
    - Zertifikatsmodus steht jetzt im Log (Certificate mode: AD-CS /
      self-signed, auch im Workflow-STEP 6.5) plus WARNING, wenn das
      Import-(PFX)-Radio aktiv ist und trotzdem "Erstellen" gedrueckt wird -
      vorher entstand stillschweigend ein selbstsigniertes Zertifikat
    - Standalone-CA unterstuetzt: neues Feld "CA:" (Config-Schluessel Cert.CA,
      Tooltip Cert_CATip) fuer SERVER\CA-Name - Standalone-CAs sind in AD nicht
      registriert (nur Enterprise CAs fuellen CN=Enrollment Services), leer =
      AD-Suche; die Fehlermeldung nennt den Hinweis. Wartende Antraege werden
      zweisprachig erkannt ("pending"/"ausstehend", Exit 0 ohne .cer, die
      Antrags-ID aus RequestId:/Anforderungs-ID:), in $Global:CertPendingReqId
      gemerkt und nach der Freigabe (certsvc.msc -> Pending Requests -> Issue,
      dt: Ausstehende Zertifikatanforderungen -> Freigeben)
      beim naechsten Klick per certreq -config CA -retrieve ID file abgeholt -
      bis dahin keine Neuanfrage (kein Pending-Stapel); abgelehnte Antraege
      bekommen einen eigenen ERROR, unbekannte Abruffehler eine WARNING mit
      Handbefehl, und die CA wird vor der Antragserzeugung geprueft
    - GUI-Start protokolliert Skript-Pfad und Aenderungszeit (Script: /
      Script last modified:) - laufende Sitzungen laden die Datei nur beim
      Start, veraltete Kopie ist damit sofort im Log erkennbar
    - CA-Eingabe wird vor dem Submit geprueft: Format SERVER\CA-NAME
      (Rechnername zuerst, nicht die Domain) plus DNS-Aufloesbarkeit ueber die
      neue Funktion Test-HostResolvable - sonst endete certreq mit 0x800706BA
      "RPC-Server ist nicht verfuegbar"; im Fehlerfall wird die verwendete
      Kennung mit Format-Hinweis mitgeloggt
    - UCMA-Medium-Vorab-Pruefung: neue Funktion Get-ExchangeMediaStatus
      (frischer Laufwerk-Scan ueber Find-MountedExchangeISO - erkennt
      gemountete ISO-Images UND eingelegte Exchange-CDs/DVDs ueber Volume-
      Label bzw. UCMARedist-Ordner - plus die GUI-ISO-Datei als Auto-Mount-
      Quelle; Pfad-Zusammenbau ohne Join-Path, damit ein verschwundenes
      Laufwerk nicht per Exception den ganzen Check abbricht); ist UCMA
      angehakt, nicht installiert und kein Medium da, bricht
      Install-PrerequisiteSoftware BEVOR Schritt [1/9] ab (zweisprachiger
      ERROR vor jeder Aenderung, mit Hinweis, UCMA abzuwaehlen), sonst
      protokolliert eine INFO die gefundene Quelle; die Statuszeile
      "UCMA 4.0" im Voraussetzungs-Tab zeigt den Medium-Zustand vor dem
      Klick (Medium-Quelle bzw. rot "FEHLT - kein Medium! ISO mounten /
      CD einlegen"), und der [4/9]-Guard nutzt jetzt denselben Helper
      statt nur Radio-Status/gemerkter ISO-Liste (eingelegte CD ohne
      vorherige Anzeige wurde uebersehen)
    - Bugfix: EWS-Standardpfad war /ews statt /EWS/Exchange.asmx - frisches
      Exchange konfiguriert in Get-WebServicesVirtualDirectory
      https://FQDN/EWS/Exchange.asmx, und genau diese URL geht ueber
      Autodiscover an die Clients; /ews ohne Exchange.asmx ist kein
      EWS-Endpunkt, daher lief "URLs vervollstaendigen" auf einen
      kaputten Endpunkt. Andere Standardpfade bleiben unveraendert
    - Autodiscover-SCP wird mit Host autodiscover.<Domain> gebaut: "URLs
      vervollstaendigen" leitet den Host aus der URL-Basis ab (neuer
      Helper Get-AutodiscoverHost: fuehrendes Dienst-Label mail/www/
      webmail/email/smtp/exchange/owa/mx wird ersetzt - mail.test.de ->
      autodiscover.test.de - sonst Praefix, autodiscover.* bleibt; Scheme/
      Pfad verworfen, Port bleibt) statt den Basis-Host zu verwenden;
      entspricht der Microsoft-Doku, dem von Outlook extern hartcoded
      geprueften Namen autodiscover.<smtp-domain> und der SAN-Vorlage
      Get-DefaultSanNames (DNS-Eintrag + SAN fuer den abgeleiteten Namen
      vorausgesetzt); Tooltip URL_AdTip nennt die Ableitung, der Pfad
      /autodiscover/autodiscover.xml bleibt unveraendert
    - Bugfix: Das Feld "Installations-Pfad" hatte keine Wirkung auf die
      Installation - der Workflow uebergab -TargetDir nie an setup.exe
      (der Parameter existierte, wurde aber nicht gefuellt), setup installierte
      stillschweigend im Default C:\Program Files\Microsoft\Exchange Server\V15,
      waehrend Anti-Spam-Schritt und Config-Export den Feldwert nutzten (bei
      abweichendem Pfad also z. B. "AntiSpam script not found"); jetzt geht das
      Feld als -TargetDir an das Setup, die neue Funktion
      Resolve-InstallTargetDir validiert/normalisiert vorher (nur absoluter
      lokaler Pfad, Laufwerk muss existieren, Verzeichnis wird angelegt,
      abschliessender Backslash entfaellt - er stünde direkt vor dem
      schliessenden Anfuehrungszeichen und wuerde dessen Escape zerstoeren),
      ein ungueltiger Pfad bricht mit zweisprachigem ERROR vor dem Setup ab;
      /TargetDir gilt weiterhin nur im Install-Modus (nicht RecoverServer)
    - Bugfix: "URLs anwenden" blockierte stundenlang an der interaktiven
      Exchange-Rueckfrage "Der fuer den Parameter "InternalUrl" angegebene
      Host kann nicht aufgeloest werden. Mochten Sie den Vorgang wirklich
      fortsetzen?" ([J] Ja [A] Ja, alle ...) - ein ShouldContinue-Prompt des
      Cmdlets selbst, den -Confirm:$false NICHT abschaltet; nicht aufloesbare
      Hosts (z. B. mail.contoso.local) liessen jeden Setter zweimal fragen,
      der UI-Thread-Workflow war eingefroren (beobachtet: 4,5 h an EWS, bis
      jemand "j" tippte). Set-ExchangeUrlConfiguration prueft jetzt vor jedem
      Setter die Hosts der zu setzenden Seiten (verschachtelte Helper
      Get-UrlHostName + Test-UrlSideResolvable ueber Test-HostResolvable):
      unloesbar -> Seite NICHT setzen, zweisprachiger ERROR mit
      Loesungshinweis (DNS-A-Eintrag anlegen, URL-Schritt wiederholen) und
      Fehlerzaehler; gleich fuer den Autodiscover-SCP vor
      Set-ClientAccessService; unveraenderte URLs laufen weiterhin vorher
      durch den "unveraendert"-Check (kein DNS-Fehler); test_url_apply.ps1
      66 Checks (Szenarien J-M), test_url_build.ps1 68 Checks
    - Bugfix: STEP 9 "Dismount ISO" fror die GUI ein und die ISO blieb
      gemountet - nach der STEP-9-Logzeile kam nichts mehr (PROCESS COMPLETED
      fehlte), weil Dismount-DiskImage direkt auf dem UI-Thread aufgerufen
      werden konnte und an offenen Handles des gemounteten Volums haengen-
      bleiben kann; der leere catch{} verschluckte ausserdem jeden Fehler.
      Dismount-ExchangeISO laeuft jetzt in einer Kind-Powershell
      (-NonInteractive) mit WaitForExit(30 s) + Kill() beim Ueberlauf,
      verifiziert den Zustand per Get-DiskImage (Exit 0 getrennt / 2 noch
      gemountet / 1 Fehler) und meldet jeden Ausgang zweisprachig - die GUI
      bleibt bedienbar, der Workflow erreicht PROCESS COMPLETED;
      Dismount-ScriptISO schreibt Diagnose-Marker ("Refreshing mounted ISO
      list ...", "Dismount step finished ...") zur Lokalisation eines
      naechsten Falls; test_iso_mount.ps1 29 Checks
    - Neu: Energiesparung der Netzwerkkarte pruefen und deaktivieren
      (HealthChecker SleepyNICCheck): eigene Karte "NIC power saving
      (SleepyNIC)" rechts in der Statusgruppe des Tabs Voraussetzungen mit
      Statuszeile und Direkt-Button "Energiesparung NIC deaktivieren";
      neue Funktionen Get-NicPowerSavingInfo (liest wie der HealthChecker
      PnPCapabilities pro Adapter unter HKLM\SYSTEM\CurrentControlSet\
      Control\Class\{4D36E972-...} - 24/280 = deaktiviert, Wert fehlt =
      nicht konfiguriert, Multiplexor-Adapter werden uebersprungen) und
      Disable-NicPowerSaving (schreibt PnPCapabilities=24 nur an offene
      Stellen, pro Karte Alt->Neu ins Log, inkl. Hinweis wenn der Treiber
      die Option gar nicht anbietet - z.B. Nutanix-VM: Wert fehlte, wird
      aber trotzdem fuer den HealthChecker gesetzt); Get-PrerequisiteStatus
      liefert NicPowerSavingOK, der Start-Check meldet "NIC power saving
      active" als Issue und springt wie bei SMB1 in den Voraussetzungs-Tab;
      Checkbox "NIC power saving disable (SleepyNIC)" in "Was soll
      installiert werden": neuer Param -DisableNicPower + neuer Schritt
      [8/9] "NIC power saving deactivation (SleepyNICCheck)" in
      Install-PrerequisiteSoftware (Nummerierung /8 -> /9, Power-Plan +
      Pagefile ist jetzt [9/9]), Smart-Auswahl haekt die Checkbox nur ein,
      wenn noch nicht deaktiviert, Config speichert/laedt NicPower (Laden
      alt-kompatibel per Property-Guard); i18n-PrereqNicFix (DE/EN);
      test_nic_power.ps1 46 Checks
    - Bugfix: STEP 7 "Create databases" des Master-Workflows legte im
      kombinierten Lauf KEINE Datenbanken an - der Workflow rief
      BtnCreateDBNow.PerformClick(), und ein PerformClick feuert in WinForms
      nur bei sichtbarem Button (CanSelect); das DB-Tab war nie aktiv, das
      Klick-Ereignis entfiel stillschweigend ohne Logzeile (manueller Klick
      mit offenem Tab funktionierte). Die Aktion steckt jetzt in
      Invoke-DatabaseCreation, die der Workflow DIREKT aufruft; alle
      Abbruchgruende werden protokolliert (leere Liste mit Loesungshinweis,
      Shell nicht ladbar), bestehende DBs gemeldet, Summary am Ende.
      Gleiches Muster fuer STEP 8 (Invoke-DagCreation) und den Start-Status-
      Refresh: BtnRefreshPrereq.PerformClick() lief vor ShowDialog ins
      Leere (Statuswerte blieben "...") - jetzt
      Update-PrerequisiteStatusDisplay, aufgerufen von Buttons UND Splash;
      test_db_create.ps1 27 Checks, test_install_gate.ps1 67 Checks
    - Bugfix: NIC-Erkennung fand gar keine Netzwerkkarten ("Erkennung
      funktioniert nicht") - Get-NicPowerSavingInfo enumerierte den
      Klassen-Key mit -ErrorAction Stop, und unter dem Key liegen gesperrte
      Sonder-Subkeys (z.B. "Properties" mit Access-Denied-ACL): EIN nicht
      lesbarer Eintrag brach die komplette Enumeration ab, der stille
      catch{} lieferte 0 Treffer und die Statuszeile zeigte "no NICs found"
      (reproduziert: 24 Subkeys per Rohzugriff lesbar, 0 Treffer im Code).
      Jetzt SilentlyContinue + Fehlerzaehler, pro Adapter-Key weiterhin
      einzeln gelesen; kommt tatsaechlich kein Adapter heraus, steht der
      Abbruchgrund (Zugriff verweigert / Key nicht gefunden) als ERROR im
      Log statt zu verschwinden, und jeder Status-Refresh schreibt
      zusaetzlich eine INFO-Zeile mit Anzahl gefundener/nicht
      deaktivierter Karten; test_nic_power.ps1 S5 als Regressionstest
    - Pagefile exakt nach HealthChecker PagefileSizeCheck - NUR fuer Exchange
      2019/SE: neue Funktion Get-ExchangeTargetVersion (installiertes Exchange
      ueber Uninstall-Anzeigeversion bzw. Dateiversion der Bin-Binaerien aus
      MsiInstallPath, sonst gemountetes Medium ueber Setup.exe-FileVersion,
      sonst GUI-Ordner/ISO-Dateiname nach ExchangeServerSE/2019/2016/2013;
      major.minor: 15.2 = 2019/SE, 15.1 = 2016, 15.0 = 2013) entscheidet in
      Schritt [9/9]: nur "2019SE" greift ein - automatische Verwaltung aus,
      InitialSize = MaximumSize = exakt 25% der installierten Speicher-
      Groesse (OHNE +10-MB-Zuschlag, das ist die 2013/2016-Regel und wird
      bewusst nicht angewendet) und GENAU EINE Pagefile (die auf dem
      Systemlaufwerk bleibt, zusaetzliche Eintraege werden entfernt, fehlt
      die Einstellung wird sie auf dem Systemlaufwerk angelegt); aeltere
      oder unbekannte Versionen -> Skip mit INFO inkl. erkannter Version.
      Checkbox-Label: "Pagefile (25% RAM, Exchange 2019/SE)";
      test_pagefile.ps1 (30 Checks), test_install_gate.ps1 (82 Checks)
    - Bugfix: Pagefile-Checkbox ohne angehakten "High-Performance Power
      Plan" hatte nie Wirkung - der Block war in if ($SetHighPerformance)
      verschachtelt und wurde stillschweigend uebersprungen (auch im
      Master-Workflow, wenn die Smart-Auswahl das Power-Plan-Kreuz
      entfernte); Schritt [9/9] laeuft jetzt bei SetHighPerformance -or
      $OptimizePageFile, Power-Plan und Pagefile sind zwei unabhaengige
      if-Bloecke

    1.3 (2026-09-12)
    - Fortschrittsanzeige: 13 Installationsphasen mit ProgressBar & Phasentext
    - Live-Setup-Log: Phasen-Zuordnung aus dem Setup-Log, Meilensteine mit [n/13]
    - Restzeit-Schätzung im Heartbeat, Heartbeat-Intervall auf 30s reduziert
    - PrepareAD: OrganizationName wird nur bei Namensänderung übergeben (keine Upgrade-Warnung)
    - GUI-Header: Autor/Version weiter links eingerückt

    1.2 (2026-09-08)
    - Sender-ID-Agent wird immer deaktiviert (veraltet, Checkbox ausgegraut)
    - AntiSpam-Agents werden bei deaktiviertem Haken explizit deaktiviert
    - DB-Generator: Pfade direkt in der Vorschau editierbar
    - Bugfix: DivideByZeroException beim Generieren der DB-Konfiguration behoben

    1.1 (2026-09-07)
    - URL Rewrite Modul wird erst NACH der Windows-Feature-/Rolleninstallation installiert
    - Installationsreihenfolge der Prerequisites korrigiert (Features vor URL Rewrite)
    - Schritt-Nummerierung der Prerequisite-Installation aktualisiert

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
Write-Host "@@DIAG@@ [1/7] Assemblies geladen" -ForegroundColor DarkGray

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
# Setup-Schritte, die tatsaechlich gestartet wurden (fuer den Ergebnis-Report:
# dort muss zwischen "ausgefuehrtem Setup-Schritt" und "Ist-Stand aus AD" getrennt werden)
$Global:AdPrepExecuted     = @()
$Global:PrereqStatusLoaded = $false
$Global:FormWidth          = 1150
$Global:FormHeight         = 820
# Design-Proportionen des Formulars (ClientArea) fuer das responsive Layout
$Global:ResizeDesignW      = 0
$Global:ResizeDesignH      = 0

# Phasenmodell fuer die Setup-Fortschrittsanzeige.
# MASSGEBLICH sind die Top-Level-Tasks aus ExchangeSetup.log:
#   START: "Setup will run the task 'X'"   (Fallback: "Beginning processing: X")
#   ENDE : "Ending processing: X"          (bzw. "Finished executing the task 'X'.")
# Beim frischen Voll-Install-Lauf laeuft Setup in 14 solchen Punkten durch.
# Untertasks (start-setupservice, Write-ExchangeSetupLog, new-perfCounters, ...)
# sind KEINE Phasen - sie erzeugen waehrend der Installation keine eigenen
# START/DONE-Zeilen mehr, sonst ersaufen die 14 Punkte im Rauschen.
# WICHTIG: Die fruehere Fuzzy-Zuordnung ueber Schlagwoerter ("Configur", "Service",
# "Transport" ...) sprang bei jeder Zeile auf die naechsthoehere Phase - daher
# stand die Anzeige schon nach dem 1. Phasenwechsel auf 13/13. Nur exakte
# Task-Namen duerfen den Fortschritt bewegen.
$Global:SetupPhaseDefs = @(
    @{ No=1;  Task='Start-PreConfiguration';        Text=@{DE='Vorkonfiguration (AD-Vorbereitung)';  EN='Pre-configuration (AD prep)'} }
    @{ No=2;  Task='Start-PreSetup';                Text=@{DE='PreSetup (Systemvoraussetzungen)';    EN='PreSetup (system prerequisites)'} }
    @{ No=3;  Task='Start-PreFileCopy';             Text=@{DE='Dateien vorkopieren';                 EN='Copying files (pre)'} }
    @{ No=4;  Task='install-msipackage';            Text=@{DE='Exchange MSI installieren';           EN='Installing Exchange MSI'} }
    @{ No=5;  Task='install-LanguageFiles';         Text=@{DE='Sprachdateien installieren';          EN='Installing language files'} }
    @{ No=6;  Task='Start-PostFileCopy';            Text=@{DE='Dateien nachkopieren';                EN='Copying files (post)'} }
    @{ No=7;  Task='install-Languages';             Text=@{DE='Sprachpakete installieren';           EN='Installing language packs'} }
    @{ No=8;  Task='Install-AdminToolsRole';        Text=@{DE='Verwaltungstools (AdminTools)';       EN='Management tools (AdminTools)'} }
    @{ No=9;  Task='Install-BridgeheadRole';        Text=@{DE='Bridgehead-Rolle (Transport)';        EN='Bridgehead role (transport)'} }
    @{ No=10; Task='Install-ClientAccessRole';      Text=@{DE='Client Access-Rolle';                 EN='Client Access role'} }
    @{ No=11; Task='Install-MailboxRole';           Text=@{DE='Mailbox-Rolle (Datenbanken)';         EN='Mailbox role (databases)'} }
    @{ No=12; Task='Install-FrontendTransportRole'; Text=@{DE='Frontend-Transport-Rolle';            EN='Frontend Transport role'} }
    @{ No=13; Task='Install-CafeRole';              Text=@{DE='CAFE-Rolle (HTTP-Proxys)';            EN='CAFE role (HTTP proxies)'} }
    @{ No=14; Task='Start-PostSetup';               Text=@{DE='PostSetup / Abschluss';              EN='PostSetup / completion'} }
)
$Global:SetupPhaseCount = $Global:SetupPhaseDefs.Count
$Global:SetupPhaseDone  = 0
$Global:SetupPhaseStart = $null
$Global:SetupCurrentPhaseText = ""

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
        AppTitle="Microsoft Exchange SE - Konfigurations-Center"; AppSubtitle="v1.4  |  Rocco Ammon"
        TabPrereq="  Voraussetzungen  "; TabAD="  AD-Vorbereitung  "; TabInstall="  Installation  "
        TabSec="  Sicherheit / TLS  "; TabSpam="  Antispam  "; TabDB="  Datenbanken  "
        TabDAG="  DAG  "; TabRun="  Ausfuehrung und Log  "; TabUrls="  URLs  "; TabCert="  Zertifikate  "
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
        PrereqRefresh="Status aktualisieren"; PrereqInstall="Voraussetzungen jetzt installieren"; PrereqNicFix="Energiesparung NIC deaktivieren"
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
        Run_Info="Live-Output von Setup. Der Fortschrittsbalken zeigt die 14 Installationsphasen - pro Phase eine Zeile mit Setup-Task und OK (bei Fehler der Fehler)."
        Run_ProgressLabel="Installationsfortschritt"; Run_PhaseRunning="Setup laeuft..."
        Run_PhaseDone="Setup erfolgreich abgeschlossen"; Run_PhaseFailed="Setup mit Fehler beendet"
        Run_SaveCfg="Konfig speichern"; Run_LoadCfg="Konfig laden"; Run_ClearLog="Log leeren"
        Run_OpenLog="ExchangeSetup.log oeffnen"; Run_StartAll=">>>  GESAMTEN PROZESS STARTEN  <<<"
        Yes="Ja"; No="Nein"; OK="OK"; Cancel="Abbrechen"; Error="Fehler"; Info="Info"
        Warning="Warnung"; Confirm="Bestaetigung"
        Opt_PrereqCheck="Voraussetzungspruefung"; Opt_RunPrereq="Voraussetzungen vorab installieren"
        Opt_DoADPrep="AD-Vorbereitung im Master-Workflow"
        Opt_InstExch="Exchange Server installieren"; Opt_InstSpam="Antispam-Agenten installieren"
        Opt_CfgSpam="Antispam-Filter konfigurieren"; Opt_Verify="Installation verifizieren"
        Opt_TLS="TLS-Hardening anwenden"; Opt_DBs="Postfach-Datenbanken anlegen"
        Opt_DAG="DAG erstellen + Mitglieder"
        Opt_Admin="Strikte Admin-Pruefung"; Opt_Continue="Bei Fehlern weiter machen"
        Opt_CreateCert="Zertifikat erzeugen/importieren"; Opt_SetUrls="URLs setzen"
        Filt_Content="Content-Filter aktivieren"; Filt_SenderID="Sender-ID-Filter aktivieren (deaktiviert, veraltet)"
        Filt_Sender="Sender-Filter aktivieren"; Filt_Recip="Recipient-Filter aktivieren"
        Filt_Reputation="Sender-Reputation aktivieren"
        URL_ReadTitle="URLs: auslesen oder aus Domain erzeugen"
        URL_Read="Von Exchange auslesen"; URL_Apply="URLs anwenden"; URL_ApplyAuto="Nach Installation anwenden"
        URL_Service="Dienst"; URL_Int="Interne URL"; URL_Ext="Externe URL"
        URL_Table="Virtuelle Directories: interne und externe URL"
        URL_HostInt="Domain intern:"; URL_HostExt="Domain extern:"
        URL_SameHost="externe URLs = interne"
        URL_Build="URLs vervollstaendigen"
        URL_Built="{0} URLs aus der Domain erzeugt (Pfade nach Exchange-Standard)."
        URL_HostEmpty="Bitte zuerst eine Domain eingeben (z. B. mail.test.de)."
        URL_Hint="Beispiel: mail.test.de -> https://mail.test.de/owa (Pfade nach Exchange-Standard)"
        URL_NoExch="Kein Exchange gefunden - Felder bleiben unveraendert."
        URL_ReadOk="{0} Eintraege von Server '{1}' uebernommen."
        URL_Empty="Bitte zuerst mindestens eine URL auslesen oder eintragen."
        URL_Confirm="Die eingetragenen URLs jetzt auf diesem Exchange setzen?"
        URL_Applied="URL-Konfiguration gesetzt ({0} von {1} Diensten)."
        URL_Help="Setzt die internen/externen URLs auf den Directories (OWA, ECP, EWS, ActiveSync, MAPI, OAB); Autodiscover als SCP."
        URL_Help2="PowerShell wird NICHT gesetzt - diese URL bleibt wie vom Exchange-Setup angelegt."
        URL_PsTip="Bleibt Setup-Standard: diese URL wird weder erzeugt noch gesetzt."
        URL_AdTip="Autodiscover hat nur EINE URL: sie wird als SCP (AutoDiscoverServiceInternalUri) in Active Directory gesetzt - daher nur dieses eine Feld. Beim Bauen wird der Host automatisch als autodiscover.<Domain> aus der URL-Basis abgeleitet."
        URL_Status="Status: keine Daten"
        URL_Server="Exchange-Server:"; URL_SrvRefresh="Aktualisieren"
        Cert_Title="Zertifikat (TLS) fuer OWA / ECP / MAPI / Outlook"
        Cert_GrpNew="Zertifikat erstellen oder importieren"
        Cert_GrpAct="Aktionen"
        Cert_Hint="Reihenfolge beliebig: erzeugen (AD-CS oder selbstsigniert) oder PFX importieren, danach aktivieren - uebernommen werden IIS, SMTP, IMAP und POP."
        Cert_RbSelf="Selbstsigniertes Zertifikat erzeugen"
        Cert_RbImport="Zertifikat aus Datei importieren (.pfx)"
        Cert_RbADCS="Von der AD-Zertifikatsstelle (CA) ausstellen"
        Cert_CN="Common Name:"; Cert_Days="Gueltig (Tage):"; Cert_Key="Schluessel:"; Cert_Template="CA-Template:"; Cert_CA="CA:"; Cert_CATip="Standalone-CA: SERVER\CA-NAME eintragen - erster Teil ist der Rechnername des CA-Servers, NICHT die Domain (z.B. WIN-ABC123\contoso). Enterprise-CA: leer lassen, wird in AD gefunden"
        Cert_Pfx="PFX-Datei:"; Cert_Pass="PFX-Kennwort:"; Cert_Browse="Durchsuchen..."
        Cert_San="SAN-Namen:"; Cert_FillSan="SAN aus URLs ableiten"
        Cert_Create="Zertifikat erzeugen"; Cert_ImportBtn="PFX importieren"
        Cert_Enable="Zertifikat aktivieren"
        Cert_Activate="Aktivieren fuer IIS, SMTP, IMAP, POP"
        Cert_NoCert="Noch kein Exchange-Zertifikat aktiv."
        Cert_Active="Aktiv: {0}`r`nbis {1} | Thumbprint {2}"
        Cert_Exported="PFX gesichert: {0}"
        Cert_SanEmpty="Bitte mindestens einen SAN-Namen (FQDN) angeben."
        AD_CheckTitle="AD-Vorbereitung: Ergebnis"
        AD_Check="Ergebnis automatisch pruefen"
        AD_ResultOk="Alle {0} Pruefungen OK (Ist-Stand aus AD) - AD vollstaendig vorbereitet."
        AD_ResultFail="{0} von {1} Pruefungen NICHT OK (Ist-Stand aus AD) - Details im Log."
        AD_ResultNone="Ergebnis-Check noch nicht ausgefuehrt."
        AD_Ran="Ausgefuehrt: {0}"
        AD_InstallBlocked="Exchange-Installation verhindert: die AD-Vorbereitung ist nicht vollstaendig ({0} von {1} Pruefungen NICHT OK)."
        AD_CheckUnknown="Exchange-Installation verhindert: der AD-Status konnte nicht geprueft werden. Bitte 'Ergebnis automatisch pruefen' ausfuehren und das Log pruefen."
    }
    EN = @{
        AppTitle="Microsoft Exchange SE - Configuration Center"; AppSubtitle="v1.4  |  Rocco Ammon"
        TabPrereq="  Prerequisites  "; TabAD="  AD Preparation  "; TabInstall="  Installation  "
        TabSec="  Security / TLS  "; TabSpam="  AntiSpam  "; TabDB="  Databases  "
        TabDAG="  DAG  "; TabRun="  Execution and Log  "; TabUrls="  URLs  "; TabCert="  Certificates  "
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
        PrereqRefresh="Refresh status"; PrereqInstall="Install prerequisites now"; PrereqNicFix="Disable NIC power saving"
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
        Run_Info="Live output from setup. The progress bar shows the 14 installation phases - one line per phase with setup task and OK (error shown on failure)."
        Run_ProgressLabel="Installation progress"; Run_PhaseRunning="Setup running..."
        Run_PhaseDone="Setup completed successfully"; Run_PhaseFailed="Setup finished with errors"
        Run_SaveCfg="Save config"; Run_LoadCfg="Load config"; Run_ClearLog="Clear log"
        Run_OpenLog="Open ExchangeSetup.log"; Run_StartAll=">>>  START ENTIRE PROCESS  <<<"
        Yes="Yes"; No="No"; OK="OK"; Cancel="Cancel"; Error="Error"; Info="Info"
        Warning="Warning"; Confirm="Confirmation"
        Opt_PrereqCheck="Prerequisite check"; Opt_RunPrereq="Install prerequisites first"
        Opt_DoADPrep="AD preparation in master workflow"
        Opt_InstExch="Install Exchange Server"; Opt_InstSpam="Install AntiSpam agents"
        Opt_CfgSpam="Configure AntiSpam filters"; Opt_Verify="Verify installation"
        Opt_TLS="Apply TLS hardening"; Opt_DBs="Create mailbox databases"
        Opt_DAG="Create DAG + members"
        Opt_Admin="Strict admin check"; Opt_Continue="Continue on errors"
        Opt_CreateCert="Create/import certificate"; Opt_SetUrls="Set URLs"
        Filt_Content="Enable Content Filter"; Filt_SenderID="Enable Sender-ID Filter (deaktiviert, veraltet)"
        Filt_Sender="Enable Sender Filter"; Filt_Recip="Enable Recipient Filter"
        Filt_Reputation="Enable Sender Reputation"
        URL_ReadTitle="URLs: read from Exchange or build from a domain"
        URL_Read="Read from Exchange"; URL_Apply="Apply URLs"; URL_ApplyAuto="Apply after installation"
        URL_Service="Service"; URL_Int="Internal URL"; URL_Ext="External URL"
        URL_Table="Virtual directories: internal and external URL"
        URL_HostInt="Internal domain:"; URL_HostExt="External domain:"
        URL_SameHost="external = internal"
        URL_Build="Complete URLs"
        URL_Built="{0} URLs built from the domain (Exchange default paths)."
        URL_HostEmpty="Please enter a domain first (e.g. mail.test.de)."
        URL_Hint="Example: mail.test.de -> https://mail.test.de/owa (Exchange default paths)"
        URL_NoExch="No Exchange found - fields left unchanged."
        URL_ReadOk="Took over {0} entries from server '{1}'."
        URL_Empty="Please read or enter at least one URL first."
        URL_Confirm="Apply the entered URLs to this Exchange now?"
        URL_Applied="URL configuration applied ({0} of {1} services)."
        URL_Help="Applies the internal/external URLs on the virtual directories (OWA, ECP, EWS, ActiveSync, MAPI, OAB); Autodiscover is set as SCP."
        URL_Help2="PowerShell is NOT set - that URL stays as created by Exchange setup."
        URL_PsTip="Setup default: this URL is neither built nor applied."
        URL_AdTip="Autodiscover has only ONE URL: it is written as the SCP (AutoDiscoverServiceInternalUri) in Active Directory - hence the single field. When building, the host is automatically derived as autodiscover.<Domain> from the URL base."
        URL_Status="Status: no data"
        URL_Server="Exchange server:"; URL_SrvRefresh="Refresh"
        Cert_Title="Certificate (TLS) for OWA / ECP / MAPI / Outlook"
        Cert_GrpNew="Create or import certificate"
        Cert_GrpAct="Actions"
        Cert_Hint="Any order: create (AD CS or self-signed) or import a PFX, then activate it - this assigns IIS, SMTP, IMAP and POP."
        Cert_RbSelf="Create self-signed certificate"
        Cert_RbImport="Import certificate from file (.pfx)"
        Cert_RbADCS="Issue from Active Directory CA"
        Cert_CN="Common Name:"; Cert_Days="Valid (days):"; Cert_Key="Key size:"; Cert_Template="CA template:"; Cert_CA="CA:"; Cert_CATip="Standalone CA: enter SERVER\CA-NAME - the first part is the CA server's computer name, NOT the domain (e.g. WIN-ABC123\contoso). Enterprise CA: leave empty, it is found in AD"
        Cert_Pfx="PFX file:"; Cert_Pass="PFX password:"; Cert_Browse="Browse..."
        Cert_San="SAN names:"; Cert_FillSan="Derive SANs from URLs"
        Cert_Create="Create certificate"; Cert_ImportBtn="Import PFX"
        Cert_Enable="Activate certificate"
        Cert_Activate="Enable for IIS, SMTP, IMAP, POP"
        Cert_NoCert="No Exchange certificate active yet."
        Cert_Active="Active: {0}`r`nvalid until {1} | thumbprint {2}"
        Cert_Exported="PFX saved: {0}"
        Cert_SanEmpty="Please provide at least one SAN name (FQDN)."
        AD_CheckTitle="AD Preparation: Result"
        AD_Check="Check result automatically"
        AD_ResultOk="All {0} checks OK (actual AD state) - AD fully prepared."
        AD_ResultFail="{0} of {1} checks NOT OK (actual AD state) - see log for details."
        AD_ResultNone="Result check has not been run yet."
        AD_Ran="Setup steps run: {0}"
        AD_InstallBlocked="Exchange installation blocked: AD preparation is incomplete ({0} of {1} checks NOT OK)."
        AD_CheckUnknown="Exchange installation blocked: could not verify the AD status. Run 'Check result automatically' and inspect the log."
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

Write-Host "@@DIAG@@ [2/7] i18n-Tabelle + Spracherkennung ok" -ForegroundColor DarkGray

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

Write-Host "@@DIAG@@ [3/7] Ordner-Init ok (falls ISE-Warnung: bitte bestaetigen)" -ForegroundColor DarkGray

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
    # AllowEmptyString: leere Trennzeilen ("") duerfen den Mandatory-Parameter NICHT
    # mehr werfen - sonst bricht jeder Aufruf (z. B. Blank-Line vor >>> START) den
    # aufrufenden Codeblock ab (das hat das Setup-Log-Tailing lahmgelegt).
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Message,[ValidateSet("INFO","WARNING","ERROR","SUCCESS")][string]$Level="INFO")
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

#region ============================ SETUP-FORTSCHRITT ============================
function Get-PhaseText {
    param([int]$Step)
    try {
        if ($Step -ge 1 -and $Step -le $Global:SetupPhaseCount) {
            return $Global:SetupPhaseDefs[$Step-1].Text[$Global:CurrentLang]
        }
    } catch {}
    return ""
}

function Initialize-SetupProgress {
    param([string]$Title="")
    try {
        $Global:SetupPhaseDone  = 0
        $Global:SetupPhaseStart = Get-Date
        if ($Global:PrgSetup) {
            try {
                $Global:PrgSetup.Style   = "Continuous"
                $Global:PrgSetup.Minimum = 0
                $Global:PrgSetup.Maximum = $Global:SetupPhaseCount
                $Global:PrgSetup.Value   = 0
                $Global:PrgSetup.Refresh()
            } catch {}
        }
        if ($Global:LblSetupPhase) {
            $t = if ($Title) { $Title } else { (Get-T "Run_PhaseRunning") }
            $Global:LblSetupPhase.Text = ("0 / $($Global:SetupPhaseCount)  -  " + $t)
            $Global:LblSetupPhase.ForeColor = $Global:ColorAccent
            $Global:LblSetupPhase.Refresh()
        }
        try { [System.Windows.Forms.Application]::DoEvents() } catch {}
    } catch { Write-Log ("SetupProgress init error: " + $_) -Level WARNING }
}

function Set-SetupProgress {
    param([Parameter(Mandatory)][int]$Step,[string]$Text="")
    try {
        if ($Step -lt 1) { return }
        if ($Step -gt $Global:SetupPhaseCount) { $Step = $Global:SetupPhaseCount }
        if ($Step -gt $Global:SetupPhaseDone) { $Global:SetupPhaseDone = $Step }
        if (-not $Text) { $Text = Get-PhaseText -Step $Global:SetupPhaseDone }
        $Global:SetupCurrentPhaseText = $Text
        if ($Global:PrgSetup) {
            try {
                if ($Global:PrgSetup.Value -ne $Global:SetupPhaseDone) { $Global:PrgSetup.Value = $Global:SetupPhaseDone }
                $Global:PrgSetup.Refresh()
            } catch {}
        }
        if ($Global:LblSetupPhase) {
            $Global:LblSetupPhase.Text = ("$($Global:SetupPhaseDone) / $($Global:SetupPhaseCount)  -  " + $Text)
            $Global:LblSetupPhase.ForeColor = $Global:ColorAccent
            $Global:LblSetupPhase.Refresh()
        }
        try { [System.Windows.Forms.Application]::DoEvents() } catch {}
    } catch {}
}

# Index (0-basiert) eines Top-Level-Setup-Tasks in der Phasenliste finden.
# Tolerant gegen Anfuehrungszeichen, abschliessenden Punkt und angehaengte
# Parameter ("Install-MailboxRole -DomainController '...'"), NICHT aber gegen
# Teilstrings - Untertasks duerfen nie eine Phase ausloesen.
function Get-SetupPhaseIndex {
    param([string]$Task)
    try {
        $t = "$Task".Trim().Trim('"',"'").Trim().TrimEnd('.').Trim()
        if (-not $t) { return -1 }
        $sp = $t.IndexOf(' ')
        if ($sp -gt 0) { $t = $t.Substring(0, $sp) }
        for ($i = 0; $i -lt $Global:SetupPhaseDefs.Count; $i++) {
            if ([string]::Equals($Global:SetupPhaseDefs[$i].Task, $t, [System.StringComparison]::OrdinalIgnoreCase)) { return $i }
        }
    } catch {}
    return -1
}

# Phasen-Beginn: "[ n/14] Task (Label) ..." + Fortschrittsbalken auf n stellen.
function Start-SetupPhase {
    param([Parameter(Mandatory)][int]$Index,[hashtable]$State)
    try {
        if ($State -and $State.PhaseRunning -eq $Index) { return }   # Doppelmeldung (will-run + beginning)
        $def  = $Global:SetupPhaseDefs[$Index]
        $n    = $Index + 1
        $text = "$($def.Text[$Global:CurrentLang])"
        Write-Log "" -Level INFO
        Write-Log ("[{0,2}/{1}] {2}  ({3}) ..." -f $n, $Global:SetupPhaseCount, $def.Task, $text) -Level INFO
        if ($State) { $State.PhaseRunning = $Index; if ($Index -gt $State.PhaseLastStart) { $State.PhaseLastStart = $Index } }
        Set-SetupProgress -Step $n -Text ("$($def.Task) - $text")
    } catch {}
}

# Phasen-Ende: "[ n/14] Task  OK" (bzw. FEHLER mit Exit-Code) - genau diese eine
# Zeile ist die Rueckmeldung "Paket wurde installiert".
function Complete-SetupPhase {
    param([Parameter(Mandatory)][int]$Index,[hashtable]$State,[string]$Result="OK")
    try {
        $def = $Global:SetupPhaseDefs[$Index]
        $n   = $Index + 1
        $lvl = if ($Result -eq "OK") { "SUCCESS" } else { "ERROR" }
        Write-Log ("[{0,2}/{1}] {2}  {3}" -f $n, $Global:SetupPhaseCount, $def.Task, $Result) -Level $lvl
        if ($State) {
            if ($State.PhaseRunning -eq $Index) { $State.PhaseRunning = -1 }
            if ($Index -gt $State.PhaseLastStart) { $State.PhaseLastStart = $Index }
            $State.PhaseDone[[string]$Index] = $true
            if ($Result -eq "OK") { $State.PhasesOk++ }
        }
        if ($Result -eq "OK") { Set-SetupProgress -Step $n -Text ("$($def.Task) - $($def.Text[$Global:CurrentLang])") }
        Write-Log "" -Level INFO
    } catch {}
}

# Nur noch exakte Task-Namen bewegen den Fortschritt (siehe Warnung bei
# $Global:SetupPhaseDefs) - freier Logtext wird NICHT mehr zugeordnet.
function Update-SetupProgressFromTask {
    param([Parameter(Mandatory)][string]$Task)
    try {
        $idx = Get-SetupPhaseIndex -Task $Task
        if ($idx -ge 0) { Set-SetupProgress -Step ($idx + 1) }
    } catch {}
}

function Write-SetupPhaseOverview {
    try {
        $lbl = if ($Global:CurrentLang -eq "DE") { "Installationsphasen" } else { "Installation phases" }
        Write-Log ("$lbl (" + $Global:SetupPhaseCount + "):") -Level INFO
        for ($i = 0; $i -lt $Global:SetupPhaseCount; $i++) {
            $ph = $Global:SetupPhaseDefs[$i]
            Write-Log ("  [{0,2}/{1}] {2}  -  {3}" -f ($i+1), $Global:SetupPhaseCount, $ph.Task, $ph.Text[$Global:CurrentLang]) -Level INFO
        }
        Write-Log "----------------------------------------------" -Level INFO
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

function Get-ExchangeMediaStatus {
    <#
        VORAB-Pruefung fuer die UCMA-Installation: Existiert eine Exchange-Medium-
        Quelle? Frischer Laufwerk-Scan ueber Find-MountedExchangeISO (alle
        Buchstaben A-Z - erkennt gemountete ISO-Images UND eingelegte Exchange-
        CDs/DVDs ueber Volume-Label bzw. den UCMARedist-Ordner), sonst die in der
        GUI gewaehlte ISO-Datei (wird beim Installieren automatisch gemountet).
        Liefert Available/Source/Path - eigene Funktion, damit Tests den Zugriff
        mocken koennen, ohne echte Laufwerke zu brauchen.
    #>
    try {
        foreach ($iso in @(Find-MountedExchangeISO)) {
            # Zeichenkette statt Join-Path: Join-Path "D:\" wuerde die Laufwerks-
            # existenz pruefen und beim Verschwinden des Mediums eine Exception
            # werfen - hier still nach unten durchfallen (iso-file-Fallback),
            # statt den ganzen Check abzubrechen. TrimEnd, weil Split-Path auf
            # Root-Ebene "D:\" MIT Backslash liefert.
            $root = (Split-Path $iso.SetupPath).TrimEnd('\')
            $cand = "$root\UCMARedist\Setup.exe"
            if (Test-Path $cand) { return [PSCustomObject]@{ Available=$true; Source="mounted"; Path=$cand } }
        }
    } catch {}
    try {
        if ($Global:TxtISO -and $Global:TxtISO.Text -and (Test-Path "$($Global:TxtISO.Text)")) {
            return [PSCustomObject]@{ Available=$true; Source="iso-file"; Path="$($Global:TxtISO.Text)" }
        }
    } catch {}
    return [PSCustomObject]@{ Available=$false; Source="none"; Path="" }
}

function Get-ExchangeTargetVersion {
    <#
        Liefert die fuer die Pagefile-Entscheidung noetige Exchange-Version:
        Version = "2019SE" (Exchange 2019 ODER Subscription Edition), "2016",
        "2013" oder $null (unbekannt), dazu die Quelle (Source: installed /
        mounted / folder / iso-name / none). Reihenfolge: (1) installiertes
        Exchange (Uninstall-Anzeigeversion, sonst Dateiversion der Bin-
        Binaerien aus MsiInstallPath), (2) gemountetes Medium (Setup.exe
        FileVersion), (3) GUI-Medium (Ordner -> Setup.exe, sonst ISO-Dateiname
        nach den offiziellen Mustern ExchangeServerSE/2019/2016/2013).
        Genau wie der HealthChecker PagefileSizeCheck
        (https://microsoft.github.io/CSS-Exchange/Diagnostics/HealthChecker/PagefileSizeCheck/)
        genuegt major.minor: 15.2 = 2019/SE, 15.1 = 2016, 15.0 = 2013. Grund:
        die 25%-Pagefile-Regel gilt laut Vorgabe NUR fuer 2019 und SE - bei
        aelteren oder unbekannten Versionen wird der Pagefile-Block in
        Install-PrerequisiteSoftware (Schritt [9/9]) uebersprungen.
    #>
    function ConvertTo-TargetShortName([string]$mm) {
        switch ($mm) {
            '15.2' { return '2019SE' }
            '15.1' { return '2016' }
            '15.0' { return '2013' }
            default { return $null }
        }
    }
    function Get-ExeShortVersion([string]$exe) {
        try {
            if ($exe -and (Test-Path $exe)) {
                $fv = "$((Get-Item $exe -ErrorAction Stop).VersionInfo.FileVersion)"
                if ($fv -match '^(\d+)\.(\d+)') { return ("$([int]$Matches[1]).$([int]$Matches[2])") }
            }
        } catch {}
        return $null
    }
    function Get-TargetFromName([string]$text) {
        # Offizielle Mediennamen: ExchangeServerSE-x64, ExchangeServer2019-x64,
        # ExchangeServer2016-x64, ExchangeServer2013-x64 (Datei/Ordner).
        if (-not $text) { return $null }
        if ($text -match '(?i)serverSE')   { return '2019SE' }
        if ($text -match '(?i)server2019') { return '2019SE' }
        if ($text -match '(?i)server2016') { return '2016' }
        if ($text -match '(?i)server2013') { return '2013' }
        return $null
    }

    # (1) installiertes Exchange?
    try {
        foreach ($uk in @(Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' -ErrorAction SilentlyContinue)) {
            $p = Get-ItemProperty -Path $uk.PSPath -ErrorAction SilentlyContinue
            if ($p -and "$($p.DisplayName)" -match '(?i)Microsoft Exchange Server' -and "$($p.DisplayVersion)" -match '^(\d+)\.(\d+)') {
                $v = ConvertTo-TargetShortName ("$([int]$Matches[1]).$([int]$Matches[2])")
                if ($v) { return [PSCustomObject]@{ Version=$v; Source='installed' } }
            }
        }
    } catch {}
    try {
        $setupKey = 'HKLM:\SOFTWARE\Microsoft\ExchangeServer\v15\Setup'
        if (Test-Path $setupKey) {
            $msi = "$((Get-ItemProperty -Path $setupKey -ErrorAction Stop).MsiInstallPath)"
            if ($msi) {
                foreach ($exe in @("$msi\Bin\ExSetup.exe", "$msi\Bin\EdgeTransport.exe")) {
                    $mm = Get-ExeShortVersion $exe
                    $v = if ($mm) { ConvertTo-TargetShortName $mm } else { $null }
                    if ($v) { return [PSCustomObject]@{ Version=$v; Source='installed' } }
                }
            }
        }
    } catch {}

    # (2) gemountetes Medium (ISO-Image oder eingelegte CD)?
    try {
        foreach ($iso in @(Find-MountedExchangeISO)) {
            # String-Konkatenation statt Join-Path (Join-Path prueft die
            # Laufwerks-Existenz) - siehe Kommentar in Get-ExchangeMediaStatus.
            $root = (Split-Path $iso.SetupPath).TrimEnd('\')
            $mm = Get-ExeShortVersion "$root\Setup.exe"
            $v = if ($mm) { ConvertTo-TargetShortName $mm } else { $null }
            if ($v) { return [PSCustomObject]@{ Version=$v; Source='mounted' } }
        }
    } catch {}

    # (3) GUI-Medium: Ordner -> Setup.exe lesen, ISO-Datei -> Dateiname
    try {
        $txt = ''
        try { if ($Global:TxtISO -and $Global:TxtISO.Text) { $txt = "$($Global:TxtISO.Text)" } } catch {}
        if ($txt -and (Test-Path $txt)) {
            if ($txt -notmatch '\.iso$') {
                $mm = Get-ExeShortVersion "$txt\Setup.exe"
                $v = if ($mm) { ConvertTo-TargetShortName $mm } else { $null }
                if (-not $v) { $v = Get-TargetFromName $txt }
                if ($v) { return [PSCustomObject]@{ Version=$v; Source='folder' } }
            } else {
                $v = Get-TargetFromName $txt
                if ($v) { return [PSCustomObject]@{ Version=$v; Source='iso-name' } }
            }
        }
    } catch {}
    return [PSCustomObject]@{ Version=$null; Source='none' }
}

function Get-NicPowerSavingInfo {
    <#
        Netzwerkkarten-Energiesparung pruefen wie der Exchange HealthChecker
        (SleepyNICCheck, https://microsoft.github.io/CSS-Exchange/Diagnostics/HealthChecker/SleepyNICCheck/):
        Unter HKLM\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}
        pro Adapter PnPCapabilities (REG_DWORD) lesen - 24 oder 280 bedeuten
        "Energiesparung deaktiviert" (von Microsoft so empfohlen, sonst kann es
        zu Paketverlusten kommen); der Wert fehlt = nicht konfiguriert (der
        HealthChecker warnt), ein anderer Wert = aktiv. Multiplexor-Adapter
        werden wie dort uebersprungen. Auf virtuellen Maschinen (z.B. Nutanix)
        stellt der Treiber die Option manchmal gar nicht zur Verfuegung - dann
        fehlt der Wert, und Disable-NicPowerSaving schreibt ihn trotzdem
        (fuer den HealthChecker ist dann alles sauber).
        Liefert pro Adapter: Name, Path, Value (int oder $null), Disabled, Skipped.
    #>
    $classKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}'
    $list = @()
    # WICHTIG: NICHT mit -ErrorAction Stop enumerieren! Neben den Adaptern
    # liegen unter dem Klassen-Key gesperrte Sonder-Subkeys (z.B. "Properties"
    # mit Access-Denied-ACL) - EIN nicht lesbarer Eintrag brach die komplette
    # Enumeration ab, die Funktion lieferte 0 NICs und die GUI zeigte
    # "no NICs found" ("NIC-Erkennung funktioniert nicht"). Deshalb
    # SilentlyContinue + Fehler zaehlen; kam tatsaechlich kein Adapter
    # heraus, melden wir den Grund ins Log statt ihn zu verschlucken.
    $enumErr = @()
    $subs = @()
    try {
        $subs = @(Get-ChildItem -Path $classKey -ErrorAction SilentlyContinue -ErrorVariable +enumErr)
    } catch {
        Write-Log ("NIC class key enumeration failed / NIC-Klassen-Key nicht lesbar: " + $_.Exception.Message) -Level ERROR
    }
    foreach ($k in $subs) {
        $desc = $null
        try { $desc = "$((Get-ItemProperty -Path $k.PSPath -Name DriverDesc -ErrorAction Stop).DriverDesc)" } catch { continue }
        if (-not $desc) { continue }
        if ($desc -match 'Multiplexor') {
            $list += [PSCustomObject]@{ Name=$desc; Path="$($k.PSPath)"; Value=$null; Disabled=$false; Skipped=$true }
            continue
        }
        $v = $null
        try { $v = [int](Get-ItemProperty -Path $k.PSPath -Name PnPCapabilities -ErrorAction Stop).PnPCapabilities } catch {}
        $list += [PSCustomObject]@{ Name=$desc; Path="$($k.PSPath)"; Value=$v; Disabled=($v -eq 24 -or $v -eq 280); Skipped=$false }
    }
    if ($subs.Count -eq 0) {
        if ($enumErr.Count -gt 0) {
            Write-Log ("NIC class key enumeration failed / NIC-Klassen-Key nicht lesbar: " + $enumErr[0].Exception.Message) -Level ERROR
        } else {
            Write-Log ("NIC class key not found / NIC-Klassen-Key nicht gefunden: " + $classKey) -Level ERROR
        }
    }
    return $list
}

function Disable-NicPowerSaving {
    <#
        Energiesparung aller Netzwerkkarten deaktivieren: PnPCapabilities = 24
        (der HealthChecker-SleepyNICCheck akzeptiert 24/280 als "aus").
        Bereits korrekte Werte bleiben unveraendert, Multiplexor-Adapter werden
        uebersprungen, Schreibfehler (z.B. kein Admin) werden pro Adapter
        gemeldet statt zuverschweigen. Liefert @{ Total; Fixed; Already; Skipped; Errors }.
    #>
    $info = @(Get-NicPowerSavingInfo)
    $r = @{ Total=0; Fixed=0; Already=0; Skipped=0; Errors=0 }
    foreach ($a in $info) {
        if ($a.Skipped) {
            $r.Skipped++
            Write-Log ("  NIC '" + $a.Name + "': Multiplexor adapter - skipped / uebersprungen") -Level INFO
            continue
        }
        $r.Total++
        if ($a.Disabled) {
            $r.Already++
            Write-Log ("  NIC '" + $a.Name + "': power saving already disabled (PnPCapabilities=" + $a.Value + ") / Energiesparung bereits deaktiviert") -Level SUCCESS
            continue
        }
        try {
            New-ItemProperty -Path $a.Path -Name PnPCapabilities -Value 24 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
            $r.Fixed++
            $old = if ($null -eq $a.Value) { "not set / nicht gesetzt" } else { $a.Value }
            Write-Log ("  NIC '" + $a.Name + "': PnPCapabilities " + $old + " -> 24 (power saving disabled / Energiesparung deaktiviert)") -Level SUCCESS
            if ($null -eq $a.Value) {
                Write-Log ("  NIC '" + $a.Name + "': driver exposes no power option (e.g. Nutanix/VM) - value written anyway for HealthChecker / Treiber ohne Power-Option - Wert trotzdem geschrieben") -Level INFO
            }
        } catch {
            $r.Errors++
            Write-Log ("  NIC '" + $a.Name + "': cannot write PnPCapabilities / PnPCapabilities nicht schreibbar: " + $_.Exception.Message + " (run as administrator / als Administrator ausfuehren)") -Level ERROR
        }
    }
    return $r
}

function Update-NicPowerSavingLabel {
    <# Fuellt das Status-Label $Global:LblNicPower (Tab Voraussetzungen). #>
    if (-not $Global:LblNicPower) { return }
    try {
        $nic = @(Get-NicPowerSavingInfo | Where-Object { -not $_.Skipped })
        $bad = @($nic | Where-Object { -not $_.Disabled })
        Write-Log ("NIC power saving check: " + $nic.Count + " adapters / Netzwerkkarten, " + $bad.Count + " not disabled / nicht deaktiviert") -Level INFO
        if ($nic.Count -eq 0) {
            $Global:LblNicPower.Text = "no NICs found / keine NICs gefunden"
            $Global:LblNicPower.ForeColor = $Global:ColorWarning
        } elseif ($bad.Count -eq 0) {
            $Global:LblNicPower.Text = if ($Global:CurrentLang -eq "DE") { "OK - deaktiviert (" + $nic.Count + " NICs)" } else { "OK - disabled (" + $nic.Count + " NICs)" }
            $Global:LblNicPower.ForeColor = $Global:ColorAccent2
        } else {
            $Global:LblNicPower.Text = if ($Global:CurrentLang -eq "DE") { "AKTIV / nicht gesetzt (" + $bad.Count + " von " + $nic.Count + ")" } else { "ACTIVE / not set (" + $bad.Count + " of " + $nic.Count + ")" }
            $Global:LblNicPower.ForeColor = $Global:ColorWarning
        }
    } catch { $Global:LblNicPower.Text = "..." }
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
    # SleepyNIC-Status (HealthChecker): alle Adapter mit deaktivierter
    # Energiesparung? Kein Adapter gefunden = nicht meckern (kein Issue).
    $nicOK = $true
    try {
        $nicList = @(Get-NicPowerSavingInfo | Where-Object { -not $_.Skipped })
        if ($nicList.Count -gt 0) { $nicOK = (@($nicList | Where-Object { -not $_.Disabled }).Count -eq 0) }
    } catch {}
    return [PSCustomObject]@{
        DotNet48=Test-DotNet48; VC2012=(Test-VCRedistInstalled "Visual C++ 2012 x64")
        VC2013=(Test-VCRedistInstalled "Visual C++ 2013 x64"); URLRewrite=Test-URLRewrite
        UCMA=Test-UCMA; Features=$features; MissingFeatures=$missing
        FeaturesOK=($missing.Count -eq 0); SMB1Enabled=$smb1Enabled
        NicPowerSavingOK=$nicOK
    }
}

function Install-PrerequisiteSoftware {
    param(
        [bool]$InstallDotNet=$true,[bool]$InstallVC2012=$true,[bool]$InstallVC2013=$true,
        [bool]$InstallURLRewrite=$true,[bool]$InstallUCMA=$true,[bool]$InstallFeatures=$true,
        [bool]$DisableSMB1=$true,[bool]$OptimizePageFile=$true,[bool]$SetHighPerformance=$true,
        [bool]$DisableNicPower=$true
    )
    Write-Log "==============================================" -Level INFO
    Write-Log " EXCHANGE PREREQUISITES INSTALLATION" -Level INFO
    Write-Log "==============================================" -Level INFO
    # VORAB-Pruefung: Wenn UCMA 4.0 fehlt und angehaakt ist, muss das Exchange-
    # Medium (ISO-Datei, gemountetes Image oder eingelegte CD) JETZT da sein -
    # der Lauf bricht vor Schritt [1/9] ab, BEVOR irgendetwas veraendert wird,
    # statt erst bei [4/9] und nach .NET/VC++-Installationen zu scheitern.
    if ($InstallUCMA -and -not (Test-UCMA)) {
        $media = Get-ExchangeMediaStatus
        if (-not $media.Available) {
            Write-Log "UCMA 4.0 requested, but no Exchange medium found - select or mount an Exchange ISO in the Installation tab or insert the Exchange CD first (or uncheck UCMA 4.0 to install the other prerequisites without it). / UCMA 4.0 angehaakt, aber kein Exchange-Medium gefunden - zuerst ISO auswaehlen/mounten oder CD einlegen (oder UCMA 4.0 abwaehlen, um die uebrigen Voraussetzungen ohne Medium zu installieren). Prerequisites installation aborted BEFORE any change." -Level ERROR
            return $false
        }
        Write-Log ("UCMA 4.0 medium check: " + $media.Source + " -> " + $media.Path) -Level INFO
    }
    $tempDir = $Global:DefaultTempPath
    if (-not (Test-Path $tempDir)) { New-Item -Path $tempDir -ItemType Directory -Force | Out-Null }

    if ($InstallDotNet) {
        if (Test-DotNet48) { Write-Log "[1/9] .NET 4.8+ already installed" -Level SUCCESS }
        else {
            Write-Log "[1/9] Installing .NET 4.8..." -Level INFO
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
        if (Test-VCRedistInstalled "Visual C++ 2012 x64") { Write-Log "[2/9] VC++ 2012 already installed" -Level SUCCESS }
        else {
            Write-Log "[2/9] Installing VC++ 2012 x64..." -Level INFO
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
        if (Test-VCRedistInstalled "Visual C++ 2013 x64") { Write-Log "[3/9] VC++ 2013 already installed" -Level SUCCESS }
        else {
            Write-Log "[3/9] Installing VC++ 2013 x64..." -Level INFO
            try {
                $url = "https://download.visualstudio.microsoft.com/download/pr/10912041/cee5d6bca2ddbcd039da727bf4acb48a/vcredist_x64.exe"
                $file = Join-Path $tempDir "vcredist2013_x64.exe"
                if (-not (Test-Path $file)) { Invoke-WebRequest -Uri $url -OutFile $file -UseBasicParsing }
                Start-Process -FilePath $file -ArgumentList "/install /quiet /norestart" -Wait
                Write-Log "  VC++ 2013 installed" -Level SUCCESS
            } catch { Write-Log ("  Error: " + $_) -Level ERROR }
        }
    }
    if ($InstallUCMA) {
        if (Test-UCMA) { Write-Log "[4/9] UCMA 4.0 already installed" -Level SUCCESS }
        else {
            Write-Log "[4/9] Installing UCMA 4.0..." -Level INFO
            # Quellen-Pruefung ueber denselben Helper wie beim Laufstart: frischer
            # Laufwerk-Scan ueber alle Buchstaben A-Z - erkennt auch eine eingelegte
            # Exchange-CD/DVD, waehrend der alte Guard nur den Radio-Status und die
            # gemerkte DetectedISOs-Liste pruefte (CD ohne vorherige Anzeige wurde
            # uebersehen). Der Helper wurde vor Schritt [1/9] bereits verifiziert;
            # hier wird er vor dem Mounten ein zweites Mal konsistent benutzt.
            $media = Get-ExchangeMediaStatus
            if (-not $media.Available) {
                Write-Log "  ERROR: Bitte Exchange ISO auswaehlen oder Exchange ISO mounten (UCMA 4.0 wird von UCMARedist\Setup.exe auf der ISO installiert). / Please select an Exchange ISO file or mount an Exchange ISO first." -Level ERROR
            } else {
            try { $Global:DetectedISOs = @(Find-MountedExchangeISO) } catch {}
            $ucmaInst = $null
            foreach ($iso in $Global:DetectedISOs) {
                $cand = Join-Path (Split-Path $iso.SetupPath) "UCMARedist\Setup.exe"
                if (Test-Path $cand) { $ucmaInst = $cand; break }
            }
            # Fallback: Nur ISO-DATEI angegeben (nicht gemountet)? Dann jetzt mounten,
            # sonst ist UCMARedist\Setup.exe auf der ISO nicht erreichbar.
            if (-not $ucmaInst) {
                try {
                    $isoFile = ""
                    if ($Global:TxtISO -and $Global:TxtISO.Text -and (Test-Path "$($Global:TxtISO.Text)")) { $isoFile = "$($Global:TxtISO.Text)" }
                    if ($isoFile) {
                        Write-Log ("  Mounting ISO for UCMA access: " + $isoFile) -Level INFO
                        $mountedSetup = Mount-ExchangeISO -ISOPath $isoFile
                        if ($mountedSetup) {
                            $Global:DetectedISOs = @(Find-MountedExchangeISO)
                            try {
                                if ($Global:CmbMountedDrives) {
                                    $Global:CmbMountedDrives.Items.Clear()
                                    foreach ($f in $Global:DetectedISOs) { [void]$Global:CmbMountedDrives.Items.Add($f.Display) }
                                    if ($Global:CmbMountedDrives.Items.Count -gt 0) { $Global:CmbMountedDrives.SelectedIndex = 0 }
                                }
                                if ($Global:RbISOMounted) { $Global:RbISOMounted.Checked = $true; $Global:RbISOFile.Checked = $false }
                            } catch {}
                            foreach ($iso in $Global:DetectedISOs) {
                                $cand = Join-Path (Split-Path $iso.SetupPath) "UCMARedist\Setup.exe"
                                if (Test-Path $cand) { $ucmaInst = $cand; break }
                            }
                            if ($ucmaInst) { Write-Log ("  UCMA source: " + $ucmaInst) -Level INFO }
                        }
                    } else {
                        Write-Log "  Hint: mount the Exchange ISO or specify the ISO file (UCMA redist is at UCMARedist\Setup.exe on the ISO)." -Level INFO
                    }
                } catch { Write-Log ("  ISO mount fallback failed: " + $_) -Level WARNING }
            }
            if ($ucmaInst) {
                try {
                    Start-Process -FilePath $ucmaInst -ArgumentList "/quiet /norestart" -Wait
                    Write-Log "  UCMA 4.0 installed" -Level SUCCESS
                } catch { Write-Log ("  Error: " + $_) -Level ERROR }
            } else { Write-Log "  UCMA installer not found on ISO" -Level WARNING }
            } # else (ISO-Quelle ausgewaehlt)
        }
    }
    if ($InstallFeatures) {
        Write-Log "[5/9] Checking Windows features..." -Level INFO
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
    if ($InstallURLRewrite) {
        if (Test-URLRewrite) { Write-Log "[6/9] URL Rewrite already installed" -Level SUCCESS }
        else {
            Write-Log "[6/9] Installing URL Rewrite 2.1..." -Level INFO
            try {
                $url = "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi"
                $file = Join-Path $tempDir "rewrite_2.1_x64.msi"
                if (-not (Test-Path $file)) { Invoke-WebRequest -Uri $url -OutFile $file -UseBasicParsing }
                Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$file`" /quiet /norestart" -Wait
                Write-Log "  URL Rewrite installed" -Level SUCCESS
            } catch { Write-Log ("  Error: " + $_) -Level ERROR }
        }
    }
    if ($DisableSMB1) {
        Write-Log "[7/9] SMB1 deactivation..." -Level INFO
        try {
            $smb1 = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue
            if ($smb1 -and $smb1.State -eq "Enabled") {
                Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction Stop | Out-Null
                Write-Log "  SMB1 disabled" -Level SUCCESS
            } else { Write-Log "  SMB1 already disabled" -Level SUCCESS }
        } catch { Write-Log ("  Error: " + $_) -Level WARNING }
    }
    if ($DisableNicPower) {
        Write-Log "[8/9] NIC power saving deactivation (SleepyNICCheck)..." -Level INFO
        $nicFix = Disable-NicPowerSaving
        if ($nicFix.Total -eq 0) {
            Write-Log "  No network adapters found / Keine Netzwerkkarten gefunden" -Level WARNING
        } elseif ($nicFix.Errors -gt 0) {
            Write-Log ("  NIC power saving: " + $nicFix.Fixed + " changed / geaendert, " + $nicFix.Errors + " errors / Fehler") -Level ERROR
        } else {
            Write-Log ("  NIC power saving: " + $nicFix.Fixed + " changed / geaendert, " + $nicFix.Already + " already disabled / bereits deaktiviert, " + $nicFix.Skipped + " skipped / uebersprungen") -Level SUCCESS
        }
    }
    # Power plan UND Pagefile laufen ab jetzt unabhaengig voneinander: vorher
    # war der Pagefile-Block in $SetHighPerformance verschachtelt - wer nur
    # "Pagefile" angehakt hatte, bekam ohne Power-Plan-Kreuz stillschweigend
    # gar nichts (Pagefile-Checkbox wirkte dann nie).
    if ($SetHighPerformance -or $OptimizePageFile) {
        Write-Log "[9/9] Power plan + pagefile..." -Level INFO
        if ($SetHighPerformance) {
            try { powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>&1 | Out-Null; Write-Log "  High Performance active" -Level SUCCESS } catch {}
        }
        if ($OptimizePageFile) {
            # Pagefile exakt wie der HealthChecker PagefileSizeCheck
            # (https://microsoft.github.io/CSS-Exchange/Diagnostics/HealthChecker/PagefileSizeCheck/):
            # GILT NUR FUER EXCHANGE 2019 UND SE - dort fest 25% der
            # installierten Speicher-Groesse (Min = Max) und GENAU EINE
            # Pagefile (mehrfache gelten dort als Performance-Problem).
            # Die 2013/2016-Regel (RAM + 10 MB, max. 32 GB) wird bewusst NICHT
            # angewandt; bei aelteren oder unbekannten Versionen wird komplett
            # uebersprungen (Entscheidungsgrundlage: Get-ExchangeTargetVersion).
            $pfTarget = Get-ExchangeTargetVersion
            if ($pfTarget.Version -ne '2019SE') {
                $why = if ($pfTarget.Version) { $pfTarget.Version } else { 'unknown' }
                Write-Log ("  Pagefile skipped: HealthChecker rule (25% of RAM, fixed, single pagefile) applies only to Exchange 2019/SE - detected: " + $why + " / Pagefile uebersprungen: Regel gilt nur fuer Exchange 2019/SE") -Level INFO
            } else {
                $pf = $null
                try {
                    $ramMB = [int]((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1MB)
                    $pf = [int][math]::Floor($ramMB * 0.25)
                    $cs = Get-CimInstance Win32_ComputerSystem
                    if ($cs.AutomaticManagedPagefile) {
                        $cs | Set-CimInstance -Property @{AutomaticManagedPagefile=$false} -ErrorAction SilentlyContinue
                        Write-Log "  Automatic pagefile management disabled / automatische Pagefile-Verwaltung deaktiviert" -Level INFO
                    }
                    $settings = @(Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue)
                    if ($settings.Count -eq 0) {
                        # Kein Win32_PageFileSetting vorhanden (z.B. gerade erst
                        # aus der automatischen Verwaltung genommen) - Einstellung
                        # auf dem Systemlaufwerk anlegen, sonst bliebe der Sollwert
                        # ungesetzt.
                        $pfPath = "$env:SystemDrive\pagefile.sys"
                        if (Get-Command Set-WmiInstance -ErrorAction SilentlyContinue) {
                            Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{Name=$pfPath; InitialSize=[uint32]$pf; MaximumSize=[uint32]$pf} -ErrorAction Stop | Out-Null
                        } else {
                            New-CimInstance -ClassName Win32_PageFileSetting -Property @{Name=$pfPath; InitialSize=[uint32]$pf; MaximumSize=[uint32]$pf} -ErrorAction Stop | Out-Null
                        }
                        Write-Log ("  Pagefile created: " + $pfPath + " = " + $pf + " MB fixed (25% of " + $ramMB + " MB RAM)") -Level SUCCESS
                    } else {
                        # Genau EINE Pagefile: die auf dem Systemlaufwerk
                        # behalten, alle weiteren Eintraege entfernen
                        # (HealthChecker: multiple PageFiles -> Performance-Problem).
                        $keep = $null
                        if ($settings.Count -gt 1) {
                            $keep = @($settings | Where-Object { $_.Name -like "${env:SystemDrive}\*" }) | Select-Object -First 1
                            if (-not $keep) { $keep = $settings[0] }
                            foreach ($extra in @($settings | Where-Object { $_.Name -ne $keep.Name })) {
                                $removed = $false
                                try { Remove-CimInstance -InputObject $extra -ErrorAction Stop; $removed = $true } catch {}
                                if (-not $removed) {
                                    try {
                                        $w = Get-WmiObject -Class Win32_PageFileSetting -ErrorAction Stop | Where-Object { $_.Name -eq $extra.Name }
                                        if ($w) { [void]$w.Delete(); $removed = $true }
                                    } catch {}
                                }
                                if ($removed) {
                                    Write-Log ("  Additional pagefile removed / zusaetzliche Pagefile entfernt: " + $extra.Name) -Level WARNING
                                } else {
                                    Write-Log ("  Could not remove additional pagefile / zusaetzliche Pagefile NICHT entfernt: " + $extra.Name + " - bitte manuell loeschen (HealthChecker: nur 1 Pagefile)") -Level WARNING
                                }
                            }
                        } else {
                            $keep = $settings[0]
                        }
                        $keep | Set-CimInstance -Property @{InitialSize=[uint32]$pf; MaximumSize=[uint32]$pf} -ErrorAction Stop
                        Write-Log ("  Pagefile set: " + $keep.Name + " = " + $pf + " MB fixed, min = max (25% of " + $ramMB + " MB RAM; HealthChecker PagefileSizeCheck for Exchange 2019/SE)") -Level SUCCESS
                    }
                } catch {
                    $soll = if ($pf) { "$pf MB" } else { "25% of RAM" }
                    Write-Log ("  Pagefile error: " + $_.Exception.Message + " - target: fixed " + $soll + "; verify after reboot / nach Neustart manuell pruefen") -Level WARNING
                }
            }
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
    <#
        Mountet die angegebene ISO-Datei und liefert den Pfad zu Setup.exe zurueck.
        - Ist die ISO bereits gemountet (manuell oder aus einem frueheren Schritt),
          wird NICHT erneut gemountet (kein sichtbarer Doppel-Mount) und auch nicht
          als "vom Skript gemountet" markiert.
        - Nur wenn DIESE Funktion das Mount ausloest, wird $Global:ISOMountedByScript
          gesetzt - der Master-Workflow dismountet am Ende immer (STEP 9 + finally).
    #>
    param([Parameter(Mandatory)][string]$ISOPath)
    try {
        $wasAttached = $false
        try { $di = Get-DiskImage -ImagePath $ISOPath -ErrorAction Stop; if ($di -and $di.Attached) { $wasAttached = $true } } catch {}
        if ($wasAttached) {
            $mr = Get-DiskImage -ImagePath $ISOPath -ErrorAction Stop
        } else {
            $mr = Mount-DiskImage -ImagePath $ISOPath -PassThru
            $Global:ISOMountedByScript = $true
            Start-Sleep -Seconds 2
        }
        $drive = ($mr | Get-Volume).DriveLetter
        if ($drive) { return ("${drive}:\Setup.exe") }
        throw "Drive letter not detected"
    } catch { Write-Log ("Mount error: " + $_) -Level ERROR; return $null }
}

function Dismount-ExchangeISO {
    <#
        Dismountet die ISO mit Zeitlimit und meldet den Zustand ehrlich.
        Dismount-DiskImage kann haengenbleiben, solange das gemountete Volume
        offene Handles hat (Explorer-Fenster, Virenscanner, Suche) - ein
        direkter Aufruf im GUI-Workflow wuerde das Fenster dauerhaft
        einfrieren (beobachtet: Hngen an "STEP 9: Dismount ISO", ISO blieb
        gemountet, keine einzige weitere Logzeile). Deshalb laeuft der
        Dismount in einer Kind-Powershell: der Elternprozess wartet
        hoechstens $TimeoutSec Sekunden und killt den Kindprozess bei
        Ueberlauf - die GUI bleibt bedienbar und der Zustand wird geloggt,
        statt dass der Workflow stillschweigend blockiert.
        Kindprozess-Exitcodes: 0 = getrennt, 2 = weiterhin gemountet,
        1 = Dismount-DiskImage-Fehler. Rueckgabe: "ok"|"attached"|"error"|"timeout".
    #>
    param([Parameter(Mandatory)][string]$ISOPath, [int]$TimeoutSec = 30)
    Write-Log ("Dismounting ISO: " + $ISOPath) -Level INFO
    $q = "$ISOPath" -replace "'", "''"
    # Kindprozess dismountet UND verifiziert den Zustand - der Elternprozess
    # beruehrt die Storage-WMI-Schicht nie selbst (auch die koennte hngen).
    $inner = "try { Dismount-DiskImage -ImagePath '" + $q + "' -ErrorAction Stop | Out-Null } catch { exit 1 }; " +
             "try { if ((Get-DiskImage -ImagePath '" + $q + "' -ErrorAction Stop).Attached) { exit 2 } } catch {}; exit 0"
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = (Join-Path $PSHOME "powershell.exe")
    $psi.Arguments = "-NoProfile -NonInteractive -Command `"" + $inner + "`""
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $p = $null
    try {
        $p = [System.Diagnostics.Process]::Start($psi)
        if (-not $p.WaitForExit($TimeoutSec * 1000)) {
            try { $p.Kill(); $p.WaitForExit(5000) } catch {}
            Write-Log ("ISO dismount TIMEOUT / Dismount-Timeout nach " + $TimeoutSec + "s: Dismount-DiskImage blockiert (offener Handle auf dem gemounteten Laufwerk / open handle on the mounted volume) - ISO BLEIBT GEMOUNTET / ISO STAYS MOUNTED: beteiligte Programme schliessen und manuell auswerfen / close the programs using it and dismount manually") -Level ERROR
            return "timeout"
        }
        switch ($p.ExitCode) {
            0 { Write-Log "ISO dismounted / ISO getrennt" -Level SUCCESS; return "ok" }
            2 {
                Write-Log ("ISO still mounted / ISO weiterhin gemountet: Volume wird belegt / volume is busy - Explorer-Fenster und Prozesse auf dem gemounteten Laufwerk schliessen, dann manuell auswerfen / close Explorer windows and processes using the mounted drive, then dismount manually") -Level ERROR
                return "attached"
            }
            default {
                Write-Log ("ISO dismount failed / Dismount fehlgeschlagen (Exit-Code / exit code: " + $p.ExitCode + ") - ISO BLEIBT GEMOUNTET / ISO STAYS MOUNTED") -Level ERROR
                return "error"
            }
        }
    } catch {
        Write-Log ("ISO dismount error / Dismount-Fehler: " + $_.Exception.Message) -Level ERROR
        return "error"
    } finally {
        if ($p) { try { $p.Dispose() } catch {} }
    }
}

function Dismount-ScriptISO {
    <#
        Dismountet die ISO-Datei IMMER, wenn das Skript sie selbst gemountet hat
        (Flag kommt aus Mount-ExchangeISO). Wird am Ende jedes Laufs aufgerufen -
        auch bei Abbruch ueber try/finally - damit nie ein Rest-Mount uebrig bleibt.
        Ein manuell gemountetes ISO bleibt unangetastet.
    #>
    if (-not $Global:ISOMountedByScript) { return }
    $iso = ""
    try { if ($Global:TxtISO -and $Global:TxtISO.Text) { $iso = "$($Global:TxtISO.Text)" } } catch {}
    $Global:ISOMountedByScript = $false
    if (-not $iso) { return }
    Write-Log "--- STEP 9: Dismount ISO ---" -Level INFO
    [void](Dismount-ExchangeISO -ISOPath $iso)
    # Diagnose-Marker: fehlt die naechste Zeile im Log, hngt die Laufwerk-
    # suche selbst (Test-Path/Get-Volume ueber A-Z) - dann dort weiter suchen.
    Write-Log "Refreshing mounted ISO list / Suche nach gemounteten ISOs ..." -Level INFO
    # GUI-Auswahl ehrlich halten: das soeben dismountete Laufwerk gibt es nicht mehr.
    # Sonst wuerde der naechste Lauf gegen eine tote Laufwerk-Auswahl arbeiten.
    try {
        $found = @(Find-MountedExchangeISO)
        $Global:DetectedISOs = $found
        if ($Global:CmbMountedDrives) {
            $Global:CmbMountedDrives.Items.Clear()
            if ($found.Count -gt 0) {
                foreach ($f in $found) { [void]$Global:CmbMountedDrives.Items.Add($f.Display) }
                $Global:CmbMountedDrives.SelectedIndex = 0
            } else {
                [void]$Global:CmbMountedDrives.Items.Add("(No Exchange ISO found)")
                $Global:CmbMountedDrives.SelectedIndex = 0
            }
        }
        if ($found.Count -eq 0 -and $Global:RbISOFile -and $Global:TxtISO -and $Global:TxtISO.Text) {
            $Global:RbISOFile.Checked = $true
            if ($Global:RbISOMounted) { $Global:RbISOMounted.Checked = $false }
        }
    } catch {}
    Write-Log "Dismount step finished / Dismount-Schritt abgeschlossen" -Level INFO
}

function Invoke-ResponsiveProcess {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$Arguments,
        [string]$LogPrefix="Setup",[int]$HeartbeatSec=60,
        [string]$ExchangeSetupLog=$Global:ExchangeSetupLog,[bool]$TailExchangeLog=$true,
        [bool]$TrackSetupProgress=$false,
        [bool]$ShowAllTailLines=$false,
        [int]$TailMaxChars=250
    )
    # Interne Hilfsfunktion: einen Log-Block aus ExchangeSetup.log auswerten und
    # ins Tool-Log spiegeln. Wird waehrend der Laufzeit UND zum finalen Drain
    # nach Prozessende aufgerufen, damit keine Zeilen verloren gehen.
    # TAILMODE v7 (LDF-only + BYWEISE-LESEMODE): je Schema-LDF genau 1 Zeile
    # "Schema-Datei X: OK". v6 hatte 2 Faehlerquellen: $fs.Position nach $sr.Close()
    # (StreamReader schliesst den FileStream => LastPos rutschte nie voran, Endlosscan)
    # und ""-Write-Log-Abrueche => LDF-Zeilen wurden nie erreicht.
    # Prereq-Analyse (Started/Evaluated/Finished [Rule|Setting]) wird verworfen.
    # Enthaelt: Rotations-Erkennung (Setup legt das Log neu an) + Banner-Bremse
    # (wiederholte "Starting..."-Bloecke werden eingeklappt) + Domain-Warnung
    # (Setup meldet andere Domaene als erwartet, z. B. altes Log / falscher DC).
    function Invoke-TailDrain {
        param([ref]$LastPosRef, [ref]$LinesShownRef, [ref]$LastTaskRef, [ref]$TailStateRef, [switch]$FlushTail)
        if (-not $TailExchangeLog) { return }
        if (-not (Test-Path $ExchangeSetupLog)) { return }
        try {
            $fi = Get-Item $ExchangeSetupLog -ErrorAction Stop
            if ($fi.Length -lt $LastPosRef.Value) {
                # Log wurde rotiert/neu angelegt (Setup startet frisch) - von vorn lesen.
                $LastPosRef.Value = 0
                if (-not $TailStateRef.Value.RotWarned) {
                    Write-Log "ExchangeSetup.log wurde neu angelegt/rotiert - lese von vorn." -Level WARNING
                    $TailStateRef.Value.RotWarned = $true
                }
            }
            if ($fi.Length -le $LastPosRef.Value) { return }
            $fs = [System.IO.File]::Open($ExchangeSetupLog,'Open','Read','ReadWrite')
            try {
                $fs.Seek($LastPosRef.Value,'Begin') | Out-Null
                # --- BYWEISE-LESEMODE (TAILMODE v7) ---
                # 1) VORHER: $sr.Close() schloss auch den FileStream, $fs.Position danach
                #    warf einen Fehler => $LastPos rutschte NIE voran, jede Drain scannte
                #    den ganzen Log von vorn (Diagnose: "76516 Zeilen gescannt").
                # 2) VORHER: StreamReader puffert; fiel der Lesestand mitten in eine
                #    Logzeile, zerfiel diese in Fragmente ("LdapFileNa" + "me: 'x.ldf'")
                #    und das LDF-Matching traf nie eine ganze Zeile.
                # 3) VORHER: ""-Trennzeilen in Write-Log warfen einen Parameterfehler und
                #    brachen die Drain UNMIDDLICH ab (erste "Beginning processing"-Zeile) -
                #    daher erreichte nie eine LDF-Zeile die Anzeige.
                # Jetzt: Rohbytes lesen, NUR bis zum letzten LF konsumieren; der Rest
                # bleibt bis zur naechsten Drain stehen (kein Fragment, kein Datenverlust).
                $toRead = [long]$fi.Length - [long]$LastPosRef.Value
                if ($toRead -le 0) { return }
                if ($toRead -gt 4MB) { $toRead = 4MB }
                $buf = New-Object byte[] ([int]$toRead)
                $total = 0
                while ($total -lt $toRead) {
                    $n = $fs.Read($buf, $total, [int]([long]$toRead - $total))
                    if ($n -le 0) { break }
                    $total += $n
                }
                $consumed = -1
                if ($FlushTail) {
                    # Prozessende: auch die letzte Zeile ohne abschliessendes LF verarbeiten.
                    $consumed = $total
                } else {
                    $e = $total - 1
                    while ($e -ge 0 -and $buf[$e] -ne 10) { $e-- }
                    if ($e -lt 0) { return }   # noch keine vollstaendige Zeile neu - Inhalt bleibt stehen
                    $consumed = $e + 1
                }
                if ($consumed -le 0) { return }
                $chunkText = [System.Text.Encoding]::Default.GetString($buf, 0, $consumed)
                $newLastPos = [long]$LastPosRef.Value + $consumed
                $chunkLines = $chunkText -split "`n"
                try {
                    foreach ($line in $chunkLines) {
                        $line = $line.TrimEnd([char]13)
                        $TailStateRef.Value.RawLines++
                        if ([string]::IsNullOrWhiteSpace($line)) { continue }
                        try {
                            # LDF-Erfassung VOR allen Filtern (darf nie verloren gehen):
                            # Merkt sich die aktuelle schema*.ldf-Datei und meldet je Datei
                            # genau 1 Zeile "Schema-Datei X: OK/FEHLER" beim ldifde-Exit.
                            # (Laeuft vor Level-/Rausch-Filtern, damit ein fehlendes
                            #  Important-Pattern die LDF-Anzeige nie stumm schaltet.)
                            try {
                                # Erfassung je schema*.ldf: LdapFileName -> Pending, Exit-Code -> Meldung.
                                # Tolerant: einfache/doppelte Anfuehrungszeichen, ':' optional.
                                if ($line -match "LdapFileName\s*[:=]?\s*['`"]?([^'`"]+\.ldf)") {
                                    $TailStateRef.Value.PendingLdf = [System.IO.Path]::GetFileName($matches[1])
                                    continue
                                }
                                $code = $null
                                if ($line -match 'ldifde\.exe finished with exit code\s*:?\s*(\d+)') { $code = $matches[1] }
                                elseif ($line -match 'ldifde\.exe finished[^\d]{0,40}(\d+)') { $code = $matches[1] }
                                if ($null -ne $code) {
                                    $ldf = "$($TailStateRef.Value.PendingLdf)"
                                    if (-not $ldf -and ($line -match '([^"\\\s]+\.ldf)')) {
                                        $ldf = [System.IO.Path]::GetFileName($matches[1])
                                    }
                                    if (-not $ldf) { $ldf = "Schema-LDF" }
                                    if ($code -eq "0") {
                                        $TailStateRef.Value.LdfOk++
                                        Write-Log ("    Schema-Datei ${ldf}: OK (Exit 0)") -Level SUCCESS
                                    } else {
                                        $TailStateRef.Value.LdfFail++
                                        Write-Log ("    Schema-Datei ${ldf}: FEHLER (Exit $code)") -Level ERROR
                                    }
                                    $LinesShownRef.Value++
                                    $TailStateRef.Value.PendingLdf = ""
                                    if ($TrackSetupProgress) { Update-SetupProgressFromTask -Task "Schema $ldf" }
                                    continue
                                }
                            } catch {}
                            # Prerequisite-Analyse-Rauschen IMMER ausblenden:
                            # "Started/Evaluated/Finished [Rule:...]/[Setting:...]" wiederholt sich
                            # hundertfach und ist kein Fortschritt. Nur LDF + echte Fehler bleiben.
                            if ($line -match '(Started|Evaluated|Finished)\s*\[(Rule|Setting):') { continue }
                            $level = $null
                            foreach ($pat in $errPatt) { if ($line -match $pat) { $level = "ERROR"; break } }
                            if (-not $level) { foreach ($pat in $warnPatt) { if ($line -match $pat) { $level = "WARNING"; break } } }
                            if (-not $level) { foreach ($pat in $important) { if ($line -match $pat.Pattern) { $level = $pat.Level; break } } }
                            # Quiet-Modus: NUR wichtige Meilensteine + Fehler/Warnungen.
                            # ShowAllTailLines wird bewusst NICHT mehr als INFO-Fallback genutzt
                            # (das hat tausende Startup-Zeilen in das Tool-Log gespiegelt).
                            # Wer Volltext braucht: C:\ExchangeSetupLogs\ExchangeSetup.log.
                            if (-not $level) { continue }
                            $clean = $line -replace '^\[\d{2}[\./]\d{2}[\./]\d{4}\s+\d{2}:\d{2}:\d{2}\.\d+\]\s*\[\d+\]\s*','' -replace '^\[\d{2}[\./]\d{2}[\./]\d{4}\s+\d{2}:\d{2}:\d{2}\.\d+\]\s*',''
                            $short = $clean.Trim()
                            if ($short.Length -gt $TailMaxChars) { $short = $short.Substring(0,$TailMaxChars) + "..." }
                            # --- Domain-Signale einsammeln (fuer Warnung bei falscher Domaene) ---
                            try {
                                if ($short -match 'Logged on user:\s*([^\\\s]+)\\') {
                                    $TailStateRef.Value.SeenUserDomains[$matches[1].ToUpper()] = $true
                                }
                                if ($short -match "domain controller\s+'?([A-Za-z0-9_.-]+\.[A-Za-z0-9_.-]+)") {
                                    $TailStateRef.Value.SeenDcDomains[$matches[1]] = $true
                                }
                            } catch {}
                            # --- Banner-Bremse: nur 1. Setup-Start voll zeigen, Rest einklappen ---
                            $isBanner = ($short -match 'Starting Microsoft Exchange Server.*Setup')
                            if ($isBanner) {
                                $TailStateRef.Value.BannerCount++
                                $n = $TailStateRef.Value.BannerCount
                                if ($n -eq 1) {
                                    Write-Log ("    " + $short) -Level INFO
                                    $LinesShownRef.Value++
                                } elseif (($n % 25) -eq 0) {
                                    Write-Log ("Setup-Pruefung laeuft noch (${n}x gestartet) ...") -Level INFO
                                }
                                # Banner selbst treibt keinen Fortschritt
                                continue
                            }
                            # Startup-Laerm IMMER unterdruecken (nicht erst ab Banner 2):
                            # Der mitgelesene Ausschnitt enthaelt oft gar keinen
                            # "Starting..."-Banner mehr (Start lag vor logStartPos),
                            # dann blieb BannerCount=0 und nichts wurde gefiltert.
                            if ($short -match '^(\*{4,}|Local time zone|Operating system version|Setup version|Logged on user|Der Registrierungsschlüssel|Command Line Parameter|RuntimeAssembly|Dateien werden kopiert|Starting copy|Finished copy|Dateikopiervorgang beendet|Assembly dll file location|Setup is choosing|Setup has chosen|PrepareAD has either not been run|The schema master|Setup will use the (domain controller|global catalog|path)|No Exchange configuration container|The following (roles|datacenter roles|roles are)|The local server does not have|Server Name=|The installation mode|Exchange organization name is required|Active Directory Initialization status|Schema Update Required Status|Organization Configuration Update Required Status|Domain Configuration Update Required Status|Applying default role selection|Setup is determining what|The command-line option|Because the command-line option|Setup will run from path|InstallModeDataHandler|RootDataHandler|Validating options|Die Voraussetzungen für Microsoft|Setup launched task .test-SetupPrerequisites|Die Active Directory-Sitzungseinstellungen|User specified parameters|Setup will run the task .test-SetupPrerequisites|Executing:|Loaded (component|\d+ parameters)|Writing informational script|Running <C:\\Windows\\system32\\ldifde|Processing component|tasks were found to run|Loaded 7 parameters|Updating performance counter strings|did not exist, this is not an error)') {
                                # test-SetupPrerequisites o. ae. Tasks trotzdem als Fortschritt werten,
                                # aber nicht jede Wiederholung loggen.
                                if ($TrackSetupProgress) { Update-SetupProgressFromTask -Task $short }
                                if ($short -match "Setup (will run|launched task).*test-SetupPrerequisites") {
                                    $TailStateRef.Value.PrereqSeen++
                                    if ($TailStateRef.Value.PrereqSeen -le 1) {
                                        Write-Log "    Voraussetzungstest laeuft (test-SetupPrerequisites) ..." -Level INFO
                                        $LinesShownRef.Value++
                                    }
                                }
                                continue
                            }
                            # --- Doppelzeilen-Dedup: identische Zeile direkt hintereinander nur 1x ---
                            if ($short -eq $TailStateRef.Value.LastShort) {
                                $TailStateRef.Value.RepeatCount++
                                if (($TailStateRef.Value.RepeatCount % 25) -eq 0) {
                                    Write-Log ("    (... wiederholt sich, $($TailStateRef.Value.RepeatCount)x unterdrueckt)") -Level INFO
                                }
                                if ($TrackSetupProgress) { Update-SetupProgressFromTask -Task $short }
                                continue
                            }
                            $TailStateRef.Value.LastShort = $short
                            $TailStateRef.Value.RepeatCount = 0
                            # --- Phasen-Anzeige (nur im Exchange-Setup-Lauf, TAILMODE v8) ---
                            # Die 14 Top-Level-Tasks des Setups werden als kompakte
                            # "[ n/14] Task ..." Zeile gemeldet, abgeschlossen mit OK
                            # (bzw. FEHLER). "Setup will run the task 'X'" ist der
                            # eindeutige Startmarker; Untertasks (start-setupservice,
                            # Write-ExchangeSetupLog, new-perfCounters, ...) erzeugen
                            # KEINE eigenen START/DONE-Zeilen mehr - sonst ersaufen
                            # die 14 Punkte im Rauschen (frueher 7000+ Meilensteine).
                            if ($TrackSetupProgress) {
                                if ($short -match "^Setup will run the task\s+'([^']+)'") {
                                    $idx = Get-SetupPhaseIndex -Task $matches[1]
                                    if ($idx -ge 0) {
                                        if ($TailStateRef.Value.PhaseRunning -ge 0 -and $TailStateRef.Value.PhaseRunning -ne $idx) {
                                            # Vorige Phase ohne eigenen Endmarker abschliessen
                                            Complete-SetupPhase -Index $TailStateRef.Value.PhaseRunning -State $TailStateRef.Value
                                        }
                                        Start-SetupPhase -Index $idx -State $TailStateRef.Value
                                        $LastTaskRef.Value = $Global:SetupPhaseDefs[$idx].Task
                                        $LinesShownRef.Value++
                                        continue
                                    }
                                }
                                # "Finished executing the task 'X'." = Phasen-Ende (andere Setup-Versionen)
                                if ($short -match "^Finished executing the task\s+'([^']+)'") {
                                    $idx = Get-SetupPhaseIndex -Task $matches[1]
                                    if ($idx -ge 0 -and $TailStateRef.Value.PhaseRunning -eq $idx) {
                                        Complete-SetupPhase -Index $idx -State $TailStateRef.Value
                                        $LinesShownRef.Value++
                                    }
                                    continue
                                }
                                # Komponenten-Lauf beendet -> laufende Phase abschliessen
                                if ($short -match '^Finished executing component tasks') {
                                    if ($TailStateRef.Value.PhaseRunning -ge 0) {
                                        Complete-SetupPhase -Index $TailStateRef.Value.PhaseRunning -State $TailStateRef.Value
                                        $LinesShownRef.Value++
                                    }
                                    continue
                                }
                            }
                            if ($short -match 'Beginning processing[:\s]+(.+?)\s*$') {
                                $task = $matches[1].Trim().Trim('"',"'")
                                # install-ExchangeSchema je LDF NICHT extra loggen -
                                # dafuer gibt es die 1-zeilige "Schema-Datei ...: OK"-Meldung.
                                if ($task -match '^install-ExchangeSchema$') {
                                    if ($TrackSetupProgress) { Update-SetupProgressFromTask -Task $task }
                                    continue
                                }
                                if ($TrackSetupProgress) {
                                    $idx = Get-SetupPhaseIndex -Task $task
                                    if ($idx -ge 0) {
                                        # Fallback, falls "Setup will run ..." nicht mitgelesen wurde
                                        # (Tail-Beginn mitten im Lauf): nur wenn KEINE Phase laeuft
                                        # und die Phasennummer fortlaufend ist - so kann ein
                                        # phasen-ähnlicher Untertask (install-msipackage) nie
                                        # waehrend laufender Phase 9 eine Ruecksprung-Anzeige ausloesen.
                                        if ($TailStateRef.Value.PhaseRunning -lt 0 -and $idx -gt $TailStateRef.Value.PhaseLastStart) {
                                            Start-SetupPhase -Index $idx -State $TailStateRef.Value
                                            $LinesShownRef.Value++
                                        }
                                    } elseif ($task) {
                                        # Untertask: nur merken (Heartbeat zeigt die Activity)
                                        $LastTaskRef.Value = $task
                                    }
                                    continue
                                }
                                if ($task -and $task -ne $LastTaskRef.Value) {
                                    Write-Log "" -Level INFO
                                    Write-Log ("[$($Global:SetupPhaseDone)/$($Global:SetupPhaseCount)] >>> START: " + $task) -Level INFO
                                    $LastTaskRef.Value = $task; $LinesShownRef.Value++
                                    if ($TrackSetupProgress) { Update-SetupProgressFromTask -Task $task }
                                    continue
                                }
                            }
                            if ($short -match 'Ending processing[:\s]+(.+?)\s*$') {
                                $doneTask = $matches[1].Trim().Trim('"',"'")
                                if ($TrackSetupProgress) {
                                    $idx = Get-SetupPhaseIndex -Task $doneTask
                                    if ($idx -ge 0) {
                                        if ($TailStateRef.Value.PhaseRunning -eq $idx) {
                                            Complete-SetupPhase -Index $idx -State $TailStateRef.Value
                                            $LinesShownRef.Value++
                                        } elseif ($TailStateRef.Value.PhaseRunning -lt 0 -and $idx -gt $TailStateRef.Value.PhaseLastStart) {
                                            # Phase erst am Ende mitgelesen (Tail-Beginn mitten im Lauf)
                                            Complete-SetupPhase -Index $idx -State $TailStateRef.Value
                                            $LinesShownRef.Value++
                                        }
                                    }
                                    continue
                                }
                                # install-ExchangeSchema je LDF NICHT extra loggen (siehe oben).
                                if ($doneTask -match '^install-ExchangeSchema$') {
                                    if ($TrackSetupProgress) { Update-SetupProgressFromTask -Task $short }
                                    continue
                                }
                                Write-Log ("<<< DONE: " + $doneTask) -Level SUCCESS
                                Write-Log "" -Level INFO; $LinesShownRef.Value++
                                if ($TrackSetupProgress) { Update-SetupProgressFromTask -Task $short }
                                continue
                            }
                            if ($TrackSetupProgress) {
                                # NUR echte Abschlussmeldungen faellen die Anzeige auf 14/14.
                                # Frueher stand hier auch "Finished executing" - das trifft
                                # "Finished executing component tasks." nach JEDEM Phasenwechsel
                                # und hat die Anzeige sofort auf 13/13 gezogen (Hauptfehlerquelle).
                                if ($short -match 'Setup completed successfully|Setup has completed|erfolgreich abgeschlossen') {
                                    Set-SetupProgress -Step $Global:SetupPhaseCount
                                }
                            }
                            Write-Log ("    " + $short) -Level $level
                            $LinesShownRef.Value++
                        } catch {
                            # Fehler in EINER Zeile: registrieren, Zeile ueberspringen,
                            # Drain LÄUFT WEITER (sonst wuerden spaetere Zeilen -
                            # z. B. die LDF-Importe - nie erreicht).
                            $TailStateRef.Value.ReadErrors++
                            if (-not $TailStateRef.Value.LastError) {
                                $sn = "$line"
                                if ($sn.Length -gt 150) { $sn = $sn.Substring(0,150) }
                                $TailStateRef.Value.LastError = "$($_.Exception.Message) | Zeile: $sn"
                            }
                        }
                    }
                } finally {}
                $LastPosRef.Value = $newLastPos
            } finally { try { $fs.Close() } catch {} }
        } catch {
            $TailStateRef.Value.ReadErrors++
            if (-not $TailStateRef.Value.LastError) { $TailStateRef.Value.LastError = "Drain: $($_.Exception.Message)" }
        }
    }
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $FilePath; $psi.Arguments = ($Arguments -join ' ')
        $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true; $psi.WindowStyle = 'Hidden'
        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $psi
        $logStartPos = 0L
        if ($TailExchangeLog -and (Test-Path $ExchangeSetupLog)) {
            try { $logStartPos = (Get-Item $ExchangeSetupLog).Length } catch {}
        } else {
            Write-Log ("Setup-Logdatei: $ExchangeSetupLog (wird live mitgelesen)") -Level INFO
        }
        Write-Log ("Kommando: $FilePath " + ($Arguments -join ' ')) -Level INFO
        Write-Log "Tailing v7 (Byte-Reader + LDF-only + Prereq-Filter + Diagnose)" -Level INFO
        [void]$proc.Start()
        Write-Log ("PID: " + $proc.Id + " started") -Level INFO
        Write-Log "----------- LIVE-MILESTONES -----------" -Level INFO
        if ($TrackSetupProgress) { Initialize-SetupProgress -Title $LogPrefix }
        $startTime = Get-Date; $lastHB = Get-Date; $lastLogPos = $logStartPos; $linesShown = 0; $lastTask = ""
        # PhaseRunning/PhaseLastStart/PhaseDone/PhasesOk: Zustand der 14-Punkte-Anzeige
        # (PhaseRunning = -1 heisst "keine Phase laeuft"; ohne diesen Default wuerde
        #  $null -lt 0  fehlschlagen und der Phasen-Fallback nie anschlagen.)
        $tailState = @{ BannerCount=0; RotWarned=$false; SeenUserDomains=@{}; SeenDcDomains=@{}; DomainWarned=$false; PrereqSeen=0; LastShort=""; RepeatCount=0; PendingLdf=""; LdfOk=0; LdfFail=0; RawLines=0; ReadErrors=0; LogStartBytes=$logStartPos; LastError=""; PhaseRunning=-1; PhaseLastStart=-1; PhaseDone=@{}; PhasesOk=0 }
        $important = @(
            @{Pattern='Beginning processing'; Level='INFO'},
            @{Pattern='Ending processing'; Level='SUCCESS'},
            @{Pattern='Setup is running|Setup will run|Setup has completed|Setup completed'; Level='INFO'},
            @{Pattern='Successfully (extended|installed|configured|prepared|added)'; Level='SUCCESS'},
            @{Pattern='Schema upgrade (started|completed)|Updating Schema|Successfully extended.*schema'; Level='INFO'},
            @{Pattern='Importing schema file|Importing.*ldif|Applying.*schema'; Level='INFO'},
            @{Pattern='install-ExchangeSchema|LdapFileName|ldifde\.exe finished|schema\d+\.ldf|PostWindows2003_schema'; Level='INFO'},
            @{Pattern='Step \d+ of \d+'; Level='INFO'},
            @{Pattern='Mailbox role:|Client Access|Transport|Database'; Level='INFO'},
            @{Pattern='is being prepared|is preparing|preparation'; Level='INFO'},
            @{Pattern='PrepareSchema|PrepareAD|PrepareDomain|PrepareAllDomains'; Level='INFO'},
            @{Pattern='Configuring Microsoft Exchange|Configuring Prerequisites|Copying Setup Files'; Level='INFO'},
            @{Pattern='Setup completed successfully|Finished executing'; Level='SUCCESS'},
            @{Pattern='erfolgreich abgeschlossen'; Level='SUCCESS'},
            @{Pattern='has completed'; Level='SUCCESS'},
            @{Pattern='Restart .{0,30}required'; Level='WARNING'},
            @{Pattern='Updating Schema'; Level='INFO'}
        )
        $errPatt = @('\[ERROR\]','Setup encountered an error','A fatal error','Setup cannot continue','Setup failed')
        $warnPatt = @('\[WARNING\]','recommendation:','is not recommended')

        while (-not $proc.HasExited) {
            try { [System.Windows.Forms.Application]::DoEvents() } catch {}
            Start-Sleep -Milliseconds 800
            Invoke-TailDrain -LastPosRef ([ref]$lastLogPos) -LinesShownRef ([ref]$linesShown) -LastTaskRef ([ref]$lastTask) -TailStateRef ([ref]$tailState)
            if (((Get-Date) - $lastHB).TotalSeconds -ge $HeartbeatSec) {
                $el = ((Get-Date) - $startTime).ToString("hh\:mm\:ss")
                $ph = ""
                if ($TrackSetupProgress) {
                    $ph = " | Schritt $($Global:SetupPhaseDone)/$($Global:SetupPhaseCount)"
                    if ($Global:SetupCurrentPhaseText) { $ph += " ($($Global:SetupCurrentPhaseText))" }
                    if ($Global:SetupPhaseDone -gt 0 -and $Global:SetupPhaseStart) {
                        $secPerPhase = ((Get-Date) - $Global:SetupPhaseStart).TotalSeconds / $Global:SetupPhaseDone
                        $restMin = [int](($secPerPhase * ($Global:SetupPhaseCount - $Global:SetupPhaseDone)) / 60)
                        if ($restMin -ge 1) { $ph += " | ca. $restMin min verbleibend" }
                    }
                    if ($lastTask) { $ph += " | Task: $lastTask" }
                } else {
                    if ($lastTask) { $ph = " | Task: $lastTask" }
                }
                Write-Log ("  ... $LogPrefix laeuft | Betriebszeit: $el$ph | Meilensteine: $linesShown") -Level INFO
                $lastHB = Get-Date
            }
        }
        Start-Sleep -Milliseconds 1000
        # Finaler Drain: Zeilen zwischen letztem Poll und Prozessende nachholen.
        # -FlushTail: am Prozessende auch die letzte Zeile ohne abschliessendes LF lesen.
        Invoke-TailDrain -LastPosRef ([ref]$lastLogPos) -LinesShownRef ([ref]$linesShown) -LastTaskRef ([ref]$lastTask) -TailStateRef ([ref]$tailState) -FlushTail
        # Domain-Check: Setup meldet ggf. andere Domaene als erwartet (falscher Server / altes Log).
        try {
            if (-not $tailState.DomainWarned) {
                $expected = @()
                foreach ($c in @($env:USERDNSDOMAIN, $Global:TxtDomain.Text)) {
                    $c = "$c".Trim().ToUpper()
                    if ($c) { $expected += $c }
                }
                $seen = @()
                foreach ($k in $tailState.SeenUserDomains.Keys) { $seen += $k }
                foreach ($fqdn in $tailState.SeenDcDomains.Keys) {
                    $dot = $fqdn.IndexOf('.')
                    if ($dot -gt 0) { $seen += $fqdn.Substring($dot + 1).ToUpper() }
                }
                $seen = @($seen | Sort-Object -Unique)
                if ($seen.Count -gt 0 -and $expected.Count -gt 0) {
                    $match = $false
                    foreach ($s in $seen) { if ($expected -contains $s) { $match = $true } }
                    if (-not $match) {
                        Write-Log ("ACHTUNG Domaene: Setup meldet '" + ($seen -join ", ") + "', erwartet '" + ($expected -join ", ") + "' - falscher Server/DC, falsches DNS oder altes ExchangeSetup.log?") -Level WARNING
                        $tailState.DomainWarned = $true
                    }
                }
            }
            if ($tailState.BannerCount -gt 3 -and $proc.ExitCode -ne 0) {
                Write-Log ("Setup ist $($tailState.BannerCount)x neu gestartet - das deutet auf eine Prerequisite-Schleife hin. Massgeblich ist das ENDE von $ExchangeSetupLog ([ERROR] suchen), nicht die wiederholten Start-Bloecke.") -Level WARNING
            }
        } catch {}
        if (($tailState.LdfOk + $tailState.LdfFail) -gt 0) {
            $lvlLdf = if ($tailState.LdfFail -eq 0) { "SUCCESS" } else { "ERROR" }
            Write-Log ("Schema-Dateien: $($tailState.LdfOk) OK, $($tailState.LdfFail) Fehler") -Level $lvlLdf
        } elseif ($LogPrefix -match 'PrepareSchema') {
            Write-Log "Keine LDF-Zeilen mitgelesen (0 Dateien) - ExchangeSetup.log auf 'LdapFileName/ldifde' pruefen; ggf. lief alte Skriptversion ohne TAILMODE v7." -Level WARNING
        }
        # Diagnose: Wieviel hat der Tailer wirklich gesehen? (Start/Ende-Bytes,
        # gescannte Rohzeilen, Lesefehler). Klaert "nichts im Log" zweifelsfrei.
        try {
            $endBytes = 0L
            try { if (Test-Path $ExchangeSetupLog) { $endBytes = (Get-Item $ExchangeSetupLog).Length } } catch {}
            $grew = $endBytes - [long]$tailState.LogStartBytes
            Write-Log ("Setup-Log Diagnose: Start $($tailState.LogStartBytes) Bytes -> Ende $endBytes Bytes (Zuwachs $grew), $($tailState.RawLines) Zeilen gescannt, $($tailState.ReadErrors) Lesefehler, LDF $($tailState.LdfOk)/$($tailState.LdfFail).") -Level INFO
            if ($tailState.LastError) {
                Write-Log ("Erster Verarbeitungsfehler: " + $tailState.LastError) -Level WARNING
            }
            if (($tailState.LdfOk + $tailState.LdfFail) -eq 0 -and $tailState.RawLines -gt 0) {
                # Datei enthaelt offenbar keine LDF-Importe in diesem Lauf -
                # Gegenprobe direkt in der Datei (unabhaengig vom Tailing).
                try {
                    $hits = @(Select-String -Path $ExchangeSetupLog -Pattern 'LdapFileName|ldifde\.exe finished' -ErrorAction SilentlyContinue)
                    Write-Log ("Gegenprobe ExchangeSetup.log: $($hits.Count)x 'LdapFileName/ldifde' im GESAMTEN Log (inkl. alte Laeufe).") -Level INFO
                    if ($hits.Count -gt 0) {
                        $last = @($hits | Select-Object -Last 3 | ForEach-Object { "$($_.LineNumber): $($_.Line.Trim())" })
                        foreach ($lh in $last) {
                            $s = "$lh"
                            if ($s.Length -gt 220) { $s = $s.Substring(0,220) + "..." }
                            Write-Log ("    Log: " + $s) -Level INFO
                        }
                    } else {
                        Write-Log "Gegenprobe: KEIN 'LdapFileName/ldifde' in ExchangeSetup.log - dieser Setup-Lauf hat keine Schema-Dateien importiert (ggf. Schema bereits aktuell oder Setup schrieb woanders hin)." -Level WARNING
                    }
                } catch {}
            }
        } catch {}
        Write-Log "----------- DONE -----------" -Level INFO
        $tt = ((Get-Date) - $startTime).ToString("hh\:mm\:ss")
        $lvl = if ($proc.ExitCode -eq 0) { "SUCCESS" } else { "ERROR" }
        Write-Log ("Exit code: " + $proc.ExitCode + " | runtime: " + $tt) -Level $lvl
        if ($TrackSetupProgress) {
            # Noch offene Phase quittieren: bei Exit 0 = OK, sonst FEHLER mit Exit-Code
            # (die konkrete Fehlerzeile steht unmittelbar davor als [ERROR] im Log).
            try {
                if ($tailState.PhaseRunning -ge 0) {
                    $runIdx = [int]$tailState.PhaseRunning
                    if ($proc.ExitCode -eq 0) {
                        Complete-SetupPhase -Index $runIdx -State $tailState -Result "OK"
                    } else {
                        Complete-SetupPhase -Index $runIdx -State $tailState -Result ("FEHLER (Setup-Exit " + $proc.ExitCode + ")")
                    }
                }
                $phOk = 0
                for ($i = 0; $i -lt $Global:SetupPhaseCount; $i++) { if ($tailState.PhaseDone[[string]$i]) { $phOk++ } }
                $lvlP = if ($phOk -eq $Global:SetupPhaseCount) { "SUCCESS" } else { "INFO" }
                Write-Log ("Phasen-Report: " + $phOk + " von " + $Global:SetupPhaseCount + " Punkten mit OK quittiert.") -Level $lvlP
            } catch {}
            if ($proc.ExitCode -eq 0) {
                Set-SetupProgress -Step $Global:SetupPhaseCount -Text (Get-T "Run_PhaseDone")
                if ($Global:LblSetupPhase) { $Global:LblSetupPhase.ForeColor = $Global:ColorAccent2 }
            } else {
                if ($Global:LblSetupPhase) {
                    $Global:LblSetupPhase.Text = ("$($Global:SetupPhaseDone) / $($Global:SetupPhaseCount)  -  " + (Get-T "Run_PhaseFailed"))
                    $Global:LblSetupPhase.ForeColor = $Global:ColorError
                }
            }
        }
        return $proc.ExitCode
    } catch { Write-Log ("Error: " + $_) -Level ERROR; return -1 }
}

function Resolve-InstallTargetDir {
    <#
        Validiert den GUI-Installations-Pfad und normalisiert ihn fuer /TargetDir.
        Liefert @{ Ok=$true; Path=<normalisierter Pfad> } oder
                 @{ Ok=$false; Error="invalid"|"drive"|"create" }.
        Ein abschliessender Backslash wird entfernt: er stünde direkt vor dem
        schliessenden Anfuehrungszeichen, wuerde dort escape'd und zerschoesse
        den ArgumentString (CommandLineToArgvW: \" = Literal-Anfuehrungszeichen).
    #>
    param([Parameter(Mandatory)][string]$Path)
    $p = "$Path".Trim()
    while ($p.EndsWith('\')) { $p = $p.Substring(0, $p.Length - 1) }
    # Nur lokaler absoluter Pfad (X:\...): nach dem Trim waere "C:\" zu "C:"
    # (laufwerksrelativ, also das aktuelle Verzeichnis auf C:) - deshalb muss
    # hinter dem Doppelpunkt noch ein Backslash mit Inhalt folgen.
    if ($p -notmatch '^[A-Za-z]:\\.+') { return @{ Ok=$false; Error="invalid" } }
    if (-not (Test-Path -LiteralPath ($p.Substring(0,3)))) { return @{ Ok=$false; Error="drive" } }
    if (-not (Test-Path -LiteralPath $p)) {
        # fruehes Feedback, falls das Ziel nicht anlegbar ist (fehlendes Recht etc.)
        try { New-Item -Path $p -ItemType Directory -Force -ErrorAction Stop | Out-Null }
        catch { return @{ Ok=$false; Error="create" } }
    }
    return @{ Ok=$true; Path=$p }
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
        if ($TargetDir -and $setupMode -eq "Install") {
            # GUI-Feld "Installations-Pfad" -> /TargetDir (sonst bliebe der Wert
            # wirkungslos und setup.exe wuerde stillschweigend im Default landen).
            # Vorher validieren/normalisieren, damit nur ein existierender,
            # absoluter lokaler Pfad ohne abschliessenden Backslash ans Setup geht.
            $tdRes = Resolve-InstallTargetDir -Path $TargetDir
            if (-not $tdRes.Ok) {
                $tdWhy = switch ($tdRes.Error) {
                    "drive"  { "Laufwerk nicht vorhanden / Drive not found" }
                    "create" { "Verzeichnis nicht anlegbar / Cannot create directory" }
                    default  { "kein absoluter lokaler Pfad wie D:\Exchange / not an absolute local path like D:\Exchange" }
                }
                Write-Log ("ERROR invalid install path / Ungueltiger Installations-Pfad '" + $TargetDir + "': " + $tdWhy + " - setup NOT started / Setup wurde nicht gestartet") -Level ERROR
                return $false
            }
            $TargetDir = $tdRes.Path
            $arguments += "/TargetDir:`"$TargetDir`""
            Write-Log ("Install path / Installationspfad: " + $TargetDir) -Level INFO
        }

        Write-Log "Starting Exchange Setup (60-90 min)..." -Level INFO
        Write-Log ("Arguments: " + ($arguments -join ' ')) -Level INFO
        Write-Log ("Setup-Logdatei (Volltext): " + $Global:ExchangeSetupLog) -Level INFO
        Write-SetupPhaseOverview

        $exitCode = Invoke-ResponsiveProcess -FilePath $SetupPath -Arguments $arguments -LogPrefix "Exchange-Setup" -HeartbeatSec 30 -TrackSetupProgress $true -ShowAllTailLines $true
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
        [bool]$EnableContent=$true,[bool]$EnableSenderID=$false,
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
        } else { Set-ContentFilterConfig -Enabled $false }
        if ($EnableSenderID) { Set-SenderIDConfig -Enabled $true -SpoofedDomainAction Reject }
        else { Set-SenderIDConfig -Enabled $false }
        if ($EnableSenderFilter) { Set-SenderFilterConfig -Enabled $true -BlankSenderBlockingEnabled $true }
        else { Set-SenderFilterConfig -Enabled $false }
        if ($EnableRecipientFilter) { Set-RecipientFilterConfig -Enabled $true -RecipientValidationEnabled $true }
        else { Set-RecipientFilterConfig -Enabled $false }
        if ($EnableSenderReputation) { Set-SenderReputationConfig -Enabled $true -SenderBlockingEnabled $true -SenderBlockingPeriod 24 }
        else { Set-SenderReputationConfig -Enabled $false }
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
        $started = Get-Date
        Write-Log "==============================================" -Level INFO
        Write-Log ("AD-Vorbereitung: $Step startet (" + $started.ToString("yyyy-MM-dd HH:mm:ss") + ")") -Level INFO
        $arguments = @("/IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF")
        switch ($Step) {
            "PrepareSchema"     { $arguments += "/PrepareSchema" }
            "PrepareAD"         {
                $arguments += "/PrepareAD"
                if ($OrgName) {
                    $existingOrg = (Get-ExchangeSchemaInfo).ExchangeOrgName
                    if ($existingOrg -and $existingOrg -ne "(not yet installed)" -and $existingOrg -eq $OrgName) {
                        Write-Log ("OrganizationName unchanged ('" + $OrgName + "') - parameter omitted") -Level INFO
                    } else {
                        $arguments += "/OrganizationName:$OrgName"
                    }
                }
            }
            "PrepareAllDomains" { $arguments += "/PrepareAllDomains" }
            "PrepareDomain"     { if ($DomainName) { $arguments += "/PrepareDomain:$DomainName" } else { $arguments += "/PrepareDomain" } }
        }
        Write-Log ("Setup-Pfad: " + $SetupPath) -Level INFO
        Write-Log ("Argumente: " + ($arguments -join ' ')) -Level INFO
        Write-Log ("Details live in: " + $Global:ExchangeSetupLog) -Level INFO
        # Vorher-Versionen loggen, damit man die Aenderung sieht
        try {
            $pre = Get-ExchangeSchemaInfo
            Write-Log ("Vorher: Schema=" + $pre.SchemaVersion + " Org=" + $pre.OrgVersion + " (" + $pre.ExchangeOrgName + ") Domain=" + $pre.DomainVersion) -Level INFO
        } catch {}
        Write-Log ("Fuehre aus: Setup.exe " + ($arguments -join ' ')) -Level INFO
        # Ausgefuehrten Setup-Schritt fuer den spaeteren Ergebnis-Report merken.
        # Der Eintrag entsteht VOR dem Lauf (sichtbar auch bei Fehler/Abbruch),
        # das OK-Flag wird nach dem Exit-Code gesetzt.
        $prepSwitch = (@($arguments | Where-Object { $_ -like '/Prepare*' }) -join ' ')
        if (-not $Global:AdPrepExecuted) { $Global:AdPrepExecuted = @() }
        $runEntry = [PSCustomObject]@{ Step=$Step; Switch=$prepSwitch; OK=$false; At=(Get-Date -Format "HH:mm:ss") }
        $Global:AdPrepExecuted += $runEntry
        # ShowAllTailLines=true: jede neue Zeile aus ExchangeSetup.log spiegeln,
        # damit Schema-Import / Org-/Domain-Prep sichtbar sind.
        $ec = Invoke-ResponsiveProcess -FilePath $SetupPath -Arguments $arguments -LogPrefix $Step -HeartbeatSec 30 -ShowAllTailLines $true
        $dur = ((Get-Date) - $started).ToString("hh\:mm\:ss")
        if ($ec -eq 0) {
            $runEntry.OK = $true
            Write-Log ("$Step OK (Dauer: $dur)") -Level SUCCESS
            try {
                $post = Get-ExchangeSchemaInfo
                Write-Log ("Nachher: Schema=" + $post.SchemaVersion + " Org=" + $post.OrgVersion + " (" + $post.ExchangeOrgName + ") Domain=" + $post.DomainVersion) -Level SUCCESS
            } catch {}
            return $true
        }
        Write-Log ("$Step FEHLER: Exit-Code " + $ec + " (Dauer: $dur) - ABBRUCH, naechste Schritte werden NICHT ausgefuehrt. Details: " + $Global:ExchangeSetupLog) -Level ERROR
        return $false
    } catch { Write-Log ("$Step Ausnahme: " + $_) -Level ERROR; return $false }
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

# ------------------------------------------------------------
#  AD-Vorbereitung: automatisches Ergebnis-Check
# ------------------------------------------------------------
function Get-ADDomainPrepVersion {
    <#
        Liest die Version der Domain-Vorbereitung (Attribut objectVersion des Objekts
        "Microsoft Exchange System Objects") aus einer beliebigen Forest-Domain.
        $DomainOrNC : DNS-Name ("contoso.local") oder Distinguished Name ("DC=contoso,DC=local").
        Statt eines stillen Fehlschlags wird der konkrete Grund zurueckgegeben.
    #>
    param([string]$DomainOrNC)
    $out = [PSCustomObject]@{ Version=""; Base=""; Found=$false; Error="objectVersion not found" }
    if (-not $DomainOrNC) { $out.Error = "no domain given"; return $out }
    $raw = "$DomainOrNC"
    $out.Base = if ($raw.StartsWith("LDAP://", [System.StringComparison]::OrdinalIgnoreCase)) { $raw }
                elseif ($raw.StartsWith("LDAP:",  [System.StringComparison]::OrdinalIgnoreCase)) { "LDAP://" + $raw.Substring(6) }
                else { "LDAP://$raw" }
    try {
        $s = New-Object System.DirectoryServices.DirectorySearcher
        $s.SearchRoot = [ADSI]$out.Base
        $s.Filter = "(cn=Microsoft Exchange System Objects)"
        $s.PropertiesToLoad.Add("objectVersion") | Out-Null
        $s.SearchScope = "OneLevel"
        $r = $s.FindOne()
        if (-not $r) { $out.Error = "object 'Microsoft Exchange System Objects' not found - PrepareDomain not run?"; return $out }
        $v = $null
        try { if ($r.Properties["objectVersion"].Count -gt 0) { $v = "$($r.Properties['objectVersion'][0])" } } catch {}
        if (-not $v) { $out.Error = "objectVersion attribute not readable"; return $out }
        if ($v -notmatch '^\d+$') { $out.Error = "unexpected objectVersion value '" + $v + "'"; return $out }
        $out.Version = $v
        $out.Found = $true
        $out.Error = ""
    }
    catch { $out.Error = $_.Exception.Message }
    return $out
}

function Get-AdPrepRunSummary {
    <#
        Liefert die Setup-Schritte, die tatsaechlich gestartet wurden ($Global:AdPrepExecuted),
        sowie die davon noch nicht ausgefuehrten.
        Zweck: Der Ergebnis-Report muss klar trennen zwischen dem, was Setup ausgefuehrt hat,
        und dem, was nur ein Ist-Stand aus Active Directory ist.
    #>
    $ran = @($Global:AdPrepExecuted | Where-Object { $_ -and $_.Step })
    $ranSteps = @($ran | ForEach-Object { $_.Step } | Select-Object -Unique)
    $executedText = ""
    if ($ran.Count -gt 0) {
        $executedText = (($ran | ForEach-Object {
            $s = "$($_.Switch)"
            if (-not $s) { $s = "/" + $_.Step }
            if ($_.OK) { $s } else { $s + " (FEHLER)" }
        }) -join ", ")
    }
    $allSteps = @("PrepareSchema","PrepareAD","PrepareDomain","PrepareAllDomains")
    $notRun = @($allSteps | Where-Object { $ranSteps -notcontains $_ } | ForEach-Object { "/" + $_ })
    return [PSCustomObject]@{
        ExecutedText    = $executedText
        NotExecutedText = ($notRun -join ", ")
    }
}

function Test-ADPrepResult {
    <#
        Prueft nach der AD-Vorbereitung automatisch, ob wirklich alles erfolgreich war.
        Geprueft werden Schema-, Organisations- und Domain-Prep, die Replikation auf alle DCs
        sowie die noetigen Berechtigungen des ausfuehrenden Benutzers.
    #>
    $results = @()
    # Sichere Ganzzahl-Konvertierung: liefert den Default, wenn kein Zahlenwert vorliegt
    function ConvertTo-SafeInt {
        param($Value, [int]$Default = -1)
        $s = "$Value"
        if ($s -match '^\d+$') { return [int]$s }
        return $Default
    }
    try {
        $info = Get-ExchangeSchemaInfo
        $needSchema = ConvertTo-SafeInt $info.SchemaVersionNeeded 17003
        $needOrg    = ConvertTo-SafeInt $info.OrgVersionNeeded 16763
        $needDom    = ConvertTo-SafeInt $info.DomainVersionNeeded 13243

        $schemaOK = $false
        if ("$($info.SchemaVersion)" -match '^\d+$') { $schemaOK = ([int]$info.SchemaVersion -ge $needSchema) }
        $results += [PSCustomObject]@{
            Item="PrepareSchema (Schema forest-weit)"; Current="$($info.SchemaVersion)"
            Required=">= $needSchema"; OK=$schemaOK
            Detail=$info.SchemaNC
        }

        $orgOK = $false
        if ("$($info.OrgVersion)" -match '^\d+$') { $orgOK = ([int]$info.OrgVersion -ge $needOrg) }
        $results += [PSCustomObject]@{
            Item="PrepareAD (Exchange-Organisation)"; Current="$($info.OrgVersion)"
            Required=">= $needOrg"; OK=$orgOK
            Detail=$info.ExchangeOrgName
        }

        # Domain-Prep muss in JEDER Domain des Forests gelaufen sein.
        # Die aktuelle Domain wird aus Get-ExchangeSchemaInfo uebernommen - das ist derselbe
        # LDAP-Zugriff, ueber den DomainVersion bereits ermittelt und oben geprueft wurde.
        $curNC  = "$($info.DomainNC)"
        $curVal = "$($info.DomainVersion)"
        $curNum = ($curVal -match '^\d+$')
        $curOK  = $curNum -and ([int]$curVal -ge $needDom)
        $results += [PSCustomObject]@{
            Item="Domain-Prep (aktuelle Domain, via /PrepareAD)"
            Current=$(if ($curNum) { $curVal } else { "n/a" })
            Required=">= $needDom"; OK=$curOK
            Detail=$(if ($curOK) { "IST-Stand aus AD - die aktuelle Domain wird von Exchange bei /PrepareAD automatisch mitvorbereitet (DomainNC: $curNC)" }
                    else { "IST-Stand: objectVersion fehlt oder nicht lesbar - Domain-Prep nicht vorhanden (DomainNC: $curNC)" })
        }

        # Weitere Domains im Forest pruefen - Domain-Prep muss auch dort gelaufen sein.
        $curDns = if ($curNC) { ((($curNC -split ',') | ForEach-Object { ("$_" -replace '^\s*DC=','').Trim() } | Where-Object { $_ }) -join '.') } else { "" }
        try {
            $forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
            foreach ($fd in $forest.Domains) {
                $dns = "$($fd.Name)".Trim()
                if (-not $dns) { continue }
                $fdNC = "$($fd.NamingContext)".Trim()
                # Die aktuelle Domain ist bereits oben geprueft - nicht doppelt auffuehren
                if ($curNC) {
                    if ($fdNC -and ($fdNC -eq $curNC)) { continue }
                    if ((-not $fdNC) -and $curDns -and ($dns -eq $curDns)) { continue }
                }
                $dv = Get-ADDomainPrepVersion -DomainOrNC $dns
                $results += [PSCustomObject]@{
                    Item="Domain-Prep (Forest-Domain: $dns)"
                    Current=$(if ($dv.Found) { $dv.Version } else { "n/a" })
                    Required=">= $needDom"
                    OK=($dv.Found -and ([int]$dv.Version -ge $needDom))
                    Detail=$(if ($dv.Error) { "$dns -> $($dv.Error) - /PrepareDomain:$dns oder /PrepareAllDomains erforderlich" }
                            else { "IST-Stand aus AD - diese Domain wird NICHT von /PrepareAD mitvorbereitet" })
                }
            }
        } catch { Write-Log ("Forest domain enumeration failed: " + $_.Exception.Message) -Level WARNING }

        # Berechtigungen
        $perm = Test-ExchangePrepPermissions
        $permOK = $perm.IsSchemaAdmin -and $perm.IsEnterpriseAdmin -and $perm.IsDomainAdmin
        $permMissing = @()
        if (-not $perm.IsSchemaAdmin)     { $permMissing += "Schema-Admin" }
        if (-not $perm.IsEnterpriseAdmin) { $permMissing += "Enterprise-Admin" }
        if (-not $perm.IsDomainAdmin)     { $permMissing += "Domain-Admin" }
        $results += [PSCustomObject]@{
            Item="Berechtigungen des Benutzers"; Current=$perm.Username
            Required="Schema+Enterprise+Domain-Admin"
            OK=$permOK
            Detail=$(if ($permOK) { "alle Rollen vorhanden" } else { "fehlt: " + ($permMissing -join ", ") })
        }

        # Replikation: ist die Schema-Erweiterung auf allen DCs des Forests angekommen?
        $dcs = @()
        # System.DirectoryServices liefert den kompletten Forest - Get-ADDomainController
        # wuerde nur die DCs der aktuellen Domain zurueckgeben.
        try {
            $forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
            foreach ($fd in $forest.Domains) {
                foreach ($dc in $fd.DomainControllers) {
                    if ($dc.Name) { $dcs += $dc.Name }
                }
            }
        } catch {}
        if ($dcs.Count -eq 0) {
            try { $dcs = @(Get-ADDomainController -Filter * -ErrorAction Stop | ForEach-Object { $_.HostName }) } catch {}
        }
        if ($dcs.Count -gt 0 -and $info.SchemaNC) {
            $notReplicated = @()
            $total = 0
            foreach ($dc in $dcs) {
                $total++
                try {
                    [System.Windows.Forms.Application]::DoEvents()
                    $s = New-Object System.DirectoryServices.DirectorySearcher
                    $s.SearchRoot = [ADSI]("LDAP://$dc/" + $info.SchemaNC)
                    $s.Filter = "(cn=ms-Exch-Schema-Version-Pt)"
                    $s.PropertiesToLoad.Add("rangeUpper") | Out-Null
                    $s.SearchScope = "Subtree"
                    $r = $s.FindOne()
                    $remote = $null
                    if ($r -and $r.Properties["rangeUpper"].Count -gt 0) { $remote = "$($r.Properties['rangeUpper'][0])" }
                    if (-not $remote -or -not ($remote -match '^\d+$') -or [int]$remote -lt $needSchema) {
                        $notReplicated += $dc
                    }
                } catch { $notReplicated += $dc }
            }
            $results += [PSCustomObject]@{
                Item="Schema-Replikation (alle DCs)"
                Current="$($dcs.Count - $notReplicated.Count)/$($dcs.Count) DCs"
                Required="auf allen DCs identisch"
                OK=($notReplicated.Count -eq 0)
                Detail=$(if ($notReplicated.Count -gt 0) { "fehlt auf: " + ($notReplicated -join ", ") } else { "alle DCs aktuell" })
            }
        }

        $failed = @($results | Where-Object { -not $_.OK })
        $run = Get-AdPrepRunSummary
        return [PSCustomObject]@{
            Results=$results
            AllOK=($failed.Count -eq 0)
            TotalCount=$results.Count
            FailedCount=$failed.Count
            ExecutedText=$run.ExecutedText
            NotExecutedText=$run.NotExecutedText
            CheckedAt=(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        }
    }
    catch { Write-Log ("Result check error: " + $_) -Level ERROR; return $null }
}

function Write-ADPrepResultReport {
    param($Result)
    if (-not $Result) { return }
    Write-Log "==============================================" -Level INFO
    Write-Log (" AD PREPARATION RESULT (" + $Result.CheckedAt + ")") -Level INFO
    Write-Log "==============================================" -Level INFO
    # Zuerst: was wurde tatsaechlich ausgefuehrt? (die Pruefpunkte darunter sind nur der Ist-Stand)
    if ($Result.ExecutedText) {
        Write-Log ("  Ausgefuehrte Setup-Schritte : " + $Result.ExecutedText) -Level INFO
        if ($Result.NotExecutedText) {
            Write-Log ("  Nicht ausgefuehrt            : " + $Result.NotExecutedText) -Level INFO
        }
    } else {
        Write-Log "  Ausgefuehrte Setup-Schritte : - (in dieser Sitzung kein Adprep-Lauf erfasst)" -Level INFO
    }
    Write-Log "  Hinweis: Alle Pruefpunkte unten sind der IST-STAND aus Active Directory," -Level INFO
    Write-Log "           nicht die Aufzeichnung, welche Setup-Schritte gelaufen sind." -Level INFO
    foreach ($r in $Result.Results) {
        $mark = if ($r.OK) { "[OK]  " } else { "[FAIL]" }
        $line = "  $mark " + $r.Item.PadRight(46) + " : " + $r.Current.PadRight(14) + " (erforderlich: " + $r.Required + ")"
        if ($r.OK) { Write-Log $line -Level SUCCESS } else { Write-Log $line -Level ERROR }
        if ($r.Detail) { Write-Log ("         " + $r.Detail) -Level INFO }
    }
    if ($Result.AllOK) {
        Write-Log ("Alle " + $Result.TotalCount + " Pruefungen OK - Active Directory ist vollstaendig vorbereitet (Ist-Stand).") -Level SUCCESS
    } else {
        Write-Log ($Result.FailedCount + " von " + $Result.TotalCount + " Pruefungen NICHT OK - AD-Vorbereitung unvollstaendig (Ist-Stand).") -Level ERROR
    }
    Write-Log "==============================================" -Level INFO
}

function Update-ADPrepResultLabels {
    param($Result)
    try {
        if (-not $Result) {
            $Global:LblADResult.Text = (Get-T "AD_ResultNone")
            $Global:LblADResult.ForeColor = $Global:ColorTextDim
            return
        }
        $runTxt = ""
        if ($Result.ExecutedText) { $runTxt = "  |  " + ((Get-T "AD_Ran") -f $Result.ExecutedText) }
        if ($Result.AllOK) {
            $Global:LblADResult.Text = ((Get-T "AD_ResultOk") -f $Result.TotalCount) + $runTxt + "  |  " + $Result.CheckedAt
            $Global:LblADResult.ForeColor = $Global:ColorAccent2
        } else {
            $Global:LblADResult.Text = ((Get-T "AD_ResultFail") -f $Result.FailedCount, $Result.TotalCount) + $runTxt + "  |  " + $Result.CheckedAt
            $Global:LblADResult.ForeColor = $Global:ColorError
        }
    } catch {}
}
#endregion

#region ============================ URL & ZERTIFIKAT-FUNKTIONEN ============================

# ------------------------------------------------------------
#  URLs: bestehenden Exchange auslesen / setzen
# ------------------------------------------------------------
function Get-ExchangeVirtualDirectory {
    param([string]$Type, [string]$Server)
    try {
        $srvArg = @{}
        if ($Server) { $srvArg['Server'] = $Server }
        switch ($Type) {
            "OWA"      { return Get-OwaVirtualDirectory @srvArg -ErrorAction Stop | Select-Object -First 1 }
            "ECP"      { return Get-EcpVirtualDirectory @srvArg -ErrorAction Stop | Select-Object -First 1 }
            "EWS"      { return Get-WebServicesVirtualDirectory @srvArg -ErrorAction Stop | Select-Object -First 1 }
            "AS"       { return Get-ActiveSyncVirtualDirectory @srvArg -ErrorAction Stop | Select-Object -First 1 }
            "PS"       { return Get-PowerShellVirtualDirectory @srvArg -ErrorAction Stop | Select-Object -First 1 }
            "AD"       { return Get-AutodiscoverVirtualDirectory @srvArg -ErrorAction Stop | Select-Object -First 1 }
            "MAPI"     { return Get-MapiVirtualDirectory @srvArg -ErrorAction Stop | Select-Object -First 1 }
            "OAB"      { return Get-OabVirtualDirectory @srvArg -ErrorAction Stop | Select-Object -First 1 }
            "RCP"      { return Get-RpcCasVirtualDirectory @srvArg -ErrorAction Stop | Select-Object -First 1 }
        }
    } catch { return $null }
    return $null
}

function Get-ExchangeServerList {
    <#
        Liefert die Namen aller Exchange-Server der Organisation.
        Zuerst per ADSI (schnell, ohne EMS), Fallback per Get-ExchangeServer
        (nur wenn lokal Exchange installiert ist, sonst kein Log-Spam).
    #>
    $names = @()
    try {
        $info = Get-ExchangeSchemaInfo
        if ($info.ConfigNC) {
            $s = New-Object System.DirectoryServices.DirectorySearcher
            $s.SearchRoot = [ADSI]("LDAP://CN=Microsoft Exchange,CN=Services," + $info.ConfigNC)
            $s.Filter = "(objectClass=msExchExchangeServer)"
            $s.PropertiesToLoad.Add("cn") | Out-Null
            $s.SearchScope = "Subtree"
            $all = $s.FindAll()
            try {
                foreach ($r in $all) {
                    if ($r.Properties["cn"].Count -gt 0) { $names += "$($r.Properties['cn'][0])" }
                }
            } finally { try { $all.Dispose() } catch {} }
        }
    } catch {}
    if ($names.Count -eq 0) {
        try {
            $localExch = $false
            try { if (Get-Service -Name "MSExchangeADTopology" -ErrorAction SilentlyContinue) { $localExch = $true } } catch {}
            if ($localExch -and (Import-ExchangeManagementShell)) {
                $names = @(Get-ExchangeServer -ErrorAction Stop | ForEach-Object { "$($_.Name)".Trim() })
            }
        } catch {}
    }
    return @($names | Where-Object { $_ } | Sort-Object -Unique)
}

function Get-ExchangeAutodiscoverScp {
    <#
        Liest den Autodiscover-SCP (Service Connection Point) - also die URL,
        die domain-jointer Outlook-Clients per AD beziehen.
        1. EMS: AutoDiscoverServiceInternalUri (+ InternalUrl/ExternalUrl) des
           angegebenen Servers bzw. des ersten ClientAccessService.
        2. ADSI-Fallback direkt am SCP-Objekt (serviceBindingInformation),
           funktioniert auch ohne geladene Exchange-Shell.
    #>
    param([string]$Server)
    $out = [PSCustomObject]@{ Internal=""; External=""; Source="" }
    $emsOK = $false
    try { $emsOK = Import-ExchangeManagementShell } catch {}
    if ($emsOK) {
        try {
            if ($Server) { $cas = Get-ClientAccessService -Identity $Server -ErrorAction Stop }
            else { $cas = Get-ClientAccessService -ErrorAction Stop | Select-Object -First 1 }
            if ($cas) {
                if ($cas.AutoDiscoverServiceInternalUri) {
                    $out.Internal = "$($cas.AutoDiscoverServiceInternalUri)".TrimEnd('/')
                    $out.Source = "SCP"
                }
                if (-not $out.Internal -and $cas.InternalUrl) {
                    $out.Internal = "$($cas.InternalUrl)".TrimEnd('/')
                    $out.Source = "ClientAccessService"
                }
                if ($cas.ExternalUrl) { $out.External = "$($cas.ExternalUrl)".TrimEnd('/') }
            }
        } catch {}
    }
    if (-not $out.Internal -and $Server) {
        try {
            $info = Get-ExchangeSchemaInfo
            if ($info.ConfigNC) {
                $esc = ("$Server" -replace '[\*\(\)\\\0]','').Trim()
                if ($esc) {
                    $s = New-Object System.DirectoryServices.DirectorySearcher
                    $s.SearchRoot = [ADSI]("LDAP://CN=Microsoft Exchange,CN=Services," + $info.ConfigNC)
                    $s.Filter = "(&(objectClass=msExchExchangeServer)(cn=" + $esc + "))"
                    $s.PropertiesToLoad.Add("distinguishedName") | Out-Null
                    $s.SearchScope = "Subtree"
                    $srv = $s.FindOne()
                    if ($srv -and $srv.Properties["distinguishedname"].Count -gt 0) {
                        $scp = [ADSI]("LDAP://CN=Autodiscover,CN=Protocols," + $srv.Properties["distinguishedname"][0])
                        if ($scp.Properties["servicebindinginformation"].Count -gt 0) {
                            $out.Internal = "$($scp.Properties['servicebindinginformation'][0])".TrimEnd('/')
                            $out.Source = "SCP-ADSI"
                        }
                    }
                }
            }
        } catch {}
    }
    return $out
}

function Update-UrlServerList {
    <#
        Fuellt das Server-Auswahlfeld im URL-Tab. Eine getroffene Auswahl bleibt
        erhalten, sonst wird der lokale Rechner bevorzugt, sonst der erste Eintrag.
    #>
    try {
        if (-not $Global:CmbUrlServer) { return 0 }
        $prev = ""
        try { if ($Global:CmbUrlServer.SelectedItem) { $prev = "$($Global:CmbUrlServer.SelectedItem)" } } catch {}
        $servers = @(Get-ExchangeServerList)
        $Global:CmbUrlServer.Items.Clear()
        foreach ($s in $servers) { [void]$Global:CmbUrlServer.Items.Add($s) }
        if ($Global:CmbUrlServer.Items.Count -gt 0) {
            $idx = 0
            $want = if ($prev) { $prev } else { "$env:COMPUTERNAME" }
            for ($i = 0; $i -lt $Global:CmbUrlServer.Items.Count; $i++) {
                if ("$($Global:CmbUrlServer.Items[$i])" -eq $want) { $idx = $i; break }
            }
            $Global:CmbUrlServer.SelectedIndex = $idx
        }
        return $Global:CmbUrlServer.Items.Count
    } catch { Write-Log ("Update server list error: " + $_) -Level ERROR; return 0 }
}

function Get-ExchangeUrlDefaultPath {
    <#
        Standardpfad des Virtual Directory je URL-Schluessel - genau das, was ein
        frisch installierter Exchange ohne eigene Anpassung verwendet.
        Beispiel: OWA -> /owa, Autodiscover -> /autodiscover/autodiscover.xml
    #>
    param([string]$Key)
    switch ("$Key") {
        "OWA"   { return "/owa" }
        "ECP"   { return "/ecp" }
        "EWS"   { return "/EWS/Exchange.asmx" }
        "AS"    { return "/Microsoft-Server-ActiveSync" }
        "PS"    { return "/PowerShell" }
        "AD"    { return "/autodiscover/autodiscover.xml" }
        "MAPI"  { return "/mapi" }
        "OAB"   { return "/oab" }
        default { return "" }
    }
}

function Test-UrlBaseDomain {
    <#
        Prueft, ob eine Eingabe als Basis-Domain nutzbar ist.
        "mail.test.de", "https://mail.test.de", "mail.test.de:443" sind gueltig,
        "mail" oder "" nicht - sonst entstehen URLs ohne gueltigen FQDN.
    #>
    param([string]$Base)
    $b = "$Base".Trim()
    if (-not $b) { return $false }
    $b = ($b -replace '^[a-zA-Z][a-zA-Z0-9+.\-]*://','')   # Scheme entfernen
    $b = ($b -split '/')[0]                                 # angegebenen Pfad verwerfen
    return ($b -match '^[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)+(:\d+)?$')
}

function ConvertTo-ExchangeUrl {
    <#
        Baut aus Basis + Standardpfad die vollstaendige URL.
        Ohne angegebenes Schema wird https:// verwendet; der Host-Teil wird
        isoliert, damit die Basis "nur die Domain" bleibt (mail.test.de/owa
        wuerde sonst zu mail.test.de/owa/owa verdoppelt).
    #>
    param([string]$Base, [string]$Path)
    $b = "$Base".Trim().TrimEnd('/')
    if (-not $b) { return "" }
    if ($b -notmatch '^[a-zA-Z][a-zA-Z0-9+.\-]*://') { $b = "https://" + $b }
    if ($b -match '^(?<scheme>https?://)(?<host>[^/]+)') { $b = $matches['scheme'] + $matches['host'] }
    $p = "$Path"
    if ($p -and (-not $p.StartsWith('/'))) { $p = '/' + $p }
    return ($b + $p)
}

function Get-AutodiscoverHost {
    <#
        Leitet den SCP-Host aus der URL-Basis ab: "autodiscover.<Domain>"
        wie in der Microsoft-Dokumentation (Set-ClientAccessService
        -AutoDiscoverServiceInternalUri) und wie der externe Outlook-Probe
        es erwartet - nicht den URL-Basis-Host (mail.test.de/... erreicht
        nur domain-beigetretenene Clients via SCP, extern probiert Outlook
        zunaechst hartcoded autodiscover.<smtp-domain>).
        Fuehrendes Dienst-Label (mail, www, webmail, email, smtp, exchange,
        owa, mx) wird durch "autodiscover." ersetzt (mail.test.de ->
        autodiscover.test.de), sonst praefigiert (test.de ->
        autodiscover.test.de); "autodiscover.test.de" bleibt unveraendert.
        Scheme und Pfad werden verworfen (wie Test-UrlBaseDomain), ein
        Port bleibt erhalten.
    #>
    param([string]$Base)
    $b = "$Base".Trim()
    if (-not $b) { return "" }
    $b = ($b -replace '^[a-zA-Z][a-zA-Z0-9+.\-]*://','')   # Scheme entfernen
    $b = ($b -split '/')[0]                                 # angegebenen Pfad verwerfen
    if ($b -notmatch '^(?<first>[^.]+)\.(?<rest>.+)$') { return "autodiscover.$b" }
    $first = $matches['first'].ToLower()
    if ($first -eq 'autodiscover') { return $b }
    if (@('mail','www','webmail','email','smtp','exchange','owa','mx') -contains $first) {
        return ("autodiscover." + $matches['rest'])
    }
    return ("autodiscover." + $b)
}

function Set-UrlHostExtMirror {
    <#
        Spiegelt die externe Basis-Domain auf die interne (gesperrtes Feld)
        oder gibt sie wieder zum freien Editieren frei.
    #>
    param([bool]$Mirror)
    if (-not $Global:TxtUrlHostExt) { return }
    $Global:TxtUrlHostExt.ReadOnly = $Mirror
    $Global:TxtUrlHostExt.BackColor = if ($Mirror) { $Global:ColorPanelAlt } else { $Global:ColorInputBg }
    if ($Mirror -and $Global:TxtUrlHostInt) { $Global:TxtUrlHostExt.Text = "$($Global:TxtUrlHostInt.Text)" }
}

function Get-UrlFieldValue {
    <#
        Liest einen Wert aus der Dienst-Tabelle (URL-Tab).
        Autodiscover hat nur EIN Feld (SCP-URI) - dort ist External=$null.
        Diese Funktion darf nie auf ein nicht vorhandenes Control treffen,
        sonst wirft Speichern/Anwenden eine Exception.
    #>
    param([Parameter(Mandatory)][string]$Key, [ValidateSet("Internal","External")][string]$Side = "Internal")
    try {
        $f = $Global:UrlFields[$Key].$Side
        if ($f) { return "$($f.Text)".Trim() }
    } catch {}
    return ""
}
function Set-UrlFieldValue {
    <#
        Schreibt einen Wert in die Dienst-Tabelle; fehlt das Feld
        (z. B. externe Autodiscover-Spalte), wird still uebersprungen.
    #>
    param([Parameter(Mandatory)][string]$Key, [ValidateSet("Internal","External")][string]$Side = "Internal",
          [AllowEmptyString()][string]$Value = "")
    try {
        $f = $Global:UrlFields[$Key].$Side
        if ($f) { $f.Text = $Value }
    } catch {}
}

function Update-UrlFieldsFromDomain {
    <#
        Fuellt alle anwendbaren Dienste (intern/extern) aus den Basis-Domains und den
        Exchange-Standardpfaden. PowerShell bleibt unangetastet (Setup-Standard).
        Leere externe Basis laesst die externe Spalte
        unangetastet - vorhandene, manuell getrennte URLs bleiben dann erhalten.
    #>
    $hi = ""; $he = ""
    try { $hi = "$($Global:TxtUrlHostInt.Text)".Trim() } catch {}
    $same = $false
    try { $same = [bool]$Global:ChkUrlSameHost.Checked } catch {}
    if ($same) { $he = $hi }
    else { try { $he = "$($Global:TxtUrlHostExt.Text)".Trim() } catch { $he = "" } }

    if (-not $hi -and -not $he) { return [PSCustomObject]@{ Built=0; Error=(Get-T "URL_HostEmpty") } }
    if ($hi -and (-not (Test-UrlBaseDomain $hi))) { return [PSCustomObject]@{ Built=0; Error=(Get-T "URL_HostEmpty") } }
    if ($he -and (-not (Test-UrlBaseDomain $he))) { return [PSCustomObject]@{ Built=0; Error=(Get-T "URL_HostEmpty") } }

    $built = 0
    foreach ($k in @($Global:UrlFields.Keys)) {
        # PowerShell-VD bleibt Setup-Standard - weder gebaut noch gesetzt
        if ($k -eq "PS") { continue }
        $path = Get-ExchangeUrlDefaultPath -Key $k
        if ($hi) {
            # SCP (Autodiscover): Host autodiscover.<Domain> ableiten statt den
            # URL-Basis-Host - entspricht der Microsoft-Doku, dem externen
            # Outlook-Probe und der SAN-Vorlage (Get-DefaultSanNames)
            $base = if ($k -eq "AD") { Get-AutodiscoverHost -Base $hi } else { $hi }
            Set-UrlFieldValue -Key $k -Side Internal -Value (ConvertTo-ExchangeUrl -Base $base -Path $path); $built++
        }
        # Autodiscover hat nur ein Feld (SCP-URI) - dort wird nichts extern gebaut
        if ($he -and $Global:UrlFields[$k].External) { Set-UrlFieldValue -Key $k -Side External -Value (ConvertTo-ExchangeUrl -Base $he -Path $path); $built++ }
    }
    return [PSCustomObject]@{ Built=$built; Error="" }
}

function Get-ExchangeUrlConfiguration {
    <#
        Liest die komplette URL-Konfiguration eines bestehenden Exchange-Servers aus.
        Das Ergebnis dient als Vorbelegung fuer die Uebernahme auf einen neuen Server.
        $Server: welcher Exchange-Server gelesen wird (leer = erster Treffer/lokal).
        Autodiscover/SCP hat Vorrang vor der VD-InternalUrl (SCP ist was Outlook nutzt).
    #>
    param([string]$Server)
    $types = @("OWA","ECP","EWS","AS","PS","AD","MAPI","OAB")
    # ACHTUNG: bewusst Hashtable (kein PSCustomObject) - unten wird per
    # String-Index $result[$t] zugegriffen, was auf PSCustomObject $null liefert
    # und beim Setzen "Eigenschaft 'Internal' nicht gefunden" wirft.
    $result = @{
        Found=$false; Server=""; OrganizationName=""; ExchangeVersion=""
        OWA=@{Internal="";External=""}; ECP=@{Internal="";External=""}
        EWS=@{Internal="";External=""}; AS=@{Internal="";External=""}
        PS=@{Internal="";External=""}; AD=@{Internal="";External=""}
        MAPI=@{Internal="";External=""}; OAB=@{Internal="";External=""}
        RCP=@{Internal="";External=""}
        FoundCount=0
    }
    try {
        if (-not (Import-ExchangeManagementShell)) { return $result }

        $result.Server = if ($Server) { $Server } else { "$env:COMPUTERNAME" }
        try {
            $svc = Get-Service -Name "MSExchangeADTopology" -ErrorAction SilentlyContinue
            if ($svc) { $result.ExchangeVersion = "Exchange installed (V15)" }
        } catch {}
        try {
            $schema = Get-ExchangeSchemaInfo
            if ($schema.ExchangeOrgName -and $schema.ExchangeOrgName -ne "(not yet installed)") {
                $result.OrganizationName = $schema.ExchangeOrgName
            }
        } catch {}

        $count = 0
        foreach ($t in $types) {
            $vd = Get-ExchangeVirtualDirectory -Type $t -Server $Server
            if (-not $vd) { continue }
            $i = ""; $e = ""
            try { if ($vd.PSObject.Properties['InternalUrl']) { $i = "$($vd.InternalUrl)" } } catch {}
            try { if ($vd.PSObject.Properties['ExternalUrl']) { $e = "$($vd.ExternalUrl)" } } catch {}
            $result[$t].Internal = $i.TrimEnd('/')
            $result[$t].External = $e.TrimEnd('/')
            if ($i -or $e) { $count++ }
        }

        # Autodiscover/SCP gezielt (pro Server) - SCP ist die Quelle, die Outlook per AD bezieht
        $adWasEmpty = (-not $result.AD.Internal -and -not $result.AD.External)
        try {
            $scp = Get-ExchangeAutodiscoverScp -Server $Server
            if ($scp.Internal -and (-not $result.AD.Internal -or ($scp.Source -like "SCP*"))) {
                $result.AD.Internal = $scp.Internal
            }
            if ($scp.External -and -not $result.AD.External) { $result.AD.External = $scp.External }
            if ($result.AD.Internal -or $result.AD.External) {
                if ($scp.Source) { Write-Log ("  AD : SCP source='" + $scp.Source + "' internal='" + $result.AD.Internal + "' external='" + $result.AD.External + "'") -Level INFO }
                if ($adWasEmpty) { $count++ }
            }
        } catch {}

        $result.FoundCount = $count
        $result.Found = ($count -gt 0)
        return $result
    }
    catch { Write-Log ("URL read error: " + $_) -Level ERROR; return $result }
}

function Set-ExchangeUrlConfiguration {
    <#
        Schreibt die uebernommenen URLs auf den lokalen Exchange-Server.
        Leere Felder werden uebersprungen, damit bestehende Werte erhalten bleiben.
    #>
    param([Parameter(Mandatory)]$Config)
    try {
        if (-not (Import-ExchangeManagementShell)) { return $false }
        $ok = 0; $skip = 0; $err = 0

        # Reihenfolge ist bewusst fest: erst Web-, dann Client-Zugriffsdienste
        $setters = @(
            @{ Type="OWA";  Cmd="Set-OwaVirtualDirectory" }
            , @{ Type="ECP";  Cmd="Set-EcpVirtualDirectory" }
            , @{ Type="EWS";  Cmd="Set-WebServicesVirtualDirectory" }
            , @{ Type="AS";   Cmd="Set-ActiveSyncVirtualDirectory" }
            , @{ Type="PS";   Cmd="Set-PowerShellVirtualDirectory" }
            , @{ Type="AD";   Cmd="Set-AutodiscoverVirtualDirectory" }
            , @{ Type="MAPI"; Cmd="Set-MapiVirtualDirectory" }
            , @{ Type="OAB";  Cmd="Set-OabVirtualDirectory" }
        )

        # URL-Host ermitteln ("" = keine absolute URL mit Host).
        # Verschachtelt, damit die AST-Extraktion der Tests beide mitliefert.
        function Get-UrlHostName {
            param([string]$Url)
            $u = $null
            try {
                if ([Uri]::TryCreate("$Url", [UriKind]::Absolute, [ref]$u) -and $u -and $u.Host) { return "$($u.Host)" }
            } catch {}
            return ""
        }
        # Eine einzelne URL-Seite (Internal/External) gegen DNS pruefen.
        # $false mit ERROR-Log = diese Seite wird NICHT gesetzt, weil sonst
        # Exchange interaktiv nachfragt (siehe Aufrufer).
        function Test-UrlSideResolvable {
            param([string]$Type, [string]$Side, [string]$Url)
            $h = Get-UrlHostName $Url
            if (-not $h) {
                Write-Log ("  $Type : host of " + $Side + " URL '" + $Url + "' cannot be determined / Host der " + $Side + "-URL nicht ermittelbar - " + $Side + " URL NOT set / nicht gesetzt (invalid URL / ungueltige URL)") -Level ERROR
                return $false
            }
            if (-not (Test-HostResolvable -HostName $h)) {
                Write-Log ("  $Type : host '" + $h + "' (" + $Side + " URL) cannot be resolved in DNS / Host '" + $h + "' (" + $Side + "-URL) ist in DNS nicht aufloesbar - URL NOT set / URL nicht gesetzt: create DNS A record '" + $h + "' pointing to this Exchange server and repeat the URL step / A-Eintrag '" + $h + "' auf diesen Exchange-Server anlegen und den URL-Schritt wiederholen (otherwise Exchange asks interactively and blocks the tool / sonst fragt Exchange interaktiv nach und blockiert das Tool)") -Level ERROR
                return $false
            }
            return $true
        }

        foreach ($s in $setters) {
            $t   = $s.Type
            $cmd = $s.Cmd
            # PowerShell-VD wird nie angefasst - bleibt wie vom Setup angelegt
            if ($t -eq "PS") { $skip++; Write-Log ("  PS : left at Exchange setup default - not changed") -Level INFO; continue }
            $entry = $Config.$t
            if (-not $entry) { continue }
            $i = "$($entry.Internal)"; $e = "$($entry.External)"
            if (-not $i -and -not $e) { $skip++; continue }

            $existing = Get-ExchangeVirtualDirectory -Type $t
            if (-not $existing) { $skip++; Write-Log ("  $t : virtual directory not found - skipped") -Level WARNING; continue }

            # Nur setzen, wenn sich etwas aendert
            $curI = ""; $curE = ""
            try { if ($existing.PSObject.Properties['InternalUrl']) { $curI = "$($existing.InternalUrl)".TrimEnd('/') } } catch {}
            try { if ($existing.PSObject.Properties['ExternalUrl']) { $curE = "$($existing.ExternalUrl)".TrimEnd('/') } } catch {}
            if (($i -eq $curI) -and ($e -eq $curE)) { $skip++; continue }

            # -Identity ist bei ALLEN Set-*VirtualDirectory-Cmdlets PFLICHT.
            # Wird es nicht uebergeben, fragt PowerShell interaktiv nach
            # ("Geben Sie Werte fuer die folgenden Parameter an: Identity:")
            # und die Ausfuehrung haengt in der Konsole. Der Wert kommt direkt
            # vom geholten VD-Objekt (Format: SERVER\owa (Default Web Site)).
            $idn = ""
            try { if ($existing.PSObject.Properties['Identity']) { $idn = "$($existing.Identity)".Trim() } } catch {}
            if (-not $idn) {
                $nm = ""
                try { $nm = "$($existing.Name)".Trim() } catch {}
                if ($nm) { $idn = "$env:COMPUTERNAME\$nm" }
            }
            if (-not $idn) {
                $err++
                Write-Log ("  $t : virtual directory has no identity - skipped (avoids interactive prompt)") -Level ERROR
                continue
            }

            # Capability-Pruefung: Nicht jede Exchange-Version kennt jeden URL-Parameter.
            # InternalUrl/ExternalUrl an Set-AutodiscoverVirtualDirectory gibt es NUR in
            # Exchange 2010 - ab 2013 (2016/2019/SE) meldet das Cmdlet:
            #   "Es wurde kein Parameter gefunden, der dem Parameternamen 'InternalUrl' entspricht."
            # Dort wird die Autodiscover-URL ausschliesslich ueber den SCP gesetzt (unten).
            $cmdParams = $null
            try { $cmdParams = (@(Get-Command -Name $cmd -ErrorAction Stop) | Select-Object -First 1).Parameters } catch {}
            $canI = (-not $cmdParams) -or $cmdParams.ContainsKey('InternalUrl')
            $canE = (-not $cmdParams) -or $cmdParams.ContainsKey('ExternalUrl')
            if (-not $canI -and -not $canE) {
                $skip++
                $why = if ($t -eq "AD") { "autodiscover URL is set via the SCP step below" } else { "no URL can be written by this cmdlet" }
                Write-Log ("  $t : '" + $cmd + "' has no InternalUrl/ExternalUrl parameter in this Exchange version - skipped (" + $why + ")") -Level INFO
                continue
            }

            # Was technisch gesetzt werden koennte (Parameter vorhanden)?
            $setI = ""; $setE = ""
            if ($i -and $canI) { $setI = $i }
            if ($e -and $canE) { $setE = $e }
            if (($i -or $e) -and (-not $setI -and -not $setE)) {
                $skip++
                Write-Log ("  $t : requested URL parameter not supported by '" + $cmd + "' - skipped") -Level WARNING
                continue
            }

            # DNS-Vorabpruefung: Einen nicht aufloesbaren Host zu setzen, bringt
            # Exchange zu einer interaktiven Rueckfrage ("Der fuer den Parameter
            # ... Host kann nicht aufgeloest werden. Mochten Sie den Vorgang
            # wirklich fortsetzen? [J] Ja [A] Ja, alle ..."). Das ist ein
            # ShouldContinue-Prompt, den -Confirm:$false NICHT abschaltet - im
            # GUI-Workflow wartet die Konsole auf Tastatureingabe, waehrend das
            # Fenster eingefroren bleibt (beobachtet: 4,5 h Hngen bei den URLs,
            # weil niemand an der Konsole sass). Also nicht fragen: betroffene
            # Seite weglassen und den DNS-Fehler mit Loesungshinweis melden.
            if ($setI -and -not (Test-UrlSideResolvable -Type $t -Side "Internal" -Url $setI)) { $setI = ""; $err++ }
            if ($setE -and -not (Test-UrlSideResolvable -Type $t -Side "External" -Url $setE)) { $setE = ""; $err++ }
            if (-not $setI -and -not $setE) { continue }

            try {
                $setParams = @{ Identity = $idn }
                if ($setI) { $setParams['InternalUrl'] = $setI }
                if ($setE) { $setParams['ExternalUrl'] = $setE }
                & $cmd @setParams -Confirm:$false -ErrorAction Stop
                $ok++
                Write-Log ("  $t : Identity='" + $idn + "' internal='" + $setI + "' external='" + $setE + "'") -Level SUCCESS
            } catch {
                $err++
                Write-Log ("  $t : " + $_.Exception.Message) -Level ERROR
            }
        }

        # Autodiscover-SCP mitsetzen: Das SCP-Objekt (AutoDiscoverServiceInternalUri)
        # ist die Quelle, die Outlook per AD zieht - die VD-Url allein wirkt dort nicht.
        $adEntry = $Config.AD
        $adInt = ""
        try { if ($adEntry) { $adInt = "$($adEntry.Internal)".Trim().TrimEnd('/') } } catch {}
        if ($adInt) {
            # Gleiche DNS-Vorabpruefung wie oben: auch Set-ClientAccessService
            # kann bei einem nicht aufloesbaren SCP-Host interaktiv nachfragen -
            # und selbst ohne Prompt waere die URL ohne DNS-Eintrag fuer Outlook
            # ohnehin unbrauchbar. Also vorher pruefen statt blockieren.
            $scpHost = Get-UrlHostName $adInt
            if (-not $scpHost) {
                $err++
                Write-Log ("  SCP : host of '" + $adInt + "' cannot be determined / Host nicht ermittelbar - SCP NOT set / SCP nicht gesetzt (invalid URL / ungueltige URL)") -Level ERROR
            } elseif (-not (Test-HostResolvable -HostName $scpHost)) {
                $err++
                Write-Log ("  SCP : host '" + $scpHost + "' cannot be resolved in DNS / Host '" + $scpHost + "' ist in DNS nicht aufloesbar - SCP NOT set / SCP nicht gesetzt: create DNS A record '" + $scpHost + "' pointing to this Exchange server / A-Eintrag '" + $scpHost + "' auf diesen Exchange-Server anlegen (Outlook/Autodiscover braucht diesen Namen / Outlook/Autodiscover benoetigt diesen Namen) and repeat the URL step / und den URL-Schritt wiederholen") -Level ERROR
            } else {
                try {
                    Set-ClientAccessService -Identity $env:COMPUTERNAME -AutoDiscoverServiceInternalUri $adInt -Confirm:$false -ErrorAction Stop
                    $ok++
                    Write-Log ("  SCP : AutoDiscoverServiceInternalUri='" + $adInt + "'") -Level SUCCESS
                } catch {
                    $err++
                    Write-Log ("  SCP : " + $_.Exception.Message) -Level ERROR
                }
            }
        }

        Write-Log ("URLs applied - changed: $ok, unchanged: $skip, errors: $err") -Level $(if ($err -eq 0) { "SUCCESS" } else { "WARNING" })
        return ($err -eq 0)
    }
    catch { Write-Log ("URL apply error: " + $_) -Level ERROR; return $false }
}

function Get-ExchangeCertificateStatus {
    $r = [PSCustomObject]@{ Found=$false; Subject=""; Thumbprint=""; NotAfter=""; DaysLeft=0; Services=""; IsValid=$false }
    try {
        if (-not (Import-ExchangeManagementShell)) { return $r }
        $certs = @(Get-ExchangeCertificate -ErrorAction SilentlyContinue)
        if ($certs.Count -eq 0) { return $r }
        # Bevorzugt ein Zertifikat mit IIS/SMTP-Diensten (OWA/ECP/MAPI)
        $c = $certs | Where-Object { $_.Services -and ("$($_.Services)" -match "IIS|SMTP|IMAP|POP") } | Select-Object -First 1
        if (-not $c) { $c = $certs | Select-Object -First 1 }
        if (-not $c) { return $r }
        $r.Found = $true
        $r.Subject = "$($c.Subject)"
        $r.Thumbprint = "$($c.Thumbprint)"
        if ($c.NotAfter) {
            $r.NotAfter = (Get-Date $c.NotAfter).ToString("yyyy-MM-dd")
            $days = ((Get-Date $c.NotAfter) - (Get-Date)).TotalDays
            $r.DaysLeft = [int]$days
            $r.IsValid = ($days -gt 0)
        }
        $r.Services = "$($c.Services)"
        return $r
    } catch { return $r }
}

# ------------------------------------------------------------
#  Zertifikat: Import oder selbstsigniert (mit mehreren SANs)
# ------------------------------------------------------------
function Show-CertificateImportDialog {
    <#
        Oeffnet einen Import-Dialog fuer ein bestehendes Zertifikat (PFX/PKCS#12).
        Liefert bei Erfolg ein Objekt mit Pfad, Kennwort und Ziel-Store zurueck.
    #>
    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = "Exchange Zertifikat importieren / Import Exchange certificate"
    $dlg.StartPosition = "CenterParent"
    $dlg.FormBorderStyle = "FixedDialog"
    $dlg.MaximizeBox = $false; $dlg.MinimizeBox = $false
    $dlg.Size = New-Object System.Drawing.Size(620,300)
    $dlg.BackColor = $Global:ColorBackground
    $dlg.Font = $Global:FontDefault
    $dlg.TopMost = $true

    $lblFile = New-Label "Zertifikatsdatei (PFX / PKCS#12):" 15 22 590
    $dlg.Controls.Add($lblFile)
    $txtFile = New-TextBox 15 46 590
    $dlg.Controls.Add($txtFile)
    $btnBrowse = New-Button (Get-T "Cert_Browse") 500 44 105 26 $Global:ColorAccent
    $btnBrowse.Add_Click({
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Title = "Zertifikat auswaehlen / Select certificate"
        $ofd.Filter = "PKCS#12 (*.pfx;*.p12)|*.pfx;*.p12|PFX (*.pfx)|*.pfx|All files (*.*)|*.*"
        if ($ofd.ShowDialog() -eq "OK") { $txtFile.Text = $ofd.FileName }
    })
    $dlg.Controls.Add($btnBrowse)

    $lblPass = New-Label "Kennwort (leer lassen, falls keines):" 15 80 590
    $dlg.Controls.Add($lblPass)
    $txtPass = New-Object System.Windows.Forms.TextBox
    $txtPass.Location = New-Object System.Drawing.Point(15,104)
    $txtPass.Size = New-Object System.Drawing.Size(590,24)
    $txtPass.UseSystemPasswordChar = $true
    $txtPass.BackColor = $Global:ColorInputBg; $txtPass.ForeColor = $Global:ColorText
    $txtPass.BorderStyle = "FixedSingle"; $txtPass.Font = $Global:FontDefault
    $dlg.Controls.Add($txtPass)

    $chkSvcIIS  = New-CheckBox "IIS (OWA/ECP/MAPI/Autodiscover)" 15 140 290 $true
    $chkSvcSMTP = New-CheckBox "SMTP" 15 166 290 $true
    $chkSvcIMAP = New-CheckBox "IMAP" 310 140 290 $false
    $chkSvcPOP  = New-CheckBox "POP" 310 166 290 $false
    $dlg.Controls.Add($chkSvcIIS); $dlg.Controls.Add($chkSvcSMTP)
    $dlg.Controls.Add($chkSvcIMAP); $dlg.Controls.Add($chkSvcPOP)

    $lblInfo = New-Label "Das Zertifikat wird in den Exchange-Zertifikatsspeicher importiert und fuer die gewaehlten Dienste aktiviert." 15 196 590
    $lblInfo.ForeColor = $Global:ColorTextDim
    $lblInfo.Size = New-Object System.Drawing.Size(590,32)
    $dlg.Controls.Add($lblInfo)

    $btnOk = New-Button (Get-T "OK") 400 240 95 34 $Global:ColorAccent2
    $btnCancel = New-Button (Get-T "Cancel") 505 240 95 34 $Global:ColorWarning
    $btnCancel.Add_Click({ $dlg.Tag = "Cancel"; $dlg.Close() })
    $btnOk.Add_Click({ $dlg.Tag = "OK"; $dlg.Close() })
    $dlg.Controls.Add($btnOk); $dlg.Controls.Add($btnCancel)
    $dlg.AcceptButton = $btnOk
    $dlg.CancelButton = $btnCancel

    $result = $null
    $dlg.Add_Shown({
        try { $dlg.Activate() } catch {}
    })
    [void]$dlg.ShowDialog()
    if ($dlg.Tag -eq "OK" -and $txtFile.Text) {
        $svc = @()
        if ($chkSvcIIS.Checked)  { $svc += "IIS" }
        if ($chkSvcSMTP.Checked) { $svc += "SMTP" }
        if ($chkSvcIMAP.Checked) { $svc += "IMAP" }
        if ($chkSvcPOP.Checked)  { $svc += "POP" }
        $result = [PSCustomObject]@{ Path=$txtFile.Text; Password=$txtPass.Text; Services=$svc }
    }
    try { $dlg.Dispose() } catch {}
    return $result
}

function Import-ExchangeCertificateFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [string]$Password,
        [string[]]$Services=@("IIS")
    )
    try {
        if (-not (Test-Path $Path)) { Write-Log ("Certificate file not found: " + $Path) -Level ERROR; return $false }
        if (-not (Import-ExchangeManagementShell)) { return $false }

        $sec = $null
        if ($Password) { $sec = ConvertTo-SecureString -String $Password -AsPlainText -Force }
        $pfx = $null
        try { $pfx = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($Path, $sec, 'Exportable,MachineKeySet') } catch { $pfx = $null }
        if (-not $pfx) { Write-Log "PFX could not be read" -Level ERROR; return $false }

        $existing = @(Get-ExchangeCertificate -ErrorAction SilentlyContinue | Where-Object { $_.Thumbprint -eq $pfx.Thumbprint })
        if ($existing.Count -gt 0) {
            Write-Log ("Certificate already in the store (" + $pfx.Subject + ")") -Level INFO
        } else {
            Write-Log ("Importing certificate: " + $pfx.Subject) -Level INFO
            $importParams = @{ FilePath=$Path; ErrorAction="Stop" }
            if ($sec) { $importParams['Password'] = $sec }
            Import-ExchangeCertificate @importParams | Out-Null
            Write-Log "Certificate imported into the Exchange store" -Level SUCCESS
        }

        if ($Services -and $Services.Count -gt 0) {
            Write-Log ("Activating for services: " + ($Services -join ", ")) -Level INFO
            Enable-ExchangeCertificate -Thumbprint $pfx.Thumbprint -Services $Services -Confirm:$false -ErrorAction Stop | Out-Null
            Write-Log "Certificate activated" -Level SUCCESS
        }
        return $true
    }
    catch { Write-Log ("Certificate import error: " + $_) -Level ERROR; return $false }
}

function Get-LocalStoreCertificate {
    <#
        Holt das Zertifikat mit dem Thumbprint aus dem Maschinenspeicher
        (Store "My", "LocalMachine"). Der X509Certificate2-Konstruktor versteht
        den Cert:\-Provider nicht ("Das angegebene Pfadformat wird nicht
        unterstuetzt"), daher nie per Pfad laden, sondern ueber die Store-API.
        Eigene Funktion, damit Tests den Zugriff mocken koennen.
    #>
    param([Parameter(Mandatory)][string]$Thumbprint)
    try {
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("My","LocalMachine")
        $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly)
        try {
            $found = $store.Certificates.Find(
                [System.Security.Cryptography.X509Certificates.X509FindType]::FindByThumbprint,
                $Thumbprint, $false)
            if ($found.Count -gt 0) { return $found[0] }
        } finally { $store.Close() }
    } catch {}
    return $null
}

function Add-LocalStoreCertificate {
    <#
        Legt ein Zertifikat in den angegebenen Maschinenspeicher (z.B. Root fuer
        lokales Vertrauen). Store-API statt Export-Certificate: das Cmdlet kennt
        keinen CertStoreLocation-Parameter (es exportiert nur in eine Datei) und
        Import-Certificate muesste zusaetzlich ueber eine Temporaerdatei laufen.
        Benoetigt Administratorrechte; Fehler werden vom Aufrufer geloggt.
    #>
    param(
        [Parameter(Mandatory)]$Certificate,
        [string]$StoreName="Root"
    )
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($StoreName,"LocalMachine")
    $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    try { $store.Add($Certificate) } finally { $store.Close() }
}

function Publish-SelfSignedCertificateToExchange {
    <#
        Uebernimmt ein selbstsigniertes Windows-Zertifikat in den Exchange-Zertifikatsspeicher
        und aktiviert es fuer die gewaehlten Dienste. Der PFX-Roundtrip laeuft ueber eine
        temporaere Datei, die anschliessend wieder geloescht wird.
    #>
    param(
        [Parameter(Mandatory)]$Certificate,
        [string[]]$Services=@("IIS","SMTP"),
        [string]$Password=""
    )
    $tmpPfx = $null
    try {
        if (-not $Certificate -or -not $Certificate.Thumbprint) { return $false }
        if (-not (Import-ExchangeManagementShell)) { return $false }

        # NICHT den X509Certificate2-Konstruktor mit "Cert:\..."-Pfad fuellen -
        # der erwartet eine echte Datei und endete mit "Das angegebene Pfadformat
        # wird nicht unterstuetzt". Stattdessen das uebergebene Objekt nutzen
        # (kommt direkt von New-SelfSignedCertificate, inkl. privatem Schluessel)
        # oder das Zertifikat per Thumbprint aus dem Maschinenspeicher holen.
        $x509 = $Certificate -as [System.Security.Cryptography.X509Certificates.X509Certificate2]
        if (-not $x509) { $x509 = Get-LocalStoreCertificate -Thumbprint ("$($Certificate.Thumbprint)") }
        if (-not $x509) {
            Write-Log ("Certificate not found in the local machine store: " + $Certificate.Thumbprint) -Level ERROR
            return $false
        }

        # Selbstsignierte Zertifikate zusaetzlich in den Wurzelzertifikatsspeicher legen,
        # sonst melden Clients (Browser, OWA) weiterhin einen Zertifikatsfehler.
        # Kein Export-Certificate - das Cmdlet hat keinen CertStoreLocation-
        # Parameter ("kein Parameter, der dem Parameternamen entspricht"),
        # daher die Store-API ueber Add-LocalStoreCertificate.
        try {
            $trusted = @(Get-ChildItem ("Cert:\LocalMachine\Root\" + $Certificate.Thumbprint) -ErrorAction SilentlyContinue)
            if ($trusted.Count -eq 0) {
                Add-LocalStoreCertificate -Certificate $x509 -StoreName "Root"
                Write-Log "Self-signed certificate added to the local trusted root store" -Level SUCCESS
            }
        } catch { Write-Log ("Could not add to root store: " + $_.Exception.Message) -Level WARNING }

        if (-not $Services -or $Services.Count -eq 0) { return $true }

        # Der PFX-Export verlangt zwingend ein nicht leeres Kennwort
        $pfxPass = $Password
        if (-not $pfxPass) { $pfxPass = [Guid]::NewGuid().ToString("N") }

        $tmpPfx = Join-Path $env:TEMP ("exchcert_" + $Certificate.Thumbprint + ".pfx")
        $pfxBytes = $x509.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx, $pfxPass)
        [System.IO.File]::WriteAllBytes($tmpPfx, $pfxBytes)
        return (Import-ExchangeCertificateFile -Path $tmpPfx -Password $pfxPass -Services $Services)
    }
    catch { Write-Log ("Certificate publish error: " + $_) -Level ERROR; return $false }
    finally { if ($tmpPfx -and (Test-Path $tmpPfx)) { Remove-Item $tmpPfx -Force -ErrorAction SilentlyContinue } }
}

function New-ExchangeSelfSignedCertificate {
    <#
        Erzeugt ein selbstsigniertes Zertifikat im Windows-Zertifikatsspeicher.
        Alle SAN-Namen werden als DnsNameList uebergeben (Exchange 2016+/SE unterstuetzt
        Subject Alternative Names; ab Exchange 2019 CU13 zwingend).
    #>
    param(
        [Parameter(Mandatory)][string[]]$DnsName,
        [string]$FriendlyName="Exchange SelfSigned",
        [int]$ValidDays=1095,
        [int]$KeySize=2048,
        [string]$Subject=""
    )
    try {
        $sans = @($DnsName | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        if ($sans.Count -eq 0) { Write-Log "No SAN names given" -Level ERROR; return $null }
        Write-Log ("SAN names (" + $sans.Count + "): " + ($sans -join ", ")) -Level INFO

        if (-not $Subject) { $Subject = "CN=" + $sans[0] }
        Write-Log ("Subject: " + $Subject + " | " + $KeySize.ToString() + " bit | " + $ValidDays + " Tage") -Level INFO

        $usage = @("DigitalSignature","KeyEncipherment")
        $eku   = "1.3.6.1.5.5.7.3.1"   # serverAuth
        $params = @{
            DnsName           = $sans
            Subject           = $Subject
            CertStoreLocation = "Cert:\LocalMachine\My"
            FriendlyName      = $FriendlyName
            KeyAlgorithm      = "RSA"
            KeyLength         = $KeySize
            KeyUsage          = $usage
            KeyExportPolicy   = "Exportable"
            NotAfter          = (Get-Date).AddDays($ValidDays)
            TextExtension     = @("2.5.29.37={text}$eku")
            HashAlgorithm     = "SHA256"
            ErrorAction       = "Stop"
        }
        $cert = New-SelfSignedCertificate @params
        if (-not $cert) { Write-Log "Certificate creation returned nothing" -Level ERROR; return $null }
        Write-Log ("Created self-signed certificate: " + $cert.Thumbprint) -Level SUCCESS
        Write-Log ("  Subject: " + $cert.Subject) -Level INFO
        Write-Log ("  Valid until: " + (Get-Date $cert.NotAfter).ToString("yyyy-MM-dd")) -Level INFO
        return $cert
    }
    catch { Write-Log ("Self-signed certificate error: " + $_) -Level ERROR; return $null }
}

function Get-EnterpriseCaConfig {
    <#
        Liest die erste verfuegbare Enterprise-CA aus dem AD-Konfigurationspartition
        (CN=Enrollment Services,CN=Public Key Services,CN=Services,<ConfigNC>) und
        liefert die certreq-Konfigurationskennung "dNSHostName\CAName" zurueck
        (Fallback: CAName allein) oder "" wenn keine CA gefunden wird.
    #>
    try {
        $root = [ADSI]"LDAP://RootDSE"
        $nc = "" + $root.configurationNamingContext
        if (-not $nc) { return "" }
        $enroll = [ADSI]("LDAP://CN=Enrollment Services,CN=Public Key Services,CN=Services," + $nc)
        foreach ($e in @($enroll.Children)) {
            $ca = ""; $dns = ""
            try { $ca = "" + $e.Properties["cn"][0] } catch {}
            try { $dns = "" + $e.Properties["dNSHostName"][0] } catch {}
            if (-not $ca) { continue }
            if ($dns) { return "$dns\$ca" }
            return $ca
        }
    } catch {}
    return ""
}

function Invoke-CertReq {
    <#
        Ruft certreq.exe auf (Einreichen/Accept) und liefert ExitCode und Ausgabe
        als Objekt zurueck. Eigene Funktion, damit Tests den Aufruf mocken koennen,
        ohne eine echte Binary zu benoetigen.
    #>
    param([Parameter(Mandatory)][string[]]$ArgumentList)
    $out = & certreq.exe @ArgumentList 2>&1
    [PSCustomObject]@{
        ExitCode = $LASTEXITCODE
        Output   = (($out | ForEach-Object { "$_" }) -join " ")
    }
}

function Test-HostResolvable {
    <#
        Prueft, ob ein Rechnername per DNS/hosts-Datei aufloesbar ist. Verhindert,
        dass certreq gegen eine falsche Adresse (z.B. die Domain statt des
        CA-Servers) laeuft und nur mit 0x800706BA "RPC-Server ist nicht
        verfuegbar" scheitert. Eigene Funktion, damit Tests den Zugriff mocken.
    #>
    param([Parameter(Mandatory)][string]$HostName)
    try { $null = [System.Net.Dns]::GetHostEntry($HostName); return $true } catch { return $false }
}

function New-ExchangeADCertificate {
    <#
        Echte Zertifikatsanfrage bei der AD-Zertifikatsstelle:
        1. CA ZUERST ermitteln und pruefen: AD-Suche oder -CAConfig, Format
           SERVER\CA-NAME (Rechner zuerst, nicht die Domain) und DNS-Aufloesbarkeit
        2. Falls in dieser Sitzung ein ausstehender Antrag gemerkt ist: per
           certreq -retrieve abrufen (nach Freigabe auf der CA) - solange er noch
           aussteht, wird KEINE Neuanfrage geschickt (kein Pending-Stapel);
           nur wenn keiner aussteht, wird neu beantragt:
           New-ExchangeCertificate -GenerateRequest erzeugt den PKCS#10-Antrag
           (SANs ueber -DomainName - es gibt KEIN -DNSName; -Force verhindert die
           interaktive SMTP-Rueckfrage, die in der GUI ein Haengen waere),
           Request als UTF-16-Datei schreiben (Exchange 2016+/SE hat kein
           -RequestFile) und per certreq -submit bei der CA einreichen
        3. certreq -accept paart den privaten Schluessel lokal
        4. Import-ExchangeCertificate + Enable-ExchangeCertificate fuer die Dienste
        -Template waehlt das CA-Template (Standard: WebServer). Eine wartende
        Standalone-CA meldet sich je nach CA-Sprache als "pending" oder
        "ausstehend" (Exit 0 ohne .cer) -> WARNING mit Antrags-ID, die in
        $Global:CertPendingReqId gemerkt wird. Keine CA, Fehlercode von certreq
        oder leere Rueckgabe -> $null mit Log-Grund; die Temporaerdateien werden
        immer entfernt.
    #>
    param(
        [Parameter(Mandatory)][string[]]$DnsName,
        [string]$FriendlyName="Exchange ADCS",
        [int]$KeySize=2048,
        [string[]]$Services=@("IIS","SMTP"),
        [string]$CAConfig="",
        [string]$Template="WebServer"
    )
    $reqFile = $null; $cerFile = $null
    try {
        $sans = @($DnsName | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        if ($sans.Count -eq 0) { Write-Log "No SAN names given" -Level ERROR; return $null }
        if (-not (Import-ExchangeManagementShell)) { return $null }
        if (-not "$Template".Trim()) { $Template = "WebServer" } else { $Template = "$Template".Trim() }

        # Subject/CN: bevorzugt die GUI-CN, wenn sie eine FQDN ist, sonst der erste SAN
        $cn = if ("$FriendlyName" -match '^[A-Za-z0-9][A-Za-z0-9\.\-]*\.[A-Za-z]{2,}$') { "$FriendlyName" } else { $sans[0] }
        $subject = "CN=$cn"

        # CA ZUERST ermitteln und pruefen - erst danach wird der Antrag erzeugt,
        # damit eine ungueltige CA-Angabe keine sinnlose Neuanfrage hinterlaesst
        if (-not "$CAConfig".Trim()) { $CAConfig = Get-EnterpriseCaConfig } else { $CAConfig = "$CAConfig".Trim() }
        if (-not $CAConfig) {
            Write-Log "No CA found in Active Directory (CN=Enrollment Services) - only enterprise CAs register there; enter a standalone CA manually as SERVER\CA-Name in the CA field (parameter -CAConfig) - certificate request aborted" -Level ERROR
            return $null
        }
        # Format SERVER\CA-NAME pruefen: der erste Teil ist der Rechnername des
        # CA-Servers (NICHT die Domain), der zweite Teil der CA-Name - sonst
        # waehlt certreq die Domain als Server und scheitert mit 0x800706BA
        # "RPC-Server ist nicht verfuegbar". Zusaetzlich Aufloesbarkeit testen.
        $caParts = $CAConfig -split '\\', 2
        if ($caParts.Count -ne 2 -or -not "$($caParts[0])".Trim() -or -not "$($caParts[1])".Trim()) {
            Write-Log ("CA entry must be SERVER\CA-NAME (first part: CA server computer name, not the domain; second part: CA name): '" + $CAConfig + "' - certificate request aborted") -Level ERROR
            return $null
        }
        $caHost = "$($caParts[0])".Trim()
        if (-not (Test-HostResolvable -HostName $caHost)) {
            Write-Log ("CA server '$caHost' cannot be resolved from this machine - check the name (format SERVER\CA-NAME: first part is the CA server's computer name, not the domain) and DNS - certificate request aborted") -Level ERROR
            return $null
        }

        # Ausstehenden Antrag aus dieser Sitzung zuerst abrufen: nach der Freigabe
        # auf der CA holt certreq -retrieve das Zertifikat hier ab - und solange
        # der Antrag noch aussteht, wird KEINE Neuanfrage geschickt (sonst
        # stapeln sich Pending-Antraege auf der Standalone-CA)
        $issued = $false
        if ($Global:CertPendingReqId) {
            $rid = "$Global:CertPendingReqId"
            $cerFile = Join-Path $env:TEMP ("exchtool_req_" + [guid]::NewGuid().ToString("N") + ".cer")
            Write-Log ("Retrieving earlier certificate request ID $rid from CA '$CAConfig'") -Level INFO
            $ret = Invoke-CertReq -ArgumentList @("-config",$CAConfig,"-retrieve",$rid,$cerFile)
            if ($ret.ExitCode -eq 0 -and (Test-Path $cerFile)) {
                Write-Log ("Certificate for request ID $rid was approved by the CA - using it (no new request)") -Level SUCCESS
                $Global:CertPendingReqId = $null
                $issued = $true
            } else {
                $retOut = "" + $ret.Output
                if (Test-Path $cerFile) { Remove-Item -LiteralPath $cerFile -Force -ErrorAction SilentlyContinue }
                $cerFile = $null
                if ($retOut -match '(?i)pending|ausstehend') {
                    Write-Log ("Certificate request ID $rid is still pending on the CA - approve it there (certsvc.msc -> Pending Requests -> Issue; German UI: Ausstehende Zertifikatanforderungen -> Freigeben) and run certificate creation again; no new request was sent. certreq said: " + $retOut) -Level WARNING
                    return $null
                }
                if ($retOut -match '(?i)nicht gefunden|not found|cannot be found|abgelehnt|denied') {
                    Write-Log ("Earlier certificate request ID $rid is no longer retrievable - sending a new request. certreq said: " + $retOut) -Level INFO
                    $Global:CertPendingReqId = $null
                } else {
                    Write-Log ('Could not retrieve certificate request ID {0} (certreq exit 0x{1:X8}) - no new request was sent; test manually with: certreq -config "{2}" -retrieve {0} <out.cer>. certreq said: {3}' -f $rid, $ret.ExitCode, $CAConfig, $retOut) -Level WARNING
                    return $null
                }
            }
        }

        if (-not $issued) {
            Write-Log ("Creating certificate request: Subject=$subject | SANs: " + ($sans -join ", ")) -Level INFO
            $txt = New-ExchangeCertificate -GenerateRequest -SubjectName $subject -DomainName $sans `
                -FriendlyName $FriendlyName -KeySize $KeySize -PrivateKeyExportable $true -Force -ErrorAction Stop
            if ("$txt".Trim().Length -eq 0) { Write-Log "Certificate request is empty" -Level ERROR; return $null }
            $reqFile = Join-Path $env:TEMP ("exchtool_req_" + [guid]::NewGuid().ToString("N") + ".req")
            [System.IO.File]::WriteAllBytes($reqFile, [System.Text.Encoding]::Unicode.GetBytes("$txt"))
            Write-Log "Certificate request created (PKCS#10)" -Level INFO

            $cerFile = [System.IO.Path]::ChangeExtension($reqFile, ".cer")
            Write-Log ("Submitting request to CA '$CAConfig' (Template: $Template)") -Level INFO
            $sub = Invoke-CertReq -ArgumentList @("-submit","-config",$CAConfig,"-attrib","CertificateTemplate:$Template",$reqFile,$cerFile)
            if ($sub.ExitCode -ne 0 -or -not (Test-Path $cerFile)) {
                # Antrags-ID sowohl auf Englisch (RequestId) als auch auf Deutsch
                # (Anforderungs-ID) lesen - die certreq-Ausgabe ist lokalisiert
                $rid = ""
                if ("$($sub.Output)" -match '(?:Anforderungs-ID|RequestId)[^0-9]{0,10}(\d+)') { $rid = $Matches[1] }
                $denied  = "$($sub.Output)" -match '(?i)abgelehnt|denied'
                $pending = ("$($sub.Output)" -match '(?i)pending|ausstehend') -or ($sub.ExitCode -eq 0 -and $rid -ne "")
                if ($pending -and -not $denied) {
                    if ($rid) {
                        $Global:CertPendingReqId = $rid
                        Write-Log ("CA request is PENDING approval (request ID $rid) - standalone CAs wait for manager approval. Approve it on the CA (certsvc.msc -> Pending Requests -> Issue; German UI: Ausstehende Zertifikatanforderungen -> Freigeben) and run certificate creation again; the issued certificate is then fetched automatically. certreq said: " + $sub.Output) -Level WARNING
                    } else {
                        Write-Log ("CA request is PENDING approval (no request ID found in the certreq output) - approve it on the CA (certsvc.msc -> Pending Requests -> Issue; German UI: Ausstehende Zertifikatanforderungen -> Freigeben) and run certificate creation again. certreq said: " + $sub.Output) -Level WARNING
                    }
                    return $null
                }
                if ($denied) {
                    Write-Log ("CA request DENIED by the CA: " + $sub.Output) -Level ERROR
                } else {
                    Write-Log ("CA request failed (certreq exit 0x{0:X8}): {1}" -f $sub.ExitCode, $sub.Output) -Level ERROR
                }
                Write-Log ("CA config used: '" + $CAConfig + "' - correct format is SERVER\CA-NAME (CA server computer name first, CA name second)") -Level INFO
                return $null
            }
            Write-Log "Certificate issued by CA" -Level SUCCESS
        }

        # Privaten Schluessel lokal annehmen (paart den von Exchange erzeugten Keypair)
        $acc = Invoke-CertReq -ArgumentList @("-accept",$cerFile)
        if ($acc.ExitCode -ne 0) {
            Write-Log ("certreq -accept (private key pairing): " + $acc.Output) -Level WARNING
        }

        $bytes = [System.IO.File]::ReadAllBytes($cerFile)
        $imported = Import-ExchangeCertificate -FileData $bytes -ErrorAction Stop
        $cert = @($imported) | Where-Object { $_ } | Select-Object -First 1
        if (-not $cert) { Write-Log "Import-ExchangeCertificate returned nothing" -Level ERROR; return $null }
        $thumb = "" + $cert.Thumbprint

        if ($Services -and $Services.Count -gt 0) {
            if (-not $thumb) {
                Write-Log "Imported certificate has no thumbprint - services not activated" -Level WARNING
            } else {
                Enable-ExchangeCertificate -Thumbprint $thumb -Services $Services -Confirm:$false -ErrorAction Stop | Out-Null
                Write-Log ("Activated for: " + ($Services -join ", ")) -Level SUCCESS
            }
        }
        Write-Log ("Certificate issued: $thumb ($subject)") -Level SUCCESS
        return $cert
    }
    catch { Write-Log ("AD certificate error: " + $_) -Level ERROR; return $null }
    finally {
        foreach ($f in @($reqFile, $cerFile)) {
            if ($f -and (Test-Path -LiteralPath $f)) { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue }
        }
    }
}

function Get-DefaultSanNames {
    <#
        Leitet typische SAN-Namen aus der E-Mail-Domain der Organisation ab.
    #>
    $sans = @()
    try {
        $domain = ""
        if ($Global:TxtDomain -and $Global:TxtDomain.Text) { $domain = $Global:TxtDomain.Text.Trim() }
        if (-not $domain) { $domain = "$env:USERDNSDOMAIN" }
        if (-not $domain) { $domain = (Get-CimInstance Win32_ComputerSystem).Domain }
        if (-not $domain) { return $sans }

        $host = $env:COMPUTERNAME
        $base = if ($host -match '\.') { $host } else { "$host.$domain" }
        $sans = @(
            $base
            "mail.$domain"
            "owa.$domain"
            "ecp.$domain"
            "autodiscover.$domain"
            "oab.$domain"
            "mail.$domain"
            "sipfedautodiscover.$domain"
        ) | Sort-Object -Unique
    } catch {}
    return $sans
}

function Enable-ExchangeCertificateServices {
    param([string]$Thumbprint, [string[]]$Services=@("IIS"))
    try {
        if (-not (Import-ExchangeManagementShell)) { return $false }
        Enable-ExchangeCertificate -Thumbprint $Thumbprint -Services $Services -Confirm:$false -ErrorAction Stop | Out-Null
        Write-Log ("Certificate " + $Thumbprint + " activated for: " + ($Services -join ", ")) -Level SUCCESS
        return $true
    } catch { Write-Log ("Certificate activation error: " + $_) -Level ERROR; return $false }
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

#region ============================ RESPONSIVES LAYOUT ============================
function Update-ResponsiveLayout {
    <#
        Skaliert bei jeder Formulargroesse (z. B. Vollbild / maximiertes Fenster)
        alle Steuerelemente proportional zur Design-Groesse mit.
        Die Design-Geometrie wird beim ERSTEN Aufruf eingefroren; alle weiteren
        Aufrufe sind idempotent (kein Aufaddieren der Skalierungsfaktoren).
        Truncation statt Runden garantiert, dass keine Steuerelement-Ueberlappung
        entstehen kann (siehe Set-ResponsiveControlScale).
    #>
    try {
        if ($Global:ResizeDesignW -le 0 -or $Global:ResizeDesignH -le 0) { return }
        $cw = $Form.ClientSize.Width; $ch = $Form.ClientSize.Height
        if ($cw -le 0 -or $ch -le 0) { return }
        $sx = $cw / [double]$Global:ResizeDesignW
        $sy = $ch / [double]$Global:ResizeDesignH
        # KEIN Fruehabbruch bei Skala ~1.0: sonst blieben nach Maximieren->Wiederherstellen
        # (exakt auf Design-Groesse) die skalierten Steuerelemente zurueck.
        $Form.SuspendLayout()
        try {
            Set-ResponsiveControlScale -Container $Form -Sx $sx -Sy $sy
        } finally {
            $Form.ResumeLayout($true)
            $Form.PerformLayout()
        }
    } catch {}
}

function Set-ResponsiveControlScale {
    <#
        Skaliert Position, Groesse und Schrift aller Kind-Steuerelemente relativ zum
        Ursprung. Basis sind die beim ersten Aufruf eingefrorenen Design-Werte (.Tag),
        dadurch ist die Operation idempotent. Truncation ([int]-Cast) verhindert
        Ueberlappungen: fuer positive Faktoren gilt floor(x*f)+floor(y*f) <= floor((x+y)*f).
    #>
    param([System.Windows.Forms.Control]$Container, [double]$Sx, [double]$Sy)
    foreach ($c in $Container.Controls) {
        if ($c -is [System.Windows.Forms.TabPage]) {
            # Die TabPage-Geometrie verwaltet das TabControl - nur die Kinder skalieren
            Set-ResponsiveControlScale -Container $c -Sx $Sx -Sy $Sy
            continue
        }
        # Design-Werte einmalig pro Steuerelement einfrieren
        $d = $c.Tag
        if ($null -eq $d -or $d -isnot [System.Collections.IDictionary]) {
            $d = @{ X=[int]$c.Left; Y=[int]$c.Top; W=[int]$c.Width; H=[int]$c.Height; FS=[single]$c.Font.Size }
            try { $c.Tag = $d } catch {}
        }
        try {
            $c.Location = New-Object System.Drawing.Point([int]($d.X * $Sx), [int]($d.Y * $Sy))
            $c.Size     = New-Object System.Drawing.Size([int]($d.W * $Sx), [int]($d.H * $Sy))
        } catch {}
        if ($c -isnot [System.Windows.Forms.TabControl]) {
            # Schrift proportional mit skalieren (gedaempft, um Flackern beim Ziehen zu vermeiden).
            # TabControl bewusst ausgenommen - die Tab-Leiste soll kompakt bleiben.
            try {
                $fScale  = [Math]::Min($Sx, $Sy)
                $newSize = [Math]::Max(7.0, [Math]::Min(24.0, $d.FS * $fScale))
                if ([Math]::Abs($newSize - $c.Font.Size) -gt 1.5) {
                    $c.Font = New-Object System.Drawing.Font($c.Font.FontFamily, [single]$newSize, $c.Font.Style)
                }
            } catch {}
        }
        if ($c.HasChildren) { Set-ResponsiveControlScale -Container $c -Sx $Sx -Sy $Sy }
    }
}
#endregion

#region ============================ HAUPTFORMULAR ============================
Write-Host "@@DIAG@@ [4/7] Formular-Aufbau startet (Haengt-Verdacht: WMI-Abfrage unten in Zeile Dom-Feld)" -ForegroundColor DarkGray
$Form = New-Object System.Windows.Forms.Form
$Form.Text=(Get-T "AppTitle")
$Form.Size=New-Object System.Drawing.Size($Global:FormWidth,$Global:FormHeight)
$Form.StartPosition="CenterScreen"; $Form.BackColor=$Global:ColorBackground
$Form.ForeColor=$Global:ColorText; $Form.Font=$Global:FontDefault
$Form.FormBorderStyle="Sizable"; $Form.MinimizeBox=$true; $Form.MaximizeBox=$true
$Form.MinimumSize=New-Object System.Drawing.Size(900,600)

# Design-Proportionen einfrieren (ClientArea) - Basis fuer das responsive Layout
$Global:ResizeDesignW = $Form.ClientSize.Width
$Global:ResizeDesignH = $Form.ClientSize.Height

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
$LblSub.Location=New-Object System.Drawing.Point(730,24)
$LblSub.Size=New-Object System.Drawing.Size(180,20)
$LblSub.AutoEllipsis=$true
$LblSub.TextAlign="MiddleLeft"; $LblSub.BackColor=[System.Drawing.Color]::Transparent
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
$TabUrls     = New-Object System.Windows.Forms.TabPage; $TabUrls.Text=(Get-T "TabUrls")
$TabCert     = New-Object System.Windows.Forms.TabPage; $TabCert.Text=(Get-T "TabCert")
$TabRun      = New-Object System.Windows.Forms.TabPage; $TabRun.Text=(Get-T "TabRun")

foreach ($t in @($TabPrereq,$TabADPrep,$TabInstall,$TabSecurity,$TabAntiSpam,$TabDB,$TabDAG,$TabUrls,$TabCert,$TabRun)) {
    $t.BackColor=$Global:ColorBackground; $t.ForeColor=$Global:ColorText
}
$TabControl.TabPages.AddRange(@($TabPrereq,$TabADPrep,$TabInstall,$TabSecurity,$TabAntiSpam,$TabDB,$TabDAG,$TabUrls,$TabCert,$TabRun))
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

# NIC-Energiesparung (HealthChecker SleepyNICCheck) - eigene Karte rechts:
# Statuszeile + Direkt-Aktion, weil auf fertig installierten Servern nur
# dieser eine Punkt fehlt (kompletter Voraussetzungs-Lauf waere overkill).
$GrpPS.Controls.Add( (New-Label "NIC power saving (SleepyNIC)" 730 70 330 $Global:FontBold) )
$Global:LblNicPower = New-Label "..." 730 98 330 $Global:FontBold; $GrpPS.Controls.Add($Global:LblNicPower)
$BtnFixNicPower = New-Button (Get-T "PrereqNicFix") 730 126 330 30 $Global:ColorAccent
$BtnFixNicPower.Add_Click({
    try {
        Write-Log "Disabling NIC power saving (SleepyNICCheck)..." -Level INFO
        $r = Disable-NicPowerSaving
        $msg = ("NIC power saving / Energiesparung NIC: " + $r.Fixed + " changed / geaendert, " + $r.Already + " already disabled / bereits deaktiviert, " + $r.Skipped + " skipped / uebersprungen, " + $r.Errors + " errors / Fehler")
        if ($r.Errors -gt 0) { Write-Log $msg -Level ERROR }
        elseif ($r.Total -eq 0) { Write-Log "No network adapters found / Keine Netzwerkkarten gefunden" -Level WARNING }
        else { Write-Log $msg -Level SUCCESS }
        Update-NicPowerSavingLabel
    } catch { Write-Log ("NIC power saving error: " + $_) -Level ERROR }
})
$GrpPS.Controls.Add($BtnFixNicPower)

$BtnRefreshPrereq = New-Button (Get-T "PrereqRefresh") 870 28 200 32 $Global:ColorAccent
# Status-Anzeige als EIGENE Funktion: der alte Handler lief nur ueber
# Button.PerformClick() - das feuert NICHT, wenn der Button nicht sichtbar
# ist (nicht aktiver Tab, Formular vor ShowDialog), wodurch die Statuswerte
# beim Start als "..." stehen blieben. Jetzt Button UND Start-Aufruf (Splash)
# gehen direkt durch diese Funktion.
function Update-PrerequisiteStatusDisplay {
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
        if ($st.UCMA) {
            $Global:LblUCMA.Text = $okText
            $Global:LblUCMA.ForeColor = $Global:ColorAccent2
        } else {
            # Vorab-Anzeige: Schon vor dem Klick auf "Voraussetzungen installieren"
            # sichtbar, ob das benoetigte Exchange-Medium (ISO-Datei, gemountetes
            # Image oder eingelegte CD) existiert - derselbe Helper wie im Lauf.
            $media = Get-ExchangeMediaStatus
            if ($media.Available) {
                $mediaHint = if ($media.Source -eq "iso-file") {
                    if ($Global:CurrentLang -eq "DE") { "ISO-Datei gewaehlt" } else { "ISO file selected" }
                } else { $media.Path }
                $Global:LblUCMA.Text = "$missText ($mediaHint)"
                $Global:LblUCMA.ForeColor = $Global:ColorWarning
            } else {
                $Global:LblUCMA.Text = if ($Global:CurrentLang -eq "DE") { "FEHLT - kein Medium! ISO mounten / CD einlegen" } else { "MISSING - no medium! mount ISO / insert CD" }
                $Global:LblUCMA.ForeColor = $Global:ColorError
            }
        }
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
        $Global:ChkDisableNicPower.Checked = -not $st.NicPowerSavingOK
        $Global:ChkDisableNicPower.Enabled = -not $st.NicPowerSavingOK

        Update-NicPowerSavingLabel
        Write-Log "Prerequisite status updated" -Level SUCCESS
    } catch { Write-Log ("Error: " + $_) -Level ERROR }
}
$BtnRefreshPrereq.Add_Click({ Update-PrerequisiteStatusDisplay })
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
$Global:ChkSetPagefile    = New-CheckBox "Pagefile (25% RAM, Exchange 2019/SE)" 540 90 500 $true
$Global:ChkSetHighPerf    = New-CheckBox "High-Performance Power Plan" 540 120 500 $true
$Global:ChkDisableNicPower = New-CheckBox "NIC power saving disable (SleepyNIC)" 540 150 500 $true
foreach ($c in @($Global:ChkInstDotNet,$Global:ChkInstVC2012,$Global:ChkInstVC2013,
                 $Global:ChkInstURLRewrite,$Global:ChkInstUCMA,$Global:ChkInstFeatures,
                 $Global:ChkDisableSMB1,$Global:ChkSetPagefile,$Global:ChkSetHighPerf,
                 $Global:ChkDisableNicPower)) {
    $GrpPO.Controls.Add($c)
}

$GrpPA = New-GroupBox (Get-T "PrereqAction") 10 504 1080 80
$TabPrereq.Controls.Add($GrpPA)
$BtnInstallPrereq = New-Button (Get-T "PrereqInstall") 15 22 350 34 $Global:ColorAccent2
$BtnInstallPrereq.Add_Click({
    $r = [System.Windows.Forms.MessageBox]::Show("Continue?",(Get-T "Confirm"),'YesNo','Question')
    if ($r -ne "Yes") { return }
    $TabControl.SelectedTab = $TabRun
    [System.Windows.Forms.Application]::DoEvents()
    try {
        Install-PrerequisiteSoftware `
            -InstallDotNet $Global:ChkInstDotNet.Checked -InstallVC2012 $Global:ChkInstVC2012.Checked `
            -InstallVC2013 $Global:ChkInstVC2013.Checked -InstallURLRewrite $Global:ChkInstURLRewrite.Checked `
            -InstallUCMA $Global:ChkInstUCMA.Checked -InstallFeatures $Global:ChkInstFeatures.Checked `
            -DisableSMB1 $Global:ChkDisableSMB1.Checked -OptimizePageFile $Global:ChkSetPagefile.Checked `
            -SetHighPerformance $Global:ChkSetHighPerf.Checked `
            -DisableNicPower $Global:ChkDisableNicPower.Checked
    } finally {
        # UCMA koennte die ISO gemountet haben - nach dem Schritt IMMER freigeben
        # (ein manuell gemountetes ISO bleibt unangetastet)
        Dismount-ScriptISO
    }
    $TabControl.SelectedTab = $TabPrereq
    # Direkt aufrufen - PerformClick hängt an der Sichtbarkeit des Buttons
    Update-PrerequisiteStatusDisplay
})
$GrpPA.Controls.Add($BtnInstallPrereq)
$LblHint = New-Label (Get-T "PrereqHint") 380 30 600
$LblHint.ForeColor = $Global:ColorTextDim
$GrpPA.Controls.Add($LblHint)
#endregion

#region ============================ TAB: AD-VORBEREITUNG ============================
$GrpADStatus = New-GroupBox (Get-T "AD_Status") 10 8 1080 200
$TabADPrep.Controls.Add($GrpADStatus)
$GrpADStatus.Controls.Add( (New-Label (Get-T "PrereqComponent") 20 24 200 $Global:FontBold) )
$GrpADStatus.Controls.Add( (New-Label (Get-T "AD_Current") 230 24 200 $Global:FontBold) )
$GrpADStatus.Controls.Add( (New-Label (Get-T "AD_Required") 430 24 200 $Global:FontBold) )
$GrpADStatus.Controls.Add( (New-Label (Get-T "PrereqState") 630 24 200 $Global:FontBold) )

$GrpADStatus.Controls.Add( (New-Label (Get-T "AD_Schema") 20 48 200) )
$Global:LblADSchemaCur = New-Label "..." 230 48 200 $Global:FontBold; $GrpADStatus.Controls.Add($Global:LblADSchemaCur)
$Global:LblADSchemaReq = New-Label "..." 430 48 200; $GrpADStatus.Controls.Add($Global:LblADSchemaReq)
$Global:LblADSchemaSt = New-Label "..." 630 48 200 $Global:FontBold; $GrpADStatus.Controls.Add($Global:LblADSchemaSt)

$GrpADStatus.Controls.Add( (New-Label (Get-T "AD_Org") 20 74 200) )
$Global:LblADOrgCur = New-Label "..." 230 74 200 $Global:FontBold; $GrpADStatus.Controls.Add($Global:LblADOrgCur)
$Global:LblADOrgReq = New-Label "..." 430 74 200; $GrpADStatus.Controls.Add($Global:LblADOrgReq)
$Global:LblADOrgSt = New-Label "..." 630 74 200 $Global:FontBold; $GrpADStatus.Controls.Add($Global:LblADOrgSt)

$GrpADStatus.Controls.Add( (New-Label (Get-T "AD_Dom") 20 100 200) )
$Global:LblADDomCur = New-Label "..." 230 100 200 $Global:FontBold; $GrpADStatus.Controls.Add($Global:LblADDomCur)
$Global:LblADDomReq = New-Label "..." 430 100 200; $GrpADStatus.Controls.Add($Global:LblADDomReq)
$Global:LblADDomSt = New-Label "..." 630 100 200 $Global:FontBold; $GrpADStatus.Controls.Add($Global:LblADDomSt)

$GrpADStatus.Controls.Add( (New-Label (Get-T "AD_User") 20 128 200 $Global:FontBold) )
$Global:LblADUser = New-Label "..." 230 128 600; $GrpADStatus.Controls.Add($Global:LblADUser)
$GrpADStatus.Controls.Add( (New-Label (Get-T "AD_Perms") 20 152 200 $Global:FontBold) )
$Global:LblADPerms = New-Label "..." 230 152 800; $GrpADStatus.Controls.Add($Global:LblADPerms)

function Update-ADStatusDisplay {
    <#
        Fuellt die AD-Status-Gruppe (Schema/Org/Domain, Benutzer, Berechtigungen) neu.
        Wird vom Button "Status aktualisieren" UND automatisch nach jedem Ergebnis-Check
        aufgerufen - nach einem Adprep-Lauf muss also nicht mehr manuell aktualisiert
        werden, damit die neue Vorbereitung sichtbar wird.
    #>
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
}

$BtnRefreshAD = New-Button (Get-T "PrereqRefresh") 870 22 200 32 $Global:ColorAccent
$BtnRefreshAD.Add_Click({ Update-ADStatusDisplay })
$GrpADStatus.Controls.Add($BtnRefreshAD)

$GrpPrepSteps = New-GroupBox (Get-T "AD_Steps") 10 212 1080 202
$TabADPrep.Controls.Add($GrpPrepSteps)
$Global:ChkPrepSchema = New-CheckBox (Get-T "AD_PrepSchema") 15 24 800 $true
$GrpPrepSteps.Controls.Add($Global:ChkPrepSchema)
$Global:ChkPrepAD = New-CheckBox (Get-T "AD_PrepAD") 15 50 800 $true
$GrpPrepSteps.Controls.Add($Global:ChkPrepAD)
$Global:ChkPrepDom = New-CheckBox (Get-T "AD_PrepDom") 15 78 250 $true
$GrpPrepSteps.Controls.Add($Global:ChkPrepDom)

$Global:RbAllDomains = New-Object System.Windows.Forms.RadioButton
$Global:RbAllDomains.Text=(Get-T "AD_AllDoms")
$Global:RbAllDomains.Location=New-Object System.Drawing.Point(40,102); $Global:RbAllDomains.Size=New-Object System.Drawing.Size(400,22)
$Global:RbAllDomains.Checked=$true; $Global:RbAllDomains.BackColor=[System.Drawing.Color]::Transparent
$GrpPrepSteps.Controls.Add($Global:RbAllDomains)

$Global:RbSingleDomain = New-Object System.Windows.Forms.RadioButton
$Global:RbSingleDomain.Text=(Get-T "AD_OneDom")
$Global:RbSingleDomain.Location=New-Object System.Drawing.Point(40,128); $Global:RbSingleDomain.Size=New-Object System.Drawing.Size(220,22)
$Global:RbSingleDomain.BackColor=[System.Drawing.Color]::Transparent
$GrpPrepSteps.Controls.Add($Global:RbSingleDomain)

$Global:CmbDomainList = New-Object System.Windows.Forms.ComboBox
$Global:CmbDomainList.Location=New-Object System.Drawing.Point(265,128); $Global:CmbDomainList.Size=New-Object System.Drawing.Size(350,22)
$Global:CmbDomainList.DropDownStyle="DropDownList"
$Global:CmbDomainList.BackColor=$Global:ColorInputBg; $Global:CmbDomainList.ForeColor=$Global:ColorText
$GrpPrepSteps.Controls.Add($Global:CmbDomainList)

$GrpPrepSteps.Controls.Add( (New-Label (Get-T "AD_WaitMin") 15 156 250) )
$Global:NumWaitMin = New-NumericUpDown 270 154 70 0 60 5
$GrpPrepSteps.Controls.Add($Global:NumWaitMin)
$LH2 = New-Label (Get-T "AD_WaitHint") 350 156 600
$LH2.ForeColor = $Global:ColorTextDim
$GrpPrepSteps.Controls.Add($LH2)

$GrpPA2 = New-GroupBox (Get-T "AD_CheckTitle") 10 420 1080 162
$TabADPrep.Controls.Add($GrpPA2)

# Statuszeile fuer den automatischen Ergebnis-Check
$Global:LblADResult = New-Label (Get-T "AD_ResultNone") 15 76 1050 60 $Global:FontBold
$Global:LblADResult.ForeColor = $Global:ColorTextDim
$Global:LblADResult.TextAlign = "MiddleLeft"
$GrpPA2.Controls.Add($Global:LblADResult)

# Funktion: Ergebnis-Check ausfuehren und anzeigen (wird nach Adprep automatisch aufgerufen)
$Global:Script:RunAdPrepCheck = {
    try {
        Write-Log ("--- Automatic AD preparation result check ---") -Level INFO
        $res = Test-ADPrepResult
        if ($res) {
            Write-ADPrepResultReport -Result $res
            Update-ADPrepResultLabels -Result $res
        }
        # Auch die AD-Status-Gruppe (Schema/Org/Domain/Berechtigungen) neu fuellen -
        # nach einem Adprep-Lauf muss der User nicht mehr "Status aktualisieren" klicken.
        Update-ADStatusDisplay
        return $res
    } catch { Write-Log ("Result check error: " + $_) -Level ERROR; return $null }
}

$BtnPrepAD = New-Button (Get-T "AD_StartBtn") 15 24 350 36 $Global:ColorAccent2
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
        $Global:AdPrepExecuted = @()   # neuer Lauf - Ausfuehrungsliste fuer den Report zuruecksetzen
        $waitMin = [int]$Global:NumWaitMin.Value
        if ($Global:ChkPrepSchema.Checked) {
            $okSchema = Invoke-ExchangePrepareStep -SetupPath $setupPath -Step "PrepareSchema"
            if (-not $okSchema) {
                Write-Log "AD-Vorbereitung ABGEBROCHEN nach PrepareSchema - PrepareAD/Domain werden NICHT ausgefuehrt." -Level ERROR
                [System.Windows.Forms.MessageBox]::Show("PrepareSchema fehlgeschlagen - Vorgang abgebrochen. Details im Log.`r`n" + $Global:ExchangeSetupLog,(Get-T "Error"),'OK','Error')
                $TabControl.SelectedTab = $TabADPrep
                return
            }
            if ($waitMin -gt 0) { Wait-ADReplication -Minutes $waitMin }
        }
        if ($Global:ChkPrepAD.Checked) {
            $okAD = Invoke-ExchangePrepareStep -SetupPath $setupPath -Step "PrepareAD" -OrgName $Global:TxtOrg.Text
            if (-not $okAD) {
                Write-Log "AD-Vorbereitung ABGEBROCHEN nach PrepareAD - Domain-Prep wird NICHT ausgefuehrt." -Level ERROR
                [System.Windows.Forms.MessageBox]::Show("PrepareAD fehlgeschlagen - Vorgang abgebrochen. Details im Log.`r`n" + $Global:ExchangeSetupLog,(Get-T "Error"),'OK','Error')
                $TabControl.SelectedTab = $TabADPrep
                return
            }
            if ($waitMin -gt 0) { Wait-ADReplication -Minutes $waitMin }
        }
        if ($Global:ChkPrepDom.Checked) {
            $okDom = $true
            if ($Global:RbAllDomains.Checked) {
                $okDom = Invoke-ExchangePrepareStep -SetupPath $setupPath -Step "PrepareAllDomains"
            } elseif ($Global:RbSingleDomain.Checked -and $Global:CmbDomainList.SelectedItem) {
                $okDom = Invoke-ExchangePrepareStep -SetupPath $setupPath -Step "PrepareDomain" -DomainName ($Global:CmbDomainList.SelectedItem.ToString())
            }
            if (-not $okDom) {
                Write-Log "AD-Vorbereitung ABGEBROCHEN nach Domain-Prep." -Level ERROR
                [System.Windows.Forms.MessageBox]::Show("Domain-Vorbereitung fehlgeschlagen - Vorgang abgebrochen. Details im Log.`r`n" + $Global:ExchangeSetupLog,(Get-T "Error"),'OK','Error')
                $TabControl.SelectedTab = $TabADPrep
                return
            }
        }

        # === Automatischer Ergebnis-Check direkt nach der Adprep ===
        # (RunAdPrepCheck aktualisiert auch die AD-Status-Gruppe automatisch)
        $adCheckResult = & $Global:Script:RunAdPrepCheck

        $TabControl.SelectedTab = $TabADPrep

        if ($adCheckResult) {
            $msg = (Get-T "AD_CheckTitle") + "`r`n" + $Global:LblADResult.Text
            if (-not $adCheckResult.AllOK) {
                $failedNames = @($adCheckResult.Results | Where-Object { -not $_.OK } | ForEach-Object { $_.Item })
                $msg += "`r`n`r`n" + ($failedNames -join "`r`n")
                [System.Windows.Forms.MessageBox]::Show($msg,(Get-T "Warning"),'OK','Warning')
            } else {
                [System.Windows.Forms.MessageBox]::Show($msg,(Get-T "Info"),'OK','Information')
            }
        }
    } catch { Write-Log ("Error: " + $_) -Level ERROR }
    finally {
        # Nach jedem AD-Prep-Lauf (auch bei Abbruch/Fehler) die vom Skript gemountete
        # ISO wieder freigeben - ein manuell gemountetes ISO bleibt unangetastet.
        Dismount-ScriptISO
        # Status-Gruppe auch bei Abbruch neu darstellen - ohne manuellen Klick
        # auf "Status aktualisieren".
        Update-ADStatusDisplay
    }
})
$GrpPA2.Controls.Add($BtnPrepAD)

# Manueller Ergebnis-Check (ohne erneute Vorbereitung)
$BtnCheckAD = New-Button (Get-T "AD_Check") 390 24 350 36 $Global:ColorAccent
$BtnCheckAD.Add_Click({
    $TabControl.SelectedTab = $TabRun
    [System.Windows.Forms.Application]::DoEvents()
    $res = & $Global:Script:RunAdPrepCheck
    $TabControl.SelectedTab = $TabADPrep
    if ($res) {
        $msg = (Get-T "AD_CheckTitle") + "`r`n" + $Global:LblADResult.Text
        if ($res.AllOK) {
            [System.Windows.Forms.MessageBox]::Show($msg,(Get-T "Info"),'OK','Information')
        } else {
            $failedNames = @($res.Results | Where-Object { -not $_.OK } | ForEach-Object { $_.Item })
            $msg += "`r`n`r\n" + ($failedNames -join "`r`n")
            [System.Windows.Forms.MessageBox]::Show($msg,(Get-T "Warning"),'OK','Warning')
        }
    }
})
$GrpPA2.Controls.Add($BtnCheckAD)
#endregion

#region ============================ TAB: INSTALLATION ============================
$GrpISO = New-GroupBox (Get-T "ISO_Source") 10 8 1080 156
$TabInstall.Controls.Add($GrpISO)

$Global:RbISOFile = New-Object System.Windows.Forms.RadioButton
$Global:RbISOFile.Text=(Get-T "ISO_RbFile")
$Global:RbISOFile.Location=New-Object System.Drawing.Point(15,24); $Global:RbISOFile.Size=New-Object System.Drawing.Size(400,24)
$Global:RbISOFile.Checked=$true; $Global:RbISOFile.BackColor=[System.Drawing.Color]::Transparent; $Global:RbISOFile.ForeColor=$Global:ColorText
$GrpISO.Controls.Add($Global:RbISOFile)

$Global:RbISOMounted = New-Object System.Windows.Forms.RadioButton
$Global:RbISOMounted.Text=(Get-T "ISO_RbMounted")
$Global:RbISOMounted.Location=New-Object System.Drawing.Point(15,50); $Global:RbISOMounted.Size=New-Object System.Drawing.Size(550,24)
$Global:RbISOMounted.BackColor=[System.Drawing.Color]::Transparent; $Global:RbISOMounted.ForeColor=$Global:ColorText
$GrpISO.Controls.Add($Global:RbISOMounted)

$GrpISO.Controls.Add( (New-Label (Get-T "ISO_FileLbl") 35 80 100) )
$Global:TxtISO = New-TextBox 145 78 760
$GrpISO.Controls.Add($Global:TxtISO)

$BtnBrowseISO = New-Button (Get-T "ISO_Browse") 915 77 130 24 $Global:ColorAccent2
$BtnBrowseISO.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "ISO files (*.iso)|*.iso|All files|*.*"
    if ($ofd.ShowDialog() -eq "OK") { $Global:TxtISO.Text = $ofd.FileName; $Global:RbISOFile.Checked = $true }
})
$GrpISO.Controls.Add($BtnBrowseISO)

$GrpISO.Controls.Add( (New-Label (Get-T "ISO_DriveLbl") 35 108 100) )
$Global:CmbMountedDrives = New-Object System.Windows.Forms.ComboBox
$Global:CmbMountedDrives.Location=New-Object System.Drawing.Point(145,106); $Global:CmbMountedDrives.Size=New-Object System.Drawing.Size(760,22)
$Global:CmbMountedDrives.DropDownStyle="DropDownList"
$Global:CmbMountedDrives.BackColor=$Global:ColorInputBg; $Global:CmbMountedDrives.ForeColor=$Global:ColorText; $Global:CmbMountedDrives.Font=$Global:FontDefault
$GrpISO.Controls.Add($Global:CmbMountedDrives)

$BtnDetectISO = New-Button (Get-T "ISO_AutoDetect") 915 105 130 24 $Global:ColorAccent
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

$GrpSetup = New-GroupBox (Get-T "Setup_Params") 10 170 1080 208
$TabInstall.Controls.Add($GrpSetup)

$GrpSetup.Controls.Add( (New-Label (Get-T "Setup_Org") 15 24 150) )
$Global:TxtOrg = New-TextBox 175 22 400 "Contoso"
$GrpSetup.Controls.Add($Global:TxtOrg)

$Global:LblOrgWarning = New-Object System.Windows.Forms.Label
$Global:LblOrgWarning.Location=New-Object System.Drawing.Point(580,24); $Global:LblOrgWarning.Size=New-Object System.Drawing.Size(465,20)
$Global:LblOrgWarning.Font=New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
$Global:LblOrgWarning.BackColor=[System.Drawing.Color]::Transparent; $Global:LblOrgWarning.Text=""
$GrpSetup.Controls.Add($Global:LblOrgWarning)

$GrpSetup.Controls.Add( (New-Label (Get-T "Setup_Server") 15 52 150) )
$Global:TxtServer = New-TextBox 175 50 400 $env:COMPUTERNAME
$GrpSetup.Controls.Add($Global:TxtServer)

$GrpSetup.Controls.Add( (New-Label (Get-T "Setup_InstallPath") 15 78 150) )
$Global:TxtInstallPath = New-TextBox 175 76 870 $Global:DefaultInstallPath
$GrpSetup.Controls.Add($Global:TxtInstallPath)

$GrpSetup.Controls.Add( (New-Label (Get-T "Setup_Domain") 15 104 150) )
$Global:TxtDomain = New-TextBox 175 102 400
Write-Host "@@DIAG@@ [4b/7] vor WMI-Abfrage (Win32_ComputerSystem)" -ForegroundColor DarkGray
try { $Global:TxtDomain.Text = (Get-CimInstance Win32_ComputerSystem).Domain } catch { $Global:TxtDomain.Text = "contoso.local" }
Write-Host "@@DIAG@@ [4c/7] nach WMI-Abfrage" -ForegroundColor DarkGray
$GrpSetup.Controls.Add($Global:TxtDomain)

$GrpSetup.Controls.Add( (New-Label (Get-T "Setup_Roles") 15 130 150 $Global:FontBold) )
$Global:ChkRoleMailbox = New-CheckBox (Get-T "Setup_RoleMailbox") 175 130 250 $true
$GrpSetup.Controls.Add($Global:ChkRoleMailbox)
$Global:ChkRoleEdge = New-CheckBox (Get-T "Setup_RoleEdge") 440 130 270 $false
$GrpSetup.Controls.Add($Global:ChkRoleEdge)
$Global:ChkRoleMgmt = New-CheckBox (Get-T "Setup_RoleMgmt") 720 130 280 $true
$GrpSetup.Controls.Add($Global:ChkRoleMgmt)

$Global:ChkRoleEdge.Add_CheckedChanged({
    if ($Global:ChkRoleEdge.Checked) {
        $Global:ChkRoleMailbox.Checked = $false; $Global:ChkRoleMailbox.Enabled = $false
    } else { $Global:ChkRoleMailbox.Enabled = $true; $Global:ChkRoleMailbox.Checked = $true }
})

$GrpSetup.Controls.Add( (New-Label (Get-T "Setup_Diag") 15 158 150) )
$Global:ChkDiagData = New-CheckBox (Get-T "Setup_DiagText") 175 158 500 $false
$GrpSetup.Controls.Add($Global:ChkDiagData)

$GrpOpts = New-GroupBox (Get-T "Inst_Options") 10 384 1080 198
$TabInstall.Controls.Add($GrpOpts)
$Global:Checks = @{}
# Hinweis: Die frueheren Optionen "ISO automatisch mounten" und "ISO am Ende unmounten"
# wurden entfernt - die ISO wird jetzt IMMER automatisch gemountet, sobald ein Schritt
# sie braucht, und am Ende IMMER wieder dismountet (siehe Mount-ExchangeISO / STEP 9).
$opts = @(
    @{Key="PrereqCheck"; Text=(Get-T "Opt_PrereqCheck"); Default=$true; Col=0; Row=0},
    @{Key="RunPrereqInstall"; Text=(Get-T "Opt_RunPrereq"); Default=$true; Col=0; Row=1},
    @{Key="DoADPrep"; Text=(Get-T "Opt_DoADPrep"); Default=$true; Col=0; Row=2},
    @{Key="InstallExchange"; Text=(Get-T "Opt_InstExch"); Default=$true; Col=0; Row=3},
    @{Key="InstallAntispam"; Text=(Get-T "Opt_InstSpam"); Default=$true; Col=1; Row=0},
    @{Key="ConfigAntispam"; Text=(Get-T "Opt_CfgSpam"); Default=$true; Col=1; Row=1},
    @{Key="VerifyInstall"; Text=(Get-T "Opt_Verify"); Default=$true; Col=1; Row=2},
    @{Key="ApplyTLS"; Text=(Get-T "Opt_TLS"); Default=$true; Col=1; Row=3},
    @{Key="CreateDBs"; Text=(Get-T "Opt_DBs"); Default=$false; Col=1; Row=4},
    @{Key="CreateDAG"; Text=(Get-T "Opt_DAG"); Default=$false; Col=2; Row=0},
    @{Key="ForceAdminCheck"; Text=(Get-T "Opt_Admin"); Default=$true; Col=2; Row=1},
    @{Key="ContinueOnError"; Text=(Get-T "Opt_Continue"); Default=$false; Col=2; Row=2},
    @{Key="CreateCertificate"; Text=(Get-T "Opt_CreateCert"); Default=$false; Col=0; Row=4},
    @{Key="SetUrls"; Text=(Get-T "Opt_SetUrls"); Default=$false; Col=1; Row=5}
)
foreach ($o in $opts) {
    $cb = New-CheckBox $o.Text (20 + $o.Col*355) (26 + $o.Row*25) 340 $o.Default
    $GrpOpts.Controls.Add($cb)
    $Global:Checks[$o.Key] = $cb
}
#endregion

#region ============================ TAB: SICHERHEIT / TLS ============================
$GrpTLS = New-GroupBox (Get-T "TLS_Title") 10 10 1080 220
$TabSecurity.Controls.Add($GrpTLS)
$LblTLS = New-Object System.Windows.Forms.Label
$LblTLS.Location=New-Object System.Drawing.Point(15,28); $LblTLS.Size=New-Object System.Drawing.Size(1050,165)
$LblTLS.Font=New-Object System.Drawing.Font("Segoe UI",9); $LblTLS.ForeColor=$Global:ColorText; $LblTLS.BackColor=[System.Drawing.Color]::Transparent
$LblTLS.Text = "DISABLED: SSL 2.0/3.0, TLS 1.0/1.1, weak ciphers (RC4, DES, 3DES, NULL)`r`nENABLED:  TLS 1.2, TLS 1.3, .NET SystemDefaultTlsVersions + SchUseStrongCrypto`r`n`r`nIMPORTANT: A REBOOT is required after applying!"
$GrpTLS.Controls.Add($LblTLS)

$GrpTLSAct = New-GroupBox (Get-T "TLS_Action") 10 238 1080 130
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
$Global:ChkSenderID = New-CheckBox (Get-T "Filt_SenderID") 20 60 350 $false
$Global:ChkSenderID.Enabled = $false
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
$GrpGen = New-GroupBox "DB-Generator" 10 35 1080 190
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

$LblPv = New-Label (Get-T "DB_Preview") 10 232 800 $Global:FontBold
$TabDB.Controls.Add($LblPv)

$Global:DgvDB = New-Object System.Windows.Forms.DataGridView
$Global:DgvDB.Location=New-Object System.Drawing.Point(10,256); $Global:DgvDB.Size=New-Object System.Drawing.Size(1080,258)
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

function Invoke-DatabaseCreation {
    <#
        Legt die in der Datenbank-Liste definierten Mailbox-Datenbanken an.
        Wird SOWOHL vom Button als auch direkt aus STEP 7 des Master-Workflows
        aufgerufen: Button.PerformClick() feuert NICHT, wenn der Button auf
        einem nicht aktiven Tab liegt (nicht sichtbar => CanSelect=false =>
        das Klick-Ereignis entfaellt stillschweigend) - genau das war der
        Grund, warum STEP 7 im kombinierten Lauf keine Datenbanken anlegte,
        waehrend der manuelle Klick (Tab offen) funktionierte. Jeder
        Abbruchgrund wird jetzt protokolliert statt stillschweigend zu
        return'n. Liefert $true, wenn keine Fehler auftraten.
    #>
    $rows = @()
    try {
        $rows = @($Global:DgvDB.Rows | Where-Object {
            -not $_.IsNewRow -and -not [string]::IsNullOrWhiteSpace("$($_.Cells['DBName'].Value)")
        })
    } catch {}
    if ($rows.Count -eq 0) {
        Write-Log "No database rows defined - open the 'Databases' tab and generate or load databases first / Keine Datenbanken definiert - im Tab 'Datenbanken' zuerst DBs erzeugen oder Konfiguration laden. Database step SKIPPED / Datenbank-Schritt uebersprungen" -Level WARNING
        return $false
    }
    if (-not (Import-ExchangeManagementShell)) {
        Write-Log "Exchange Management Shell could not be loaded - database step SKIPPED / Exchange-Verwaltungsshell nicht ladbar - Datenbank-Schritt uebersprungen" -Level ERROR
        return $false
    }
    $created = 0; $existing = 0; $errCnt = 0
    foreach ($row in $rows) {
        $n = "$($row.Cells['DBName'].Value)"
        try {
            if (Get-MailboxDatabase -Identity $n -ErrorAction SilentlyContinue) {
                $existing++
                Write-Log ("  DB '" + $n + "' already exists - skipped / bereits vorhanden - uebersprungen") -Level INFO
                continue
            }
            $edb = "$($row.Cells['EdbFilePath'].Value)"; $lp = "$($row.Cells['LogFolderPath'].Value)"
            $eDir = Split-Path $edb -Parent
            if (-not (Test-Path $eDir)) { New-Item $eDir -ItemType Directory -Force | Out-Null }
            if (-not (Test-Path $lp)) { New-Item $lp -ItemType Directory -Force | Out-Null }
            New-MailboxDatabase -Name $n -Server "$($row.Cells['Server'].Value)" -EdbFilePath $edb -LogFolderPath $lp -ErrorAction Stop | Out-Null
            Mount-Database -Identity $n -ErrorAction Stop
            Write-Log ("DB '" + $n + "' created / angelegt") -Level SUCCESS
            $created++
        } catch { $errCnt++; Write-Log ("DB Error '" + $n + "': " + $_) -Level ERROR }
    }
    $sum = ("Database summary / Datenbanken: " + $created + " created / angelegt, " + $existing + " already existing / vorhanden, " + $errCnt + " errors / Fehler")
    if ($errCnt -gt 0) { Write-Log $sum -Level ERROR } else { Write-Log $sum -Level SUCCESS }
    return ($errCnt -eq 0)
}

$BtnCreateDBNow = New-Button (Get-T "DB_CreateNow") 10 524 350 38 $Global:ColorAccent2
$BtnCreateDBNow.Add_Click({ [void](Invoke-DatabaseCreation) })
$TabDB.Controls.Add($BtnCreateDBNow)

#endregion

#region ============================ TAB: DAG ============================
$GrpDAG1 = New-GroupBox (Get-T "DAG_Settings") 10 10 1080 240
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

$GrpDAG2 = New-GroupBox (Get-T "DAG_Members") 10 256 1080 212
$TabDAG.Controls.Add($GrpDAG2)
$Global:TxtMembers = New-Object System.Windows.Forms.TextBox
$Global:TxtMembers.Location=New-Object System.Drawing.Point(15,25); $Global:TxtMembers.Size=New-Object System.Drawing.Size(1050,160)
$Global:TxtMembers.Multiline=$true; $Global:TxtMembers.ScrollBars="Vertical"
$Global:TxtMembers.BackColor=$Global:ColorInputBg; $Global:TxtMembers.ForeColor=$Global:ColorText
$Global:TxtMembers.Font=$Global:FontMono; $Global:TxtMembers.Text="EX01`r`nEX02"
$GrpDAG2.Controls.Add($Global:TxtMembers)

$BtnCreateDAGNow = New-Button (Get-T "DAG_Create") 10 476 1080 40 $Global:ColorAccent
function Invoke-DagCreation {
    <#
        Erstellt die DAG (inkl. DC-Witness-Warnung, ETS-Rechte, Witness-Ordner).
        Eigene Funktion statt Scriptblock-Handler, weil STEP 8 des Master-
        Workflows die Aktion direkt aufrufen kann: ein PerformClick auf dem
        Button im nicht aktiven DAG-Tab feuert nicht (nicht sichtbar =>
        CanSelect=false => das Klick-Ereignis entfaellt stillschweigend),
        die Erstellung waere stillschweigend entfallen - derselbe Fehler wie
        bei STEP 7/DBs.
    #>
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
}
$BtnCreateDAGNow.Add_Click({ [void](Invoke-DagCreation) })
$TabDAG.Controls.Add($BtnCreateDAGNow)
#endregion

#region ============================ TAB: URLS ============================

# ---------- Gruppe 1: Quelle auslesen und Basis-Domain ----------
$GrpURLSrc = New-GroupBox (Get-T "URL_ReadTitle") 10 6 1080 142
$TabUrls.Controls.Add($GrpURLSrc)
$Global:UrlUiLoading = $false

$GrpURLSrc.Controls.Add( (New-Label (Get-T "URL_Server") 20 24 125 $Global:FontBold) )
$Global:CmbUrlServer = New-Object System.Windows.Forms.ComboBox
$Global:CmbUrlServer.Location=New-Object System.Drawing.Point(150,22); $Global:CmbUrlServer.Size=New-Object System.Drawing.Size(405,22)
$Global:CmbUrlServer.DropDownStyle="DropDownList"
$Global:CmbUrlServer.BackColor=$Global:ColorInputBg; $Global:CmbUrlServer.ForeColor=$Global:ColorText
$GrpURLSrc.Controls.Add($Global:CmbUrlServer)
$BtnUrlSrvRefresh = New-Button (Get-T "URL_SrvRefresh") 565 21 120 24 $Global:ColorAccent
$BtnUrlSrvRefresh.Add_Click({ try { [void](Update-UrlServerList) } catch { Write-Log ("Error: " + $_) -Level ERROR } })
$GrpURLSrc.Controls.Add($BtnUrlSrvRefresh)
$BtnUrlRead = New-Button (Get-T "URL_Read") 695 21 180 24 $Global:ColorAccent2
$Global:ChkSetUrls = New-CheckBox (Get-T "URL_ApplyAuto") 885 23 175 $false
$GrpURLSrc.Controls.Add($Global:ChkSetUrls)

# Basis-Domain: eine Domain fuer die anwendbaren Dienste - die Pfade ergaenzt Exchange selbst
$GrpURLSrc.Controls.Add( (New-Label (Get-T "URL_HostInt") 20 56 125 $Global:FontBold) )
$Global:TxtUrlHostInt = New-TextBox 150 54 300
$GrpURLSrc.Controls.Add($Global:TxtUrlHostInt)
$GrpURLSrc.Controls.Add( (New-Label (Get-T "URL_HostExt") 465 56 125 $Global:FontBold) )
$Global:TxtUrlHostExt = New-TextBox 595 54 300
$Global:TxtUrlHostExt.ReadOnly = $true
$Global:TxtUrlHostExt.BackColor = $Global:ColorPanelAlt
$GrpURLSrc.Controls.Add($Global:TxtUrlHostExt)
$Global:ChkUrlSameHost = New-CheckBox (Get-T "URL_SameHost") 905 55 155 $true
$GrpURLSrc.Controls.Add($Global:ChkUrlSameHost)

$BtnUrlBuild = New-Button (Get-T "URL_Build") 150 86 180 26 $Global:ColorAccent
$GrpURLSrc.Controls.Add($BtnUrlBuild)
$LblUrlHint = New-Label (Get-T "URL_Hint") 345 91 700
$LblUrlHint.ForeColor = $Global:ColorTextDim
$GrpURLSrc.Controls.Add($LblUrlHint)

# ---------- Gruppe 2: Dienst-Tabelle (intern / extern) ----------
$GrpURLTable = New-GroupBox (Get-T "URL_Table") 10 154 1080 300
$TabUrls.Controls.Add($GrpURLTable)
$GrpURLTable.Controls.Add( (New-Label (Get-T "URL_Service") 20 24 125 $Global:FontBold) )
$GrpURLTable.Controls.Add( (New-Label (Get-T "URL_Int")     150 24 440 $Global:FontBold) )
$GrpURLTable.Controls.Add( (New-Label (Get-T "URL_Ext")     600 24 440 $Global:FontBold) )

# Feld-Variablen: Key -> @{ Label; Internal; External }
$Global:UrlFields = [ordered]@{}
$urlRows = @(
    @{ Key="OWA";  Text="OWA" },
    @{ Key="ECP";  Text="ECP" },
    @{ Key="EWS";  Text="EWS (Webservices)" },
    @{ Key="AS";   Text="ActiveSync" },
    @{ Key="PS";   Text="PowerShell" },
    @{ Key="AD";   Text="Autodiscover" },
    @{ Key="MAPI"; Text="MAPI" },
    @{ Key="OAB";  Text="OAB" }
)
$y = 48
$Global:UrlPsTip = New-Object System.Windows.Forms.ToolTip
foreach ($u in $urlRows) {
    $lbl = New-Label $u.Text 20 ($y+1) 125
    $tbI = New-TextBox 150 $y 440
    $tbE = New-TextBox 600 $y 440
    if ($u.Key -eq "PS") {
        # PowerShell-VD bleibt Setup-Standard: Zeile nur sichtbar, nicht aenderbar
        $lbl.ForeColor = $Global:ColorTextDim
        $tbI.ReadOnly = $true
        $tbE.ReadOnly = $true
        $tbI.BackColor = $Global:ColorPanelAlt
        $tbE.BackColor = $Global:ColorPanelAlt
        $Global:UrlPsTip.SetToolTip($lbl, (Get-T "URL_PsTip"))
        $Global:UrlPsTip.SetToolTip($tbI, (Get-T "URL_PsTip"))
        $Global:UrlPsTip.SetToolTip($tbE, (Get-T "URL_PsTip"))
    } elseif ($u.Key -eq "AD") {
        # Autodiscover hat NUR eine URL: AutoDiscoverServiceInternalUri (SCP) -
        # eine interne/externe Trennung gibt es dort nicht. Deshalb in dieser
        # Zeile nur EIN Feld; die externe Spalte bleibt leer (External=$null,
        # Zugriffe laufen ueber Get-/Set-UrlFieldValue und werden dort geprueft).
        $tbE = $null
        $Global:UrlPsTip.SetToolTip($lbl, (Get-T "URL_AdTip"))
        $Global:UrlPsTip.SetToolTip($tbI, (Get-T "URL_AdTip"))
    }
    $GrpURLTable.Controls.Add($lbl)
    $GrpURLTable.Controls.Add($tbI)
    if ($tbE) { $GrpURLTable.Controls.Add($tbE) }
    $Global:UrlFields[$u.Key] = @{ Label=$u.Text; Internal=$tbI; External=$tbE }
    $y += 24
}

$Global:LblUrlStatus = New-Label (Get-T "URL_Status") 150 252 900 $Global:FontBold
$Global:LblUrlStatus.ForeColor = $Global:ColorTextDim
$Global:LblUrlStatus.AutoEllipsis = $true
$GrpURLTable.Controls.Add($Global:LblUrlStatus)

# Button: URLs vom Exchange-Server lesen (Snapshot der Spalten)
$BtnUrlRead.Add_Click({
    try {
        $TabControl.SelectedTab = $TabRun
        [System.Windows.Forms.Application]::DoEvents()
        Write-Log "=== Reading URL configuration from Exchange ===" -Level INFO
        $srv = ""
        try { if ($Global:CmbUrlServer -and $Global:CmbUrlServer.SelectedItem) { $srv = "$($Global:CmbUrlServer.SelectedItem)" } } catch {}
        $cfg = Get-ExchangeUrlConfiguration -Server $srv
        if ($cfg -and $cfg.Found) {
            $filled = 0
            foreach ($k in $Global:UrlFields.Keys) {
                $entry = $cfg.$k
                if (-not $entry) { continue }
                # Neu-Einlesen = Snapshot: leere gelesene Werte loeschen alte Eintraege
                Set-UrlFieldValue -Key $k -Side Internal -Value "$($entry.Internal)"
                Set-UrlFieldValue -Key $k -Side External -Value "$($entry.External)"
                if ($entry.Internal -or $entry.External) { $filled++ }
            }
            $msg = (Get-T "URL_ReadOk") -f $filled, $cfg.Server
            $Global:LblUrlStatus.Text = $msg
            $Global:LblUrlStatus.ForeColor = $Global:ColorAccent2
            Write-Log $msg -Level SUCCESS
            $TabControl.SelectedTab = $TabUrls
            [System.Windows.Forms.MessageBox]::Show($msg,(Get-T "Info"),'OK','Information')
        } else {
            $Global:LblUrlStatus.Text = (Get-T "URL_NoExch")
            $Global:LblUrlStatus.ForeColor = $Global:ColorWarning
            Write-Log (Get-T "URL_NoExch") -Level WARNING
            $TabControl.SelectedTab = $TabUrls
            [System.Windows.Forms.MessageBox]::Show((Get-T "URL_NoExch"),(Get-T "Warning"),'OK','Warning')
        }
    } catch { Write-Log ("Error: " + $_) -Level ERROR }
})
$GrpURLSrc.Controls.Add($BtnUrlRead)

# --- URLs aus der Basis-Domain erzeugen (Exchange-Standardpfade) ----------
$BtnUrlBuild.Add_Click({
    $r = Update-UrlFieldsFromDomain
    if ($r.Error) {
        $Global:LblUrlStatus.Text = $r.Error
        $Global:LblUrlStatus.ForeColor = $Global:ColorWarning
        [System.Windows.Forms.MessageBox]::Show($r.Error,(Get-T "Warning"),'OK','Warning')
        return
    }
    $msg = (Get-T "URL_Built") -f $r.Built
    $Global:LblUrlStatus.Text = $msg
    $Global:LblUrlStatus.ForeColor = $Global:ColorAccent2
    Write-Log $msg -Level SUCCESS
})

# Gleicher Domainname fuer intern und extern: externe Spalte wird gespiegelt
$Global:ChkUrlSameHost.Add_CheckedChanged({
    try {
        if ($Global:UrlUiLoading) { return }
        Set-UrlHostExtMirror -Mirror $Global:ChkUrlSameHost.Checked
        if (-not $Global:ChkUrlSameHost.Checked) { return }
        $r = Update-UrlFieldsFromDomain
        if (-not $r.Error -and $r.Built -gt 0) {
            $Global:LblUrlStatus.Text = (Get-T "URL_Built") -f $r.Built
            $Global:LblUrlStatus.ForeColor = $Global:ColorAccent2
        }
    } catch { Write-Log ("Error: " + $_) -Level ERROR }
})

# Tippen in der internen Domain aktualisiert die Tabelle sofort (wenn gespiegelt)
$Global:TxtUrlHostInt.Add_TextChanged({
    try {
        if ($Global:UrlUiLoading) { return }
        if (-not $Global:ChkUrlSameHost.Checked) { return }
        $v = "$($Global:TxtUrlHostInt.Text)".Trim()
        if ($Global:TxtUrlHostExt.Text -ne $v) { $Global:TxtUrlHostExt.Text = $v }
        if (-not (Test-UrlBaseDomain $v)) { return }
        $r = Update-UrlFieldsFromDomain
        if (-not $r.Error -and $r.Built -gt 0) {
            $Global:LblUrlStatus.Text = (Get-T "URL_Built") -f $r.Built
            $Global:LblUrlStatus.ForeColor = $Global:ColorAccent2
        }
    } catch { Write-Log ("Error: " + $_) -Level ERROR }
})

# ---------- Gruppe 3: URLs anwenden ----------
$GrpURLApply = New-GroupBox (Get-T "URL_Apply") 10 460 1080 68
$TabUrls.Controls.Add($GrpURLApply)
$LblUrlHelp = New-Label (Get-T "URL_Help") 340 24 720
$LblUrlHelp.ForeColor = $Global:ColorTextDim
$GrpURLApply.Controls.Add($LblUrlHelp)
$LblUrlHelp2 = New-Label (Get-T "URL_Help2") 340 44 720
$LblUrlHelp2.ForeColor = $Global:ColorWarning
$GrpURLApply.Controls.Add($LblUrlHelp2)
$BtnUrlApply = New-Button (Get-T "URL_Apply") 20 22 300 22 $Global:ColorAccent
$BtnUrlApply.Add_Click({
    try {
        $r = [System.Windows.Forms.MessageBox]::Show((Get-T "URL_Confirm"),(Get-T "Confirm"),'YesNo','Question')
        if ($r -ne "Yes") { return }
        $TabControl.SelectedTab = $TabRun
        [System.Windows.Forms.Application]::DoEvents()
        Write-Log "=== Applying URL configuration ===" -Level INFO
        $cfg = [PSCustomObject]@{}
        $any = $false
        foreach ($k in $Global:UrlFields.Keys) {
            $i = Get-UrlFieldValue -Key $k -Side Internal
            $e = Get-UrlFieldValue -Key $k -Side External
            if (($k -ne "PS") -and ($i -or $e)) { $any = $true }
            $cfg | Add-Member -NotePropertyName $k -NotePropertyValue ([PSCustomObject]@{ Internal=$i; External=$e })
        }
        if (-not $any) {
            $TabControl.SelectedTab = $TabUrls
            [System.Windows.Forms.MessageBox]::Show((Get-T "URL_Empty"),(Get-T "Warning"),'OK','Warning')
            return
        }
        $ok = Set-ExchangeUrlConfiguration -Config $cfg
        $svcTotal = $Global:UrlFields.Keys.Count - 1   # ohne PowerShell (bleibt Setup-Standard)
        $Global:LblUrlStatus.Text = if ($ok) { (Get-T "URL_Applied") -f $svcTotal, $svcTotal } else { "URLs partially applied - see log" }
        $Global:LblUrlStatus.ForeColor = if ($ok) { $Global:ColorAccent2 } else { $Global:ColorWarning }
        $TabControl.SelectedTab = $TabUrls
    } catch { Write-Log ("Error: " + $_) -Level ERROR }
})
$GrpURLApply.Controls.Add($BtnUrlApply)

# ---------- TAB: ZERTIFIKATE (eigener Reiter, volle Fensterhoehe) ----------
# Statt Einer Gruppe (284 px, klebte weit oben in der GUI) jetzt drei Gruppen,
# die die TabPage bis unten ausfuellen (Design-Hoehe ~585 px):
# Status (oben), Parameter (Mitte), Aktionen (unten).
$GrpCertInfo = New-GroupBox (Get-T "Cert_Title") 10 6 1080 124
$TabCert.Controls.Add($GrpCertInfo)

# Zertifikats-Status (bis 3 Zeilen: Subject + Gueltigkeit/Thumbprint)
$Global:LblCertStatus = New-Label (Get-T "Cert_NoCert") 20 30 850 $Global:FontDefault
$Global:LblCertStatus.AutoSize=$false
$Global:LblCertStatus.Size=New-Object System.Drawing.Size(850,76)
$Global:LblCertStatus.ForeColor = $Global:ColorTextDim
$Global:LblCertStatus.AutoEllipsis = $true
$GrpCertInfo.Controls.Add($Global:LblCertStatus)

$BtnCertRefresh = New-Button (Get-T "PrereqRefresh") 880 28 180 30 $Global:ColorAccent
$BtnCertRefresh.Add_Click({
    $st = Get-ExchangeCertificateStatus
    if ($st.Found) {
        $Global:LblCertStatus.Text = $st.Subject + "`r`n" + $st.NotAfter + " | " + $st.Thumbprint
        $Global:LblCertStatus.ForeColor = $Global:ColorAccent2
    } else {
        $Global:LblCertStatus.Text = (Get-T "Cert_NoCert")
        $Global:LblCertStatus.ForeColor = $Global:ColorTextDim
    }
})
$GrpCertInfo.Controls.Add($BtnCertRefresh)

# ---------- Gruppe: Parameter (Modus, PFX, Eigenschaften, SAN) ----------
$GrpCertNew = New-GroupBox (Get-T "Cert_GrpNew") 10 136 1080 300
$TabCert.Controls.Add($GrpCertNew)

# Modusauswahl - 3 Optionen nebeneinander (DE-Textbreiten gemessen: 204/239/195 px)
$Global:RbCertImport = New-Object System.Windows.Forms.RadioButton
$Global:RbCertImport.Text=(Get-T "Cert_RbImport")
$Global:RbCertImport.Location=New-Object System.Drawing.Point(15,22); $Global:RbCertImport.Size=New-Object System.Drawing.Size(235,22)
$Global:RbCertImport.Checked=$true; $Global:RbCertImport.BackColor=[System.Drawing.Color]::Transparent
$GrpCertNew.Controls.Add($Global:RbCertImport)

$Global:RbCertADCS = New-Object System.Windows.Forms.RadioButton
$Global:RbCertADCS.Text=(Get-T "Cert_RbADCS")
$Global:RbCertADCS.Location=New-Object System.Drawing.Point(255,22); $Global:RbCertADCS.Size=New-Object System.Drawing.Size(270,22)
$Global:RbCertADCS.BackColor=[System.Drawing.Color]::Transparent
$GrpCertNew.Controls.Add($Global:RbCertADCS)

$Global:RbCertSelf = New-Object System.Windows.Forms.RadioButton
$Global:RbCertSelf.Text=(Get-T "Cert_RbSelf")
$Global:RbCertSelf.Location=New-Object System.Drawing.Point(535,22); $Global:RbCertSelf.Size=New-Object System.Drawing.Size(230,22)
$Global:RbCertSelf.BackColor=[System.Drawing.Color]::Transparent
$GrpCertNew.Controls.Add($Global:RbCertSelf)

# Import-Controls
$GrpCertNew.Controls.Add( (New-Label (Get-T "Cert_Pfx") 20 57 95) )
$Global:TxtCertPfx = New-TextBox 120 56 480
$GrpCertNew.Controls.Add($Global:TxtCertPfx)
$BtnCertBrowse = New-Button (Get-T "Cert_Browse") 610 55 150 26 $Global:ColorAccent
$BtnCertBrowse.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "PKCS#12 (*.pfx;*.p12)|*.pfx;*.p12|PFX (*.pfx)|*.pfx|All files (*.*)|*.*"
    if ($ofd.ShowDialog() -eq "OK") { $Global:TxtCertPfx.Text = $ofd.FileName }
})
$GrpCertNew.Controls.Add($BtnCertBrowse)

$GrpCertNew.Controls.Add( (New-Label (Get-T "Cert_Pass") 20 89 95) )
$Global:TxtCertPass = New-Object System.Windows.Forms.TextBox
$Global:TxtCertPass.Location=New-Object System.Drawing.Point(120,88)
$Global:TxtCertPass.Size=New-Object System.Drawing.Size(300,22)
$Global:TxtCertPass.UseSystemPasswordChar=$true
$Global:TxtCertPass.BackColor=$Global:ColorInputBg; $Global:TxtCertPass.ForeColor=$Global:ColorText
$Global:TxtCertPass.BorderStyle="FixedSingle"; $Global:TxtCertPass.Font=$Global:FontDefault
$GrpCertNew.Controls.Add($Global:TxtCertPass)

# Selbstsigniert-/AD-CS-Controls
$GrpCertNew.Controls.Add( (New-Label (Get-T "Cert_CN") 440 89 110) )
$Global:TxtCertCN = New-TextBox 555 88 190 "mail"
$GrpCertNew.Controls.Add($Global:TxtCertCN)
$GrpCertNew.Controls.Add( (New-Label (Get-T "Cert_Days") 765 89 105) )
$Global:NumCertDays = New-NumericUpDown 875 88 80 1 3650 1095
$GrpCertNew.Controls.Add($Global:NumCertDays)
$GrpCertNew.Controls.Add( (New-Label (Get-T "Cert_Key") 20 121 110) )
$Global:CmbCertKey = New-Object System.Windows.Forms.ComboBox
$Global:CmbCertKey.Location=New-Object System.Drawing.Point(135,120); $Global:CmbCertKey.Size=New-Object System.Drawing.Size(90,22)
$Global:CmbCertKey.DropDownStyle="DropDownList"
$Global:CmbCertKey.Items.AddRange(@("1024","2048","4096")) | Out-Null
$Global:CmbCertKey.SelectedIndex=1
$Global:CmbCertKey.BackColor=$Global:ColorInputBg; $Global:CmbCertKey.ForeColor=$Global:ColorText
$GrpCertNew.Controls.Add($Global:CmbCertKey)

$Global:ChkCertActivate = New-CheckBox (Get-T "Cert_Activate") 250 119 320 $true
$GrpCertNew.Controls.Add($Global:ChkCertActivate)

# CA-Template (nur Modus "AD-Zertifikatsstelle") - rechts in derselben Zeile
$GrpCertNew.Controls.Add( (New-Label (Get-T "Cert_Template") 580 121 85) )
$Global:TxtCertTemplate = New-TextBox 670 120 190 "WebServer"
$GrpCertNew.Controls.Add($Global:TxtCertTemplate)

# CA-Kennung (nur Modus "AD-Zertifikatsstelle"): Standalone-CAs sind in AD nicht
# registriert (nur Enterprise CAs fuellen CN=Enrollment Services), deshalb hier
# manuell SERVER\CA-Name eintragen; leer = automatische Suche in AD
$GrpCertNew.Controls.Add( (New-Label (Get-T "Cert_CA") 868 121 42) )
$Global:TxtCertCA = New-TextBox 912 120 143
$GrpCertNew.Controls.Add($Global:TxtCertCA)
$Global:CertTip = New-Object System.Windows.Forms.ToolTip
$Global:CertTip.SetToolTip($Global:TxtCertCA, (Get-T "Cert_CATip"))

# SAN-Feld (eine Zeile pro Name) - gross ueber die linke Spalte
$GrpCertNew.Controls.Add( (New-Label (Get-T "Cert_San") 20 153 110 $Global:FontBold) )
$Global:TxtCertSAN = New-Object System.Windows.Forms.TextBox
$Global:TxtCertSAN.Location=New-Object System.Drawing.Point(135,152)
$Global:TxtCertSAN.Size=New-Object System.Drawing.Size(750,112)
$Global:TxtCertSAN.Multiline=$true; $Global:TxtCertSAN.ScrollBars="Vertical"
$Global:TxtCertSAN.Font=$Global:FontMono
$Global:TxtCertSAN.BackColor=$Global:ColorInputBg; $Global:TxtCertSAN.ForeColor=$Global:ColorText
$Global:TxtCertSAN.BorderStyle="FixedSingle"
$GrpCertNew.Controls.Add($Global:TxtCertSAN)

# SAN aus Domain und den konfigurierten URL-Basen ableiten
$BtnCertSan = New-Button (Get-T "Cert_FillSan") 895 152 165 26 $Global:ColorAccent
$BtnCertSan.Add_Click({
    $sans = @(Get-DefaultSanNames)
    $bases = @()
    try { $bases += "$($Global:TxtUrlHostInt.Text)" } catch {}
    try { $bases += "$($Global:TxtUrlHostExt.Text)" } catch {}
    foreach ($h in $bases) {
        $hv = ("$h".Trim() -replace '^[A-Za-z]+://','' -split '/')[0].Trim()
        if ($hv -match '^[A-Za-z0-9][A-Za-z0-9\.\-]*\.[A-Za-z]+$') { $sans += $hv }
    }
    $sans = @($sans | Where-Object { $_ } | Sort-Object -Unique)
    if ($sans.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show((Get-T "Cert_SanEmpty"),(Get-T "Warning"),'OK','Warning'); return }
    $Global:TxtCertSAN.Text = ($sans -join "`r`n")
})
$GrpCertNew.Controls.Add($BtnCertSan)

$LH3 = New-Label "Ein Name pro Zeile (FQDN), z. B. mail.contoso.local" 895 186 165
$LH3.ForeColor = $Global:ColorTextDim
$LH3.AutoSize=$false
$LH3.Size=New-Object System.Drawing.Size(165,70)
$GrpCertNew.Controls.Add($LH3)

# ---------- Gruppe: Aktionen ----------
$GrpCertAct = New-GroupBox (Get-T "Cert_GrpAct") 10 442 1080 132
$TabCert.Controls.Add($GrpCertAct)

$BtnCertImport = New-Button (Get-T "Cert_ImportBtn") 20 30 320 40 $Global:ColorAccent2
$BtnCertImport.Add_Click({
    $dlg = Show-CertificateImportDialog
    if (-not $dlg) { return }
    $TabControl.SelectedTab = $TabRun
    [System.Windows.Forms.Application]::DoEvents()
    Write-Log "=== Importing certificate ===" -Level INFO
    $ok = Import-ExchangeCertificateFile -Path $dlg.Path -Password $dlg.Password -Services $dlg.Services
    $TabControl.SelectedTab = $TabCert
    if ($ok) {
        $st = Get-ExchangeCertificateStatus
        $Global:LblCertStatus.Text = (Get-T "Cert_Active") -f @($st.Subject, $st.NotAfter, $st.Thumbprint)
        $Global:LblCertStatus.ForeColor = $Global:ColorAccent2
    }
})
$GrpCertAct.Controls.Add($BtnCertImport)

$BtnCertCreate = New-Button (Get-T "Cert_Create") 360 30 320 40 $Global:ColorAccent
$BtnCertCreate.Add_Click({
    try {
        $sans = @($Global:TxtCertSAN.Text.Split("`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        if ($sans.Count -eq 0) { $sans = @(Get-DefaultSanNames) }
        if ($sans.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show((Get-T "Cert_SanEmpty"),(Get-T "Warning"),'OK','Warning'); return
        }
        $r = [System.Windows.Forms.MessageBox]::Show(($sans -join "`r`n") + "`r`n`r`nCreate certificate?",(Get-T "Confirm"),'YesNo','Question')
        if ($r -ne "Yes") { return }
        $TabControl.SelectedTab = $TabRun
        [System.Windows.Forms.Application]::DoEvents()

        $keySize = 2048
        try { $keySize = [int]$Global:CmbCertKey.SelectedItem } catch {}
        $days = [int]$Global:NumCertDays.Value
        $useADCS = $Global:RbCertADCS.Checked

        Write-Log "=== Creating certificate ===" -Level INFO
        if ($useADCS) {
            Write-Log "Certificate mode: AD-CS (request at the enterprise CA)" -Level INFO
        } else {
            Write-Log "Certificate mode: self-signed" -Level INFO
            if ($Global:RbCertImport.Checked) {
                Write-Log "Import (PFX) mode is selected - 'Create' still produces a self-signed certificate; use 'Import from file' for an existing PFX or select the AD-CS mode" -Level WARNING
            }
        }
        $cert = $null
        if ($useADCS) {
            $svcs = if ($Global:ChkCertActivate.Checked) { @("IIS","SMTP","IMAP","POP") } else { @() }
            $cert = New-ExchangeADCertificate -DnsName $sans -FriendlyName $Global:TxtCertCN.Text -KeySize $keySize -Services $svcs -Template "$($Global:TxtCertTemplate.Text)" -CAConfig "$($Global:TxtCertCA.Text)"
        } else {
            $subject = "CN=" + $Global:TxtCertCN.Text.Trim()
            $cert = New-ExchangeSelfSignedCertificate -DnsName $sans -FriendlyName $Global:TxtCertCN.Text.Trim() -ValidDays $days -KeySize $keySize -Subject $subject
            if ($cert -and $Global:ChkCertActivate.Checked) {
                $svcs = @("IIS","SMTP","IMAP","POP")
                Publish-SelfSignedCertificateToExchange -Certificate $cert -Services $svcs -Password $Global:TxtCertPass.Text | Out-Null
            }
        }
        $TabControl.SelectedTab = $TabCert
        if ($cert) {
            $st = Get-ExchangeCertificateStatus
            # Format-Ausdruck EINMAL vorberechnen und mit @(...) bilden: als
            # Argument der MessageBox::Show waere "X -f a, b, c" durch die
            # Kommata der Argumentliste zerrissen - nur das erste Operand erreicht
            # -f, {1} bekam keinen Wert und es endete mit "Der Index ... muss ...
            # kleiner als die Groesse der Argumentenliste sein"; ausserdem waeren
            # Titel- und Icon-Argumente in den Format-Ausdruck gewandert.
            $statusText = (Get-T "Cert_Active") -f @($st.Subject, $st.NotAfter, $st.Thumbprint)
            $Global:LblCertStatus.Text = $statusText
            $Global:LblCertStatus.ForeColor = $Global:ColorAccent2
            [System.Windows.Forms.MessageBox]::Show($statusText, (Get-T "Info"), 'OK', 'Information')
        }
    } catch { Write-Log ("Error: " + $_) -Level ERROR }
})
$GrpCertAct.Controls.Add($BtnCertCreate)

$BtnCertEnable = New-Button (Get-T "Cert_Enable") 700 30 340 40 $Global:ColorAccent2
$BtnCertEnable.Add_Click({
    $st = Get-ExchangeCertificateStatus
    if (-not $st.Found) { [System.Windows.Forms.MessageBox]::Show((Get-T "Cert_NoCert"),(Get-T "Warning"),'OK','Warning'); return }
    $r = [System.Windows.Forms.MessageBox]::Show(($st.Subject) + "`r`n`r`n" + (Get-T "Cert_Enable") + "?",(Get-T "Confirm"),'YesNo','Question')
    if ($r -ne "Yes") { return }
    $TabControl.SelectedTab = $TabRun
    [System.Windows.Forms.Application]::DoEvents()
    Enable-ExchangeCertificateServices -Thumbprint $st.Thumbprint -Services @("IIS","SMTP","IMAP","POP") | Out-Null
    $TabControl.SelectedTab = $TabCert
})
$GrpCertAct.Controls.Add($BtnCertEnable)

$CertHint = New-Label (Get-T "Cert_Hint") 20 84 1040
$CertHint.ForeColor = $Global:ColorTextDim
$CertHint.AutoSize=$false
$CertHint.Size=New-Object System.Drawing.Size(1040,44)
$GrpCertAct.Controls.Add($CertHint)
#endregion

#region ============================ TAB: AUSFUEHRUNG & LOG ============================
$LblRun = New-Label (Get-T "Run_Info") 10 10 1080 $Global:FontBold
$TabRun.Controls.Add($LblRun)

$Global:LogTextBox = New-Object System.Windows.Forms.RichTextBox
$Global:LogTextBox.Location=New-Object System.Drawing.Point(10,40)
$Global:LogTextBox.Size=New-Object System.Drawing.Size(1080,355)
$Global:LogTextBox.BackColor=[System.Drawing.Color]::White
$Global:LogTextBox.ForeColor=$Global:ColorText
$Global:LogTextBox.Font=$Global:FontMono; $Global:LogTextBox.ReadOnly=$true
$Global:LogTextBox.BorderStyle="FixedSingle"
$TabRun.Controls.Add($Global:LogTextBox)

# === Fortschritt der Exchange-Installation ===
$Global:LblSetupPhase = New-Label ((Get-T "Run_ProgressLabel") + ":  " + (Get-T "Ready")) 10 400 1080 $Global:FontBold
$TabRun.Controls.Add($Global:LblSetupPhase)

$Global:PrgSetup = New-Object System.Windows.Forms.ProgressBar
$Global:PrgSetup.Location=New-Object System.Drawing.Point(10,422)
$Global:PrgSetup.Size=New-Object System.Drawing.Size(1080,18)
$Global:PrgSetup.Minimum=0; $Global:PrgSetup.Maximum=$Global:SetupPhaseCount; $Global:PrgSetup.Value=0
$TabRun.Controls.Add($Global:PrgSetup)

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
            Version = "1.4"
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
                HighPerf=$Global:ChkSetHighPerf.Checked; NicPower=$Global:ChkDisableNicPower.Checked
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
                Content=$Global:ChkContent.Checked; SenderID=$false
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
            URLs = @{
                Set=$Global:ChkSetUrls.Checked
                Host_I=$Global:TxtUrlHostInt.Text
                Host_E=$Global:TxtUrlHostExt.Text
                SameHost=[bool]$Global:ChkUrlSameHost.Checked
                OWA_I=(Get-UrlFieldValue -Key "OWA" -Side Internal);  OWA_E=(Get-UrlFieldValue -Key "OWA" -Side External)
                ECP_I=(Get-UrlFieldValue -Key "ECP" -Side Internal);  ECP_E=(Get-UrlFieldValue -Key "ECP" -Side External)
                EWS_I=(Get-UrlFieldValue -Key "EWS" -Side Internal);  EWS_E=(Get-UrlFieldValue -Key "EWS" -Side External)
                AS_I=(Get-UrlFieldValue -Key "AS" -Side Internal);    AS_E=(Get-UrlFieldValue -Key "AS" -Side External)
                PS_I=(Get-UrlFieldValue -Key "PS" -Side Internal);    PS_E=(Get-UrlFieldValue -Key "PS" -Side External)
                AD_I=(Get-UrlFieldValue -Key "AD" -Side Internal);    AD_E=(Get-UrlFieldValue -Key "AD" -Side External)
                MAPI_I=(Get-UrlFieldValue -Key "MAPI" -Side Internal); MAPI_E=(Get-UrlFieldValue -Key "MAPI" -Side External)
                OAB_I=(Get-UrlFieldValue -Key "OAB" -Side Internal);  OAB_E=(Get-UrlFieldValue -Key "OAB" -Side External)
            }
            Cert = @{
                Mode=$(if ($Global:RbCertADCS.Checked) { "ADCS" } elseif ($Global:RbCertSelf.Checked) { "SelfSigned" } else { "Import" })
                CN=$Global:TxtCertCN.Text; Days=[int]$Global:NumCertDays.Value
                KeySize=$(if ($Global:CmbCertKey.SelectedItem) { "$($Global:CmbCertKey.SelectedItem)" } else { "2048" })
                SANs=@($Global:TxtCertSAN.Text.Split("`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ })
                PfxPath=$Global:TxtCertPfx.Text
                Activate=$Global:ChkCertActivate.Checked
                Template=$Global:TxtCertTemplate.Text
                CA=$Global:TxtCertCA.Text
            }
        }
        foreach ($k in $Global:Checks.Keys) { $cfg.Options[$k] = $Global:Checks[$k].Checked }
        $cfg | ConvertTo-Json -Depth 8 | Set-Content $Global:ConfigFile -Encoding UTF8 -ErrorAction Stop

        Write-Log "===========================================" -Level SUCCESS
        Write-Log " CONFIG SAVED" -Level SUCCESS
        Write-Log ("  File: " + $Global:ConfigFile) -Level INFO
        Write-Log ("  Databases: " + $dbList.Count) -Level INFO
        Write-Log ("  DAG members: " + $dagMembers.Count) -Level INFO
        Write-Log "===========================================" -Level SUCCESS

        $urlSaved = 0
        foreach ($k in $Global:UrlFields.Keys) {
            if ((Get-UrlFieldValue -Key $k -Side Internal) -or (Get-UrlFieldValue -Key $k -Side External)) { $urlSaved++ }
        }
        [System.Windows.Forms.MessageBox]::Show(
            "Config saved!`r`nFile: $Global:ConfigFile`r`nDBs: $($dbList.Count)`r`nDAG-Members: $($dagMembers.Count)`r`nURL-Services: $urlSaved",
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
            # NicPower fehlt in alten Configs - nur uebernehmen, wenn vorhanden,
            # sonst wuerde das Laden eine alte Config die Vorauswahl loeschen
            if ($cfg.Prereq.PSObject.Properties['NicPower']) {
                $Global:ChkDisableNicPower.Checked=[bool]$cfg.Prereq.NicPower
            }
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
            $Global:ChkSenderID.Checked=$false
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
        $urlCount = 0
        if ($cfg.URLs) {
            $Global:UrlUiLoading = $true
            try {
                $Global:ChkSetUrls.Checked=[bool]$cfg.URLs.Set
                # Basis-Domain + Spiegel-Haekchen (vor den URL-Spalten, damit alte
                # Konfigurationen ohne diese Felder weiterhin laden)
                $uProps = $cfg.URLs.PSObject.Properties
                if ($uProps['Host_I']) { $Global:TxtUrlHostInt.Text="$($cfg.URLs.Host_I)" }
                if ($uProps['SameHost']) { $Global:ChkUrlSameHost.Checked=[bool]$cfg.URLs.SameHost }
                if ($uProps['Host_E']) { $Global:TxtUrlHostExt.Text="$($cfg.URLs.Host_E)" }
                Set-UrlHostExtMirror -Mirror $Global:ChkUrlSameHost.Checked
                $urlMap = @{
                    "OWA"=@("OWA_I","OWA_E"); "ECP"=@("ECP_I","ECP_E"); "EWS"=@("EWS_I","EWS_E")
                    "AS"=@("AS_I","AS_E"); "PS"=@("PS_I","PS_E"); "AD"=@("AD_I","AD_E")
                    "MAPI"=@("MAPI_I","MAPI_E"); "OAB"=@("OAB_I","OAB_E")
                }
                foreach ($k in $urlMap.Keys) {
                    if (-not $Global:UrlFields.Contains($k)) { continue }
                    $gi = $urlMap[$k][0]; $ge = $urlMap[$k][1]
                    $vi = "$($cfg.URLs.$gi)"; $ve = "$($cfg.URLs.$ge)"
                    if ($vi -or $ve) { $urlCount++ }
                    Set-UrlFieldValue -Key $k -Side Internal -Value $vi
                    Set-UrlFieldValue -Key $k -Side External -Value $ve
                }
            } finally { $Global:UrlUiLoading = $false }
        }
        if ($cfg.Cert) {
            $mode = "$($cfg.Cert.Mode)"
            if ($mode -eq "ADCS") { $Global:RbCertADCS.Checked=$true }
            elseif ($mode -eq "SelfSigned") { $Global:RbCertSelf.Checked=$true }
            else { $Global:RbCertImport.Checked=$true }
            if ($cfg.Cert.CN) { $Global:TxtCertCN.Text="$($cfg.Cert.CN)" }
            try { $Global:NumCertDays.Value=[int]$cfg.Cert.Days } catch {}
            if ($cfg.Cert.KeySize) {
                $ki = $Global:CmbCertKey.Items.IndexOf("$($cfg.Cert.KeySize)")
                if ($ki -ge 0) { $Global:CmbCertKey.SelectedIndex=$ki }
            }
            if ($cfg.Cert.SANs) {
                $sanList = @($cfg.Cert.SANs | Where-Object { $_ })
                $Global:TxtCertSAN.Text = ($sanList -join "`r`n")
            }
            if ($cfg.Cert.PfxPath) { $Global:TxtCertPfx.Text="$($cfg.Cert.PfxPath)" }
            if ($cfg.Cert.Template) { $Global:TxtCertTemplate.Text="$($cfg.Cert.Template)" }
            if ($cfg.Cert.CA) { $Global:TxtCertCA.Text="$($cfg.Cert.CA)" }
            $Global:ChkCertActivate.Checked=[bool]$cfg.Cert.Activate
        }

        Write-Log ("  DBs loaded: " + $dbCount) -Level INFO
        Write-Log ("  DAG members: " + $dagMC) -Level INFO
        Write-Log ("  URL services: " + $urlCount) -Level INFO
        Write-Log "===========================================" -Level SUCCESS
        [System.Windows.Forms.MessageBox]::Show("Config loaded!`r`nDBs: $dbCount`r`nDAG-Members: $dagMC`r`nURL-Services: $urlCount",(Get-T "Info"),'OK','Information')
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
        $Global:ISOMountedByScript = $false

        # ISO ermitteln - die ISO-Datei wird IMMER gemountet, wenn ein Schritt sie
        # benoetigt (Voraussetzungen/UCMA, AD-Vorbereitung, Exchange-Installation).
        # Die fruehere Option "ISO automatisch mounten" gibt es dafuer nicht mehr.
        $needsIso = ($Global:Checks["RunPrereqInstall"].Checked -or
                     $Global:Checks["DoADPrep"].Checked -or
                     $Global:Checks["InstallExchange"].Checked)
        if ($Global:RbISOMounted.Checked -and $Global:CmbMountedDrives.SelectedIndex -ge 0 -and $Global:DetectedISOs.Count -gt 0) {
            $ExchangeSetupPath = $Global:DetectedISOs[$Global:CmbMountedDrives.SelectedIndex].SetupPath
            if (Test-Path "$ExchangeSetupPath") {
                Write-Log ("ISO source: " + $ExchangeSetupPath) -Level SUCCESS
            } else {
                # Auswahl evtl. stale: nach jedem Lauf dismountet das Skript die ISO
                # selbst - dann die ISO-Datei (falls hinterlegt) frisch mounten.
                Write-Log ("Selected mounted drive no longer available: " + $ExchangeSetupPath) -Level WARNING
                $ExchangeSetupPath = $null
            }
        }
        if (-not $ExchangeSetupPath -and $Global:TxtISO.Text -and $needsIso) {
            Write-Log ("Mounting ISO: " + $Global:TxtISO.Text) -Level INFO
            $ExchangeSetupPath = Mount-ExchangeISO -ISOPath $Global:TxtISO.Text
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
                -SetHighPerformance $Global:ChkSetHighPerf.Checked `
                -DisableNicPower $Global:ChkDisableNicPower.Checked
        }

        # SCHRITT 2: TLS-Hardening
        if ($Global:Checks["ApplyTLS"].Checked) {
            Write-Log "--- STEP 2: TLS Hardening ---" -Level INFO
            Set-TLSHardening | Out-Null
        }

        # SCHRITT 2.5: AD-Vorbereitung
        if ($Global:Checks["DoADPrep"].Checked -and ($Global:ChkPrepSchema.Checked -or $Global:ChkPrepAD.Checked -or $Global:ChkPrepDom.Checked)) {
            Write-Log "--- STEP 2.5: AD Preparation ---" -Level INFO
            $Global:AdPrepExecuted = @()   # neuer Lauf - Ausfuehrungsliste fuer den Report zuruecksetzen
            if (-not $ExchangeSetupPath) { Write-Log "No setup path - AD prep skipped" -Level WARNING }
            else {
                $waitMin = [int]$Global:NumWaitMin.Value
                $adAbort = $false
                if ($Global:ChkPrepSchema.Checked -and -not $adAbort) {
                    $ok = Invoke-ExchangePrepareStep -SetupPath $ExchangeSetupPath -Step "PrepareSchema"
                    if (-not $ok) {
                        Write-Log "AD-Vorbereitung ABGEBROCHEN nach PrepareSchema." -Level ERROR
                        if (-not $continueOnError) { Write-Log "Aborted (PrepareSchema failed)" -Level ERROR; return }
                        $adAbort = $true
                    } elseif ($waitMin -gt 0) { Wait-ADReplication -Minutes $waitMin }
                }
                if ($Global:ChkPrepAD.Checked -and -not $adAbort) {
                    $ok = Invoke-ExchangePrepareStep -SetupPath $ExchangeSetupPath -Step "PrepareAD" -OrgName $Global:TxtOrg.Text
                    if (-not $ok) {
                        Write-Log "AD-Vorbereitung ABGEBROCHEN nach PrepareAD." -Level ERROR
                        if (-not $continueOnError) { Write-Log "Aborted (PrepareAD failed)" -Level ERROR; return }
                        $adAbort = $true
                    } elseif ($waitMin -gt 0) { Wait-ADReplication -Minutes $waitMin }
                }
                if ($Global:ChkPrepDom.Checked -and -not $adAbort) {
                    $okDom = $true
                    if ($Global:RbAllDomains.Checked) {
                        $okDom = Invoke-ExchangePrepareStep -SetupPath $ExchangeSetupPath -Step "PrepareAllDomains"
                    } elseif ($Global:RbSingleDomain.Checked -and $Global:CmbDomainList.SelectedItem) {
                        $okDom = Invoke-ExchangePrepareStep -SetupPath $ExchangeSetupPath -Step "PrepareDomain" -DomainName ($Global:CmbDomainList.SelectedItem.ToString())
                    }
                    if (-not $okDom) {
                        Write-Log "AD-Vorbereitung ABGEBROCHEN nach Domain-Prep." -Level ERROR
                        if (-not $continueOnError) { Write-Log "Aborted (PrepareDomain failed)" -Level ERROR; return }
                    }
                }
            }

            # === Automatischer Ergebnis-Check nach der Adprep ===
            $adResult = & $Global:Script:RunAdPrepCheck
            if ($adResult) { Update-ADPrepResultLabels -Result $adResult }
        }

        # SCHRITT 3: Exchange Setup
        if ($Global:Checks["InstallExchange"].Checked -and -not $ExchangeSetupPath) {
            Write-Log "--- STEP 3: Exchange Setup --- SKIPPED: no setup path (ISO source missing or not mountable)" -Level ERROR
            if (-not $continueOnError) { return }
        }

        # AD-Freigabe-Pruefung - Exchange wird nur installiert, wenn die AD-Vorbereitung
        # alle Pruefpunkte erfuellt. Ein unvollstaendig vorbereitetes AD laesst das Setup
        # spaeter abbrechen oder hinterlaesst eine kaputte Organisation.
        if ($Global:Checks["InstallExchange"].Checked) {
            Write-Log "--- STEP 3: AD preparation gate ---" -Level INFO
            $adGate = Test-ADPrepResult
            if (-not $adGate) {
                Write-Log "Exchange installation BLOCKED: AD status could not be verified (see log above)." -Level ERROR
                [System.Windows.Forms.MessageBox]::Show((Get-T "AD_CheckUnknown"),(Get-T "Error"),'OK','Error')
                return
            }
            if (-not $adGate.AllOK) {
                $gateFailed = @($adGate.Results | Where-Object { -not $_.OK } | ForEach-Object { $_.Item })
                Write-Log ("Exchange installation BLOCKED: AD preparation incomplete (" + $adGate.FailedCount + " of " + $adGate.TotalCount + " checks NOT OK)") -Level ERROR
                foreach ($n in $gateFailed) { Write-Log ("  NOT OK: $n") -Level ERROR }
                $gateMsg = (Get-T "AD_InstallBlocked") -f $adGate.FailedCount, $adGate.TotalCount
                $gateMsg += "`r`n`r`n" + ($gateFailed -join "`r`n")
                [System.Windows.Forms.MessageBox]::Show($gateMsg,(Get-T "Error"),'OK','Error')
                return
            }
            Write-Log ("AD preparation gate: " + $adGate.TotalCount + " of " + $adGate.TotalCount + " checks OK - installation allowed") -Level SUCCESS
            Update-ADPrepResultLabels -Result $adGate
            Update-ADStatusDisplay
        }

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
                    -AcceptDiagnosticData $Global:ChkDiagData.Checked `
                    -TargetDir $Global:TxtInstallPath.Text
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

        # SCHRITT 6.5: Zertifikat (importieren oder selbstsigniert erzeugen)
        if ($Global:Checks["CreateCertificate"].Checked) {
            Write-Log "--- STEP 6.5: Certificate ---" -Level INFO
            try {
                if (Import-ExchangeManagementShell) {
                    if ($Global:RbCertImport.Checked) {
                        $dlg = Show-CertificateImportDialog
                        if ($dlg) {
                            Import-ExchangeCertificateFile -Path $dlg.Path -Password $dlg.Password -Services $dlg.Services | Out-Null
                        } else {
                            Write-Log "Certificate import cancelled by user" -Level WARNING
                        }
                    } else {
                        $sans = @($Global:TxtCertSAN.Text.Split("`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ })
                        if ($sans.Count -eq 0) { $sans = @(Get-DefaultSanNames) }
                        if ($sans.Count -eq 0) {
                            Write-Log (Get-T "Cert_SanEmpty") -Level ERROR
                        } else {
                            $keySize = 2048
                            try { $keySize = [int]$Global:CmbCertKey.SelectedItem } catch {}
                            $days = [int]$Global:NumCertDays.Value
                            $svcs = if ($Global:ChkCertActivate.Checked) { @("IIS","SMTP","IMAP","POP") } else { @() }
                            $cert = $null
                            if ($Global:RbCertADCS.Checked) {
                                Write-Log "Certificate mode: AD-CS (request at the enterprise CA)" -Level INFO
                                $cert = New-ExchangeADCertificate -DnsName $sans -FriendlyName $Global:TxtCertCN.Text -KeySize $keySize -Services $svcs -Template "$($Global:TxtCertTemplate.Text)" -CAConfig "$($Global:TxtCertCA.Text)"
                            } else {
                                Write-Log "Certificate mode: self-signed" -Level INFO
                                $cert = New-ExchangeSelfSignedCertificate -DnsName $sans -FriendlyName $Global:TxtCertCN.Text -ValidDays $days -KeySize $keySize -Subject ("CN=" + $Global:TxtCertCN.Text.Trim())
                                if ($cert -and $svcs.Count -gt 0) {
                                    Publish-SelfSignedCertificateToExchange -Certificate $cert -Services $svcs -Password $Global:TxtCertPass.Text | Out-Null
                                }
                            }
                            $st = Get-ExchangeCertificateStatus
                            if ($st.Found) {
                                $Global:LblCertStatus.Text = $st.Subject + "`r`n" + $st.NotAfter + " | " + $st.Thumbprint
                                $Global:LblCertStatus.ForeColor = $Global:ColorAccent2
                            }
                        }
                    }
                }
            } catch { Write-Log ("Certificate error: " + $_) -Level ERROR }
        }

        # SCHRITT 6.7: URLs setzen
        if ($Global:Checks["SetUrls"].Checked) {
            Write-Log "--- STEP 6.7: Set URLs ---" -Level INFO
            try {
                if (Import-ExchangeManagementShell) {
                    $urlCfg = [PSCustomObject]@{}
                    $anyUrl = $false
                    foreach ($k in $Global:UrlFields.Keys) {
                        $i = Get-UrlFieldValue -Key $k -Side Internal
                        $e = Get-UrlFieldValue -Key $k -Side External
                        if (($k -ne "PS") -and ($i -or $e)) { $anyUrl = $true }
                        $urlCfg | Add-Member -NotePropertyName $k -NotePropertyValue ([PSCustomObject]@{ Internal=$i; External=$e })
                    }
                    if ($anyUrl) {
                        Set-ExchangeUrlConfiguration -Config $urlCfg | Out-Null
                    } else {
                        Write-Log (Get-T "URL_Empty") -Level WARNING
                    }
                }
            } catch { Write-Log ("URL error: " + $_) -Level ERROR }
        }

        # SCHRITT 7: DBs - DIREKT aufrufen: Button.PerformClick() feuert auf
        # einem nicht aktivem Tab nicht (CanSelect=false), wodurch im
        # kombinierten Lauf stillschweigend gar keine DBs angelegt wurden
        if ($Global:Checks["CreateDBs"].Checked) {
            Write-Log "--- STEP 7: Create databases ---" -Level INFO
            [void](Invoke-DatabaseCreation)
        }

        # SCHRITT 8: DAG - ebenso direkt statt PerformClick (gleicher Fehler)
        if ($Global:Checks["CreateDAG"].Checked) {
            Write-Log "--- STEP 8: DAG ---" -Level INFO
            [void](Invoke-DagCreation)
        }

        # SCHRITT 9: ISO unmount - IMMER, wenn das Skript die ISO selbst gemountet hat
        # (die fruehere Option "ISO am Ende automatisch unmounten" gibt es nicht mehr)
        Dismount-ScriptISO

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
    finally {
        # Sicherheitsnetz: auch bei Abbruch (return) oder Fehler nie ein Rest-Mount.
        # Auf dem Happy Path ist das Flag bereits unten geloescht -> kein zweiter Log-Eintrag.
        Dismount-ScriptISO
        # AD-Status am Ende jedes Laufs neu darstellen - auch wenn vorher abgebrochen
        # wurde (z. B. durch das AD-Freigabe-Gate) ohne manuellen Klick aktualisiert.
        Update-ADStatusDisplay
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

# Responsive: Felder/Steuerelemente bei jeder Formulargroesse mit skalieren (Vollbild etc.)
$Form.Add_Resize({ Update-ResponsiveLayout })
#endregion

#region ============================ FORM SHOWN - SPLASH AUTO-CHECK ============================
$Form.Add_Shown({
    try {
        Show-SplashScreen
        Write-Host "@@DIAG@@ [6/7] Splash-Fenster sichtbar? Shown-Handler laeuft" -ForegroundColor DarkGray

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
        Write-Host "@@DIAG@@ [7/7] System-Checks (OS/RAM) durch, jetzt ISO-Suche" -ForegroundColor DarkGray
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
        if (-not $prereqStatus.NicPowerSavingOK) { $issues += "NIC power saving active" }
        try { Update-PrerequisiteStatusDisplay; $Global:PrereqStatusLoaded = $true } catch {}
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

            # 5.1 Automatischer Ergebnis-Check der AD-Vorbereitung
            try {
                Update-SplashStatus (Get-T "AD_Check")
                $splashAdResult = Test-ADPrepResult
                if ($splashAdResult) {
                    Update-ADPrepResultLabels -Result $splashAdResult
                    if ($splashAdResult.AllOK) {
                        $info_items += "AD prep: all $($splashAdResult.TotalCount) checks OK"
                    } else {
                        $issues += "AD prep incomplete ($($splashAdResult.FailedCount)/$($splashAdResult.TotalCount) checks)"
                    }
                }
            } catch { Write-Log ("Splash AD result check failed: " + $_) -Level WARNING }
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

        # 6.1 Exchange-Serverliste fuellen + URLs automatisch aus dem bestehenden Exchange uebernehmen
        try { [void](Update-UrlServerList) } catch { Write-Log ("URL server list failed: " + $_) -Level WARNING }
        if ($exchInst) {
            try {
                Update-SplashStatus (Get-T "URL_Read")
                $srv = ""
                try { if ($Global:CmbUrlServer -and $Global:CmbUrlServer.SelectedItem) { $srv = "$($Global:CmbUrlServer.SelectedItem)" } } catch {}
                $urlCfg = Get-ExchangeUrlConfiguration -Server $srv
                if ($urlCfg -and $urlCfg.Found) {
                    foreach ($k in $Global:UrlFields.Keys) {
                        $entry = $urlCfg.$k
                        if (-not $entry) { continue }
                        # Snapshot: leere gelesene Werte loeschen alte Eintraege
                        Set-UrlFieldValue -Key $k -Side Internal -Value "$($entry.Internal)"
                        Set-UrlFieldValue -Key $k -Side External -Value "$($entry.External)"
                    }
                    $Global:LblUrlStatus.Text = (Get-T "URL_ReadOk") -f $urlCfg.FoundCount, $urlCfg.Server
                    $Global:LblUrlStatus.ForeColor = $Global:ColorAccent2
                    $info_items += "URLs: $($urlCfg.FoundCount) services read from existing Exchange"
                } else {
                    $Global:LblUrlStatus.Text = (Get-T "URL_NoExch")
                    $Global:LblUrlStatus.ForeColor = $Global:ColorTextDim
                }
            } catch { Write-Log ("URL pre-fill failed: " + $_) -Level WARNING }
        }
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
                if ($i -match "VC\+\+|\.NET|URL|UCMA|Win-Features|SMB1|NIC power saving") { $hasPrereqIssue = $true }
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
    Write-Log ("Microsoft Exchange SE Configuration Center v1.4 started") -Level INFO
    # Welche Kopie des Skripts laeuft? Eine laufende Sitzung laedt die Datei nur
    # einmal beim Start - Pfad + Aenderungszeit machen veraltete Stände (Sync,
    # gestartete Altinstanzen) in jedem Log sofort sichtbar.
    try {
        $sp = $MyInvocation.MyCommand.Path
        if (-not $sp) { $sp = $PSCommandPath }
        if ($sp) {
            Write-Log ("Script: $sp") -Level INFO
            $spFile = Get-Item -LiteralPath $sp -ErrorAction SilentlyContinue
            if ($spFile) { Write-Log ("Script last modified: " + $spFile.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")) -Level INFO }
        }
    } catch {}
    Write-Log ("Language: " + $Global:CurrentLang) -Level INFO
    Write-Log ("Log file: " + $Global:LogFile) -Level INFO
    Write-Host "@@DIAG@@ [5/7] vor ShowDialog (GUI-Fenster muss gleich erscheinen)" -ForegroundColor DarkGray
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
