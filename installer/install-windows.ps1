#!/usr/bin/pwsh

# This script will only work in an administrator console.
# If this script will not execute because of an error  "running scripts is disabled on this system" then please run the
# following command first:
#   Set-ExecutionPolicy Unrestricted

if (-not ((Get-WmiObject Win32_OperatingSystem).Caption -Match "Windows 11")) {
    Write-Error "This script is only designed to run on Windows."
    exit 1
}

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5 -or $PSVersionTable.PSVersion.Minor -lt 1) {
    Write-Warning "PowerShell version must be at least 5.1. Please update your PowerShell version."
    exit 1
}

# Check .NET version
$dotNetVersion = [System.Environment]::Version
# Urgh, the minor version does not match AT ALL
# if ($dotNetVersion.Major -lt 4 -or ($dotNetVersion.Major -eq 4 -and $dotNetVersion.Minor -lt 8)) {
if ($dotNetVersion.Major -lt 4) {
    Write-Warning ".NET Framework version must be at least 4.8. Please update your .NET Framework version."
    exit 1
}

#Write-Host "PowerShell and .NET Framework versions are compatible."

function Sky-Log {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory, HelpMessage="Message")] [string] $message
	)
	process {
		Write-Host -ForegroundColor Blue $message
	}
}

$ErrorActionPreference = "Stop"
Sky-Log "Sky's windows setup script successfully loaded"

try {
	
	Set-ExecutionPolicy Bypass -Scope Process -Force
	[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

	if (-not (Test-Path -Path 'C:\ProgramData\chocolatey')) {
		Sky-Log -ForegroundColor Blue "Installing chocolatey..."
		Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
		Sky-Log "Please restart this shell and run the script again"
		exit 0
	}

	# Install + setup ssh
	if ((Get-WindowsCapability -Online -Name 'OpenSSH.Client~~~~0.0.1.0').State -eq 'NotPresent') {
		Sky-Log "Installing openssh client..."
		Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
	}
	if ((Get-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0').State -eq 'NotPresent') {
		Sky-Log "Installing openssh server..."
		Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
	}
	if ((Get-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0').State -ne 'NotPresent') {
		Sky-Log "Configuring openssh server..."
		Set-Service -Name sshd -StartupType 'Automatic'
		if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
			Sky-Log "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
			New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
		} else {
			Sky-Log "Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists."
		}
	}

	#if (-not Get-Service -Name sshd -ErrorAction SilentlyContinue) {
	#}

	#Sky-Log "Installing chocolatey packages..."
	#$choco = 'C:\ProgramData\chocolatey\bin\choco.exe'
	#Invoke-Expression "$choco install -y notepadplusplus winscp msys2 7zip keepass"

	## Install ms store apps
	#Sky-Log "Installing winget packages..."
	## XP9KHM4BK9FZ7Q = Visual Studio Code
	## 9WZDNCRFJ3PS = Microsoft Remote Desktop
	#winget install XP9KHM4BK9FZ7Q 9WZDNCRFJ3PS --source msstore --accept-package-agreements

} catch {
	Write-Host $_.Exception.Message -ForegroundColor Red
	throw
}

# TODO:
# Install kee on chrome, keepassrpc on keepass: https://github.com/kee-org/keepassrpc/wiki
# Enable windows integrated ssh agent
