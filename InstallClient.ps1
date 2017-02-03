<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.129
	 Created on:   	10/5/2016 9:11 AM
	 Created by:   	ddoyle
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		This script installs the SCCM Client on the local workstation
#>

# #Requires -RunAsAdministrator
$SourcePath = "\\appmdt00099p01\distribution$\Applications\Microsoft\SCCM\Client"
$DomainName = (Get-WmiObject Win32_ComputerSystem).Domain
$DNSSuffix = "corp.costco.com"
$OSArchitechture = (Get-WmiObject Win32_OperatingSystem).OSArchitecture

If ($DomainName -eq 'loc.costco.com')
{
	$MP = "WAPSCM01094P03.$DNSSuffix"
}
ElseIf ($DomainName -eq 'systems.costco.com')
{
	$MP = "WAPSCM01094P11.$DNSSuffix"
}
Else
{
	$MP = "WAPSCM01094P03.$DNSSuffix"
}


function CheckVersion
{
	If ($OSArchitechture -eq '64-bit')
	{
		$Arch = "AMD64"
	}
	ElseIf ($OSArchitechture -eq '32-bit')
	{
		$Arch = "i386"
	}
}



function InstallClient
{
	$OSArchitechture = (Get-WmiObject Win32_OperatingSystem).OSArchitecture
	Write-Host "Installing the $OSArchitecture SCCM Client version 5.00.8412.1307...Please be patient."
	Start-Process -FilePath "$SourcePath\5.00.8412.1307\CCMSetup.exe" -ArgumentList "/noservice /mp:$MP /Source:$SourcePath\5.00.8412.1307 SMSSITECODE=CM1 SMSCACHESIZE=10240 DNSSUFFIX=$DNSSuffix FSP=WAPSCM01094P30.corp.costco.com"
	Start-Sleep -Seconds 10
	Wait-Process -Name CCMSetup
	Write-Host "Installation Complete"
}

CheckVersion
InstallClient