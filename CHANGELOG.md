# Changelog

Alle wesentlichen Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

Format basierend auf [Keep a Changelog](https://keepachangelog.com/de/1.0.0/),
versioniert nach [Semantic Versioning](https://semver.org/lang/de/).

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

**Zuletzt aktualisiert**: 4. Juni 2026
