#Requires -RunAsAdministrator
# Debloat-Windows11.ps1
# Strips Store bloatware, telemetry, phoning-home tasks, and noisy services.
# Re-run after major feature updates — Microsoft loves bringing its friends back.

$ErrorActionPreference = 'SilentlyContinue'

# ---------- 1. Store apps ----------
$Bloat = @(
    'Microsoft.BingNews','Microsoft.BingWeather','Microsoft.GamingApp','Microsoft.GetHelp','Microsoft.Getstarted','Microsoft.MicrosoftOfficeHub','Microsoft.MicrosoftSolitaireCollection','Microsoft.People','Microsoft.PowerAutomateDesktop','Microsoft.SkypeApp','Microsoft.Todos','Microsoft.WindowsFeedbackHub','Microsoft.Xbox.TCUI','Microsoft.XboxGameOverlay','Microsoft.XboxGamingOverlay','Microsoft.XboxIdentityProvider','Microsoft.XboxSpeechToTextOverlay','Microsoft.YourPhone','Microsoft.ZuneMusic','Microsoft.ZuneVideo','MicrosoftCorporationII.QuickAssist','Clipchamp.Clipchamp','Microsoft.Copilot','MicrosoftWindows.Client.CBS_cw5n1h2txyewy'
)

Get-AppxPackage -AllUsers | Where-Object { $Bloat -contains $_.Name } | ForEach-Object {
    Write-Host "Removing $($_.Name)"
    Remove-AppxPackage -Package $_.PackageFullName -AllUsers
    Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $_.Name } | Remove-AppxProvisionedPackage -Online
}

# ---------- 2. Telemetry ----------
$RegPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
New-Item -Path $RegPath -Force | Out-Null
Set-ItemProperty -Path $RegPath -Name 'AllowTelemetry' -Value 0 -Type DWord
Set-ItemProperty -Path $RegPath -Name 'MaxTelemetryAllowed' -Value 0 -Type DWord

$DiagPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'
New-Item -Path $DiagPath -Force | Out-Null
Set-ItemProperty -Path $DiagPath -Name 'AllowTelemetry' -Value 0 -Type DWord

# ---------- 3. Phoning-home scheduled tasks ----------
$TaskPatterns = @('Microsoft\Windows\Application Experience\*','Microsoft\Windows\Customer Experience Improvement Program\*','Microsoft\Windows\Diagnosis\*','Microsoft\Windows\Feedback\Siuf\*','Microsoft\Windows\Maps\*','Microsoft\Windows\Shell\FamilySafety*','Microsoft\Windows\Autochk\Proxy')
foreach ($pattern in $TaskPatterns) {
    Get-ScheduledTask -TaskPath $pattern -ErrorAction SilentlyContinue | Disable-ScheduledTask | Out-Null
}

# ---------- 4. Noisy services ----------
$Services = @('DiagTrack','dmwappushservice','WerSvc')
foreach ($svc in $Services) {
    Stop-Service $svc -Force
    Set-Service $svc -StartupType Disabled
}

# ---------- 5. Edge bloat (optional, commented) ----------
# Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -ErrorAction SilentlyContinue
# New-Item 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Force | Out-Null
# Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'PersonalizationReportingEnabled' -Value 0

Write-Host 'Done. Reboot recommended.' -ForegroundColor Green