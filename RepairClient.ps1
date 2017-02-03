#################################################
#
#               SCCM Repair Script 
#        Created on 10/5/2016 by David Doyle
#
#################################################

# #Requires -RunAsAdministrator

# Get the ID and security principal of the current user account
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
 
# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
 
# Check to see if we are currently running "as Administrator"
if ($myWindowsPrincipal.IsInRole($adminRole))
   {
   # We are running "as Administrator" - so change the title and background color to indicate this
   $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
   $Host.UI.RawUI.BackgroundColor = "DarkBlue"
   clear-host
   }
else
   {
   # We are not running "as Administrator" - so relaunch as administrator
   
   # Create a new process object that starts PowerShell
   $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
   
   # Specify the current script path and name as a parameter
   $newProcess.Arguments = $myInvocation.MyCommand.Definition;
   
   # Indicate that the process should be elevated
   $newProcess.Verb = "runas";
   
   # Start the new process
   [System.Diagnostics.Process]::Start($newProcess);
   
   # Exit from the current, unelevated, process
   exit
   }
 
# Run your code that needs to be elevated here
Write-Host -NoNewLine "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
 {    
  Echo "This script needs to be run As Admin"
  Break
 }

$ClientService = "SMS Agent Host"
$ServiceStatus = (Get-Service $ClientService).Status
$SourceFolder = "\\appmdt00099p01\distribution$\Applications\Microsoft\SCCM\2012_Client\5.0.7804.1000"
$DestFolder = "C:\Temp"
$RunOnceKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
$svc = Get-Service $ClientService
 
function CheckServiceStatus
{
    Write-Host "Stopping $ClientService Service..."
    if ($ServicStatus -eq 'Running'){
        Stop-Service -DisplayName $ClientService
        $svc.WaitForStatus('Stopped','00.00.10')
        Write-Host "$ClientService Service Stopped"
    }
    elseif ($ServiceStatus -ne 'Running'){
        Write-Host "$ClientService was not running"
    }
}

function UninstallClient
{
    Write-Host "Uninstalling SCCM Client...please wait"
    Start-Process -FilePath "C:\Windows\ccmsetup\ccmsetup.exe" -ArgumentList "/Uninstall"
    Start-Sleep -Seconds 10
    Wait-Process -Name CCMSetup
    Write-Host "Uninstall complete"
}

function DeleteFiles
{
    Write-Host "Deleting C:\Windows\CCM"
    Remove-Item c:\Windows\CCM -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Deleting files from C:\Windows\ccmsetup\*.*"
    Remove-Item C:\Windows\ccmsetup\* -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Deleting files from C:\Windows\ccmcache\*.*"
    Remove-Item C:\Windows\ccmcache\* -Recurse -Force -ErrorAction SilentlyContinue
}


function CopyFileTemp
{

    Copy-Item "$SourceFolder\InstallClient.ps1" -Destination "$DestFolder\InstallClient.ps1" -Recurse -Force
} 

function CreateRegistryKey
{
    set-itemproperty $RunOnceKey "NextRun" ('C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe -executionPolicy Unrestricted -File ' + "C:\Temp\InstallClient.ps1")
}
 

function Reboot
{
    $Confirmation = Read-Host "A reboot is required. Please save all work and type 'y' to continue."
        If ($Confirmation -eq 'y') {
        Restart-Computer -Force
        }
        ElseIf ($Confirmation -ne 'y') {
        Break
        }
}  
        
CheckServiceStatus
UninstallClient
DeleteFiles
CopyFileTemp
CreateRegistryKey
Reboot        