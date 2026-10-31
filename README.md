# Exchange-Deployment-Automation-Tool

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)](https://www.microsoft.com/de-de/powershell)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Status: Production](https://img.shields.io/badge/Status-Production-brightgreen)
![Version: 1.5](https://img.shields.io/badge/Version-1.5-blue)

**Vollständig automatisierte Bereitstellung von Microsoft Exchange Server – unbeaufsichtigt und fehlerreduziert für Enterprise-Umgebungen. Inklusive Live-Fortschrittsanzeige der 14 Installationsphasen (je Setup-Task eine Zeile mit OK), URL-Übernahme vom bestehenden Exchange, Zertifikats-Center (Import / AD-CS / selbstsigniert mit SAN-Liste), automatischer AD-Prep-Ergebniskontrolle, korrekter Prerequisite-Reihenfolge (Windows-Features/Rollen vor IIS URL Rewrite Modul), granularer AntiSpam-Steuerung und editierbarer Datenbank-Vorschau.**

---

DAG Funktion ist noch nicht funktional!

## 📋 Übersicht

Das Exchange-Deployment-Automation-Tool ist ein umfassendes PowerShell-Skript zur **vollautomatisierten Installation und Konfiguration** von Microsoft Exchange Server 2016, 2019 und Standard Edition (SE). Das Skript vereinheitlicht folgende Aufgaben in einem kontinuierlichen Workflow:

- ✅ Servervorbereitung (Systemvoraussetzungen)
- ✅ Active Directory-Vorbereitung (ForestPrep, DomainPrep) mit automatischer Ergebniskontrolle
- ✅ Exchange Setup mit automatischen Antwortdateien
- ✅ Automatische Installation von Voraussetzungen und Komponenten
- ✅ Post-Installation Konfiguration (Koexistenz, Zertifikate, Services)
- ✅ URL-Übernahme vom bestehenden Exchange auf den neuen Server

---

## 🎯 Hauptmerkmale

### Vollautomatisierung
- Keine manuelle Intervention erforderlich
- Unbeaufsichtigter Modus mit automatischer Antwortdatei-Generierung
- Durchgehender Workflow ohne Unterbrechungen
- **ISO-Mount/Dismount automatisch**: Die ISO-Datei wird gemountet, sobald ein Schritt sie braucht (Voraussetzungen/UCMA im Reiter „Voraussetzungen“, Exchange-Installation im Workflow), und **immer** nach dem jeweiligen Lauf wieder freigegeben – auch bei Abbruch; manuell gemountete Laufwerke bleiben unberührt (die früheren Optionen „ISO automatisch mounten“ und „ISO am Ende automatisch unmounten“ wurden entfernt)

### Umfassende Vorbereitung
- Automatische Überprüfung der Systemvoraussetzungen
- **Vorab-Prüfung auf das Exchange-Medium bei „UCMA 4.0“**: bevor die Voraussetzungen installiert werden, prüft `Get-ExchangeMediaStatus` per frischem Laufwerk-Scan, ob eine ISO-Datei, ein gemountetes Image oder eine eingelegte Exchange-CD/DVD vorhanden ist; fehlt das Medium, bricht der Lauf **vor Schritt `[1/8]`** ab, bevor irgendetwas verändert wird (Hinweis: ISO auswählen/mounten, CD einlegen oder UCMA abwählen), und die Statuszeile „UCMA 4.0“ zeigt den Medium-Zustand bereits vor dem Klick
- AD-Vorbereitung (ForestPrep, DomainPrep) integriert
- **Automatische Ergebniskontrolle nach dem Adprep**: Schema-, Organisations- und DomainPrep-Versionsstände, Vorbereitungs-Berechtigungen sowie Schema-Replikation über alle Domain Controller
- **AD-Status aktualisiert sich automatisch**: nach jedem Adprep-Lauf (Button oder Workflow-Schritt) und nach jedem Ergebnis-Check wird auch die Status-Gruppe (Schema/Org/Domain, Benutzer, Berechtigungen) neu gefüllt – das manuelle Klicken auf „Status aktualisieren“ entfällt
- **Installations-Sperre bei unvollständiger AD-Vorbereitung**: die Exchange-Installation läuft nur, wenn alle AD-Prüfpunkte OK sind; andernfalls bricht der Lauf vor dem Setup ab und meldet die nicht OK Punkte (auch bei aktiviertem „Bei Fehlern weiter machen“)
- **Ausstehender Neustart wird vor dem Setup erkannt**: Prüft ein Setup-Lauf (AD-Vorbereitung oder Installation), dass `Component Based Servicing\RebootPending` oder `WindowsUpdate\RebootRequired` gesetzt ist, bricht er **vor** dem Start mit klarem Fehler ab – sonst läuft `Setup.exe /PrepareSchema` rund eineinhalb Minuten und scheitert mit Exit-Code 1 und `PendingRebootWindowsComponents` („Es steht ein Neustart aufgrund einer vorherigen Installation einer Windows Server-Rolle oder -Funktion aus“); auch die Voraussetzungs-Prüfung meldet den Neustart als nicht OK Punkt. `PendingFileRenameOperations` allein blockiert nicht, wird aber als Hinweis protokolliert. Nach jedem fehlgeschlagenen Setup-Lauf (Exit-Code ≠ 0) schreibt `Write-SetupLogErrorSummary` zusätzlich die `[ERROR]`/`[REQUIRED]`-Zeilen aus `ExchangeSetup.log` ins Haupt-Log, inklusive ausdrücklichem Neustart-Hinweis, wenn die Ursache ein Pending Reboot ist
- **Installations-Sperre bei fehlenden Voraussetzungen**: der Master-Workflow startet erst mit der Exchange-Installation – die früheren Schritte „Voraussetzungsprüfung“, „Voraussetzungen vorab installieren“ und „AD-Vorbereitung im Master-Workflow“ wurden entfernt, die Reiter werden links nach rechts einzeln abgearbeitet; **vor dem Setup läuft ein Voraussetzungs-Gate**, das OS/RAM/Festplatte/ISO **und** die installierten Komponenten (.NET 4.8, VC++ 2012/2013, URL Rewrite, UCMA, Windows-Features) abfragt und bei Fehlern jeden nicht OK Punkt meldet, statt das Setup ins Leere zu starten (auch bei „Bei Fehlern weiter machen“)
- Automatische Installation aller Voraussetzungen
- Komponentenverwaltung

### URLs übernehmen
- Eigener Tab **„URLs“** (der frühere Tab „URLs & Zertifikate“ ist in **„URLs“** und **„Zertifikate“** geteilt)
- **Nur die Domäne eingeben** (z. B. `mail.test.de`) und **„URLs vervollständigen“** drücken – alle sieben anwendbaren Dienste entstehen mit den Exchange-Standardpfaden, z. B. `https://mail.test.de/owa`, `/ecp`, `/EWS/Exchange.asmx`, `/mapi`, `/oab`, `/Microsoft-Server-ActiveSync`, `/autodiscover/autodiscover.xml`; beim Autodiscover wird der Host dabei automatisch zu `autodiscover.<Domain>` abgeleitet (Basis `mail.test.de` → `https://autodiscover.test.de/autodiscover/autodiscover.xml` – DNS-Eintrag und SAN für diesen Namen vorausgesetzt)
- Häkchen **„externe URLs = interne“** (Standard): alle URLs tragen denselben Domainnamen; ohne Haken lassen sich interne und externe Domäne getrennt angeben
- Interne und externe URLs eines **bestehenden Exchange-Servers auslesen** und für den neuen Server übernehmen
- Unterstützt: OWA, ECP, EWS, ActiveSync, Autodiscover, MAPI, OAB
- **PowerShell-URL wird nicht angefasst**: die Zeile ist nur sichtbar (read-only) und bleibt damit beim Setup-Standard (`/powershell`) – weder Erzeugen noch Anwenden ändert sie
- Einzelne Werte bleiben editierbar, danach mit einem Klick auf alle Virtual Directories anwenden
- Beim Anwenden wird die **Identity des jeweiligen Virtual Directory automatisch mitübergeben** (`Set-*VirtualDirectory` verlangt den Pflichtparameter `-Identity`) – es gibt damit keine interaktive Rückfrage „Geben Sie Werte für die folgenden Parameter an: Identity:“ in der Konsole
- Die interne Autodiscover-URL wird zusätzlich als **SCP** gesetzt (`Set-ClientAccessService -AutoDiscoverServiceInternalUri`), denn Outlook bezieht diese Adresse aus Active Directory
- **Autodiscover hat nur ein Feld**: Autodiscover besitzt keine interne/externe Trennung – eingetragen wird ausschließlich die SCP-URI (`AutoDiscoverServiceInternalUri`), deshalb fehlt in der Autodiscover-Zeile die externe Spalte (Tooltip erklärt das); „URLs vervollständigen“ erzeugt hier nur die interne URL
- Die Autodiscover-Zeile wird dabei bewusst **nicht** über das VD-Cmdlet gesetzt – `Set-AutodiscoverVirtualDirectory` kennt `InternalUrl`/`ExternalUrl` nur in Exchange 2010; das Tool prüft die Cmdlet-Parameter (`Get-Command`) und übergibt nur Vorhandenes, statt mit einem Parameterfehler zu scheitern
- Auch als automatischer Workflow-Schritt „URLs setzen“ verfügbar

### Zertifikats-Center
- Eigener Tab **„Zertifikate“**, der die **volle Fensterhöhe** nutzt: drei Gruppen für Status (oben), Parameter (Mitte) und Aktionen (unten) – kein Leerraum mehr unter der Eingabemaske
- Drei Modi: **PFX-Import** (eigener Dialog mit Kennwort und Serviceauswahl), **AD-Zertifizierungsstelle** oder **selbstsigniert**
- **AD-Zertifizierungsstelle = echte CA-Anfrage**: Antrag über `New-ExchangeCertificate -GenerateRequest`, Einreichung per `certreq -submit` bei der in Active Directory gefundenen Enterprise-CA (`CN=Enrollment Services`), `certreq -accept` für den privaten Schlüssel, danach Import und Aktivierung der Dienste – **eine Standalone-CA ist in AD nicht registriert und wird im Feld „CA:" als `SERVER\CA-Name` eingetragen** (leer = automatische Suche); Voraussetzung ist eine erreichbare CA mit veröffentlichtem Template (Standard **`WebServer`**, im Feld „CA-Template:" änderbar). Wartende Anträge (engl. „pending" und dt. „ausstehend") werden mit Antrags-ID gemerkt und nach der Freigabe automatisch per `certreq -retrieve` abgeholt – bis dahin bewusst keine Neuanfrage; abgelehnte Anträge enden mit klarem Fehler. Fehlt eine CA oder schlägt certreq fehl, wird der Grund ins Log geschrieben und nichts erzeugt
- **Beliebige SAN-Namen** – ein FQDN pro Zeile (z. B. `mail.contoso.local`, `autodiscover.contoso.local`); der Button **„SAN aus URLs ableiten“** füllt die Liste automatisch aus Domain und URL-Basis
- Gültigkeit und Schlüssellänge (1024/2048/4096) einstellbar
- Optionale Aktivierung für **IIS, SMTP, IMAP und POP**
- Auch als automatischer Workflow-Schritt „Zertifikat erstellen“ verfügbar
- Das PFX-Passwort wird bewusst **nicht** in der Konfigurationsdatei gespeichert

### Produktionsreife
- Fehlerreduktion durch Automatisierung
- Reproduzierbare Deployment-Prozesse
- Umfassende Validierung und Fehlerbehandlung
- Detaillierte Logging-Funktionalität
- **Responsive GUI**: Das Fenster ist frei skalierbar – bei Vollbild oder geänderter Fenstergröße werden alle Gruppen, Felder und Schriften proportional mit skaliert

### Enterprise-tauglich
- Unterstützung für Exchange 2016, 2019 und SE
- Für physische Server, VMs, Labs und Produktionsumgebungen geeignet
- Mehrsprachige Unterstützung (Deutsch/Englisch)

### AntiSpam-Steuerung
- Jeder AntiSpam-Agent einzeln aktivierbar/deaktivierbar (Content, Sender, Recipient, Reputation)
- **Sender-ID-Agent ist dauerhaft deaktiviert** (veraltet, Checkbox ausgegraut)
- Deaktivierte Agents werden explizit ausgeschaltet – kein versehentliches Aktivieren

### Datenbank-Generator
- Postfach-Datenbanken per Präfix + Startnummer + Anzahl generieren
- **Vorschau vollständig editierbar** – EDB- und Log-Pfade pro Zeile direkt anpassbar
- Datenbanken werden inkl. Verzeichniserstellung und Mount automatisch angelegt

### Live-Fortschrittsanzeige
- Fortschrittsbalken mit den **14 Installationsphasen** im Tab „Ausführung und Log“
- Phasen-Erkennung aus den echten Setup-Tasks (`Setup will run the task '<Task>'` bzw. `Ending processing: <Task>`), Untertasks erzeugen keine eigenen Zeilen mehr
- Pro Phase genau zwei Zeilen im Log: `[ n/14] <Task> (<Label>) ...` beim Start und `[ n/14] <Task> OK` am Ende – bei Fehler `[ n/14] <Task> FEHLER (Setup-Exit n)` plus die konkrete Fehlermeldung
- Phasenübersicht vor dem Start inkl. Task-Namen, `Phasen-Report` am Ende, grobe Restzeit-Schätzung im Heartbeat
- Farbliche Statusanzeige nach Erfolg (grün) bzw. Fehler (rot)

---

## 🚀 Anwendungsfälle

| Anwendungsfall | Eignung | Nutzen |
|---|---|---|
| **Laborumgebungen** | ⭐⭐⭐⭐⭐ | Schnelle Test-Setups |
| **Testumgebungen** | ⭐⭐⭐⭐⭐ | Reproduzierbare Konfigurationen |
| **Produktionsumgebungen** | ⭐⭐⭐⭐⭐ | Konsistente Enterprise-Deployments |
| **VM-Bereitstellung** | ⭐⭐⭐⭐⭐ | Automatisierte Skalierung |
| **Physische Server** | ⭐⭐⭐⭐ | Zuverlässige Installation |
| **Migrationen** | ⭐⭐⭐⭐ | Schnelle Koexistenz-Setup |

---

## 📋 Voraussetzungen

### Systemanforderungen
- **Windows Server 2016** oder höher
- **Mindestens 4 vCPU** (empfohlen: 8)
- **Mindestens 8 GB RAM** (empfohlen: 16+ GB)
- **Mindestens 200 GB freier Speicherplatz**
- **Administrator-Berechtigungen**

### Netzwerk & Domain
- Verbindung zu **Active Directory Domain Controller**
- Internetzugang (für Windows Updates, Prerequisites)
- **DNS-Auflösung** funktionsfähig
- **Gültige Domäne und Organisationsstruktur**

### Software-Voraussetzungen
- **PowerShell 5.1** oder höher
- **.NET Framework 4.7.2+** (wird bei Bedarf installiert)
- **Korrekte AD-Berechtigung** für ForestPrep/DomainPrep

### Exchange-Voraussetzungen
- **Installationsmedium** (ISO/DVD) vorhanden
- **Gültige Exchange-Lizenz** oder Evaluierungslizenz
- **Eindeutiger Computername** und IP-Konfiguration

---

## 🔧 Installation & Verwendung

### Schritt 1: Repository klonen
```powershell
git clone https://gitlab.com/RoccoAmmon/Exchange-Deployment-Automation-Tool.git
cd Exchange-Deployment-Automation-Tool
```

### Schritt 2: Berechtigungen konfigurieren
```powershell
# Execution Policy für das Skript setzen
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
```

### Schritt 3: Skript ausführen
```powershell
# Mit Administratorrechten (empfohlen: Rechtsklick → Mit PowerShell ausführen)
.\Exchange-Deployment-Automation-Tool.ps1
```

### Schritt 4: Konfiguration folgen
Die Reiter werden von links nach rechts einzeln abgearbeitet:
1. Voraussetzungen – Prüfung und Installation der Komponenten
2. AD-Vorbereitung (optional) – inklusive automatischem Ergebnis-Check
3. Installation – Setup-Parameter und der Master-Workflow (startet erst, nachdem die Voraussetzungen erfolgreich geprüft wurden)
4. Post-Installation Konfiguration (Zertifikate, URLs, Services)

---

## 📝 Konfigurationsoptionen

Die wichtigsten Konfigurationen können direkt im Skript angepasst werden:

```powershell
# Exchange-Version
$ExchangeVersion = "2019"  # 2016, 2019, SE

# Installationspfad
$ExchangePath = "C:\Program Files\Microsoft\Exchange Server\V15"

# Organization Name
$OrgName = "Contoso"

# Database-Optionen
$DBPath = "D:\ExchangeDB"
$LogPath = "E:\ExchangeLogs"
```

Weitere Konfigurationsoptionen finden Sie im [**Wiki**](../../wiki).

---

## 🛠️ Workflow

```
┌─────────────────────────────────────────────┐
│ Script-Start (Admin-Check)                  │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ 1. Voraussetzungen (Reiter)                 │
│    - OS, RAM, HDD, .NET, VC++, Features     │
│    - Komponenten nachinstallieren           │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ 2. AD-Vorbereitung (Reiter, optional)       │
│    - ForestPrep, DomainPrep                 │
│    - Automatische Ergebniskontrolle         │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ 3. Master-Workflow (Reiter Installation)    │
│    - Voraussetzungs-Gate + AD-Gate          │
│    - Exchange Setup, AntiSpam, TLS          │
│    - Zertifikat, URLs, Datenbanken, DAG     │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ ✅ Deployment abgeschlossen                │
└─────────────────────────────────────────────┘
```

Die Reiter werden von links nach rechts einzeln abgearbeitet: Voraussetzungen → AD-Vorbereitung → Installation. Der Master-Workflow („GESAMTEN PROZESS STARTEN“) beginnt mit der Exchange-Installation und startet erst, nachdem das Voraussetzungs-Gate alle Checks erfolgreich abgefragt hat.

---

## 📚 Dokumentation

Eine vollständige Dokumentation finden Sie im **[Wiki](../../wiki)**:

- [**Quick Start Guide**](../../wiki/Quick-Start-Guide)
- [**Detaillierte Installation**](../../wiki/Detaillierte-Installation)
- [**Konfigurationsoptionen**](../../wiki/Konfigurationsoptionen)
- [**Troubleshooting**](../../wiki/Troubleshooting)
- [**FAQ**](../../wiki/FAQ)
- [**Best Practices**](../../wiki/Best-Practices)

---

## 🐛 Troubleshooting

### Problem: "Admin-Rechte erforderlich"
```powershell
# Lösung: Rechtsklick auf die .ps1 Datei → "Mit PowerShell ausführen"
# Oder: PowerShell als Administrator starten
Start-Process -FilePath "powershell.exe" -Verb RunAs
```

### Problem: "Execution Policy"
```powershell
# Lösung: Execution Policy auf Bypass setzen
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
```

### Problem: "AD-Vorbereitung schlägt fehl"
Siehe [**Troubleshooting-Guide**](../../wiki/Troubleshooting#AD-Vorbereitung)

### Problem: URLs und Zertifikat nach der Installation
Die Tabs **„URLs“** und **„Zertifikate“** sind auch nach abgeschlossenem Setup manuell aufrufbar.
Steht noch ein Alt-Exchange zur Verfügung, lassen sich dessen URLs mit
**„Von Exchange auslesen“** übernehmen und anschließend auf den neuen Server anwenden.
Alternativ im Tab „URLs“ die Domäne eintragen (z. B. `mail.test.de`) und
**„URLs vervollständigen“** drücken – die Standardpfade werden ergänzt.

---

## 📈 Support & Community

| Frage/Problem | Kontakt |
|---|---|
| **Bug-Report** | [Issues](../../issues) |
| **Feature-Request** | [Diskussionen](../../discussions) |
| **Dokumentation** | [Wiki](../../wiki) |
| **Lizenzfragen** | Siehe [LICENSE](LICENSE) |

---

## 📄 Lizenz

Dieses Projekt ist unter der [MIT-Lizenz](LICENSE) lizenziert.

---

## 👤 Autor

**Rocco Ammon** – Repository: [RoccoAmmon](https://gitlab.com/RoccoAmmon)

---

## 🔄 Changelog

Siehe [CHANGELOG.md](CHANGELOG.md) für eine vollständige Versionshistorie.

---

## 🤝 Beitragen

Beiträge sind willkommen! Bitte erstelle einen Merge Request oder ein Issue für:
- 🐛 Bugfixes
- ✨ Neue Features
- 📚 Dokumentation
- 🎨 Verbesserungen

---

**Zuletzt aktualisiert:** Oktober 2026 | **Version:** 1.5


