# Changelog

Alle wesentlichen Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

Format basierend auf [Keep a Changelog](https://keepachangelog.com/de/1.0.0/),
versioniert nach [Semantic Versioning](https://semver.org/lang/de/).

---

## [1.2] - 2026-09-08

### ✨ Hinzugefügt
- **AntiSpam-Steuerung**: Jeder AntiSpam-Agent (Content, Sender, Recipient, Sender-Reputation) kann einzeln aktiviert/deaktiviert werden
- **Sender-ID-Agent dauerhaft deaktiviert**: Der veraltete Sender-ID-Filter wird immer ausgeschaltet (Checkbox ausgegraut, explizite Deaktivierung in `Set-AntiSpamConfiguration`)
- **DB-Generator mit editierbarer Vorschau**: EDB- und Log-Pfade können pro Datenbank direkt in der Vorschau-Tabelle angepasst werden

### 🔧 Geändert
- Deaktivierte AntiSpam-Agents werden jetzt **explizit ausgeschaltet** (`Set-*Config -Enabled $false`), statt unverändert zu bleiben
- Sender-ID-Filter ist in allen Ausführungspfaden (GUI, automatischer Durchlauf, Config-Laden) deaktiviert

### 🐛 Behoben
- **DivideByZeroException** beim Klick auf „Konfiguration generieren“ im DB-Generator (Reste der Round-Robin-Logik entfernt)

---

## [1.1] - 2026-09-07

### 🐛 Behoben
- **Installationsreihenfolge der Prerequisites korrigiert**: Das IIS URL Rewrite Modul 2.1 wird jetzt erst **nach** der Windows-Feature-/Rolleninstallation installiert (vorher wurde es zu früh installiert)
- Schritt-Nummerierung der Prerequisite-Installation entsprechend aktualisiert

### 🔧 Geändert
- Reihenfolge in `Install-PrerequisiteSoftware`: Features/Rollen → URL Rewrite → SMB1 → Power Plan

---

## [1.0] - 2026-06-04

### ✨ Hinzugefügt
- **Vollautomatisierte Exchange-Installation** für Exchange Server 2016, 2019 und Standard Edition
- **Active Directory Vorbereitung** mit integriertem ForestPrep und DomainPrep
- **Automatische Systemvalidierung** (OS, RAM, Speicher, .NET Framework)
- **Automatische Voraussetzungsinstallation** (.NET Framework, KB Updates, Visual C++ Redistributable)
- **Unbeaufsichtigter Setup-Modus** mit automatischer Antwortdatei-Generierung
- **Post-Installation Konfiguration**:
  - Exchange Services automatisch starten
  - Zertifikate validieren und konfigurieren
  - Koexistenz-Einstellungen
- **Mehrsprachige Unterstützung** (Deutsch/Englisch)
- **Admin-Elevation** mit automatischer UAC-Eskalation
- **Umfassendes Logging** mit konfigurierbarem Log-Pfad
- **Detaillierte Fehlerbehandlung** mit aussagekräftigen Fehlermeldungen
- **Interaktive Benutzerführung** durch alle Schritte
- **Validierung** nach jedem kritischen Schritt

### 📚 Dokumentation
- **README.md** mit ausführlicher Übersicht und Anleitung
- **Wiki** mit detaillierten Guides:
  - Quick Start Guide
  - Detaillierte Installation
  - Konfigurationsoptionen
  - Troubleshooting & FAQ
  - Best Practices
  - FAQ & häufige Probleme
- **CHANGELOG.md** für Versionsverfolgung

### 🔧 Features
- **Intelligente Systemvalidierung**:
  - OS-Version Check (Windows Server 2016+)
  - RAM-Prüfung (mindestens 8 GB empfohlen)
  - Speicherplatz-Validierung (200 GB mindestens)
  - .NET Framework-Version Check
  
- **Fehlertoleranz**:
  - Automatische Wiederholung bei transienten Fehlern
  - Detailliertes Error-Logging
  - Graceful Failure und Recovery
  
- **Produktionsreife**:
  - Enterprise-ready Validierung
  - Reproduzierbare Deployments
  - Vollständige Automatisierung
  - Minimal-invasive Konfiguration

- **Sicherheit**:
  - Admin-Berechtigungen erforderlich
  - UAC-Eskalation automatisch
  - Keine hartcodierten Passwörter
  - Zertifikat-Validierung

### 🎯 Unterstützte Versionen
- ✅ Exchange Server 2016
- ✅ Exchange Server 2019
- ✅ Exchange Server SE (Standard Edition)

### 🖥️ Unterstützte Systeme
- ✅ Windows Server 2016
- ✅ Windows Server 2019
- ✅ Windows Server 2022
- ✅ Physische Server
- ✅ Virtuelle Maschinen (Hyper-V, VMware, etc.)

---

## [Unreleased]

### Geplant für zukünftige Versionen
- [ ] DAG-Konfiguration (Database Availability Group)
- [ ] Automatische Firewall-Regelkonfiguration
- [ ] Integration mit Monitoring-Lösungen
- [ ] Azure Hybrid Identity Support
- [ ] Automatische Backup-Konfiguration
- [ ] PowerShell Gallery Paket-Integration
- [ ] Moderne CLI mit Parameter-Validierung
- [ ] GUI-Interface (WinForms/WPF)

---

## Legenden

- **✨ Hinzugefügt** - für neue Features
- **🔧 Geändert** - für Änderungen an bestehenden Features
- **🐛 Behoben** - für Bugfixes
- **⚠️ Veraltet** - für Features, die in Zukunft entfernt werden
- **🔐 Sicherheit** - für Sicherheitsfix
- **📚 Dokumentation** - für Dokumentations-Updates
- **🚀 Performance** - für Performance-Verbesserungen

---

## Kontakt & Support

- **Repository**: [Exchange-Deployment-Automation-Tool](https://github.com/RoccoAmmon/Exchange-Deployment-Automation-Tool)
- **Issues**: [Issues melden](https://github.com/RoccoAmmon/Exchange-Deployment-Automation-Tool/issues)
- **Autor**: Rocco Ammon
- **Lizenz**: MIT

---

**Zuletzt aktualisiert**: 7. September 2026
