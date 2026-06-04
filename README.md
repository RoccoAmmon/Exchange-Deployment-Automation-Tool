# Exchange-Deployment-Automation-Tool

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)](https://www.microsoft.com/de-de/powershell)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Status: Production](https://img.shields.io/badge/Status-Production-brightgreen)
![Version: 1.0](https://img.shields.io/badge/Version-1.0-blue)

**Vollständig automatisierte Bereitstellung von Microsoft Exchange Server – unbeaufsichtigt und fehlerreduziert für Enterprise-Umgebungen.**

---

## 📋 Übersicht

Das Exchange-Deployment-Automation-Tool ist ein umfassendes PowerShell-Skript zur **vollautomatisierten Installation und Konfiguration** von Microsoft Exchange Server 2016, 2019 und Standard Edition (SE). Das Skript vereinheitlicht folgende Aufgaben in einem kontinuierlichen Workflow:

- ✅ Servervorbereitung (Systemvoraussetzungen)
- ✅ Active Directory-Vorbereitung (ForestPrep, DomainPrep)
- ✅ Exchange Setup mit automatischen Antwortdateien
- ✅ Automatische Installation von Voraussetzungen und Komponenten
- ✅ Post-Installation Konfiguration (Koexistenz, Zertifikate, Services)

---

## 🎯 Hauptmerkmale

### Vollautomatisierung
- Keine manuelle Intervention erforderlich
- Unbeaufsichtigter Modus mit automatischer Antwortdatei-Generierung
- Durchgehender Workflow ohne Unterbrechungen

### Umfassende Vorbereitung
- Automatische Überprüfung der Systemvoraussetzungen
- AD-Vorbereitung (ForestPrep, DomainPrep) integriert
- Automatische Installation aller Voraussetzungen
- Komponentenverwaltung

### Produktionsreife
- Fehlerreduktion durch Automatisierung
- Reproduzierbare Deployment-Prozesse
- Umfassende Validierung und Fehlerbehandlung
- Detaillierte Logging-Funktionalität

### Enterprise-tauglich
- Unterstützung für Exchange 2016, 2019 und SE
- Für physische Server, VMs, Labs und Produktionsumgebungen geeignet
- Mehrsprachige Unterstützung (Deutsch/Englisch)

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
git clone https://github.com/RoccoAmmon/Exchange-Deployment-Automation-Tool.git
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
Das Skript leitet Sie interaktiv durch:
1. Systemvalidierung
2. AD-Vorbereitung (optional)
3. Exchange-Setup-Parameter
4. Automatische Installation
5. Post-Installation Konfiguration

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
│ 1. Systemvalidierung                        │
│    - OS-Version, RAM, HDD, .NET Framework   │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ 2. AD-Vorbereitung (optional)               │
│    - ForestPrep, DomainPrep                 │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ 3. Voraussetzungen installieren             │
│    - .NET, KB Updates, Visual C++           │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ 4. Exchange Setup                           │
│    - Automatische Antwortdatei-Generierung  │
│    - Unbeaufsichtigte Installation          │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ 5. Post-Installation Konfiguration          │
│    - Services, Zertifikate, Koexistenz     │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ ✅ Deployment abgeschlossen                │
└─────────────────────────────────────────────┘
```

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

---

## 📈 Support & Community

| Frage/Problem | Kontakt |
|---|---|
| **Bug-Report** | [Issues](../../issues) |
| **Feature-Request** | [Discussions](../../discussions) |
| **Dokumentation** | [Wiki](../../wiki) |
| **Lizenzfragen** | Siehe [LICENSE](LICENSE) |

---

## 📄 Lizenz

Dieses Projekt ist unter der [MIT-Lizenz](LICENSE) lizenziert.

---

## 👤 Autor

**Rocco Ammon** – Repository: [RoccoAmmon](https://github.com/RoccoAmmon)

---

## 🔄 Changelog

Siehe [CHANGELOG.md](CHANGELOG.md) für eine vollständige Versionshistorie.

---

## 🤝 Beitragen

Beiträge sind willkommen! Bitte erstelle einen Pull Request oder ein Issue für:
- 🐛 Bugfixes
- ✨ Neue Features
- 📚 Dokumentation
- 🎨 Verbesserungen

---

**Zuletzt aktualisiert:** Juni 2026 | **Version:** 1.0
