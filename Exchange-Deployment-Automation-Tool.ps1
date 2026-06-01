<#
.SYNOPSIS
    Exchange 2019 Konfigurations-GUI für Datenbanken, DAG und allgemeine Einstellungen
.DESCRIPTION
    Diese GUI ermöglicht:
    - Setzen verschiedener Variablen über Eingabefelder
    - Aktivieren/Deaktivieren von Optionen über Checkboxen
    - Erstellen von Exchange-Datenbanken
    - Erstellen und Konfigurieren einer Database Availability Group (DAG)
    - Speichern/Laden der Konfiguration als JSON
.AUTHOR
    Rocco Ammon, SVA
.VERSION
    1.0
.NOTES
    Voraussetzungen:
    - Exchange Server 2019 installiert (für DAG/DB-Erstellung)
    - Exchange Management Shell verfügbar
    - Ausführung als Administrator
.EXAMPLE
    .\Exchange-Config-GUI.ps1
#>

#region Variablen-Definitionen
# ============================================================================
# Globale Variablen - Hier alle wichtigen Pfade und Standardwerte definieren
# ============================================================================

# Logging-Pfad gemäß Vorgabe
$Global:LogPath          = "C:\ScriptLog"
$Global:LogFile          = Join-Path -Path $Global:LogPath -ChildPath "Exchange-Config-GUI_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Konfigurations-Speicherpfad
$Global:ConfigPath       = "C:\ScriptLog\Config"
$Global:ConfigFile       = Join-Path -Path $Global:ConfigPath -ChildPath "ExchangeConfig.json"

# Exchange 2019 OnPrem PowerShell-Modul-Pfad (Standard)
$Global:ExchangeBinPath  = "C:\Program Files\Microsoft\Exchange Server\V15\bin"
$Global:RemoteExchangeScript = Join-Path -Path $Global:ExchangeBinPath -ChildPath "RemoteExchange.ps1"

# Standard-Werte für Datenbanken
$Global:DefaultDBPath    = "D:\ExchangeDatabases"
$Global:DefaultLogPath   = "E:\ExchangeLogs"

# GUI-Fenstergröße
$Global:FormWidth        = 850
$Global:FormHeight       = 720

#endregion

#region Verzeichnisse vorbereiten
try {
    # Log- und Config-Verzeichnis sicherstellen
    foreach ($Path in @($Global:LogPath, $Global:ConfigPath)) {
        if (-not (Test-Path -Path $Path)) {
            New-Item -Path $Path -ItemType Directory -Force | Out-Null
        }
    }
}
catch {
    Write-Host "Fehler beim Erstellen der Verzeichnisse: $_" -ForegroundColor Red
    exit 1
}
#endregion

#region Logging-Funktion
function Write-Log {
    <#
    .SYNOPSIS
        Schreibt Meldungen in die Logdatei und (optional) in die GUI-Statuszeile.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet("INFO","WARNING","ERROR","SUCCESS")]
        [string]$Level = "INFO"
    )

    try {
        $TimeStamp  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $LogMessage = "[$TimeStamp] [$Level] $Message"
        Add-Content -Path $Global:LogFile -Value $LogMessage -ErrorAction SilentlyContinue

        # GUI-Statuslabel aktualisieren, falls vorhanden
        if ($Global:StatusLabel) {
            $Global:StatusLabel.Text = "[$Level] $Message"
            switch ($Level) {
                "ERROR"   { $Global:StatusLabel.ForeColor = 'Red' }
                "WARNING" { $Global:StatusLabel.ForeColor = 'DarkOrange' }
                "SUCCESS" { $Global:StatusLabel.ForeColor = 'Green' }
                default   { $Global:StatusLabel.ForeColor = 'Black' }
            }
            [System.Windows.Forms.Application]::DoEvents()
        }
    }
    catch {
        Write-Host "Logging-Fehler: $_" -ForegroundColor Red
    }
}
#endregion

#region Exchange 2019 Snapin / Modul laden
function Import-ExchangeManagementShell {
    <#
    .SYNOPSIS
        Lädt das Exchange 2019 OnPrem Snapin / Modul.
    #>
    try {
        Write-Log -Message "Lade Exchange Management Shell..." -Level "INFO"

        # Prüfen, ob bereits geladen
        if (Get-Command Get-MailboxDatabase -ErrorAction SilentlyContinue) {
            Write-Log -Message "Exchange Management Shell bereits geladen." -Level "SUCCESS"
            return $true
        }

        # RemoteExchange.ps1 verwenden (Exchange 2019 OnPrem)
        if (Test-Path -Path $Global:RemoteExchangeScript) {
            . $Global:RemoteExchangeScript
            Connect-ExchangeServer -auto -ClientApplication:ManagementShell
            Write-Log -Message "Exchange Management Shell erfolgreich geladen." -Level "SUCCESS"
            return $true
        }
        else {
            Write-Log -Message "RemoteExchange.ps1 nicht gefunden unter: $Global:RemoteExchangeScript" -Level "WARNING"
            return $false
        }
    }
    catch {
        Write-Log -Message "Fehler beim Laden der Exchange Management Shell: $_" -Level "ERROR"
        return $false
    }
}
#endregion

#region GUI-Aufbau - Assemblies laden
try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
}
catch {
    Write-Host "Fehler beim Laden der Windows Forms Assemblies: $_" -ForegroundColor Red
    exit 1
}
#endregion

#region Hauptformular erstellen
$Form = New-Object System.Windows.Forms.Form
$Form.Text          = "Exchange 2019 - Konfigurations-GUI"
$Form.Size          = New-Object System.Drawing.Size($Global:FormWidth, $Global:FormHeight)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedDialog"
$Form.MaximizeBox   = $false

# TabControl für die verschiedenen Bereiche
$TabControl          = New-Object System.Windows.Forms.TabControl
$TabControl.Location = New-Object System.Drawing.Point(10, 10)
$TabControl.Size     = New-Object System.Drawing.Size(815, 600)

# Tab-Seiten anlegen
$TabAllgemein   = New-Object System.Windows.Forms.TabPage; $TabAllgemein.Text   = "Allgemeine Einstellungen"
$TabDatenbank   = New-Object System.Windows.Forms.TabPage; $TabDatenbank.Text   = "Datenbanken"
$TabDAG         = New-Object System.Windows.Forms.TabPage; $TabDAG.Text         = "DAG erstellen"
$TabZusammen    = New-Object System.Windows.Forms.TabPage; $TabZusammen.Text    = "Übersicht / Aktionen"

$TabControl.TabPages.AddRange(@($TabAllgemein, $TabDatenbank, $TabDAG, $TabZusammen))
$Form.Controls.Add($TabControl)
#endregion

#region Tab 1: Allgemeine Einstellungen (Checkboxen + Variablen)

# --- GroupBox: Server-Einstellungen ---
$GrpServer          = New-Object System.Windows.Forms.GroupBox
$GrpServer.Text     = "Server-Einstellungen"
$GrpServer.Location = New-Object System.Drawing.Point(10, 10)
$GrpServer.Size     = New-Object System.Drawing.Size(780, 130)

# Servername
$LblServerName        = New-Object System.Windows.Forms.Label
$LblServerName.Text   = "Exchange Server Name:"
$LblServerName.Location = New-Object System.Drawing.Point(15, 30)
$LblServerName.Size   = New-Object System.Drawing.Size(180, 22)
$GrpServer.Controls.Add($LblServerName)

$TxtServerName        = New-Object System.Windows.Forms.TextBox
$TxtServerName.Location = New-Object System.Drawing.Point(200, 28)
$TxtServerName.Size   = New-Object System.Drawing.Size(250, 22)
$TxtServerName.Text   = $env:COMPUTERNAME
$GrpServer.Controls.Add($TxtServerName)

# Organisation
$LblOrg               = New-Object System.Windows.Forms.Label
$LblOrg.Text          = "Organisation:"
$LblOrg.Location      = New-Object System.Drawing.Point(15, 60)
$LblOrg.Size          = New-Object System.Drawing.Size(180, 22)
$GrpServer.Controls.Add($LblOrg)

$TxtOrg               = New-Object System.Windows.Forms.TextBox
$TxtOrg.Location      = New-Object System.Drawing.Point(200, 58)
$TxtOrg.Size          = New-Object System.Drawing.Size(250, 22)
$TxtOrg.Text          = "Contoso"
$GrpServer.Controls.Add($TxtOrg)

# Domain
$LblDomain            = New-Object System.Windows.Forms.Label
$LblDomain.Text       = "AD-Domäne (FQDN):"
$LblDomain.Location   = New-Object System.Drawing.Point(15, 90)
$LblDomain.Size       = New-Object System.Drawing.Size(180, 22)
$GrpServer.Controls.Add($LblDomain)

$TxtDomain            = New-Object System.Windows.Forms.TextBox
$TxtDomain.Location   = New-Object System.Drawing.Point(200, 88)
$TxtDomain.Size       = New-Object System.Drawing.Size(250, 22)
try { $TxtDomain.Text = (Get-CimInstance Win32_ComputerSystem).Domain } catch { $TxtDomain.Text = "contoso.local" }
$GrpServer.Controls.Add($TxtDomain)

$TabAllgemein.Controls.Add($GrpServer)

# --- GroupBox: Optionen (Checkboxen) ---
$GrpOptionen          = New-Object System.Windows.Forms.GroupBox
$GrpOptionen.Text     = "Optionen / Features aktivieren"
$GrpOptionen.Location = New-Object System.Drawing.Point(10, 150)
$GrpOptionen.Size     = New-Object System.Drawing.Size(780, 290)

# Liste der Checkboxen
$CheckBoxes = @{}
$Optionen = @(
    "Antispam-Agenten installieren",
    "Content-Filter aktivieren",
    "Sender-ID-Filter aktivieren",
    "Sender-Reputation aktivieren",
    "Recipient-Filter aktivieren",
    "Outlook Anywhere aktivieren",
    "MAPI over HTTP aktivieren",
    "OWA aktivieren",
    "ECP aktivieren",
    "ActiveSync aktivieren",
    "IMAP-Service aktivieren",
    "POP3-Service aktivieren",
    "TLS 1.2 erzwingen",
    "Internes Zertifikat erstellen",
    "Receive Connector erstellen",
    "Send Connector erstellen",
    "Postfach-Datenbanken anlegen",
    "DAG erstellen und konfigurieren"
)

# Checkboxen in 2 Spalten anordnen
$col = 0; $row = 0
foreach ($Option in $Optionen) {
    $cb               = New-Object System.Windows.Forms.CheckBox
    $cb.Text          = $Option
    $cb.Location      = New-Object System.Drawing.Point((20 + ($col * 380)), (25 + ($row * 28)))
    $cb.Size          = New-Object System.Drawing.Size(360, 24)
    $GrpOptionen.Controls.Add($cb)
    $CheckBoxes[$Option] = $cb

    $row++
    if ($row -ge 9) { $row = 0; $col++ }
}

$TabAllgemein.Controls.Add($GrpOptionen)

# --- GroupBox: Pfade ---
$GrpPfade           = New-Object System.Windows.Forms.GroupBox
$GrpPfade.Text      = "Standard-Pfade"
$GrpPfade.Location  = New-Object System.Drawing.Point(10, 450)
$GrpPfade.Size      = New-Object System.Drawing.Size(780, 100)

$LblDBPath          = New-Object System.Windows.Forms.Label
$LblDBPath.Text     = "Datenbank-Pfad:"
$LblDBPath.Location = New-Object System.Drawing.Point(15, 30)
$LblDBPath.Size     = New-Object System.Drawing.Size(180, 22)
$GrpPfade.Controls.Add($LblDBPath)

$TxtDBPath          = New-Object System.Windows.Forms.TextBox
$TxtDBPath.Location = New-Object System.Drawing.Point(200, 28)
$TxtDBPath.Size     = New-Object System.Drawing.Size(450, 22)
$TxtDBPath.Text     = $Global:DefaultDBPath
$GrpPfade.Controls.Add($TxtDBPath)

$LblLogP            = New-Object System.Windows.Forms.Label
$LblLogP.Text       = "Log-Pfad:"
$LblLogP.Location   = New-Object System.Drawing.Point(15, 60)
$LblLogP.Size       = New-Object System.Drawing.Size(180, 22)
$GrpPfade.Controls.Add($LblLogP)

$TxtLogP            = New-Object System.Windows.Forms.TextBox
$TxtLogP.Location   = New-Object System.Drawing.Point(200, 58)
$TxtLogP.Size       = New-Object System.Drawing.Size(450, 22)
$TxtLogP.Text       = $Global:DefaultLogPath
$GrpPfade.Controls.Add($TxtLogP)

$TabAllgemein.Controls.Add($GrpPfade)
#endregion

#region Tab 2: Datenbanken anlegen

$LblInfoDB           = New-Object System.Windows.Forms.Label
$LblInfoDB.Text      = "Hier können Sie mehrere Postfach-Datenbanken anlegen. Trennen Sie die DB-Namen mit Komma."
$LblInfoDB.Location  = New-Object System.Drawing.Point(10, 10)
$LblInfoDB.Size      = New-Object System.Drawing.Size(780, 22)
$TabDatenbank.Controls.Add($LblInfoDB)

# --- DataGridView für Datenbanken ---
$DgvDB              = New-Object System.Windows.Forms.DataGridView
$DgvDB.Location     = New-Object System.Drawing.Point(10, 40)
$DgvDB.Size         = New-Object System.Drawing.Size(780, 380)
$DgvDB.AllowUserToAddRows  = $true
$DgvDB.AllowUserToDeleteRows = $true
$DgvDB.AutoSizeColumnsMode = 'Fill'
$DgvDB.SelectionMode = 'FullRowSelect'

# Spalten definieren
$ColName            = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$ColName.HeaderText = "Datenbankname"
$ColName.Name       = "DBName"
$DgvDB.Columns.Add($ColName) | Out-Null

$ColServer          = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$ColServer.HeaderText = "Server"
$ColServer.Name     = "Server"
$DgvDB.Columns.Add($ColServer) | Out-Null

$ColEDB             = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$ColEDB.HeaderText  = "EDB-Pfad"
$ColEDB.Name        = "EdbFilePath"
$DgvDB.Columns.Add($ColEDB) | Out-Null

$ColLog             = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$ColLog.HeaderText  = "Log-Pfad"
$ColLog.Name        = "LogFolderPath"
$DgvDB.Columns.Add($ColLog) | Out-Null

# Beispiel-Zeile vorbelegen
$DgvDB.Rows.Add("MBX-DB01", $env:COMPUTERNAME, "$Global:DefaultDBPath\MBX-DB01\MBX-DB01.edb", "$Global:DefaultLogPath\MBX-DB01") | Out-Null

$TabDatenbank.Controls.Add($DgvDB)

# Button: Standardzeile hinzufügen
$BtnAddDB           = New-Object System.Windows.Forms.Button
$BtnAddDB.Text      = "Standard-DB hinzufügen"
$BtnAddDB.Location  = New-Object System.Drawing.Point(10, 430)
$BtnAddDB.Size      = New-Object System.Drawing.Size(180, 30)
$BtnAddDB.Add_Click({
    try {
        $newIndex = ($DgvDB.Rows.Count)
        $dbName   = "MBX-DB{0:D2}" -f $newIndex
        $DgvDB.Rows.Add($dbName, $TxtServerName.Text, "$($TxtDBPath.Text)\$dbName\$dbName.edb", "$($TxtLogP.Text)\$dbName") | Out-Null
        Write-Log -Message "Standard-DB-Zeile '$dbName' hinzugefügt." -Level "INFO"
    }
    catch {
        Write-Log -Message "Fehler beim Hinzufügen einer Standardzeile: $_" -Level "ERROR"
    }
})
$TabDatenbank.Controls.Add($BtnAddDB)

# Button: Datenbanken anlegen
$BtnCreateDBs       = New-Object System.Windows.Forms.Button
$BtnCreateDBs.Text  = "Datenbanken jetzt erstellen"
$BtnCreateDBs.Location = New-Object System.Drawing.Point(600, 430)
$BtnCreateDBs.Size  = New-Object System.Drawing.Size(190, 30)
$BtnCreateDBs.BackColor = [System.Drawing.Color]::LightGreen
$BtnCreateDBs.Add_Click({
    try {
        Write-Log -Message "Starte Erstellung der Datenbanken..." -Level "INFO"

        if (-not (Import-ExchangeManagementShell)) {
            [System.Windows.Forms.MessageBox]::Show("Exchange Management Shell konnte nicht geladen werden!","Fehler",'OK','Error')
            return
        }

        $created = 0
        foreach ($row in $DgvDB.Rows) {
            if ($row.IsNewRow) { continue }

            $dbName  = $row.Cells["DBName"].Value
            $srv     = $row.Cells["Server"].Value
            $edb     = $row.Cells["EdbFilePath"].Value
            $logp    = $row.Cells["LogFolderPath"].Value

            if ([string]::IsNullOrWhiteSpace($dbName)) { continue }

            try {
                # Prüfen, ob DB bereits existiert
                $existing = Get-MailboxDatabase -Identity $dbName -ErrorAction SilentlyContinue
                if ($existing) {
                    Write-Log -Message "Datenbank '$dbName' existiert bereits - übersprungen." -Level "WARNING"
                    continue
                }

                # Verzeichnisse anlegen
                $edbDir = Split-Path -Path $edb -Parent
                if (-not (Test-Path $edbDir))  { New-Item -Path $edbDir  -ItemType Directory -Force | Out-Null }
                if (-not (Test-Path $logp))    { New-Item -Path $logp    -ItemType Directory -Force | Out-Null }

                # Datenbank erstellen
                New-MailboxDatabase -Name $dbName -Server $srv -EdbFilePath $edb -LogFolderPath $logp -ErrorAction Stop | Out-Null
                Write-Log -Message "Datenbank '$dbName' auf Server '$srv' erstellt." -Level "SUCCESS"

                # Datenbank mounten
                Mount-Database -Identity $dbName -ErrorAction Stop
                Write-Log -Message "Datenbank '$dbName' erfolgreich gemountet." -Level "SUCCESS"
                $created++
            }
            catch {
                Write-Log -Message "Fehler beim Erstellen der DB '$dbName': $_" -Level "ERROR"
            }
        }

        [System.Windows.Forms.MessageBox]::Show("$created Datenbank(en) wurden erstellt. Details siehe Log: $Global:LogFile","Fertig",'OK','Information')
    }
    catch {
        Write-Log -Message "Kritischer Fehler bei der DB-Erstellung: $_" -Level "ERROR"
    }
})
$TabDatenbank.Controls.Add($BtnCreateDBs)
#endregion

#region Tab 3: DAG erstellen

# --- DAG-Grunddaten ---
$GrpDAG             = New-Object System.Windows.Forms.GroupBox
$GrpDAG.Text        = "DAG-Grundeinstellungen"
$GrpDAG.Location    = New-Object System.Drawing.Point(10, 10)
$GrpDAG.Size        = New-Object System.Drawing.Size(780, 220)

# DAG-Name
$LblDAGName         = New-Object System.Windows.Forms.Label
$LblDAGName.Text    = "DAG-Name:"
$LblDAGName.Location = New-Object System.Drawing.Point(15, 30)
$LblDAGName.Size    = New-Object System.Drawing.Size(180, 22)
$GrpDAG.Controls.Add($LblDAGName)

$TxtDAGName         = New-Object System.Windows.Forms.TextBox
$TxtDAGName.Location = New-Object System.Drawing.Point(200, 28)
$TxtDAGName.Size    = New-Object System.Drawing.Size(250, 22)
$TxtDAGName.Text    = "DAG01"
$GrpDAG.Controls.Add($TxtDAGName)

# Witness Server
$LblWitness         = New-Object System.Windows.Forms.Label
$LblWitness.Text    = "Witness Server:"
$LblWitness.Location = New-Object System.Drawing.Point(15, 60)
$LblWitness.Size    = New-Object System.Drawing.Size(180, 22)
$GrpDAG.Controls.Add($LblWitness)

$TxtWitness         = New-Object System.Windows.Forms.TextBox
$TxtWitness.Location = New-Object System.Drawing.Point(200, 58)
$TxtWitness.Size    = New-Object System.Drawing.Size(250, 22)
$TxtWitness.Text    = "FILESERVER01"
$GrpDAG.Controls.Add($TxtWitness)

# Witness-Verzeichnis
$LblWitnessDir      = New-Object System.Windows.Forms.Label
$LblWitnessDir.Text = "Witness-Verzeichnis:"
$LblWitnessDir.Location = New-Object System.Drawing.Point(15, 90)
$LblWitnessDir.Size = New-Object System.Drawing.Size(180, 22)
$GrpDAG.Controls.Add($LblWitnessDir)

$TxtWitnessDir      = New-Object System.Windows.Forms.TextBox
$TxtWitnessDir.Location = New-Object System.Drawing.Point(200, 88)
$TxtWitnessDir.Size = New-Object System.Drawing.Size(450, 22)
$TxtWitnessDir.Text = "C:\DAGFileShareWitness\DAG01"
$GrpDAG.Controls.Add($TxtWitnessDir)

# DAG-IP
$LblDAGIP           = New-Object System.Windows.Forms.Label
$LblDAGIP.Text      = "DAG-IP-Adresse(n):"
$LblDAGIP.Location  = New-Object System.Drawing.Point(15, 120)
$LblDAGIP.Size      = New-Object System.Drawing.Size(180, 22)
$GrpDAG.Controls.Add($LblDAGIP)

$TxtDAGIP           = New-Object System.Windows.Forms.TextBox
$TxtDAGIP.Location  = New-Object System.Drawing.Point(200, 118)
$TxtDAGIP.Size      = New-Object System.Drawing.Size(450, 22)
$TxtDAGIP.Text      = "192.168.1.100"
$GrpDAG.Controls.Add($TxtDAGIP)

# Hinweis: bei mehreren IPs Komma-getrennt
$LblHint            = New-Object System.Windows.Forms.Label
$LblHint.Text       = "(Mehrere IPs mit Komma trennen, z.B. '192.168.1.100,10.0.0.5')"
$LblHint.Location   = New-Object System.Drawing.Point(200, 145)
$LblHint.Size       = New-Object System.Drawing.Size(450, 18)
$LblHint.ForeColor  = 'Gray'
$GrpDAG.Controls.Add($LblHint)

# DatabaseAvailabilityGroupIPv4Addresses none -> Checkbox für IPless DAG
$ChkIPlessDAG       = New-Object System.Windows.Forms.CheckBox
$ChkIPlessDAG.Text  = "IP-lose DAG erstellen (Exchange 2016+ empfohlen)"
$ChkIPlessDAG.Location = New-Object System.Drawing.Point(15, 175)
$ChkIPlessDAG.Size  = New-Object System.Drawing.Size(400, 22)
$GrpDAG.Controls.Add($ChkIPlessDAG)

$TabDAG.Controls.Add($GrpDAG)

# --- DAG-Mitglieder ---
$GrpMembers         = New-Object System.Windows.Forms.GroupBox
$GrpMembers.Text    = "DAG-Mitglieder (ein Server pro Zeile)"
$GrpMembers.Location = New-Object System.Drawing.Point(10, 240)
$GrpMembers.Size    = New-Object System.Drawing.Size(780, 200)

$TxtMembers         = New-Object System.Windows.Forms.TextBox
$TxtMembers.Location = New-Object System.Drawing.Point(15, 25)
$TxtMembers.Size    = New-Object System.Drawing.Size(750, 165)
$TxtMembers.Multiline = $true
$TxtMembers.ScrollBars = 'Vertical'
$TxtMembers.Text    = "EX01`r`nEX02"
$GrpMembers.Controls.Add($TxtMembers)

$TabDAG.Controls.Add($GrpMembers)

# Button: DAG erstellen
$BtnCreateDAG       = New-Object System.Windows.Forms.Button
$BtnCreateDAG.Text  = "DAG erstellen und Mitglieder hinzufügen"
$BtnCreateDAG.Location = New-Object System.Drawing.Point(10, 460)
$BtnCreateDAG.Size  = New-Object System.Drawing.Size(780, 40)
$BtnCreateDAG.BackColor = [System.Drawing.Color]::LightSkyBlue
$BtnCreateDAG.Add_Click({
    try {
        Write-Log -Message "Starte DAG-Erstellung..." -Level "INFO"

        if (-not (Import-ExchangeManagementShell)) {
            [System.Windows.Forms.MessageBox]::Show("Exchange Management Shell konnte nicht geladen werden!","Fehler",'OK','Error')
            return
        }

        $dagName    = $TxtDAGName.Text.Trim()
        $witness    = $TxtWitness.Text.Trim()
        $witnessDir = $TxtWitnessDir.Text.Trim()

        if ([string]::IsNullOrWhiteSpace($dagName) -or [string]::IsNullOrWhiteSpace($witness)) {
            [System.Windows.Forms.MessageBox]::Show("DAG-Name und Witness-Server müssen ausgefüllt sein.","Validierung",'OK','Warning')
            return
        }

        # Prüfen ob DAG existiert
        $existingDag = Get-DatabaseAvailabilityGroup -Identity $dagName -ErrorAction SilentlyContinue
        if ($existingDag) {
            Write-Log -Message "DAG '$dagName' existiert bereits." -Level "WARNING"
        }
        else {
            # DAG erstellen
            if ($ChkIPlessDAG.Checked) {
                # IP-lose DAG (Exchange 2016+)
                New-DatabaseAvailabilityGroup -Name $dagName `
                    -WitnessServer $witness `
                    -WitnessDirectory $witnessDir `
                    -DatabaseAvailabilityGroupIpAddresses ([System.Net.IPAddress]::None) `
                    -ErrorAction Stop | Out-Null
                Write-Log -Message "IP-lose DAG '$dagName' erfolgreich erstellt." -Level "SUCCESS"
            }
            else {
                # IPs aus Textfeld extrahieren
                $ips = $TxtDAGIP.Text.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ }
                $ipObjects = $ips | ForEach-Object { [System.Net.IPAddress]::Parse($_) }

                New-DatabaseAvailabilityGroup -Name $dagName `
                    -WitnessServer $witness `
                    -WitnessDirectory $witnessDir `
                    -DatabaseAvailabilityGroupIpAddresses $ipObjects `
                    -ErrorAction Stop | Out-Null
                Write-Log -Message "DAG '$dagName' mit IP(s) '$($ips -join ',')' erstellt." -Level "SUCCESS"
            }
        }

        # Mitglieder hinzufügen
        $members = $TxtMembers.Text.Split("`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        foreach ($member in $members) {
            try {
                Add-DatabaseAvailabilityGroupServer -Identity $dagName -MailboxServer $member -ErrorAction Stop
                Write-Log -Message "Mitglied '$member' zur DAG '$dagName' hinzugefügt." -Level "SUCCESS"
            }
            catch {
                Write-Log -Message "Fehler beim Hinzufügen von '$member' zur DAG: $_" -Level "ERROR"
            }
        }

        [System.Windows.Forms.MessageBox]::Show("DAG-Konfiguration abgeschlossen. Details siehe Log:`n$Global:LogFile","Fertig",'OK','Information')
    }
    catch {
        Write-Log -Message "Kritischer Fehler bei der DAG-Erstellung: $_" -Level "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Fehler: $_","Fehler",'OK','Error')
    }
})
$TabDAG.Controls.Add($BtnCreateDAG)
#endregion

#region Tab 4: Übersicht / Aktionen

$LblOverview        = New-Object System.Windows.Forms.Label
$LblOverview.Text   = "Hier können Sie die aktuelle Konfiguration speichern, laden oder eine Übersicht ausgeben."
$LblOverview.Location = New-Object System.Drawing.Point(10, 10)
$LblOverview.Size   = New-Object System.Drawing.Size(780, 22)
$TabZusammen.Controls.Add($LblOverview)

# Übersichts-TextBox
$TxtOverview        = New-Object System.Windows.Forms.TextBox
$TxtOverview.Location = New-Object System.Drawing.Point(10, 40)
$TxtOverview.Size   = New-Object System.Drawing.Size(780, 420)
$TxtOverview.Multiline = $true
$TxtOverview.ScrollBars = 'Vertical'
$TxtOverview.ReadOnly = $true
$TxtOverview.Font   = New-Object System.Drawing.Font("Consolas", 9)
$TabZusammen.Controls.Add($TxtOverview)

# Button: Übersicht aktualisieren
$BtnRefresh         = New-Object System.Windows.Forms.Button
$BtnRefresh.Text    = "Übersicht aktualisieren"
$BtnRefresh.Location = New-Object System.Drawing.Point(10, 470)
$BtnRefresh.Size    = New-Object System.Drawing.Size(180, 30)
$BtnRefresh.Add_Click({
    try {
        $sb = New-Object System.Text.StringBuilder
        [void]$sb.AppendLine("=== EXCHANGE 2019 KONFIGURATION ===")
        [void]$sb.AppendLine("Erstellt am: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("--- ALLGEMEIN ---")
        [void]$sb.AppendLine("Servername      : $($TxtServerName.Text)")
        [void]$sb.AppendLine("Organisation    : $($TxtOrg.Text)")
        [void]$sb.AppendLine("Domain          : $($TxtDomain.Text)")
        [void]$sb.AppendLine("DB-Pfad         : $($TxtDBPath.Text)")
        [void]$sb.AppendLine("Log-Pfad        : $($TxtLogP.Text)")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("--- AKTIVIERTE OPTIONEN ---")
        foreach ($key in $CheckBoxes.Keys) {
            if ($CheckBoxes[$key].Checked) {
                [void]$sb.AppendLine("  [X] $key")
            }
        }
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("--- DATENBANKEN ---")
        foreach ($row in $DgvDB.Rows) {
            if ($row.IsNewRow) { continue }
            [void]$sb.AppendLine("  - $($row.Cells['DBName'].Value) (Server: $($row.Cells['Server'].Value))")
            [void]$sb.AppendLine("      EDB: $($row.Cells['EdbFilePath'].Value)")
            [void]$sb.AppendLine("      Log: $($row.Cells['LogFolderPath'].Value)")
        }
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("--- DAG ---")
        [void]$sb.AppendLine("DAG-Name        : $($TxtDAGName.Text)")
        [void]$sb.AppendLine("Witness         : $($TxtWitness.Text)")
        [void]$sb.AppendLine("Witness-Dir     : $($TxtWitnessDir.Text)")
        [void]$sb.AppendLine("IPs             : $(if($ChkIPlessDAG.Checked){'IPless DAG'}else{$TxtDAGIP.Text})")
        [void]$sb.AppendLine("Mitglieder      :")
        $TxtMembers.Text.Split("`n") | ForEach-Object { 
            $m = $_.Trim()
            if ($m) { [void]$sb.AppendLine("  - $m") }
        }

        $TxtOverview.Text = $sb.ToString()
        Write-Log -Message "Übersicht wurde aktualisiert." -Level "INFO"
    }
    catch {
        Write-Log -Message "Fehler beim Erstellen der Übersicht: $_" -Level "ERROR"
    }
})
$TabZusammen.Controls.Add($BtnRefresh)

# Button: Konfiguration speichern (JSON)
$BtnSaveConfig      = New-Object System.Windows.Forms.Button
$BtnSaveConfig.Text = "Konfiguration speichern"
$BtnSaveConfig.Location = New-Object System.Drawing.Point(200, 470)
$BtnSaveConfig.Size = New-Object System.Drawing.Size(180, 30)
$BtnSaveConfig.Add_Click({
    try {
        $config = @{
            ServerName  = $TxtServerName.Text
            Organisation = $TxtOrg.Text
            Domain      = $TxtDomain.Text
            DBPath      = $TxtDBPath.Text
            LogPath     = $TxtLogP.Text
            Optionen    = @{}
            Datenbanken = @()
            DAG         = @{
                Name        = $TxtDAGName.Text
                Witness     = $TxtWitness.Text
                WitnessDir  = $TxtWitnessDir.Text
                IP          = $TxtDAGIP.Text
                IPless      = $ChkIPlessDAG.Checked
                Mitglieder  = $TxtMembers.Text.Split("`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ }
            }
        }

        foreach ($key in $CheckBoxes.Keys) {
            $config.Optionen[$key] = $CheckBoxes[$key].Checked
        }

        foreach ($row in $DgvDB.Rows) {
            if ($row.IsNewRow) { continue }
            $config.Datenbanken += @{
                DBName        = $row.Cells["DBName"].Value
                Server        = $row.Cells["Server"].Value
                EdbFilePath   = $row.Cells["EdbFilePath"].Value
                LogFolderPath = $row.Cells["LogFolderPath"].Value
            }
        }

        $config | ConvertTo-Json -Depth 5 | Set-Content -Path $Global:ConfigFile -Encoding UTF8
        Write-Log -Message "Konfiguration gespeichert: $Global:ConfigFile" -Level "SUCCESS"
        [System.Windows.Forms.MessageBox]::Show("Konfiguration gespeichert unter:`n$Global:ConfigFile","Gespeichert",'OK','Information')
    }
    catch {
        Write-Log -Message "Fehler beim Speichern der Konfiguration: $_" -Level "ERROR"
    }
})
$TabZusammen.Controls.Add($BtnSaveConfig)

# Button: Konfiguration laden (JSON)
$BtnLoadConfig      = New-Object System.Windows.Forms.Button
$BtnLoadConfig.Text = "Konfiguration laden"
$BtnLoadConfig.Location = New-Object System.Drawing.Point(390, 470)
$BtnLoadConfig.Size = New-Object System.Drawing.Size(180, 30)
$BtnLoadConfig.Add_Click({
    try {
        if (-not (Test-Path $Global:ConfigFile)) {
            [System.Windows.Forms.MessageBox]::Show("Keine Konfigurationsdatei gefunden.","Info",'OK','Information')
            return
        }
        $cfg = Get-Content $Global:ConfigFile -Raw | ConvertFrom-Json

        $TxtServerName.Text = $cfg.ServerName
        $TxtOrg.Text        = $cfg.Organisation
        $TxtDomain.Text     = $cfg.Domain
        $TxtDBPath.Text     = $cfg.DBPath
        $TxtLogP.Text       = $cfg.LogPath

        foreach ($key in $CheckBoxes.Keys) {
            if ($cfg.Optionen.PSObject.Properties.Name -contains $key) {
                $CheckBoxes[$key].Checked = [bool]$cfg.Optionen.$key
            }
        }

        $DgvDB.Rows.Clear()
        foreach ($db in $cfg.Datenbanken) {
            $DgvDB.Rows.Add($db.DBName, $db.Server, $db.EdbFilePath, $db.LogFolderPath) | Out-Null
        }

        $TxtDAGName.Text     = $cfg.DAG.Name
        $TxtWitness.Text     = $cfg.DAG.Witness
        $TxtWitnessDir.Text  = $cfg.DAG.WitnessDir
        $TxtDAGIP.Text       = $cfg.DAG.IP
        $ChkIPlessDAG.Checked = [bool]$cfg.DAG.IPless
        $TxtMembers.Text     = ($cfg.DAG.Mitglieder -join "`r`n")

        Write-Log -Message "Konfiguration geladen aus: $Global:ConfigFile" -Level "SUCCESS"
    }
    catch {
        Write-Log -Message "Fehler beim Laden der Konfiguration: $_" -Level "ERROR"
    }
})
$TabZusammen.Controls.Add($BtnLoadConfig)

# Button: Log-Datei öffnen
$BtnOpenLog         = New-Object System.Windows.Forms.Button
$BtnOpenLog.Text    = "Logdatei öffnen"
$BtnOpenLog.Location = New-Object System.Drawing.Point(610, 470)
$BtnOpenLog.Size    = New-Object System.Drawing.Size(180, 30)
$BtnOpenLog.Add_Click({
    try {
        if (Test-Path $Global:LogFile) {
            Start-Process notepad.exe $Global:LogFile
        }
        else {
            [System.Windows.Forms.MessageBox]::Show("Logdatei existiert noch nicht.","Info",'OK','Information')
        }
    }
    catch {
        Write-Log -Message "Fehler beim Öffnen der Logdatei: $_" -Level "ERROR"
    }
})
$TabZusammen.Controls.Add($BtnOpenLog)
#endregion

#region Statusleiste
$Global:StatusLabel  = New-Object System.Windows.Forms.Label
$Global:StatusLabel.Location = New-Object System.Drawing.Point(10, 620)
$Global:StatusLabel.Size = New-Object System.Drawing.Size(815, 25)
$Global:StatusLabel.BorderStyle = 'Fixed3D'
$Global:StatusLabel.Text = "Bereit. Logdatei: $Global:LogFile"
$Form.Controls.Add($Global:StatusLabel)

# Beenden-Button
$BtnExit            = New-Object System.Windows.Forms.Button
$BtnExit.Text       = "Beenden"
$BtnExit.Location   = New-Object System.Drawing.Point(720, 650)
$BtnExit.Size       = New-Object System.Drawing.Size(100, 30)
$BtnExit.Add_Click({ $Form.Close() })
$Form.Controls.Add($BtnExit)
#endregion

#region GUI starten
try {
    Write-Log -Message "Exchange-Konfigurations-GUI gestartet." -Level "INFO"
    [void]$Form.ShowDialog()
    Write-Log -Message "GUI beendet." -Level "INFO"
}
catch {
    Write-Log -Message "Kritischer Fehler beim Anzeigen der GUI: $_" -Level "ERROR"
}
finally {
    if ($Form) { $Form.Dispose() }
}
#endregion
