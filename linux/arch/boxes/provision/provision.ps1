<#
.SYNOPSIS
    Provisions the Win11 Boxes guest: RDP, WinRM, virtiofs shared folder, Go.

.DESCRIPTION
    Every step is check-then-install, so this is safe to run repeatedly. On the
    first (interactive) run it also copies itself to C:\ProgramData\Win11Provision
    and registers a scheduled task, so later boots re-run it as SYSTEM and repair
    anything missing -- that is what makes Go "install itself on first run" for a
    freshly cloned VM.

    All installers are downloaded directly (MSI/EXE) rather than through winget,
    because winget is a per-user app and is unavailable in the SYSTEM context the
    scheduled task runs under.

.PARAMETER Unattended
    Skip the self-install step and never prompt. Used by the scheduled task.

.PARAMETER AllowUnencryptedHttp
    Also allow unencrypted WinRM over 5985. Off by default: use HTTPS on 5986.

.PARAMETER SkipSharedFolder
    Do not install WinFsp / virtio-win. Use if you only want WinRM and RDP.
#>
[CmdletBinding()]
param(
    [switch]$Unattended,
    [switch]$AllowUnencryptedHttp,
    [switch]$SkipSharedFolder
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$InstallRoot = Join-Path $env:ProgramData 'Win11Provision'
$LogFile     = Join-Path $InstallRoot 'provision.log'
$TaskName    = 'Win11-Provision'

$VirtioToolsUrl = 'https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win-guest-tools.exe'
$GoReleasesUrl  = 'https://go.dev/dl/?mode=json'
$WinFspApiUrl   = 'https://api.github.com/repos/winfsp/winfsp/releases/latest'

# ---------------------------------------------------------------- helpers ----

function Write-Log {
    param([string]$Message, [ValidateSet('INFO', 'WARN', 'FAIL', 'OK')][string]$Level = 'INFO')
    $line = '{0} [{1}] {2}' -f (Get-Date -Format 's'), $Level, $Message
    $colour = @{ INFO = 'Gray'; WARN = 'Yellow'; FAIL = 'Red'; OK = 'Green' }[$Level]
    Write-Host $line -ForegroundColor $colour
    try { Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8 } catch { }
}

function Assert-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'This script must run elevated. Right-click Bootstrap.cmd and pick "Run as administrator".'
    }
}

function Wait-ForNetwork {
    param([int]$TimeoutSeconds = 180)
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        if (Test-NetConnection -ComputerName 'go.dev' -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue) {
            return $true
        }
        Start-Sleep -Seconds 5
    }
    Write-Log "No outbound connectivity after ${TimeoutSeconds}s; download steps will be skipped." 'WARN'
    return $false
}

function Get-RemoteFile {
    param([Parameter(Mandatory)][string]$Uri, [Parameter(Mandatory)][string]$Destination)
    Write-Log "Downloading $Uri"
    $progress = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'   # ~10x faster for Invoke-WebRequest
    try {
        Invoke-WebRequest -Uri $Uri -OutFile $Destination -UseBasicParsing -TimeoutSec 600
    } finally {
        $ProgressPreference = $progress
    }
}

function Invoke-Installer {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string[]]$Arguments)
    $proc = Start-Process -FilePath $Path -ArgumentList $Arguments -Wait -PassThru -NoNewWindow
    # 3010 == success, reboot required.
    if ($proc.ExitCode -notin 0, 3010) {
        throw "$Path exited with code $($proc.ExitCode)"
    }
    return $proc.ExitCode
}

# ------------------------------------------------------------ remote desktop --

function Enable-RemoteDesktop {
    Write-Log 'Configuring Remote Desktop (3389)'

    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' `
        -Name 'fDenyTSConnections' -Value 0 -Type DWord
    # Keep Network Level Authentication on; every modern RDP client speaks it.
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' `
        -Name 'UserAuthentication' -Value 1 -Type DWord

    Enable-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction SilentlyContinue

    # The passt NIC usually lands in the Public profile, where the built-in rules
    # are scoped to the local subnet. An explicit any-profile rule avoids that.
    New-NetFirewallRule -Name 'Provision-RDP-In' -DisplayName 'Remote Desktop (provisioned)' `
        -Direction Inbound -Action Allow -Protocol TCP -LocalPort 3389 -Profile Any `
        -ErrorAction SilentlyContinue | Out-Null

    Set-Service -Name TermService -StartupType Automatic
    if ((Get-Service TermService).Status -ne 'Running') { Start-Service TermService }

    Write-Log 'Remote Desktop enabled on 3389' 'OK'
}

# --------------------------------------------------------------------- winrm --

function Enable-WinRmEndpoints {
    Write-Log 'Configuring WinRM (5985 HTTP / 5986 HTTPS)'

    # Enable-PSRemoting refuses to touch adapters on a Public profile, and passt
    # networks are detected as Public. Reclassify them first.
    Get-NetConnectionProfile | Where-Object NetworkCategory -eq 'Public' | ForEach-Object {
        Set-NetConnectionProfile -InterfaceIndex $_.InterfaceIndex -NetworkCategory Private -ErrorAction SilentlyContinue
    }

    Enable-PSRemoting -Force -SkipNetworkProfileCheck | Out-Null

    Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true -Force
    Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value '*' -Force
    Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value ([bool]$AllowUnencryptedHttp) -Force
    if ($AllowUnencryptedHttp) {
        Write-Log 'Unencrypted WinRM over 5985 is ENABLED (credentials cross in the clear)' 'WARN'
    }

    # HTTPS listener with a long-lived self-signed cert.
    $https = Get-ChildItem WSMan:\localhost\Listener |
        Where-Object { (Get-Item "WSMan:\localhost\Listener\$($_.Name)\Transport").Value -eq 'HTTPS' }
    if (-not $https) {
        $hostname = [System.Net.Dns]::GetHostName()
        $cert = New-SelfSignedCertificate -DnsName $hostname, 'localhost' `
            -CertStoreLocation Cert:\LocalMachine\My `
            -FriendlyName 'WinRM provisioning certificate' `
            -NotAfter (Get-Date).AddYears(5)
        New-Item -Path WSMan:\localhost\Listener -Transport HTTPS -Address * `
            -CertificateThumbPrint $cert.Thumbprint -Force | Out-Null
        Write-Log "Created HTTPS listener, cert thumbprint $($cert.Thumbprint)"
    }

    New-NetFirewallRule -Name 'Provision-WinRM-HTTP-In' -DisplayName 'WinRM HTTP (provisioned)' `
        -Direction Inbound -Action Allow -Protocol TCP -LocalPort 5985 -Profile Any `
        -ErrorAction SilentlyContinue | Out-Null
    New-NetFirewallRule -Name 'Provision-WinRM-HTTPS-In' -DisplayName 'WinRM HTTPS (provisioned)' `
        -Direction Inbound -Action Allow -Protocol TCP -LocalPort 5986 -Profile Any `
        -ErrorAction SilentlyContinue | Out-Null

    Set-Service -Name WinRM -StartupType Automatic
    if ((Get-Service WinRM).Status -ne 'Running') { Start-Service WinRM }

    Write-Log 'WinRM listening on 5985 (HTTP) and 5986 (HTTPS)' 'OK'
}

# ------------------------------------------------------------- shared folder --

function Install-WinFsp {
    if (Test-Path 'HKLM:\SOFTWARE\WOW6432Node\WinFsp') {
        Write-Log 'WinFsp already installed'
        return
    }
    Write-Log 'Installing WinFsp (virtiofs depends on it)'
    $release = Invoke-RestMethod -Uri $WinFspApiUrl -UseBasicParsing -Headers @{ 'User-Agent' = 'win11-provision' }
    $asset = $release.assets | Where-Object { $_.name -like 'winfsp-*.msi' } | Select-Object -First 1
    if (-not $asset) { throw 'No .msi asset in the latest WinFsp release' }

    $msi = Join-Path $env:TEMP $asset.name
    Get-RemoteFile -Uri $asset.browser_download_url -Destination $msi
    Invoke-Installer -Path 'msiexec.exe' -Arguments @('/i', "`"$msi`"", '/qn', '/norestart', 'INSTALLLEVEL=1000') | Out-Null
    Remove-Item $msi -Force -ErrorAction SilentlyContinue
    Write-Log 'WinFsp installed' 'OK'
}

function Install-VirtioGuestTools {
    if (Get-Service -Name 'VirtioFsSvc' -ErrorAction SilentlyContinue) {
        Write-Log 'virtio-win guest tools already installed'
        return
    }
    Write-Log 'Installing virtio-win guest tools (virtiofs driver + service)'
    $exe = Join-Path $env:TEMP 'virtio-win-guest-tools.exe'
    Get-RemoteFile -Uri $VirtioToolsUrl -Destination $exe
    Invoke-Installer -Path $exe -Arguments @('/install', '/passive', '/norestart') | Out-Null
    Remove-Item $exe -Force -ErrorAction SilentlyContinue
    Write-Log 'virtio-win guest tools installed' 'OK'
}

function Enable-SharedFolder {
    Install-WinFsp
    Install-VirtioGuestTools

    $svc = Get-Service -Name 'VirtioFsSvc' -ErrorAction SilentlyContinue
    if (-not $svc) {
        Write-Log 'VirtioFsSvc not present yet; it usually appears after a reboot.' 'WARN'
        return
    }
    Set-Service -Name 'VirtioFsSvc' -StartupType Automatic
    if ($svc.Status -ne 'Running') { Start-Service 'VirtioFsSvc' }

    Write-Log 'virtiofs service running; host share mounts as Z:\' 'OK'
}

# ------------------------------------------------------------------- golang --

function Get-InstalledGoVersion {
    $command = Get-Command go.exe -ErrorAction SilentlyContinue
    if ($command) {
        $goPath = $command.Source
    } else {
        $goPath = Join-Path $env:ProgramFiles 'Go\bin\go.exe'
        if (-not (Test-Path $goPath)) { return $null }
    }
    $raw = & $goPath version 2>$null
    if ($raw -match 'go(\d+\.\d+(\.\d+)?)') { return $Matches[1] }
    return $null
}

function Install-Go {
    $release = (Invoke-RestMethod -Uri $GoReleasesUrl -UseBasicParsing) |
        Where-Object { $_.stable } | Select-Object -First 1
    $latest = $release.version -replace '^go', ''

    $current = Get-InstalledGoVersion
    if ($current -eq $latest) {
        Write-Log "Go $current already installed"
        return
    }
    if ($current) { Write-Log "Go $current installed, upgrading to $latest" }

    $file = $release.files | Where-Object {
        $_.os -eq 'windows' -and $_.arch -eq 'amd64' -and $_.kind -eq 'installer'
    } | Select-Object -First 1
    if (-not $file) { throw "No windows/amd64 installer in Go release $latest" }

    $msi = Join-Path $env:TEMP $file.filename
    Get-RemoteFile -Uri "https://go.dev/dl/$($file.filename)" -Destination $msi
    Invoke-Installer -Path 'msiexec.exe' -Arguments @('/i', "`"$msi`"", '/qn', '/norestart') | Out-Null
    Remove-Item $msi -Force -ErrorAction SilentlyContinue

    # The MSI extends the machine PATH; refresh this session so verification works.
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User')

    $installed = Get-InstalledGoVersion
    if (-not $installed) { throw 'Go installer finished but go.exe was not found' }
    Write-Log "Go $installed installed" 'OK'
}

# ---------------------------------------------------------------- self-setup --

function Install-StartupTask {
    $target = Join-Path $InstallRoot 'provision.ps1'
    Copy-Item -LiteralPath $PSCommandPath -Destination $target -Force

    $arguments = "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$target`" -Unattended"
    if ($AllowUnencryptedHttp) { $arguments += ' -AllowUnencryptedHttp' }
    if ($SkipSharedFolder)     { $arguments += ' -SkipSharedFolder' }

    $action    = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $arguments
    $trigger   = New-ScheduledTaskTrigger -AtStartup
    $trigger.Delay = 'PT1M'   # give the network stack a head start
    $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
    $settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
        -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 1)

    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger `
        -Principal $principal -Settings $settings -Force | Out-Null

    Write-Log "Scheduled task '$TaskName' registered; re-runs at every boot" 'OK'
}

# ----------------------------------------------------------------- main flow --

New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
Assert-Administrator

Write-Log "=== provisioning run started (unattended=$Unattended) ==="

$steps = [ordered]@{
    'Remote Desktop' = { Enable-RemoteDesktop }
    'WinRM'          = { Enable-WinRmEndpoints }
}
if (-not $SkipSharedFolder) { $steps['Shared folder'] = { Enable-SharedFolder } }
$steps['Go'] = { Install-Go }

$online = Wait-ForNetwork
$failed = @()

foreach ($name in $steps.Keys) {
    $needsNetwork = $name -in 'Shared folder', 'Go'
    if ($needsNetwork -and -not $online) {
        Write-Log "Skipping '$name': no connectivity" 'WARN'
        $failed += $name
        continue
    }
    try {
        & $steps[$name]
    } catch {
        Write-Log "Step '$name' failed: $($_.Exception.Message)" 'FAIL'
        $failed += $name
    }
}

if (-not $Unattended) {
    try { Install-StartupTask } catch { Write-Log "Could not register startup task: $($_.Exception.Message)" 'FAIL' }
}

if ($failed.Count -gt 0) {
    Write-Log "Finished with failures: $($failed -join ', '). They will be retried at next boot." 'WARN'
    if (-not $Unattended) { Read-Host 'Press Enter to close' | Out-Null }
    exit 1
}

Write-Log '=== provisioning complete ===' 'OK'
if (-not $Unattended) {
    Write-Host ''
    Write-Host 'Reboot once so the virtiofs driver loads and Z:\ appears.' -ForegroundColor Cyan
    Read-Host 'Press Enter to close' | Out-Null
}
