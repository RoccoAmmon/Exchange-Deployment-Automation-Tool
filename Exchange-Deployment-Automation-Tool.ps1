<#
.SYNOPSIS
    Exchange 2019 SE - All-in-One Konfigurations-Center v3.5

.DESCRIPTION
    Vollstaendige GUI-basierte Exchange 2019 SE Installation:
    - Tab 'Voraussetzungen': .NET 4.8, VC++, URL-Rewrite, UCMA, Windows-Features, SMB1, Pagefile, Powerplan
    - Tab 'AD-Vorbereitung': Schema/AD/Domain mit Smart Auto-Selection
    - Tab 'Installation': ISO-Auto-Erkennung + Setup-Parameter
    - Tab 'Sicherheit': TLS-Hardening (TLS 1.2 + 1.3)
    - Tab 'Antispam': SCL + 5 Filter
    - Tab 'Datenbanken': DB-Generator (Praefix + Anzahl)
    - Tab 'DAG': Database Availability Group
    - Tab 'Ausfuehrung': Live-Output aus ExchangeSetup.log

.AUTHOR Rocco Ammon, SVA
.VERSION 3.5 - Voraussetzungen-Tab integriert + verbesserte Live-Logs

.NOTES
    NICHT IN DER ISE AUSFUEHREN! Rechtsklick -> "Mit PowerShell ausfuehren"
    Speichern als UTF-8 mit BOM!
#>

#region ============================ GLOBALE VARIABLEN ============================
$Global:LogPath          = "C:\ScriptLog"
$Global:LogFile          = Join-Path $Global:LogPath "Exchange2019-SE_GUI_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$Global:ConfigPath       = Join-Path $Global:LogPath "Config"
$Global:ConfigFile       = Join-Path $Global:ConfigPath "ExchangeFullConfig.json"

$Global:ExchangeBinPath      = "C:\Program Files\Microsoft\Exchange Server\V15\bin"
$Global:RemoteExchangeScript = Join-Path $Global:ExchangeBinPath "RemoteExchange.ps1"
$Global:DefaultInstallPath   = "C:\Program Files\Microsoft\Exchange Server\V15"
$Global:ExchangeSetupLog     = "C:\ExchangeSetupLogs\ExchangeSetup.log"

$Global:DefaultDBPath    = "D:\ExchangeDatabases"
$Global:DefaultLogDBPath = "E:\ExchangeLogs"
$Global:DefaultTempPath  = "C:\ExchangeInstall\Temp"

$Global:DetectedISOs       = @()
$Global:ADStatusLoaded     = $false
$Global:PrereqStatusLoaded = $false

$Global:FormWidth        = 1150
$Global:FormHeight       = 820

$Global:ColorBackground  = [System.Drawing.Color]::FromArgb(245, 247, 250)
$Global:ColorPanel       = [System.Drawing.Color]::FromArgb(255, 255, 255)
$Global:ColorPanelAlt    = [System.Drawing.Color]::FromArgb(235, 240, 247)
$Global:ColorAccent      = [System.Drawing.Color]::FromArgb(0, 120, 215)
$Global:ColorAccent2     = [System.Drawing.Color]::FromArgb(16, 137, 62)
$Global:ColorWarning     = [System.Drawing.Color]::FromArgb(202, 120, 12)
$Global:ColorError       = [System.Drawing.Color]::FromArgb(196, 43, 28)
$Global:ColorText        = [System.Drawing.Color]::FromArgb(32, 32, 32)
$Global:ColorTextDim     = [System.Drawing.Color]::FromArgb(100, 100, 100)
$Global:ColorInputBg     = [System.Drawing.Color]::FromArgb(255, 255, 255)
$Global:ColorBorder      = [System.Drawing.Color]::FromArgb(200, 205, 215)

$Global:FontDefault      = New-Object System.Drawing.Font("Segoe UI", 9)
$Global:FontBold         = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$Global:FontHeader       = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$Global:FontMono         = New-Object System.Drawing.Font("Consolas", 9)
#endregion

#region ============================ INIT ============================
try {
    foreach ($p in @($Global:LogPath, $Global:ConfigPath, $Global:DefaultTempPath)) {
        if (-not (Test-Path $p)) { New-Item -Path $p -ItemType Directory -Force | Out-Null }
    }
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()
}
catch {
    Write-Host ("Fehler beim Initialisieren: " + $_) -ForegroundColor Red
    exit 1
}

# ISE-Warnung
if ($psISE -or $Host.Name -match 'ISE') {
    [System.Windows.Forms.MessageBox]::Show(
        "WARNUNG: Sie fuehren das Skript in der PowerShell ISE aus!`r`n`r`n" +
        "Die ISE crasht bei Setup-Sub-Prozessen.`r`n`r`n" +
        "BITTE so ausfuehren:`r`n  Rechtsklick auf .ps1 -> 'Mit PowerShell ausfuehren'",
        "ISE-Warnung",'OK','Warning')
}
#endregion

#region ============================ LOGGING ============================
function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet("INFO","WARNING","ERROR","SUCCESS")][string]$Level = "INFO"
    )
    try {
        $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $line = "[$ts] [$Level] $Message"
        Add-Content -Path $Global:LogFile -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue

        if ($Global:LogTextBox) {
            $color = switch ($Level) {
                "ERROR"   { [System.Drawing.Color]::FromArgb(196, 43, 28) }
                "WARNING" { [System.Drawing.Color]::FromArgb(202, 120, 12) }
                "SUCCESS" { [System.Drawing.Color]::FromArgb(16, 137, 62) }
                default   { [System.Drawing.Color]::FromArgb(32, 32, 32) }
            }
            $Global:LogTextBox.SelectionStart  = $Global:LogTextBox.TextLength
            $Global:LogTextBox.SelectionLength = 0
            $Global:LogTextBox.SelectionColor  = $color
            $Global:LogTextBox.AppendText("$line`r`n")
            $Global:LogTextBox.ScrollToCaret()
        }
        if ($Global:StatusLabel) {
            $Global:StatusLabel.Text = "  [$Level] $Message"
            $Global:StatusLabel.ForeColor = switch ($Level) {
                "ERROR"   { $Global:ColorError }
                "WARNING" { $Global:ColorWarning }
                "SUCCESS" { $Global:ColorAccent2 }
                default   { $Global:ColorText }
            }
        }
        try { [System.Windows.Forms.Application]::DoEvents() } catch {}
    }
    catch { Write-Host ("Logging-Fehler: " + $_) -ForegroundColor Red }
}
#endregion

#region ============================ ISO-AUTOERKENNUNG ============================
function Find-MountedExchangeISO {
    $found = @()
    try {
        Write-Log "ISO-Auto-Erkennung..." -Level INFO
        $letters = [char[]](65..90) | ForEach-Object { [string]$_ }

        foreach ($letter in $letters) {
            $driveLetter = "${letter}:"
            $rootPath    = "${letter}:\"
            $setupPath   = "${letter}:\Setup.exe"

            if (-not (Test-Path $rootPath -ErrorAction SilentlyContinue)) { continue }

            $volumeName = $null
            try {
                $vol = Get-Volume -DriveLetter $letter -ErrorAction SilentlyContinue
                if ($vol -and $vol.FileSystemLabel) { $volumeName = $vol.FileSystemLabel }
            } catch {}
            if (-not $volumeName) {
                try {
                    $logical = Get-CimInstance -ClassName Win32_LogicalDisk `
                        -Filter "DeviceID='$driveLetter'" -ErrorAction SilentlyContinue
                    if ($logical -and $logical.VolumeName) { $volumeName = $logical.VolumeName }
                } catch {}
            }
            if (-not $volumeName) { $volumeName = "(kein Label)" }

            $hasSetup = Test-Path $setupPath -ErrorAction SilentlyContinue
            $isExchange = $false
            $reason     = ""

            if ($volumeName -match '(?i)EXCHANGE') { $isExchange = $true; $reason = "Label '$volumeName'" }

            if (-not $isExchange -and $hasSetup) {
                foreach ($ind in @("Setup\ServerRoles","Setup\Data","UCMARedist")) {
                    if (Test-Path (Join-Path $rootPath $ind) -ErrorAction SilentlyContinue) {
                        $isExchange = $true; $reason = "Ordner '$ind'"; break
                    }
                }
            }

            if ($isExchange) {
                $found += [PSCustomObject]@{
                    DriveLetter = $driveLetter
                    VolumeName  = $volumeName
                    SetupPath   = $setupPath
                    Display     = ("{0}  ({1})  -  {2}" -f $driveLetter, $volumeName, $reason)
                }
                Write-Log ("EXCHANGE-ISO auf " + $driveLetter + " (" + $reason + ")") -Level SUCCESS
            }
        }
        if ($found.Count -eq 0) { Write-Log "Keine Exchange-ISO gefunden" -Level WARNING }
    }
    catch { Write-Log ("Fehler bei ISO-Suche: " + $_) -Level ERROR }
    return $found
}
#endregion

#region ============================ TLS HARDENING ============================
function Set-TLSHardening {
    try {
        Write-Log "Starte TLS-Hardening..." -Level INFO
        $protocols = @{
            "SSL 2.0"=$false; "SSL 3.0"=$false; "TLS 1.0"=$false; "TLS 1.1"=$false
            "TLS 1.2"=$true;  "TLS 1.3"=$true
        }
        $base = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols"
        foreach ($proto in $protocols.Keys) {
            $enabled = $protocols[$proto]
            foreach ($side in @("Server","Client")) {
                $sidePath = Join-Path (Join-Path $base $proto) $side
                if (-not (Test-Path $sidePath)) { New-Item -Path $sidePath -Force | Out-Null }
                if ($enabled) {
                    New-ItemProperty -Path $sidePath -Name "Enabled" -Value 0xFFFFFFFF -PropertyType DWord -Force | Out-Null
                    New-ItemProperty -Path $sidePath -Name "DisabledByDefault" -Value 0 -PropertyType DWord -Force | Out-Null
                } else {
                    New-ItemProperty -Path $sidePath -Name "Enabled" -Value 0 -PropertyType DWord -Force | Out-Null
                    New-ItemProperty -Path $sidePath -Name "DisabledByDefault" -Value 1 -PropertyType DWord -Force | Out-Null
                }
                Write-Log ("  $proto $side : " + (if ($enabled){"AKTIV"}else{"DEAKTIV"})) -Level INFO
            }
        }
        $netPaths = @(
            "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319"
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
        Write-Log "TLS-Hardening abgeschlossen - NEUSTART erforderlich!" -Level SUCCESS
        return $true
    }
    catch { Write-Log ("Fehler: " + $_) -Level ERROR; return $false }
}
#endregion

#region ============================ PREREQ-FUNKTIONEN ============================
function Test-VCRedistInstalled {
    param([string]$DisplayName)
    foreach ($key in @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                       "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")) {
        if (Get-ItemProperty $key -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like "*$DisplayName*" }) { return $true }
    }
    return $false
}

function Test-DotNet48 {
    try {
        $rel = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue).Release
        return ($rel -ge 528040)
    } catch { return $false }
}

function Test-URLRewrite { return (Test-Path "$env:SystemRoot\System32\inetsrv\rewrite.dll") }

function Test-UCMA {
    foreach ($key in @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                       "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")) {
        if (Get-ItemProperty $key -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like "*Unified Communications Managed API 4.0*" }) { return $true }
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
    $missingFeatures = @()
    try {
        foreach ($f in $features) {
            $st = Get-WindowsFeature -Name $f -ErrorAction SilentlyContinue
            if ($st -and -not $st.Installed) { $missingFeatures += $f }
        }
    } catch {}

    $smb1Enabled = $false
    try {
        $smb1 = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue
        if ($smb1 -and $smb1.State -eq "Enabled") { $smb1Enabled = $true }
    } catch {}

    return [PSCustomObject]@{
        DotNet48        = Test-DotNet48
        VC2012          = Test-VCRedistInstalled "Visual C++ 2012 x64"
        VC2013          = Test-VCRedistInstalled "Visual C++ 2013 x64"
        URLRewrite      = Test-URLRewrite
        UCMA            = Test-UCMA
        Features        = $features
        MissingFeatures = $missingFeatures
        FeaturesOK      = ($missingFeatures.Count -eq 0)
        SMB1Enabled     = $smb1Enabled
    }
}

function Install-PrerequisiteSoftware {
    param(
        [bool]$InstallDotNet      = $true,
        [bool]$InstallVC2012      = $true,
        [bool]$InstallVC2013      = $true,
        [bool]$InstallURLRewrite  = $true,
        [bool]$InstallUCMA        = $true,
        [bool]$InstallFeatures    = $true,
        [bool]$DisableSMB1        = $true,
        [bool]$OptimizePageFile   = $true,
        [bool]$SetHighPerformance = $true
    )
    Write-Log "==============================================" -Level INFO
    Write-Log " EXCHANGE-VORAUSSETZUNGEN INSTALLIEREN" -Level INFO
    Write-Log "==============================================" -Level INFO

    $tempDir = $Global:DefaultTempPath
    if (-not (Test-Path $tempDir)) { New-Item -Path $tempDir -ItemType Directory -Force | Out-Null }

    if ($InstallDotNet) {
        if (Test-DotNet48) { Write-Log "[1/8] .NET 4.8+ bereits installiert" -Level SUCCESS }
        else {
            Write-Log "[1/8] Installiere .NET Framework 4.8..." -Level INFO
            try {
                $url  = "https://download.microsoft.com/download/2/4/8/24892799-1635-47E3-AAD7-9842E59990C3/ndp48-web.exe"
                $file = Join-Path $tempDir "ndp48-web.exe"
                if (-not (Test-Path $file)) {
                    Write-Log "  Download laeuft..." -Level INFO
                    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                    Invoke-WebRequest -Uri $url -OutFile $file -UseBasicParsing
                }
                Start-Process -FilePath $file -ArgumentList "/quiet /norestart" -Wait
                Write-Log "  .NET 4.8 installiert (Neustart spaeter empfohlen)" -Level SUCCESS
            } catch { Write-Log ("  Fehler: " + $_) -Level ERROR }
        }
    }

    if ($InstallVC2012) {
        if (Test-VCRedistInstalled "Visual C++ 2012 x64") { Write-Log "[2/8] VC++ 2012 bereits installiert" -Level SUCCESS }
        else {
            Write-Log "[2/8] Installiere VC++ 2012 x64..." -Level INFO
            try {
                $url  = "https://download.microsoft.com/download/1/6/b/16b06f60-3b20-4ff2-b699-5e9b7962f9ae/VSU_4/vcredist_x64.exe"
                $file = Join-Path $tempDir "vcredist2012_x64.exe"
                if (-not (Test-Path $file)) { Invoke-WebRequest -Uri $url -OutFile $file -UseBasicParsing }
                Start-Process -FilePath $file -ArgumentList "/install /quiet /norestart" -Wait
                Write-Log "  VC++ 2012 installiert" -Level SUCCESS
            } catch { Write-Log ("  Fehler: " + $_) -Level ERROR }
        }
    }

    if ($InstallVC2013) {
        if (Test-VCRedistInstalled "Visual C++ 2013 x64") { Write-Log "[3/8] VC++ 2013 bereits installiert" -Level SUCCESS }
        else {
            Write-Log "[3/8] Installiere VC++ 2013 x64..." -Level INFO
            try {
                $url  = "https://download.visualstudio.microsoft.com/download/pr/10912041/cee5d6bca2ddbcd039da727bf4acb48a/vcredist_x64.exe"
                $file = Join-Path $tempDir "vcredist2013_x64.exe"
                if (-not (Test-Path $file)) { Invoke-WebRequest -Uri $url -OutFile $file -UseBasicParsing }
                Start-Process -FilePath $file -ArgumentList "/install /quiet /norestart" -Wait
                Write-Log "  VC++ 2013 installiert" -Level SUCCESS
            } catch { Write-Log ("  Fehler: " + $_) -Level ERROR }
        }
    }

    if ($InstallURLRewrite) {
        if (Test-URLRewrite) { Write-Log "[4/8] URL Rewrite bereits installiert" -Level SUCCESS }
        else {
            Write-Log "[4/8] Installiere IIS URL Rewrite 2.1..." -Level INFO
            try {
                $url  = "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi"
                $file = Join-Path $tempDir "rewrite_2.1_x64.msi"
                if (-not (Test-Path $file)) { Invoke-WebRequest -Uri $url -OutFile $file -UseBasicParsing }
                Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$file`" /quiet /norestart" -Wait
                Write-Log "  URL Rewrite installiert" -Level SUCCESS
            } catch { Write-Log ("  Fehler: " + $_) -Level ERROR }
        }
    }

    if ($InstallUCMA) {
        if (Test-UCMA) { Write-Log "[5/8] UCMA 4.0 bereits installiert" -Level SUCCESS }
        else {
            Write-Log "[5/8] Installiere UCMA 4.0..." -Level INFO
            try {
                $ucmaInstaller = $null
                foreach ($iso in $Global:DetectedISOs) {
                    $candidate = Join-Path (Split-Path $iso.SetupPath) "UCMARedist\Setup.exe"
                    if (Test-Path $candidate) { $ucmaInstaller = $candidate; break }
                }
                if ($ucmaInstaller) {
                    Write-Log ("  UCMA-Installer: " + $ucmaInstaller) -Level INFO
                    Start-Process -FilePath $ucmaInstaller -ArgumentList "/quiet /norestart" -Wait
                    Write-Log "  UCMA 4.0 installiert" -Level SUCCESS
                } else {
                    Write-Log "  UCMA-Installer nicht gefunden (\UCMARedist\Setup.exe auf ISO)" -Level WARNING
                }
            } catch { Write-Log ("  Fehler: " + $_) -Level ERROR }
        }
    }

    if ($InstallFeatures) {
        Write-Log "[6/8] Pruefe Windows-Features..." -Level INFO
        $status = Get-PrerequisiteStatus
        if ($status.FeaturesOK) { Write-Log "  Alle Windows-Features bereits installiert" -Level SUCCESS }
        else {
            Write-Log ("  " + $status.MissingFeatures.Count + " Feature(s) fehlen - werden installiert...") -Level INFO
            try {
                $result = Install-WindowsFeature -Name $status.MissingFeatures -ErrorAction Stop
                Write-Log "  Windows-Features installiert" -Level SUCCESS
                if ($result.RestartNeeded -eq "Yes") {
                    Write-Log "  >>> NEUSTART ERFORDERLICH! <<<" -Level WARNING
                }
            } catch { Write-Log ("  Fehler: " + $_) -Level ERROR }
        }
    }

    if ($DisableSMB1) {
        Write-Log "[7/8] SMB1-Deaktivierung..." -Level INFO
        try {
            $smb1 = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue
            if ($smb1 -and $smb1.State -eq "Enabled") {
                Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction Stop | Out-Null
                Write-Log "  SMB1 deaktiviert" -Level SUCCESS
            } else { Write-Log "  SMB1 bereits deaktiviert" -Level SUCCESS }
        } catch { Write-Log ("  Fehler: " + $_) -Level WARNING }
    }

    if ($SetHighPerformance) {
        Write-Log "[8/8] High-Performance-Powerplan + Pagefile..." -Level INFO
        try {
            powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>&1 | Out-Null
            Write-Log "  High-Performance-Powerplan aktiv" -Level SUCCESS
        } catch { Write-Log ("  Fehler: " + $_) -Level WARNING }

        if ($OptimizePageFile) {
            try {
                $ramMB = [int]((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1MB)
                $pfsize = $ramMB + 10
                $cs = Get-CimInstance -ClassName Win32_ComputerSystem
                if ($cs.AutomaticManagedPagefile) {
                    $cs | Set-CimInstance -Property @{AutomaticManagedPagefile=$false} -ErrorAction SilentlyContinue
                }
                $pf = Get-CimInstance -ClassName Win32_PageFileSetting -ErrorAction SilentlyContinue
                if ($pf) {
                    $pf | Set-CimInstance -Property @{InitialSize=$pfsize; MaximumSize=$pfsize} -ErrorAction SilentlyContinue
                    Write-Log ("  Pagefile: " + $pfsize + " MB") -Level SUCCESS
                }
            } catch { Write-Log ("  Pagefile-Fehler: " + $_) -Level WARNING }
        }
    }

    Write-Log "==============================================" -Level INFO
    Write-Log " VORAUSSETZUNGEN ABGESCHLOSSEN" -Level SUCCESS
    Write-Log "==============================================" -Level INFO
}
#endregion

#region ============================ EXCHANGE-FUNKTIONEN ============================
function Import-ExchangeManagementShell {
    try {
        if (Get-Command Get-MailboxDatabase -ErrorAction SilentlyContinue) { return $true }
        if (Test-Path $Global:RemoteExchangeScript) {
            . $Global:RemoteExchangeScript
            Connect-ExchangeServer -auto -ClientApplication:ManagementShell
            Write-Log "Exchange Shell geladen" -Level SUCCESS
            return $true
        }
        return $false
    } catch { Write-Log ("Fehler: " + $_) -Level ERROR; return $false }
}

function Test-ExchangePrerequisites {
    param([string]$ExchangeISOPath)
    $errors = @()
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        if ($os.Caption -notlike "*Windows Server*") { $errors += "Kein Windows Server" }
        $ram = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        if ($ram -lt 8) { $errors += "RAM < 8 GB ($ram GB)" }
        $sysDrive = Get-PSDrive -Name ($env:SystemDrive.Replace(":",""))
        $freeGB = [math]::Round($sysDrive.Free / 1GB, 2)
        if ($freeGB -lt 30) { $errors += "Freier Speicher < 30 GB" }
        if ($ExchangeISOPath -and -not (Test-Path $ExchangeISOPath)) {
            $errors += "ISO nicht gefunden: $ExchangeISOPath"
        }
        if ($errors.Count -gt 0) {
            foreach ($e in $errors) { Write-Log ("  - " + $e) -Level ERROR }
            return $false
        }
        Write-Log "Voraussetzungen erfuellt" -Level SUCCESS
        return $true
    } catch { Write-Log ("Fehler: " + $_) -Level ERROR; return $false }
}

function Mount-ExchangeISO {
    param([Parameter(Mandatory)][string]$ISOPath)
    try {
        $mr = Mount-DiskImage -ImagePath $ISOPath -PassThru
        Start-Sleep -Seconds 2
        $drive = ($mr | Get-Volume).DriveLetter
        if ($drive) { return ("${drive}:\Setup.exe") }
        throw "Drive nicht ermittelbar"
    } catch { Write-Log ("Mount-Fehler: " + $_) -Level ERROR; return $null }
}

function Dismount-ExchangeISO {
    param([Parameter(Mandatory)][string]$ISOPath)
    try { Dismount-DiskImage -ImagePath $ISOPath -ErrorAction Stop } catch {}
}

# ============================================================
# RESPONSIVE Setup-Ausfuehrung MIT GEFILTERTEM LIVE-TAILING
# ============================================================
function Invoke-ResponsiveProcess {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$Arguments,
        [string]$LogPrefix = "Setup",
        [int]$HeartbeatSec = 60,
        [string]$ExchangeSetupLog = $Global:ExchangeSetupLog,
        [bool]$TailExchangeLog = $true
    )
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName  = $FilePath
        $psi.Arguments = ($Arguments -join ' ')
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow  = $true
        $psi.WindowStyle     = 'Hidden'

        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $psi

        $logStartPos = 0L
        if ($TailExchangeLog -and (Test-Path $ExchangeSetupLog)) {
            try { $logStartPos = (Get-Item $ExchangeSetupLog).Length } catch {}
        }

        [void]$proc.Start()
        Write-Log ("PID: " + $proc.Id + " gestartet") -Level INFO
        Write-Log "----------- LIVE-MEILENSTEINE -----------" -Level INFO

        $startTime     = Get-Date
        $lastHeartBeat = Get-Date
        $lastLogPos    = $logStartPos
        $linesShown    = 0
        $lastTask      = ""

        # Whitelist - nur DIESE Patterns werden angezeigt
        $importantPatterns = @(
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
            @{Pattern='Updating Schema'; Level='INFO'},
            @{Pattern='Microsoft Exchange Server Setup'; Level='INFO'}
        )
        $errorPatterns   = @('\[ERROR\]','Setup encountered an error','A fatal error occurred','Setup cannot continue','Failed with error','FAILED')
        $warningPatterns = @('\[WARNING\]','recommendation:','is not recommended')

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
                            foreach ($pat in $errorPatterns) {
                                if ($line -match $pat) { $level = "ERROR"; break }
                            }
                            if (-not $level) {
                                foreach ($pat in $warningPatterns) {
                                    if ($line -match $pat) { $level = "WARNING"; break }
                                }
                            }
                            if (-not $level) {
                                foreach ($pat in $importantPatterns) {
                                    if ($line -match $pat.Pattern) { $level = $pat.Level; break }
                                }
                            }
                            if (-not $level) { continue }

                            # Datums-Prefix entfernen (deutsch + englisch)
                            $cleanLine = $line `
                                -replace '^\[\d{2}[\./]\d{2}[\./]\d{4}\s+\d{2}:\d{2}:\d{2}\.\d+\]\s*\[\d+\]\s*','' `
                                -replace '^\[\d{2}[\./]\d{2}[\./]\d{4}\s+\d{2}:\d{2}:\d{2}\.\d+\]\s*',''
                            $shortLine = $cleanLine.Trim()
                            if ($shortLine.Length -gt 200) { $shortLine = $shortLine.Substring(0,200) + "..." }

                            # Task-Gruppierung
                            if ($shortLine -match "Beginning processing (\w+\s*\w*)") {
                                $task = $matches[1]
                                if ($task -ne $lastTask) {
                                    Write-Log "" -Level INFO
                                    Write-Log (">>> START: " + $task) -Level INFO
                                    $lastTask = $task; $linesShown++
                                    continue
                                }
                            }
                            if ($shortLine -match "Ending processing (\w+\s*\w*)") {
                                Write-Log ("<<< FERTIG: " + $matches[1]) -Level SUCCESS
                                Write-Log "" -Level INFO
                                $linesShown++
                                continue
                            }

                            Write-Log ("    " + $shortLine) -Level $level
                            $linesShown++
                        }
                        $lastLogPos = $fs.Position
                        $sr.Close(); $fs.Close()
                    }
                } catch {}
            }

            if (((Get-Date) - $lastHeartBeat).TotalSeconds -ge $HeartbeatSec) {
                $elapsed = ((Get-Date) - $startTime).ToString("hh\:mm\:ss")
                Write-Log ("  ... $LogPrefix laeuft | Laufzeit: $elapsed | Meilensteine: $linesShown") -Level INFO
                $lastHeartBeat = Get-Date
            }
        }

        Start-Sleep -Milliseconds 1000
        Write-Log "----------- FERTIG -----------" -Level INFO
        $totalTime = ((Get-Date) - $startTime).ToString("hh\:mm\:ss")
        $lvl = if ($proc.ExitCode -eq 0) { "SUCCESS" } else { "ERROR" }
        Write-Log ("Exit-Code: " + $proc.ExitCode + " | Laufzeit: " + $totalTime) -Level $lvl
        return $proc.ExitCode
    }
    catch { Write-Log ("Fehler: " + $_) -Level ERROR; return -1 }
}

function Install-ExchangeServer {
    param(
        [Parameter(Mandatory)][string]$SetupPath,
        [Parameter(Mandatory)][string]$OrgName
    )
    try {
        Write-Log "Starte Exchange Setup (kann Stunden dauern)..." -Level INFO
        $arguments = @(
            "/mode:Install","/role:Mailbox",
            "/OrganizationName:$OrgName",
            "/IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF",
            "/InstallWindowsComponents"
        )
        $exitCode = Invoke-ResponsiveProcess -FilePath $SetupPath -Arguments $arguments -LogPrefix "Exchange-Setup" -HeartbeatSec 60
        if ($exitCode -eq 0) { Write-Log "Exchange installiert" -Level SUCCESS; return $true }
        Write-Log ("Setup fehlgeschlagen: " + $exitCode) -Level ERROR
        return $false
    } catch { Write-Log ("Fehler: " + $_) -Level ERROR; return $false }
}

function Install-AntiSpamAgents {
    param([string]$InstallPath = $Global:DefaultInstallPath)
    try {
        $script = Join-Path $InstallPath "Scripts\Install-AntiSpamAgents.ps1"
        if (-not (Test-Path $script)) { Write-Log "Antispam-Script fehlt" -Level ERROR; return $false }
        & $script
        Restart-Service -Name MSExchangeTransport -Force
        Write-Log "Antispam-Agenten installiert" -Level SUCCESS
        return $true
    } catch { Write-Log ("Fehler: " + $_) -Level ERROR; return $false }
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
            Set-ContentFilterConfig -Enabled $true -RejectionResponse "Spam abgelehnt." `
                -SCLRejectEnabled $true -SCLRejectThreshold $SCLRejectThreshold `
                -SCLDeleteEnabled $true -SCLDeleteThreshold $SCLDeleteThreshold
        }
        if ($EnableSenderID)         { Set-SenderIDConfig -Enabled $true -SpoofedDomainAction Reject }
        if ($EnableSenderFilter)     { Set-SenderFilterConfig -Enabled $true -BlankSenderBlockingEnabled $true }
        if ($EnableRecipientFilter)  { Set-RecipientFilterConfig -Enabled $true -RecipientValidationEnabled $true }
        if ($EnableSenderReputation) { Set-SenderReputationConfig -Enabled $true -SenderBlockingEnabled $true -SenderBlockingPeriod 24 }
        Write-Log "Antispam konfiguriert" -Level SUCCESS
        return $true
    } catch { Write-Log ("Fehler: " + $_) -Level ERROR; return $false }
}

function Test-ExchangeInstallation {
    try {
        $services = @("MSExchangeADTopology","MSExchangeIS","MSExchangeTransport","MSExchangeRPC")
        $errs = @()
        foreach ($s in $services) {
            $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
            if (-not $svc -or $svc.Status -ne "Running") { $errs += "$s nicht aktiv" }
        }
        if ($errs.Count -gt 0) { foreach ($e in $errs) { Write-Log $e -Level ERROR }; return $false }
        Write-Log "Installation OK" -Level SUCCESS
        return $true
    } catch { return $false }
}

# AD-Funktionen
function Get-ExchangeSchemaInfo {
    $info = [PSCustomObject]@{
        SchemaVersion="Unbekannt"; OrgVersion="Unbekannt"; DomainVersion="Unbekannt"
        SchemaVersionNeeded="17004"; OrgVersionNeeded="16762"; DomainVersionNeeded="13243"
        SchemaOK=$false; OrgOK=$false; DomainOK=$false
        ConfigNC=""; DomainNC=""; ExchangeOrgName=""
    }
    try {
        $rootDSE = [ADSI]"LDAP://RootDSE"
        $info.ConfigNC = "$($rootDSE.configurationNamingContext)"
        $info.DomainNC = "$($rootDSE.defaultNamingContext)"
        try {
            $so = [ADSI]"LDAP://CN=ms-Exch-Schema-Version-Pt,$($rootDSE.schemaNamingContext)"
            if ($so.rangeUpper) {
                $info.SchemaVersion = "$($so.rangeUpper)"
                $info.SchemaOK = ([int]$info.SchemaVersion -ge [int]$info.SchemaVersionNeeded)
            }
        } catch {}
        try {
            $ec = [ADSI]"LDAP://CN=Microsoft Exchange,CN=Services,$($info.ConfigNC)"
            foreach ($child in $ec.psbase.Children) {
                if ($child.objectClass -contains "msExchOrganizationContainer") {
                    $info.ExchangeOrgName = "$($child.cn)"
                    if ($child.ObjectVersion) {
                        $info.OrgVersion = "$($child.ObjectVersion)"
                        $info.OrgOK = ([int]$info.OrgVersion -ge [int]$info.OrgVersionNeeded)
                    }
                    break
                }
            }
        } catch {}
        try {
            $do = [ADSI]"LDAP://CN=Microsoft Exchange System Objects,$($info.DomainNC)"
            if ($do.ObjectVersion) {
                $info.DomainVersion = "$($do.ObjectVersion)"
                $info.DomainOK = ([int]$info.DomainVersion -ge [int]$info.DomainVersionNeeded)
            }
        } catch {}
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
        $groups = $cu.Groups | ForEach-Object {
            try { $_.Translate([Security.Principal.NTAccount]).Value } catch { $null }
        }
        foreach ($g in $groups) {
            if ($g -match "Schema-Admins|Schema Admins")            { $r.IsSchemaAdmin     = $true }
            if ($g -match "Organisations-Admins|Enterprise Admins") { $r.IsEnterpriseAdmin = $true }
            if ($g -match "Domain-?Admins|Dom.nen-Admins")          { $r.IsDomainAdmin     = $true }
        }
    } catch {}
    return $r
}

function Get-ADDomainList {
    try {
        return ([System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest().Domains |
                ForEach-Object { $_.Name })
    } catch { return @() }
}

function Invoke-ExchangePrepareStep {
    param(
        [Parameter(Mandatory)][string]$SetupPath,
        [Parameter(Mandatory)][ValidateSet("PrepareSchema","PrepareAD","PrepareAllDomains","PrepareDomain")][string]$Step,
        [string]$OrgName,[string]$DomainName
    )
    try {
        Write-Log ("Starte: " + $Step) -Level INFO
        $arguments = @("/IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF")
        switch ($Step) {
            "PrepareSchema"     { $arguments += "/PrepareSchema" }
            "PrepareAD"         { $arguments += "/PrepareAD"; if ($OrgName) { $arguments += "/OrganizationName:$OrgName" } }
            "PrepareAllDomains" { $arguments += "/PrepareAllDomains" }
            "PrepareDomain"     { if ($DomainName) { $arguments += "/PrepareDomain:$DomainName" } else { $arguments += "/PrepareDomain" } }
        }
        $ec = Invoke-ResponsiveProcess -FilePath $SetupPath -Arguments $arguments -LogPrefix $Step -HeartbeatSec 30
        if ($ec -eq 0) { Write-Log ($Step + " OK") -Level SUCCESS; return $true }
        Write-Log ($Step + " FEHLER: " + $ec) -Level ERROR
        return $false
    } catch { Write-Log ("Fehler: " + $_) -Level ERROR; return $false }
}

function Wait-ADReplication {
    param([int]$Minutes = 5)
    Write-Log ("Warte " + $Minutes + " Min auf AD-Replikation...") -Level INFO
    $endTime = (Get-Date).AddMinutes($Minutes)
    $lastLog = Get-Date
    while ((Get-Date) -lt $endTime) {
        try { [System.Windows.Forms.Application]::DoEvents() } catch {}
        Start-Sleep -Milliseconds 500
        if (((Get-Date) - $lastLog).TotalSeconds -ge 30) {
            $rem = $endTime - (Get-Date)
            Write-Log ("  Verbleibend: " + ("{0:D2}:{1:D2}" -f [int]$rem.Minutes,[int]$rem.Seconds)) -Level INFO
            $lastLog = Get-Date
        }
    }
    Write-Log "Wartezeit beendet" -Level SUCCESS
}
#endregion

#region ============================ HELPER GUI ============================
function New-Label {
    param([string]$Text,[int]$X,[int]$Y,[int]$W=200,[System.Drawing.Font]$Font=$Global:FontDefault)
    $l = New-Object System.Windows.Forms.Label
    $l.Text=$Text; $l.Location=New-Object System.Drawing.Point($X,$Y); $l.Size=New-Object System.Drawing.Size($W,22)
    $l.ForeColor=$Global:ColorText; $l.BackColor=[System.Drawing.Color]::Transparent; $l.Font=$Font
    return $l
}
function New-TextBox {
    param([int]$X,[int]$Y,[int]$W=300,[string]$Default="")
    $t = New-Object System.Windows.Forms.TextBox
    $t.Location=New-Object System.Drawing.Point($X,$Y); $t.Size=New-Object System.Drawing.Size($W,22)
    $t.BackColor=$Global:ColorInputBg; $t.ForeColor=$Global:ColorText
    $t.BorderStyle="FixedSingle"; $t.Text=$Default; $t.Font=$Global:FontDefault
    return $t
}
function New-CheckBox {
    param([string]$Text,[int]$X,[int]$Y,[int]$W=350,[bool]$Checked=$false)
    $c = New-Object System.Windows.Forms.CheckBox
    $c.Text=$Text; $c.Location=New-Object System.Drawing.Point($X,$Y); $c.Size=New-Object System.Drawing.Size($W,24)
    $c.ForeColor=$Global:ColorText; $c.BackColor=[System.Drawing.Color]::Transparent
    $c.Checked=$Checked; $c.Font=$Global:FontDefault
    return $c
}
function New-Button {
    param([string]$Text,[int]$X,[int]$Y,[int]$W=180,[int]$H=32,[System.Drawing.Color]$Color=$Global:ColorAccent)
    $b = New-Object System.Windows.Forms.Button
    $b.Text=$Text; $b.Location=New-Object System.Drawing.Point($X,$Y); $b.Size=New-Object System.Drawing.Size($W,$H)
    $b.FlatStyle="Flat"; $b.BackColor=$Color; $b.ForeColor=[System.Drawing.Color]::White
    $b.Font=$Global:FontBold; $b.FlatAppearance.BorderSize=0; $b.Cursor="Hand"
    return $b
}
function New-GroupBox {
    param([string]$Text,[int]$X,[int]$Y,[int]$W,[int]$H)
    $g = New-Object System.Windows.Forms.GroupBox
    $g.Text=$Text; $g.Location=New-Object System.Drawing.Point($X,$Y); $g.Size=New-Object System.Drawing.Size($W,$H)
    $g.ForeColor=$Global:ColorAccent; $g.BackColor=$Global:ColorPanel; $g.Font=$Global:FontBold
    return $g
}
function New-NumericUpDown {
    param([int]$X,[int]$Y,[int]$W=70,[int]$Min=0,[int]$Max=99,[int]$Value=1)
    $n = New-Object System.Windows.Forms.NumericUpDown
    $n.Location=New-Object System.Drawing.Point($X,$Y); $n.Size=New-Object System.Drawing.Size($W,22)
    $n.Minimum=$Min; $n.Maximum=$Max; $n.Value=$Value
    $n.BackColor=$Global:ColorInputBg; $n.ForeColor=$Global:ColorText; $n.Font=$Global:FontDefault
    return $n
}
#endregion

#region ============================ HAUPTFORMULAR ============================
$Form = New-Object System.Windows.Forms.Form
$Form.Text="Exchange 2019 SE - Konfigurations-Center v3.5"
$Form.Size=New-Object System.Drawing.Size($Global:FormWidth,$Global:FormHeight)
$Form.StartPosition="CenterScreen"; $Form.BackColor=$Global:ColorBackground
$Form.ForeColor=$Global:ColorText; $Form.Font=$Global:FontDefault
$Form.FormBorderStyle="Sizable"; $Form.MinimizeBox=$true; $Form.MaximizeBox=$true
$Form.MinimumSize=New-Object System.Drawing.Size(900,600)

$HeaderPanel = New-Object System.Windows.Forms.Panel
$HeaderPanel.Size=New-Object System.Drawing.Size($Global:FormWidth,65)
$HeaderPanel.Location=New-Object System.Drawing.Point(0,0)
$HeaderPanel.BackColor=$Global:ColorAccent

$LblTitle = New-Object System.Windows.Forms.Label
$LblTitle.Text="  Exchange 2019 SE  -  Konfigurations-Center"
$LblTitle.Font=$Global:FontHeader; $LblTitle.ForeColor=[System.Drawing.Color]::White
$LblTitle.Location=New-Object System.Drawing.Point(15,14); $LblTitle.Size=New-Object System.Drawing.Size(800,38)
$HeaderPanel.Controls.Add($LblTitle)

$LblSub = New-Object System.Windows.Forms.Label
$LblSub.Text="v3.5  |  Rocco Ammon, SVA"; $LblSub.Font=New-Object System.Drawing.Font("Segoe UI",10)
$LblSub.ForeColor=[System.Drawing.Color]::White
$LblSub.Location=New-Object System.Drawing.Point(($Global:FormWidth-220),27)
$LblSub.Size=New-Object System.Drawing.Size(210,20); $LblSub.TextAlign="MiddleRight"
$HeaderPanel.Controls.Add($LblSub)
$Form.Controls.Add($HeaderPanel)

$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location=New-Object System.Drawing.Point(10,75)
$TabControl.Size=New-Object System.Drawing.Size(($Global:FormWidth-25),615)
$TabControl.Font=$Global:FontDefault

$TabPrereq   = New-Object System.Windows.Forms.TabPage; $TabPrereq.Text   = "  Voraussetzungen  "
$TabADPrep   = New-Object System.Windows.Forms.TabPage; $TabADPrep.Text   = "  AD-Vorbereitung  "
$TabInstall  = New-Object System.Windows.Forms.TabPage; $TabInstall.Text  = "  Installation  "
$TabSecurity = New-Object System.Windows.Forms.TabPage; $TabSecurity.Text = "  Sicherheit / TLS  "
$TabAntiSpam = New-Object System.Windows.Forms.TabPage; $TabAntiSpam.Text = "  Antispam  "
$TabDB       = New-Object System.Windows.Forms.TabPage; $TabDB.Text       = "  Datenbanken  "
$TabDAG      = New-Object System.Windows.Forms.TabPage; $TabDAG.Text      = "  DAG  "
$TabRun      = New-Object System.Windows.Forms.TabPage; $TabRun.Text      = "  Ausfuehrung und Log  "

foreach ($t in @($TabPrereq,$TabADPrep,$TabInstall,$TabSecurity,$TabAntiSpam,$TabDB,$TabDAG,$TabRun)) {
    $t.BackColor=$Global:ColorBackground; $t.ForeColor=$Global:ColorText
}
$TabControl.TabPages.AddRange(@($TabPrereq,$TabADPrep,$TabInstall,$TabSecurity,$TabAntiSpam,$TabDB,$TabDAG,$TabRun))
$Form.Controls.Add($TabControl)
#endregion

#region ============================ TAB: VORAUSSETZUNGEN ============================
$GrpPS = New-GroupBox "Status der Voraussetzungen" 10 10 1080 280
$TabPrereq.Controls.Add($GrpPS)

$GrpPS.Controls.Add( (New-Label "Komponente" 20 28 280 $Global:FontBold) )
$GrpPS.Controls.Add( (New-Label "Status"     310 28 400 $Global:FontBold) )

$GrpPS.Controls.Add( (New-Label ".NET Framework 4.8+"          20 60 280) )
$Global:LblDotNet     = New-Label "..." 310 60 400 $Global:FontBold
$GrpPS.Controls.Add($Global:LblDotNet)

$GrpPS.Controls.Add( (New-Label "Visual C++ 2012 (x64)"        20 88 280) )
$Global:LblVC2012     = New-Label "..." 310 88 400 $Global:FontBold
$GrpPS.Controls.Add($Global:LblVC2012)

$GrpPS.Controls.Add( (New-Label "Visual C++ 2013 (x64)"        20 116 280) )
$Global:LblVC2013     = New-Label "..." 310 116 400 $Global:FontBold
$GrpPS.Controls.Add($Global:LblVC2013)

$GrpPS.Controls.Add( (New-Label "IIS URL Rewrite Module 2.1"   20 144 280) )
$Global:LblURLRewrite = New-Label "..." 310 144 400 $Global:FontBold
$GrpPS.Controls.Add($Global:LblURLRewrite)

$GrpPS.Controls.Add( (New-Label "UCMA 4.0 (von Exchange-ISO)"  20 172 280) )
$Global:LblUCMA       = New-Label "..." 310 172 400 $Global:FontBold
$GrpPS.Controls.Add($Global:LblUCMA)

$GrpPS.Controls.Add( (New-Label "Windows-Features (33x)"       20 200 280) )
$Global:LblFeatures   = New-Label "..." 310 200 400 $Global:FontBold
$GrpPS.Controls.Add($Global:LblFeatures)

$GrpPS.Controls.Add( (New-Label "SMB1 (sollte deaktiviert)"    20 228 280) )
$Global:LblSMB1       = New-Label "..." 310 228 400 $Global:FontBold
$GrpPS.Controls.Add($Global:LblSMB1)

$BtnRefreshPrereq = New-Button "Status aktualisieren" 870 28 200 32 $Global:ColorAccent
$BtnRefreshPrereq.Add_Click({
    try {
        Write-Log "Lese Voraussetzungs-Status..." -Level INFO
        $st = Get-PrerequisiteStatus

        $Global:LblDotNet.Text = if ($st.DotNet48) { "OK - installiert" } else { "FEHLT - wird installiert" }
        $Global:LblDotNet.ForeColor = if ($st.DotNet48) { $Global:ColorAccent2 } else { $Global:ColorWarning }

        $Global:LblVC2012.Text = if ($st.VC2012) { "OK - installiert" } else { "FEHLT - wird installiert" }
        $Global:LblVC2012.ForeColor = if ($st.VC2012) { $Global:ColorAccent2 } else { $Global:ColorWarning }

        $Global:LblVC2013.Text = if ($st.VC2013) { "OK - installiert" } else { "FEHLT - wird installiert" }
        $Global:LblVC2013.ForeColor = if ($st.VC2013) { $Global:ColorAccent2 } else { $Global:ColorWarning }

        $Global:LblURLRewrite.Text = if ($st.URLRewrite) { "OK - installiert" } else { "FEHLT - wird installiert" }
        $Global:LblURLRewrite.ForeColor = if ($st.URLRewrite) { $Global:ColorAccent2 } else { $Global:ColorWarning }

        $Global:LblUCMA.Text = if ($st.UCMA) { "OK - installiert" } else { "FEHLT - wird von ISO installiert" }
        $Global:LblUCMA.ForeColor = if ($st.UCMA) { $Global:ColorAccent2 } else { $Global:ColorWarning }

        $Global:LblFeatures.Text = if ($st.FeaturesOK) { "OK - alle Features installiert" } else { ($st.MissingFeatures.Count.ToString() + " Features fehlen") }
        $Global:LblFeatures.ForeColor = if ($st.FeaturesOK) { $Global:ColorAccent2 } else { $Global:ColorWarning }

        $Global:LblSMB1.Text = if ($st.SMB1Enabled) { "AKTIV - sollte deaktiviert werden!" } else { "OK - deaktiviert" }
        $Global:LblSMB1.ForeColor = if ($st.SMB1Enabled) { $Global:ColorWarning } else { $Global:ColorAccent2 }

        $todo = @()
        if (-not $st.DotNet48)   { $todo += ".NET 4.8" }
        if (-not $st.VC2012)     { $todo += "VC++ 2012" }
        if (-not $st.VC2013)     { $todo += "VC++ 2013" }
        if (-not $st.URLRewrite) { $todo += "URL Rewrite" }
        if (-not $st.UCMA)       { $todo += "UCMA" }
        if (-not $st.FeaturesOK) { $todo += "Windows-Features" }
        if ($st.SMB1Enabled)     { $todo += "SMB1-Disable" }
        if ($todo.Count -eq 0) { Write-Log ">>> Server ist VOLLSTAENDIG vorbereitet!" -Level SUCCESS }
        else { Write-Log (">>> Aktionen noetig: " + ($todo -join ", ")) -Level WARNING }
    } catch { Write-Log ("Fehler: " + $_) -Level ERROR }
})
$GrpPS.Controls.Add($BtnRefreshPrereq)

# Optionen
$GrpPO = New-GroupBox "Was soll installiert/konfiguriert werden?" 10 300 1080 200
$TabPrereq.Controls.Add($GrpPO)

$Global:ChkInstDotNet     = New-CheckBox ".NET Framework 4.8 (Download)"           20 30 500 $true
$Global:ChkInstVC2012     = New-CheckBox "Visual C++ 2012 x64 (Download)"          20 60 500 $true
$Global:ChkInstVC2013     = New-CheckBox "Visual C++ 2013 x64 (Download)"          20 90 500 $true
$Global:ChkInstURLRewrite = New-CheckBox "IIS URL Rewrite Module 2.1 (Download)"   20 120 500 $true
$Global:ChkInstUCMA       = New-CheckBox "UCMA 4.0 (automatisch von Exchange-ISO)" 20 150 500 $true

$Global:ChkInstFeatures = New-CheckBox "Windows-Features (33 IIS/RPC/Cluster/RSAT)" 540 30 500 $true
$Global:ChkDisableSMB1  = New-CheckBox "SMB1 deaktivieren (Best Practice)"          540 60 500 $true
$Global:ChkSetPagefile  = New-CheckBox "Pagefile optimieren (RAM + 10 MB)"          540 90 500 $true
$Global:ChkSetHighPerf  = New-CheckBox "High-Performance-Powerplan setzen"          540 120 500 $true

foreach ($c in @($Global:ChkInstDotNet,$Global:ChkInstVC2012,$Global:ChkInstVC2013,
                 $Global:ChkInstURLRewrite,$Global:ChkInstUCMA,$Global:ChkInstFeatures,
                 $Global:ChkDisableSMB1,$Global:ChkSetPagefile,$Global:ChkSetHighPerf)) {
    $GrpPO.Controls.Add($c)
}

$GrpPA = New-GroupBox "Aktion" 10 510 1080 80
$TabPrereq.Controls.Add($GrpPA)

$BtnInstallPrereq = New-Button "Voraussetzungen jetzt installieren" 15 30 350 38 $Global:ColorAccent2
$BtnInstallPrereq.Add_Click({
    try {
        $r = [System.Windows.Forms.MessageBox]::Show(
            "Voraussetzungen werden installiert.`r`n`r`nDownloads benoetigen Internet!`r`nGgf. NEUSTART nach Windows-Features noetig.`r`n`r`nFortfahren?",
            "Bestaetigung",'YesNo','Question')
        if ($r -ne "Yes") { return }

        $TabControl.SelectedTab = $TabRun
        [System.Windows.Forms.Application]::DoEvents()

        Install-PrerequisiteSoftware `
            -InstallDotNet      $Global:ChkInstDotNet.Checked `
            -InstallVC2012      $Global:ChkInstVC2012.Checked `
            -InstallVC2013      $Global:ChkInstVC2013.Checked `
            -InstallURLRewrite  $Global:ChkInstURLRewrite.Checked `
            -InstallUCMA        $Global:ChkInstUCMA.Checked `
            -InstallFeatures    $Global:ChkInstFeatures.Checked `
            -DisableSMB1        $Global:ChkDisableSMB1.Checked `
            -OptimizePageFile   $Global:ChkSetPagefile.Checked `
            -SetHighPerformance $Global:ChkSetHighPerf.Checked

        $TabControl.SelectedTab = $TabPrereq
        $BtnRefreshPrereq.PerformClick()
        [System.Windows.Forms.MessageBox]::Show(
            "Voraussetzungen-Installation abgeschlossen.`r`n`r`nFalls Windows-Features installiert wurden -> NEUSTART empfohlen!",
            "Fertig",'OK','Information')
    } catch { Write-Log ("Fehler: " + $_) -Level ERROR }
})
$GrpPA.Controls.Add($BtnInstallPrereq)

$LblHint = New-Label "Tipp: Erst 'Status aktualisieren', dann nur fehlende Komponenten installieren." 380 40 600
$LblHint.ForeColor = $Global:ColorTextDim
$GrpPA.Controls.Add($LblHint)
#endregion
#region ============================ TAB: AD-VORBEREITUNG ============================
$GrpADStatus = New-GroupBox "Aktueller AD-Status" 10 10 1080 220
$TabADPrep.Controls.Add($GrpADStatus)

$GrpADStatus.Controls.Add( (New-Label "Komponente"     20  30 200 $Global:FontBold) )
$GrpADStatus.Controls.Add( (New-Label "Aktuell"        230 30 200 $Global:FontBold) )
$GrpADStatus.Controls.Add( (New-Label "Erforderlich"   430 30 200 $Global:FontBold) )
$GrpADStatus.Controls.Add( (New-Label "Status"         630 30 200 $Global:FontBold) )

$GrpADStatus.Controls.Add( (New-Label "AD-Schema-Version:" 20 60 200) )
$Global:LblADSchemaCur = New-Label "..." 230 60 200 $Global:FontBold; $GrpADStatus.Controls.Add($Global:LblADSchemaCur)
$Global:LblADSchemaReq = New-Label "..." 430 60 200; $GrpADStatus.Controls.Add($Global:LblADSchemaReq)
$Global:LblADSchemaSt = New-Label "..." 630 60 200 $Global:FontBold; $GrpADStatus.Controls.Add($Global:LblADSchemaSt)

$GrpADStatus.Controls.Add( (New-Label "Exchange-Organisation:" 20 90 200) )
$Global:LblADOrgCur = New-Label "..." 230 90 200 $Global:FontBold; $GrpADStatus.Controls.Add($Global:LblADOrgCur)
$Global:LblADOrgReq = New-Label "..." 430 90 200; $GrpADStatus.Controls.Add($Global:LblADOrgReq)
$Global:LblADOrgSt = New-Label "..." 630 90 200 $Global:FontBold; $GrpADStatus.Controls.Add($Global:LblADOrgSt)

$GrpADStatus.Controls.Add( (New-Label "Domain-Vorbereitung:" 20 120 200) )
$Global:LblADDomCur = New-Label "..." 230 120 200 $Global:FontBold; $GrpADStatus.Controls.Add($Global:LblADDomCur)
$Global:LblADDomReq = New-Label "..." 430 120 200; $GrpADStatus.Controls.Add($Global:LblADDomReq)
$Global:LblADDomSt = New-Label "..." 630 120 200 $Global:FontBold; $GrpADStatus.Controls.Add($Global:LblADDomSt)

$GrpADStatus.Controls.Add( (New-Label "Aktueller Benutzer:" 20 155 200 $Global:FontBold) )
$Global:LblADUser = New-Label "..." 230 155 600; $GrpADStatus.Controls.Add($Global:LblADUser)

$GrpADStatus.Controls.Add( (New-Label "Berechtigungen:" 20 180 200 $Global:FontBold) )
$Global:LblADPerms = New-Label "..." 230 180 800; $GrpADStatus.Controls.Add($Global:LblADPerms)

$BtnRefreshAD = New-Button "Status aktualisieren" 870 28 200 32 $Global:ColorAccent
$BtnRefreshAD.Add_Click({
    try {
        Write-Log "Lese AD-Status..." -Level INFO
        $info = Get-ExchangeSchemaInfo
        $perm = Test-ExchangePrepPermissions

        $Global:LblADSchemaCur.Text = $info.SchemaVersion
        $Global:LblADSchemaReq.Text = $info.SchemaVersionNeeded
        $Global:LblADSchemaSt.Text = if ($info.SchemaOK) { "OK - aktuell" } else { "Update noetig" }
        $Global:LblADSchemaSt.ForeColor = if ($info.SchemaOK) { $Global:ColorAccent2 } else { $Global:ColorWarning }

        $Global:LblADOrgCur.Text = "$($info.OrgVersion) ($($info.ExchangeOrgName))"
        $Global:LblADOrgReq.Text = $info.OrgVersionNeeded
        $Global:LblADOrgSt.Text = if ($info.OrgOK) { "OK - aktuell" } else { "Update noetig" }
        $Global:LblADOrgSt.ForeColor = if ($info.OrgOK) { $Global:ColorAccent2 } else { $Global:ColorWarning }

        $Global:LblADDomCur.Text = $info.DomainVersion
        $Global:LblADDomReq.Text = $info.DomainVersionNeeded
        $Global:LblADDomSt.Text = if ($info.DomainOK) { "OK - aktuell" } else { "Update noetig" }
        $Global:LblADDomSt.ForeColor = if ($info.DomainOK) { $Global:ColorAccent2 } else { $Global:ColorWarning }

        $Global:LblADUser.Text = $perm.Username
        $pp = @()
        $pp += if ($perm.IsSchemaAdmin)     { "[X] Schema-Admins" }     else { "[ ] Schema-Admins" }
        $pp += if ($perm.IsEnterpriseAdmin) { "[X] Enterprise-Admins" } else { "[ ] Enterprise-Admins" }
        $pp += if ($perm.IsDomainAdmin)     { "[X] Domain-Admins" }     else { "[ ] Domain-Admins" }
        $Global:LblADPerms.Text = ($pp -join "  |  ")
        $Global:LblADPerms.ForeColor = if ($perm.IsSchemaAdmin -and $perm.IsEnterpriseAdmin -and $perm.IsDomainAdmin) { $Global:ColorAccent2 } else { $Global:ColorWarning }

        # Smart Auto-Selection
        $Global:ChkPrepSchema.Checked = -not $info.SchemaOK
        $Global:ChkPrepAD.Checked     = -not $info.OrgOK
        $Global:ChkPrepDom.Checked    = -not $info.DomainOK

        if ($info.SchemaOK) {
            $Global:ChkPrepSchema.Text = "1. PrepareSchema  (NICHT NOETIG - bereits aktuell)"
            $Global:ChkPrepSchema.ForeColor = $Global:ColorAccent2
        } else {
            $Global:ChkPrepSchema.Text = "1. PrepareSchema  (NOETIG - aktuelle Version: " + $info.SchemaVersion + ")"
            $Global:ChkPrepSchema.ForeColor = $Global:ColorWarning
        }
        if ($info.OrgOK) {
            $Global:ChkPrepAD.Text = "2. PrepareAD  (NICHT NOETIG - bereits aktuell)"
            $Global:ChkPrepAD.ForeColor = $Global:ColorAccent2
        } else {
            $Global:ChkPrepAD.Text = "2. PrepareAD  (NOETIG - aktuelle Version: " + $info.OrgVersion + ")"
            $Global:ChkPrepAD.ForeColor = $Global:ColorWarning
        }
        if ($info.DomainOK) {
            $Global:ChkPrepDom.Text = "3. Domain-Vorbereitung  (NICHT NOETIG - bereits aktuell)"
            $Global:ChkPrepDom.ForeColor = $Global:ColorAccent2
        } else {
            $Global:ChkPrepDom.Text = "3. Domain-Vorbereitung  (NOETIG - aktuelle Version: " + $info.DomainVersion + ")"
            $Global:ChkPrepDom.ForeColor = $Global:ColorWarning
        }

        Write-Log "AD-Status aktualisiert" -Level SUCCESS
    } catch { Write-Log ("Fehler: " + $_) -Level ERROR }
})
$GrpADStatus.Controls.Add($BtnRefreshAD)

$GrpPrepSteps = New-GroupBox "Vorbereitungsschritte (werden nach 'Status aktualisieren' automatisch gesetzt)" 10 240 1080 220
$TabADPrep.Controls.Add($GrpPrepSteps)

$Global:ChkPrepSchema = New-CheckBox "1. PrepareSchema (Schema forest-weit)" 15 30 800 $true
$GrpPrepSteps.Controls.Add($Global:ChkPrepSchema)
$Global:ChkPrepAD = New-CheckBox "2. PrepareAD (Exchange-Organisation)" 15 60 800 $true
$GrpPrepSteps.Controls.Add($Global:ChkPrepAD)
$Global:ChkPrepDom = New-CheckBox "3. Domain-Vorbereitung:" 15 95 200 $true
$GrpPrepSteps.Controls.Add($Global:ChkPrepDom)

$Global:RbAllDomains = New-Object System.Windows.Forms.RadioButton
$Global:RbAllDomains.Text="Alle Domaenen im Forest (PrepareAllDomains)"
$Global:RbAllDomains.Location=New-Object System.Drawing.Point(40,120); $Global:RbAllDomains.Size=New-Object System.Drawing.Size(400,22)
$Global:RbAllDomains.Checked=$true; $Global:RbAllDomains.BackColor=[System.Drawing.Color]::Transparent
$GrpPrepSteps.Controls.Add($Global:RbAllDomains)

$Global:RbSingleDomain = New-Object System.Windows.Forms.RadioButton
$Global:RbSingleDomain.Text="Nur eine bestimmte Domaene:"
$Global:RbSingleDomain.Location=New-Object System.Drawing.Point(40,148); $Global:RbSingleDomain.Size=New-Object System.Drawing.Size(220,22)
$Global:RbSingleDomain.BackColor=[System.Drawing.Color]::Transparent
$GrpPrepSteps.Controls.Add($Global:RbSingleDomain)

$Global:CmbDomainList = New-Object System.Windows.Forms.ComboBox
$Global:CmbDomainList.Location=New-Object System.Drawing.Point(265,148); $Global:CmbDomainList.Size=New-Object System.Drawing.Size(350,22)
$Global:CmbDomainList.DropDownStyle="DropDownList"
$Global:CmbDomainList.BackColor=$Global:ColorInputBg; $Global:CmbDomainList.ForeColor=$Global:ColorText
$GrpPrepSteps.Controls.Add($Global:CmbDomainList)

$GrpPrepSteps.Controls.Add( (New-Label "Wartezeit nach jedem Schritt (Min):" 15 185 250) )
$Global:NumWaitMin = New-NumericUpDown 270 183 70 0 60 5
$GrpPrepSteps.Controls.Add($Global:NumWaitMin)
$LblHint2 = New-Label "(empfohlen: 5 Min fuer kleine, 15+ fuer grosse Forests)" 350 185 600
$LblHint2.ForeColor = $Global:ColorTextDim
$GrpPrepSteps.Controls.Add($LblHint2)

$GrpPA2 = New-GroupBox "Aktion" 10 470 1080 90
$TabADPrep.Controls.Add($GrpPA2)

$LblADInfo = New-Label "Voraussetzung: Setup.exe der Exchange-ISO muss verfuegbar sein (siehe Tab 'Installation')" 15 25 1000
$LblADInfo.ForeColor = $Global:ColorTextDim
$GrpPA2.Controls.Add($LblADInfo)

$BtnPrepAD = New-Button "AD-Vorbereitung jetzt starten" 15 50 350 32 $Global:ColorAccent2
$BtnPrepAD.Add_Click({
    try {
        $setupPath = $null
        if ($Global:RbISOMounted.Checked -and $Global:CmbMountedDrives.SelectedIndex -ge 0 -and $Global:DetectedISOs.Count -gt 0) {
            $setupPath = $Global:DetectedISOs[$Global:CmbMountedDrives.SelectedIndex].SetupPath
        }
        elseif ($Global:RbISOFile.Checked -and $Global:TxtISO.Text) {
            $setupPath = Mount-ExchangeISO -ISOPath $Global:TxtISO.Text
        }
        if (-not $setupPath -or -not (Test-Path $setupPath)) {
            [System.Windows.Forms.MessageBox]::Show("Setup.exe nicht gefunden!`r`nBitte zuerst ISO im Tab 'Installation' auswaehlen.","Fehler",'OK','Error')
            return
        }
        if (-not $Global:ChkPrepSchema.Checked -and -not $Global:ChkPrepAD.Checked -and -not $Global:ChkPrepDom.Checked) {
            [System.Windows.Forms.MessageBox]::Show("Keine Vorbereitungs-Schritte ausgewaehlt!","Hinweis",'OK','Information')
            return
        }
        $r = [System.Windows.Forms.MessageBox]::Show(
            "AD-Vorbereitung wird durchgefuehrt.`r`nDies ist eine forest-weite, irreversible Aenderung!`r`n`r`nFortfahren?",
            "Bestaetigung",'YesNo','Warning')
        if ($r -ne "Yes") { return }

        $TabControl.SelectedTab = $TabRun
        [System.Windows.Forms.Application]::DoEvents()

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
            }
            elseif ($Global:RbSingleDomain.Checked -and $Global:CmbDomainList.SelectedItem) {
                Invoke-ExchangePrepareStep -SetupPath $setupPath -Step "PrepareDomain" -DomainName ($Global:CmbDomainList.SelectedItem.ToString()) | Out-Null
            }
        }

        $BtnRefreshAD.PerformClick()
        $TabControl.SelectedTab = $TabADPrep

        [System.Windows.Forms.MessageBox]::Show("AD-Vorbereitung abgeschlossen.","Fertig",'OK','Information')
    } catch { Write-Log ("Fehler: " + $_) -Level ERROR }
})
$GrpPA2.Controls.Add($BtnPrepAD)

# Tab-Wechsel-Handler
$TabControl.Add_SelectedIndexChanged({
    if ($TabControl.SelectedTab -eq $TabPrereq -and -not $Global:PrereqStatusLoaded) {
        $BtnRefreshPrereq.PerformClick()
        $Global:PrereqStatusLoaded = $true
    }
    if ($TabControl.SelectedTab -eq $TabADPrep -and -not $Global:ADStatusLoaded) {
        try {
            $domains = Get-ADDomainList
            $Global:CmbDomainList.Items.Clear()
            foreach ($d in $domains) { [void]$Global:CmbDomainList.Items.Add($d) }
            if ($Global:CmbDomainList.Items.Count -gt 0) { $Global:CmbDomainList.SelectedIndex = 0 }
            $BtnRefreshAD.PerformClick()
            $Global:ADStatusLoaded = $true
        } catch {}
    }
})
#endregion

#region ============================ TAB: INSTALLATION ============================
$GrpISO = New-GroupBox "Exchange ISO-Quelle" 10 10 1080 165
$TabInstall.Controls.Add($GrpISO)

$Global:RbISOFile = New-Object System.Windows.Forms.RadioButton
$Global:RbISOFile.Text="ISO-Datei vom Dateisystem auswaehlen"
$Global:RbISOFile.Location=New-Object System.Drawing.Point(15,28); $Global:RbISOFile.Size=New-Object System.Drawing.Size(400,24)
$Global:RbISOFile.Checked=$true; $Global:RbISOFile.BackColor=[System.Drawing.Color]::Transparent
$Global:RbISOFile.ForeColor=$Global:ColorText
$GrpISO.Controls.Add($Global:RbISOFile)

$Global:RbISOMounted = New-Object System.Windows.Forms.RadioButton
$Global:RbISOMounted.Text="Bereits gemountetes Laufwerk verwenden (Auto-Erkennung)"
$Global:RbISOMounted.Location=New-Object System.Drawing.Point(15,54); $Global:RbISOMounted.Size=New-Object System.Drawing.Size(450,24)
$Global:RbISOMounted.BackColor=[System.Drawing.Color]::Transparent; $Global:RbISOMounted.ForeColor=$Global:ColorText
$GrpISO.Controls.Add($Global:RbISOMounted)

$GrpISO.Controls.Add( (New-Label "ISO-Datei:" 35 90 100) )
$Global:TxtISO = New-TextBox 145 88 760
$GrpISO.Controls.Add($Global:TxtISO)

$BtnBrowseISO = New-Button "Durchsuchen..." 915 87 130 24 $Global:ColorAccent2
$BtnBrowseISO.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "ISO-Dateien (*.iso)|*.iso|Alle Dateien|*.*"
    if ($ofd.ShowDialog() -eq "OK") { $Global:TxtISO.Text = $ofd.FileName; $Global:RbISOFile.Checked = $true }
})
$GrpISO.Controls.Add($BtnBrowseISO)

$GrpISO.Controls.Add( (New-Label "Laufwerk:" 35 122 100) )
$Global:CmbMountedDrives = New-Object System.Windows.Forms.ComboBox
$Global:CmbMountedDrives.Location=New-Object System.Drawing.Point(145,120); $Global:CmbMountedDrives.Size=New-Object System.Drawing.Size(760,22)
$Global:CmbMountedDrives.DropDownStyle="DropDownList"
$Global:CmbMountedDrives.BackColor=$Global:ColorInputBg; $Global:CmbMountedDrives.ForeColor=$Global:ColorText
$Global:CmbMountedDrives.Font=$Global:FontDefault
$GrpISO.Controls.Add($Global:CmbMountedDrives)

$BtnDetectISO = New-Button "Auto-Erkennen" 915 119 130 24 $Global:ColorAccent
$BtnDetectISO.Add_Click({
    try {
        $Global:CmbMountedDrives.Items.Clear()
        $Global:DetectedISOs = @()
        $found = @(Find-MountedExchangeISO)
        $Global:DetectedISOs = $found
        $count = if ($found) { $found.Count } else { 0 }
        if ($count -gt 0) {
            foreach ($f in $found) { [void]$Global:CmbMountedDrives.Items.Add($f.Display) }
            $Global:CmbMountedDrives.SelectedIndex = 0
            $Global:RbISOMounted.Checked = $true
            $Global:RbISOFile.Checked    = $false
            [System.Windows.Forms.MessageBox]::Show("$count Exchange-ISO(s) gefunden.","Auto-Erkennung",'OK','Information')
        } else {
            [void]$Global:CmbMountedDrives.Items.Add("(Keine Exchange-ISO gefunden)")
            $Global:CmbMountedDrives.SelectedIndex = 0
            [System.Windows.Forms.MessageBox]::Show("Keine Exchange-ISO gefunden.","Auto-Erkennung",'OK','Warning')
        }
    } catch { Write-Log ("Fehler: " + $_) -Level ERROR }
})
$GrpISO.Controls.Add($BtnDetectISO)

$GrpSetup = New-GroupBox "Exchange Setup-Parameter" 10 185 1080 145
$TabInstall.Controls.Add($GrpSetup)

$GrpSetup.Controls.Add( (New-Label "Organisation: *" 15 28 150) )
$Global:TxtOrg = New-TextBox 175 26 400 "Contoso"
$GrpSetup.Controls.Add($Global:TxtOrg)

$GrpSetup.Controls.Add( (New-Label "Servername:" 15 58 150) )
$Global:TxtServer = New-TextBox 175 56 400 $env:COMPUTERNAME
$GrpSetup.Controls.Add($Global:TxtServer)

$GrpSetup.Controls.Add( (New-Label "Installations-Pfad:" 15 88 150) )
$Global:TxtInstallPath = New-TextBox 175 86 870 $Global:DefaultInstallPath
$GrpSetup.Controls.Add($Global:TxtInstallPath)

$GrpSetup.Controls.Add( (New-Label "AD-Domaene:" 15 115 150) )
$Global:TxtDomain = New-TextBox 175 113 400
try { $Global:TxtDomain.Text = (Get-CimInstance Win32_ComputerSystem).Domain } catch { $Global:TxtDomain.Text = "contoso.local" }
$GrpSetup.Controls.Add($Global:TxtDomain)

$GrpOpts = New-GroupBox "Installations-Optionen" 10 340 1080 240
$TabInstall.Controls.Add($GrpOpts)

$Global:Checks = @{}
$opts = @(
    @{Key="PrereqCheck";       Text="Voraussetzungspruefung";                   Default=$true;  Col=0; Row=0},
    @{Key="RunPrereqInstall";  Text="Voraussetzungen vorab installieren";       Default=$true;  Col=0; Row=1},
    @{Key="MountISO";          Text="ISO automatisch mounten (falls Datei)";    Default=$true;  Col=0; Row=2},
    @{Key="DoADPrep";          Text="AD-Vorbereitung im Master-Workflow";       Default=$true;  Col=0; Row=3},
    @{Key="InstallExchange";   Text="Exchange Server installieren";             Default=$true;  Col=0; Row=4},
    @{Key="InstallAntispam";   Text="Antispam-Agenten installieren";            Default=$true;  Col=0; Row=5},
    @{Key="ConfigAntispam";    Text="Antispam-Filter konfigurieren";            Default=$true;  Col=0; Row=6},
    @{Key="VerifyInstall";     Text="Installation verifizieren";                Default=$true;  Col=1; Row=0},
    @{Key="ApplyTLS";          Text="TLS-Hardening anwenden";                   Default=$true;  Col=1; Row=1},
    @{Key="CreateDBs";         Text="Postfach-Datenbanken anlegen";             Default=$false; Col=1; Row=2},
    @{Key="CreateDAG";         Text="DAG erstellen + Mitglieder";               Default=$false; Col=1; Row=3},
    @{Key="DismountISO";       Text="ISO am Ende automatisch unmounten";        Default=$true;  Col=1; Row=4},
    @{Key="ForceAdminCheck";   Text="Strikte Admin-Pruefung";                   Default=$true;  Col=1; Row=5},
    @{Key="ContinueOnError";   Text="Bei Fehlern weiter machen";                Default=$false; Col=1; Row=6}
)
foreach ($o in $opts) {
    $cb = New-CheckBox $o.Text (20 + $o.Col*510) (28 + $o.Row*30) 490 $o.Default
    $GrpOpts.Controls.Add($cb)
    $Global:Checks[$o.Key] = $cb
}

$Form.Add_Shown({
    try {
        $found = @(Find-MountedExchangeISO)
        $Global:DetectedISOs = $found
        if ($found.Count -gt 0) {
            $Global:CmbMountedDrives.Items.Clear()
            foreach ($f in $found) { [void]$Global:CmbMountedDrives.Items.Add($f.Display) }
            $Global:CmbMountedDrives.SelectedIndex = 0
            $Global:RbISOMounted.Checked = $true
            $Global:RbISOFile.Checked    = $false
            Write-Log ("Auto-Erkennung beim Start: " + $found.Count + " ISO(s) gefunden") -Level SUCCESS
        }
    } catch {}
})
#endregion

#region ============================ TAB: SICHERHEIT / TLS ============================
$GrpTLSInfo = New-GroupBox "TLS-Hardening (Microsoft Best Practice)" 10 10 1080 200
$TabSecurity.Controls.Add($GrpTLSInfo)

$LblTLSInfo = New-Object System.Windows.Forms.Label
$LblTLSInfo.Location=New-Object System.Drawing.Point(15,28); $LblTLSInfo.Size=New-Object System.Drawing.Size(1050,165)
$LblTLSInfo.Font=New-Object System.Drawing.Font("Segoe UI",9)
$LblTLSInfo.ForeColor=$Global:ColorText; $LblTLSInfo.BackColor=[System.Drawing.Color]::Transparent
$LblTLSInfo.Text = @"
TLS-Hardening konfiguriert das System nach Microsoft Best Practice:

DEAKTIVIERT: SSL 2.0, SSL 3.0, TLS 1.0, TLS 1.1, schwache Ciphers (RC4, DES, NULL, 3DES)
AKTIVIERT:   TLS 1.2, TLS 1.3, .NET SystemDefaultTlsVersions + SchUseStrongCrypto

WICHTIG: Nach dem Anwenden ist ein NEUSTART erforderlich!
         Pruefen Sie vorab, dass alle Clients TLS 1.2 unterstuetzen.
"@
$GrpTLSInfo.Controls.Add($LblTLSInfo)

$GrpTLSAct = New-GroupBox "Aktion" 10 220 1080 130
$TabSecurity.Controls.Add($GrpTLSAct)

$Global:ChkConfirmTLS = New-CheckBox "Ich bestaetige, dass alle Clients TLS 1.2+ unterstuetzen" 15 30 700 $false
$GrpTLSAct.Controls.Add($Global:ChkConfirmTLS)

$BtnApplyTLS = New-Button "TLS-Hardening jetzt anwenden" 15 65 280 40 $Global:ColorAccent
$BtnApplyTLS.Add_Click({
    if (-not $Global:ChkConfirmTLS.Checked) {
        [System.Windows.Forms.MessageBox]::Show("Bitte zuerst Bestaetigung anhaken!","Hinweis",'OK','Warning'); return
    }
    $r = [System.Windows.Forms.MessageBox]::Show("TLS-Hardening anwenden? Neustart erforderlich!","Bestaetigung",'YesNo','Question')
    if ($r -eq "Yes") { Set-TLSHardening | Out-Null }
})
$GrpTLSAct.Controls.Add($BtnApplyTLS)

$BtnTestTLS = New-Button "TLS-Status anzeigen" 310 65 200 40 $Global:ColorAccent2
$BtnTestTLS.Add_Click({
    Write-Log "TLS-Status:" -Level INFO
    $base = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols"
    foreach ($proto in @("SSL 2.0","SSL 3.0","TLS 1.0","TLS 1.1","TLS 1.2","TLS 1.3")) {
        foreach ($side in @("Server","Client")) {
            $p = Join-Path $base "$proto\$side"
            if (Test-Path $p) {
                $en = (Get-ItemProperty -Path $p -Name Enabled -ErrorAction SilentlyContinue).Enabled
                $st = if ($en -eq 0) { "DEAKTIVIERT" } elseif ($en) { "AKTIVIERT" } else { "Standard" }
                Write-Log ("  $proto $side : $st") -Level INFO
            }
            else { Write-Log ("  $proto $side : Standard") -Level INFO }
        }
    }
})
$GrpTLSAct.Controls.Add($BtnTestTLS)
#endregion

#region ============================ TAB: ANTISPAM ============================
$GrpSCL = New-GroupBox "SCL-Schwellwerte (0-9)" 10 10 1080 110
$TabAntiSpam.Controls.Add($GrpSCL)

$GrpSCL.Controls.Add( (New-Label "SCL Reject (Mail abgelehnt ab):" 15 30 320) )
$Global:NumSCLReject = New-NumericUpDown 340 28 70 0 9 7
$GrpSCL.Controls.Add($Global:NumSCLReject)

$GrpSCL.Controls.Add( (New-Label "SCL Delete (Mail geloescht ab):" 15 65 320) )
$Global:NumSCLDelete = New-NumericUpDown 340 63 70 0 9 9
$GrpSCL.Controls.Add($Global:NumSCLDelete)

$GrpFilt = New-GroupBox "Antispam-Filter aktivieren" 10 130 1080 220
$TabAntiSpam.Controls.Add($GrpFilt)

$Global:ChkContent  = New-CheckBox "Content-Filter aktivieren"        20  30 350 $true
$Global:ChkSenderID = New-CheckBox "Sender-ID-Filter aktivieren"      20  60 350 $true
$Global:ChkSendFil  = New-CheckBox "Sender-Filter aktivieren"         20  90 350 $true
$Global:ChkRecipFil = New-CheckBox "Recipient-Filter aktivieren"      20 120 350 $true
$Global:ChkSendRep  = New-CheckBox "Sender-Reputation aktivieren"     20 150 350 $true
foreach ($c in @($Global:ChkContent,$Global:ChkSenderID,$Global:ChkSendFil,$Global:ChkRecipFil,$Global:ChkSendRep)) {
    $GrpFilt.Controls.Add($c)
}

$BtnApplyAntispam = New-Button "Antispam-Konfiguration anwenden" 10 365 350 40 $Global:ColorAccent2
$BtnApplyAntispam.Add_Click({
    try {
        if (-not (Import-ExchangeManagementShell)) { return }
        Set-AntiSpamConfiguration `
            -SCLRejectThreshold ([int]$Global:NumSCLReject.Value) `
            -SCLDeleteThreshold ([int]$Global:NumSCLDelete.Value) `
            -EnableContent          $Global:ChkContent.Checked `
            -EnableSenderID         $Global:ChkSenderID.Checked `
            -EnableSenderFilter     $Global:ChkSendFil.Checked `
            -EnableRecipientFilter  $Global:ChkRecipFil.Checked `
            -EnableSenderReputation $Global:ChkSendRep.Checked
    } catch { Write-Log ("Fehler: " + $_) -Level ERROR }
})
$TabAntiSpam.Controls.Add($BtnApplyAntispam)
#endregion

#region ============================ TAB: DATENBANKEN ============================
$LblDBHead = New-Label "Datenbank-Generator: Praefix + Startnummer + Anzahl" 10 10 1000 $Global:FontBold
$TabDB.Controls.Add($LblDBHead)

$GrpGen = New-GroupBox "DB-Generator" 10 35 1080 175
$TabDB.Controls.Add($GrpGen)

$GrpGen.Controls.Add( (New-Label "DB-Praefix:" 15 30 100) )
$Global:TxtDBPrefix = New-TextBox 120 28 120 "MDB"
$GrpGen.Controls.Add($Global:TxtDBPrefix)

$GrpGen.Controls.Add( (New-Label "Start-Nummer:" 250 30 100) )
$Global:TxtDBStart = New-TextBox 355 28 80 "01"
$GrpGen.Controls.Add($Global:TxtDBStart)
$LblHint3 = New-Label "(z.B. '01' = MDB01, MDB02, ... | '001' = MDB001, ...)" 445 30 500
$LblHint3.ForeColor = $Global:ColorTextDim
$GrpGen.Controls.Add($LblHint3)

$GrpGen.Controls.Add( (New-Label "Anzahl DBs:" 15 60 100) )
$Global:NumDBCount = New-NumericUpDown 120 58 80 1 99 4
$GrpGen.Controls.Add($Global:NumDBCount)

$GrpGen.Controls.Add( (New-Label "Zielserver:" 250 60 100) )
$Global:TxtDBServer = New-TextBox 355 58 200 $env:COMPUTERNAME
$GrpGen.Controls.Add($Global:TxtDBServer)

$GrpGen.Controls.Add( (New-Label "DB-Basispfad:" 15 95 100) )
$Global:TxtDBBase = New-TextBox 120 93 400 $Global:DefaultDBPath
$GrpGen.Controls.Add($Global:TxtDBBase)

$GrpGen.Controls.Add( (New-Label "Log-Basispfad:" 530 95 110) )
$Global:TxtLogBase = New-TextBox 645 93 400 $Global:DefaultLogDBPath
$GrpGen.Controls.Add($Global:TxtLogBase)

$BtnGenerate = New-Button "Konfiguration generieren (Vorschau)" 15 130 280 32 $Global:ColorAccent
$BtnGenerate.Add_Click({
    try {
        $Global:DgvDB.Rows.Clear()
        $prefix=$Global:TxtDBPrefix.Text.Trim(); $startStr=$Global:TxtDBStart.Text.Trim()
        $count=[int]$Global:NumDBCount.Value; $server=$Global:TxtDBServer.Text.Trim()
        $dbBase=$Global:TxtDBBase.Text.TrimEnd('\'); $logBase=$Global:TxtLogBase.Text.TrimEnd('\')
        if (-not $prefix) { [System.Windows.Forms.MessageBox]::Show("Praefix fehlt!","Fehler",'OK','Warning'); return }
        if (-not $startStr -or $startStr -notmatch '^\d+$') { [System.Windows.Forms.MessageBox]::Show("Start-Nummer muss numerisch sein!","Fehler",'OK','Warning'); return }
        $padLen=$startStr.Length; $startNum=[int]$startStr
        for ($i=0; $i -lt $count; $i++) {
            $num=$startNum+$i
            $suffix=$num.ToString().PadLeft($padLen,'0')
            $dbName="$prefix$suffix"
            $Global:DgvDB.Rows.Add($dbName,$server,"$dbBase\$dbName\$dbName.edb","$logBase\$dbName") | Out-Null
        }
        Write-Log ("$count DB-Eintraege generiert") -Level SUCCESS
    } catch { Write-Log ("Fehler: " + $_) -Level ERROR }
})
$GrpGen.Controls.Add($BtnGenerate)

$BtnClearDB = New-Button "Liste leeren" 305 130 130 32 $Global:ColorWarning
$BtnClearDB.Add_Click({ $Global:DgvDB.Rows.Clear() })
$GrpGen.Controls.Add($BtnClearDB)

$LblPv = New-Label "Vorschau / Bearbeitbare Liste:" 10 220 800 $Global:FontBold
$TabDB.Controls.Add($LblPv)

$Global:DgvDB = New-Object System.Windows.Forms.DataGridView
$Global:DgvDB.Location=New-Object System.Drawing.Point(10,245); $Global:DgvDB.Size=New-Object System.Drawing.Size(1080,260)
$Global:DgvDB.AllowUserToAddRows=$true; $Global:DgvDB.AllowUserToDeleteRows=$true
$Global:DgvDB.AutoSizeColumnsMode="Fill"; $Global:DgvDB.SelectionMode="FullRowSelect"
$Global:DgvDB.BackgroundColor=$Global:ColorPanel; $Global:DgvDB.GridColor=$Global:ColorBorder
$Global:DgvDB.DefaultCellStyle.BackColor=[System.Drawing.Color]::White
$Global:DgvDB.DefaultCellStyle.ForeColor=$Global:ColorText
$Global:DgvDB.DefaultCellStyle.SelectionBackColor=$Global:ColorAccent
$Global:DgvDB.DefaultCellStyle.SelectionForeColor=[System.Drawing.Color]::White
$Global:DgvDB.AlternatingRowsDefaultCellStyle.BackColor=$Global:ColorPanelAlt
$Global:DgvDB.ColumnHeadersDefaultCellStyle.BackColor=$Global:ColorAccent
$Global:DgvDB.ColumnHeadersDefaultCellStyle.ForeColor=[System.Drawing.Color]::White
$Global:DgvDB.ColumnHeadersDefaultCellStyle.Font=$Global:FontBold
$Global:DgvDB.EnableHeadersVisualStyles=$false; $Global:DgvDB.RowHeadersVisible=$false

foreach ($col in @(@{Name="DBName";Header="Datenbank-Name"},@{Name="Server";Header="Server"},
                   @{Name="EdbFilePath";Header="EDB-Pfad"},@{Name="LogFolderPath";Header="Log-Pfad"})) {
    $c = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $c.Name=$col.Name; $c.HeaderText=$col.Header
    $Global:DgvDB.Columns.Add($c) | Out-Null
}
$TabDB.Controls.Add($Global:DgvDB)

$BtnCreateDBNow = New-Button "Datenbanken jetzt erstellen" 10 515 350 38 $Global:ColorAccent2
$BtnCreateDBNow.Add_Click({
    try {
        if ($Global:DgvDB.Rows.Count -le 1) {
            [System.Windows.Forms.MessageBox]::Show("Bitte zuerst Konfiguration generieren!","Hinweis",'OK','Warning'); return
        }
        $r = [System.Windows.Forms.MessageBox]::Show(("Es werden " + ($Global:DgvDB.Rows.Count - 1) + " DB(s) erstellt. Fortfahren?"),"Bestaetigung",'YesNo','Question')
        if ($r -ne "Yes") { return }
        if (-not (Import-ExchangeManagementShell)) { return }
        $created = 0
        foreach ($row in $Global:DgvDB.Rows) {
            if ($row.IsNewRow) { continue }
            $n = $row.Cells["DBName"].Value
            if ([string]::IsNullOrWhiteSpace($n)) { continue }
            try {
                if (Get-MailboxDatabase -Identity $n -ErrorAction SilentlyContinue) {
                    Write-Log ("DB '$n' existiert bereits") -Level WARNING; continue
                }
                $edb=$row.Cells["EdbFilePath"].Value; $lp=$row.Cells["LogFolderPath"].Value
                $eDir=Split-Path $edb -Parent
                if (-not (Test-Path $eDir)) { New-Item $eDir -ItemType Directory -Force | Out-Null }
                if (-not (Test-Path $lp))   { New-Item $lp   -ItemType Directory -Force | Out-Null }
                New-MailboxDatabase -Name $n -Server $row.Cells["Server"].Value -EdbFilePath $edb -LogFolderPath $lp -ErrorAction Stop | Out-Null
                Mount-Database -Identity $n -ErrorAction Stop
                Write-Log ("DB '$n' erstellt") -Level SUCCESS
                $created++
            } catch { Write-Log ("Fehler DB '$n': " + $_) -Level ERROR }
        }
        [System.Windows.Forms.MessageBox]::Show("$created Datenbank(en) erstellt.","Fertig",'OK','Information')
    } catch { Write-Log ("Fehler: " + $_) -Level ERROR }
})
$TabDB.Controls.Add($BtnCreateDBNow)
#endregion

#region ============================ TAB: DAG ============================
$GrpDAG1 = New-GroupBox "DAG-Grundeinstellungen" 10 10 1080 230
$TabDAG.Controls.Add($GrpDAG1)

$GrpDAG1.Controls.Add( (New-Label "DAG-Name:" 15 30 180) )
$Global:TxtDAGName = New-TextBox 200 28 350 "DAG01"
$GrpDAG1.Controls.Add($Global:TxtDAGName)

$GrpDAG1.Controls.Add( (New-Label "Witness-Server:" 15 65 180) )
$Global:TxtWitness = New-TextBox 200 63 350 "FILESERVER01"
$GrpDAG1.Controls.Add($Global:TxtWitness)

$GrpDAG1.Controls.Add( (New-Label "Witness-Verzeichnis:" 15 100 180) )
$Global:TxtWitnessDir = New-TextBox 200 98 700 "C:\DAGFileShareWitness\DAG01"
$GrpDAG1.Controls.Add($Global:TxtWitnessDir)

$GrpDAG1.Controls.Add( (New-Label "DAG-IP-Adresse(n):" 15 135 180) )
$Global:TxtDAGIP = New-TextBox 200 133 700 "192.168.1.100"
$GrpDAG1.Controls.Add($Global:TxtDAGIP)

$LblIPHint = New-Label "(Mehrere IPs mit Komma trennen)" 200 158 400
$LblIPHint.ForeColor = $Global:ColorTextDim
$GrpDAG1.Controls.Add($LblIPHint)

$Global:ChkIPlessDAG = New-CheckBox "IP-lose DAG (Exchange 2016+ empfohlen)" 15 190 500 $false
$GrpDAG1.Controls.Add($Global:ChkIPlessDAG)

$GrpDAG2 = New-GroupBox "DAG-Mitglieder (ein Server pro Zeile)" 10 250 1080 200
$TabDAG.Controls.Add($GrpDAG2)

$Global:TxtMembers = New-Object System.Windows.Forms.TextBox
$Global:TxtMembers.Location=New-Object System.Drawing.Point(15,25); $Global:TxtMembers.Size=New-Object System.Drawing.Size(1050,160)
$Global:TxtMembers.Multiline=$true; $Global:TxtMembers.ScrollBars="Vertical"
$Global:TxtMembers.BackColor=$Global:ColorInputBg; $Global:TxtMembers.ForeColor=$Global:ColorText
$Global:TxtMembers.Font=$Global:FontMono; $Global:TxtMembers.Text="EX01`r`nEX02"
$GrpDAG2.Controls.Add($Global:TxtMembers)

$BtnCreateDAGNow = New-Button "DAG erstellen + Mitglieder" 10 465 1080 40 $Global:ColorAccent
$BtnCreateDAGNow.Add_Click({
    try {
        if (-not (Import-ExchangeManagementShell)) { return }
        $name = $Global:TxtDAGName.Text.Trim()
        if (-not $name) { [System.Windows.Forms.MessageBox]::Show("DAG-Name fehlt!","Fehler",'OK','Warning'); return }
        if (-not (Get-DatabaseAvailabilityGroup -Identity $name -ErrorAction SilentlyContinue)) {
            if ($Global:ChkIPlessDAG.Checked) {
                New-DatabaseAvailabilityGroup -Name $name `
                    -WitnessServer $Global:TxtWitness.Text -WitnessDirectory $Global:TxtWitnessDir.Text `
                    -DatabaseAvailabilityGroupIpAddresses ([System.Net.IPAddress]::None) -ErrorAction Stop | Out-Null
                Write-Log ("IP-lose DAG '$name' erstellt") -Level SUCCESS
            } else {
                $ips = $Global:TxtDAGIP.Text.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ } |
                       ForEach-Object { [System.Net.IPAddress]::Parse($_) }
                New-DatabaseAvailabilityGroup -Name $name `
                    -WitnessServer $Global:TxtWitness.Text -WitnessDirectory $Global:TxtWitnessDir.Text `
                    -DatabaseAvailabilityGroupIpAddresses $ips -ErrorAction Stop | Out-Null
                Write-Log ("DAG '$name' erstellt") -Level SUCCESS
            }
        } else { Write-Log ("DAG '$name' existiert bereits") -Level WARNING }

        $members = $Global:TxtMembers.Text.Split("`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        foreach ($m in $members) {
            try {
                Add-DatabaseAvailabilityGroupServer -Identity $name -MailboxServer $m -ErrorAction Stop
                Write-Log ("Mitglied '$m' hinzugefuegt") -Level SUCCESS
            } catch { Write-Log ("Fehler bei '$m': " + $_) -Level ERROR }
        }
        [System.Windows.Forms.MessageBox]::Show("DAG-Konfiguration abgeschlossen.","Fertig",'OK','Information')
    } catch { Write-Log ("Fehler: " + $_) -Level ERROR }
})
$TabDAG.Controls.Add($BtnCreateDAGNow)
#endregion

#region ============================ TAB: AUSFUEHRUNG & LOG ============================
$LblRun = New-Label "Live-Output von Setup. Wichtige Meilensteine erscheinen hier mit [SetupLog]." 10 10 1000 $Global:FontBold
$TabRun.Controls.Add($LblRun)

$Global:LogTextBox = New-Object System.Windows.Forms.RichTextBox
$Global:LogTextBox.Location=New-Object System.Drawing.Point(10,40); $Global:LogTextBox.Size=New-Object System.Drawing.Size(1080,420)
$Global:LogTextBox.BackColor=[System.Drawing.Color]::White; $Global:LogTextBox.ForeColor=$Global:ColorText
$Global:LogTextBox.Font=$Global:FontMono; $Global:LogTextBox.ReadOnly=$true
$Global:LogTextBox.BorderStyle="FixedSingle"
$TabRun.Controls.Add($Global:LogTextBox)

$BtnSaveCfg = New-Button "Konfig speichern" 10 470 180 32 $Global:ColorAccent
$BtnSaveCfg.Add_Click({
    try {
        $cfg = @{
            ISO = @{ File=$Global:TxtISO.Text; UseFile=$Global:RbISOFile.Checked }
            Setup = @{ Org=$Global:TxtOrg.Text; Server=$Global:TxtServer.Text; Install=$Global:TxtInstallPath.Text; Domain=$Global:TxtDomain.Text }
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
                WaitMin=$Global:NumWaitMin.Value
            }
            AntiSpam = @{
                SCLReject=$Global:NumSCLReject.Value; SCLDelete=$Global:NumSCLDelete.Value
                Content=$Global:ChkContent.Checked; SenderID=$Global:ChkSenderID.Checked
                SenderFilter=$Global:ChkSendFil.Checked; RecipientFilter=$Global:ChkRecipFil.Checked
                SenderReputation=$Global:ChkSendRep.Checked
            }
            DBGen = @{
                Prefix=$Global:TxtDBPrefix.Text; Start=$Global:TxtDBStart.Text
                Count=$Global:NumDBCount.Value; Server=$Global:TxtDBServer.Text
                DBBase=$Global:TxtDBBase.Text; LogBase=$Global:TxtLogBase.Text
            }
            DAG = @{
                Name=$Global:TxtDAGName.Text; Witness=$Global:TxtWitness.Text
                WitnessDir=$Global:TxtWitnessDir.Text; IP=$Global:TxtDAGIP.Text
                IPless=$Global:ChkIPlessDAG.Checked
                Members=$Global:TxtMembers.Text.Split("`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ }
            }
        }
        foreach ($k in $Global:Checks.Keys) { $cfg.Options[$k] = $Global:Checks[$k].Checked }
        $cfg | ConvertTo-Json -Depth 6 | Set-Content $Global:ConfigFile -Encoding UTF8
        Write-Log ("Konfig gespeichert: " + $Global:ConfigFile) -Level SUCCESS
    } catch { Write-Log ("Fehler: " + $_) -Level ERROR }
})
$TabRun.Controls.Add($BtnSaveCfg)

$BtnLoadCfg = New-Button "Konfig laden" 200 470 180 32 $Global:ColorAccent
$BtnLoadCfg.Add_Click({
    try {
        if (-not (Test-Path $Global:ConfigFile)) {
            [System.Windows.Forms.MessageBox]::Show("Keine Konfig gefunden.","Info",'OK','Information'); return
        }
        $cfg = Get-Content $Global:ConfigFile -Raw | ConvertFrom-Json
        $Global:TxtISO.Text=$cfg.ISO.File; $Global:RbISOFile.Checked=[bool]$cfg.ISO.UseFile
        $Global:RbISOMounted.Checked=-not [bool]$cfg.ISO.UseFile
        $Global:TxtOrg.Text=$cfg.Setup.Org; $Global:TxtServer.Text=$cfg.Setup.Server
        $Global:TxtInstallPath.Text=$cfg.Setup.Install; $Global:TxtDomain.Text=$cfg.Setup.Domain
        foreach ($k in $Global:Checks.Keys) {
            if ($cfg.Options.PSObject.Properties.Name -contains $k) {
                $Global:Checks[$k].Checked = [bool]$cfg.Options.$k
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
        Write-Log "Konfig geladen" -Level SUCCESS
    } catch { Write-Log ("Lade-Fehler: " + $_) -Level ERROR }
})
$TabRun.Controls.Add($BtnLoadCfg)

$BtnClearLog = New-Button "Log leeren" 390 470 130 32 $Global:ColorWarning
$BtnClearLog.Add_Click({ $Global:LogTextBox.Clear() })
$TabRun.Controls.Add($BtnClearLog)

$BtnOpenSetupLog = New-Button "ExchangeSetup.log oeffnen" 530 470 220 32 $Global:ColorAccent
$BtnOpenSetupLog.Add_Click({
    if (Test-Path $Global:ExchangeSetupLog) { Start-Process notepad.exe $Global:ExchangeSetupLog }
    else { [System.Windows.Forms.MessageBox]::Show("ExchangeSetup.log existiert noch nicht.","Info",'OK','Information') }
})
$TabRun.Controls.Add($BtnOpenSetupLog)

$BtnStartAll = New-Button ">>>  GESAMTEN PROZESS STARTEN  <<<" 10 510 1080 38 $Global:ColorAccent2
$BtnStartAll.Font = New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
$BtnStartAll.Add_Click({
    try {
        if (-not $Global:TxtOrg.Text) { [System.Windows.Forms.MessageBox]::Show("Organisation fehlt!","Fehler",'OK','Warning'); return }
        if ($Global:Checks["ForceAdminCheck"].Checked) {
            $cu = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
            if (-not $cu.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
                [System.Windows.Forms.MessageBox]::Show("Bitte als Administrator!","Fehler",'OK','Error'); return
            }
        }
        $r = [System.Windows.Forms.MessageBox]::Show("Gesamten Prozess starten? Kann Stunden dauern!","Bestaetigung",'YesNo','Question')
        if ($r -ne "Yes") { return }

        $TabControl.SelectedTab = $TabRun
        Write-Log "==============================================" -Level INFO
        Write-Log "===   EXCHANGE 2019 SE INSTALLATION    ===" -Level INFO
        Write-Log "==============================================" -Level INFO

        $continueOnError = $Global:Checks["ContinueOnError"].Checked
        $ExchangeSetupPath = $null
        $ISOMountedByScript = $false

        # ISO-Quelle ermitteln
        if ($Global:RbISOMounted.Checked -and $Global:CmbMountedDrives.SelectedIndex -ge 0 -and $Global:DetectedISOs.Count -gt 0) {
            $ExchangeSetupPath = $Global:DetectedISOs[$Global:CmbMountedDrives.SelectedIndex].SetupPath
            Write-Log ("ISO-Quelle: " + $ExchangeSetupPath) -Level SUCCESS
        }
        elseif ($Global:RbISOFile.Checked -and $Global:TxtISO.Text -and $Global:Checks["MountISO"].Checked) {
            $ExchangeSetupPath = Mount-ExchangeISO -ISOPath $Global:TxtISO.Text
            if ($ExchangeSetupPath) { $ISOMountedByScript = $true }
        }

        # SCHRITT 1: Voraussetzungen pruefen
        if ($Global:Checks["PrereqCheck"].Checked) {
            Write-Log "--- SCHRITT 1: Voraussetzungen pruefen ---" -Level INFO
            $isoCheck = if ($Global:RbISOFile.Checked) { $Global:TxtISO.Text } else { "" }
            if (-not (Test-ExchangePrerequisites -ExchangeISOPath $isoCheck) -and -not $continueOnError) {
                Write-Log "Abbruch" -Level ERROR; return
            }
        }

        # SCHRITT 1.5: Voraussetzungen installieren
        if ($Global:Checks["RunPrereqInstall"].Checked) {
            Write-Log "--- SCHRITT 1.5: Voraussetzungen installieren ---" -Level INFO
            Install-PrerequisiteSoftware `
                -InstallDotNet      $Global:ChkInstDotNet.Checked `
                -InstallVC2012      $Global:ChkInstVC2012.Checked `
                -InstallVC2013      $Global:ChkInstVC2013.Checked `
                -InstallURLRewrite  $Global:ChkInstURLRewrite.Checked `
                -InstallUCMA        $Global:ChkInstUCMA.Checked `
                -InstallFeatures    $Global:ChkInstFeatures.Checked `
                -DisableSMB1        $Global:ChkDisableSMB1.Checked `
                -OptimizePageFile   $Global:ChkSetPagefile.Checked `
                -SetHighPerformance $Global:ChkSetHighPerf.Checked
        }

        # SCHRITT 2: TLS-Hardening
        if ($Global:Checks["ApplyTLS"].Checked) {
            Write-Log "--- SCHRITT 2: TLS-Hardening ---" -Level INFO
            Set-TLSHardening | Out-Null
        }

        # SCHRITT 2.5: AD-Vorbereitung
        if ($Global:Checks["DoADPrep"].Checked -and ($Global:ChkPrepSchema.Checked -or $Global:ChkPrepAD.Checked -or $Global:ChkPrepDom.Checked)) {
            Write-Log "--- SCHRITT 2.5: AD-Vorbereitung ---" -Level INFO
            if (-not $ExchangeSetupPath) { Write-Log "Kein Setup-Pfad" -Level WARNING }
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
                    }
                    elseif ($Global:RbSingleDomain.Checked -and $Global:CmbDomainList.SelectedItem) {
                        Invoke-ExchangePrepareStep -SetupPath $ExchangeSetupPath -Step "PrepareDomain" -DomainName ($Global:CmbDomainList.SelectedItem.ToString()) | Out-Null
                    }
                }
            }
        }

        # SCHRITT 3: Exchange installieren
        if ($Global:Checks["InstallExchange"].Checked -and $ExchangeSetupPath) {
            Write-Log "--- SCHRITT 3: Exchange Setup ---" -Level INFO
            if (-not (Install-ExchangeServer -SetupPath $ExchangeSetupPath -OrgName $Global:TxtOrg.Text) -and -not $continueOnError) {
                Write-Log "Abbruch" -Level ERROR; return
            }
        }

        # SCHRITT 4: Antispam-Agenten
        if ($Global:Checks["InstallAntispam"].Checked) {
            Write-Log "--- SCHRITT 4: Antispam-Agenten ---" -Level INFO
            Install-AntiSpamAgents -InstallPath $Global:TxtInstallPath.Text | Out-Null
        }

        # SCHRITT 5: Antispam konfigurieren
        if ($Global:Checks["ConfigAntispam"].Checked) {
            Write-Log "--- SCHRITT 5: Antispam konfigurieren ---" -Level INFO
            if (Import-ExchangeManagementShell) {
                Set-AntiSpamConfiguration `
                    -SCLRejectThreshold ([int]$Global:NumSCLReject.Value) `
                    -SCLDeleteThreshold ([int]$Global:NumSCLDelete.Value) `
                    -EnableContent          $Global:ChkContent.Checked `
                    -EnableSenderID         $Global:ChkSenderID.Checked `
                    -EnableSenderFilter     $Global:ChkSendFil.Checked `
                    -EnableRecipientFilter  $Global:ChkRecipFil.Checked `
                    -EnableSenderReputation $Global:ChkSendRep.Checked | Out-Null
            }
        }

        # SCHRITT 6: Verifikation
        if ($Global:Checks["VerifyInstall"].Checked) {
            Write-Log "--- SCHRITT 6: Verifikation ---" -Level INFO
            Test-ExchangeInstallation | Out-Null
        }

        # SCHRITT 7: DBs
        if ($Global:Checks["CreateDBs"].Checked) {
            Write-Log "--- SCHRITT 7: Datenbanken ---" -Level INFO
            $BtnCreateDBNow.PerformClick()
        }

        # SCHRITT 8: DAG
        if ($Global:Checks["CreateDAG"].Checked) {
            Write-Log "--- SCHRITT 8: DAG ---" -Level INFO
            $BtnCreateDAGNow.PerformClick()
        }

        # SCHRITT 9: ISO unmounten
        if ($Global:Checks["DismountISO"].Checked -and $ISOMountedByScript -and $Global:TxtISO.Text) {
            Write-Log "--- SCHRITT 9: ISO unmounten ---" -Level INFO
            Dismount-ExchangeISO -ISOPath $Global:TxtISO.Text
        }

        Write-Log "==============================================" -Level SUCCESS
        Write-Log "===   PROZESS ABGESCHLOSSEN   ===" -Level SUCCESS
        Write-Log "==============================================" -Level SUCCESS

        $msg = "Prozess abgeschlossen!`n`nLog: $Global:LogFile"
        if ($Global:Checks["ApplyTLS"].Checked) { $msg += "`n`nWICHTIG: TLS-Hardening - NEUSTART erforderlich!" }
        [System.Windows.Forms.MessageBox]::Show($msg,"Fertig",'OK','Information')
    }
    catch {
        Write-Log ("KRITISCHER FEHLER: " + $_) -Level ERROR
        [System.Windows.Forms.MessageBox]::Show(("Fehler: " + $_),"Fehler",'OK','Error')
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
$Global:StatusLabel.Text="  Bereit | Logdatei: $Global:LogFile"; $Global:StatusLabel.TextAlign="MiddleLeft"
$Form.Controls.Add($Global:StatusLabel)

$BtnExit = New-Button "Beenden" ($Global:FormWidth-110) 700 90 28 $Global:ColorError
$BtnExit.Add_Click({ $Form.Close() })
$Form.Controls.Add($BtnExit)
#endregion

#region ============================ GUI START ============================
try {
    Write-Log "Exchange 2019 SE Konfigurations-GUI v3.5 gestartet" -Level INFO
    Write-Log ("Logdatei: " + $Global:LogFile) -Level INFO
    [void]$Form.ShowDialog()
    Write-Log "GUI beendet" -Level INFO
}
catch { Write-Host ("GUI-Fehler: " + $_) -ForegroundColor Red }
finally { if ($Form) { $Form.Dispose() } }
#endregion
