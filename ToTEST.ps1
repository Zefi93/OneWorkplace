#https://github.com/ComplianceAG/OSDCloud/blob/main/Profiles/ZG-WS.ps1

#================================================
#   [PreOS] Update Module
#================================================
Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"
Install-Module OSD -Force

Write-Host  -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force

if ((Get-MyComputerModel) -match 'Virtual') {
    Write-Host  -ForegroundColor Green "Setting Display Resolution to 1600x"
    Set-DisRes 1600
}

#=======================================================================
#   [OS] Params and Start-OSDCloud
#=======================================================================
$Params = @{
    OSBuild = "21H2"
    OSEdition = "Pro"
    OSLanguage = "fr-fr"
    ZTI = $true
    Firmware = $false
    SkipAutopilot = $true
}
Start-OSDCloud @Params

#================================================
#  [PostOS] OOBEDeploy Configuration
#================================================
Write-Host -ForegroundColor Green "Create C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json"
$OOBEDeployJson = @'
{
    "Autopilot":  {
                      "IsPresent":  false
                  },
    "UpdateDrivers":  {
                          "IsPresent":  true
                      },
    "UpdateWindows":  {
                          "IsPresent":  true
                      }
}
'@
If (!(Test-Path "C:\ProgramData\OSDeploy")) {
    New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
}
$OOBEDeployJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json" -Encoding ascii -Force

#================================================
#  [PostOS] AutopilotOOBE Configuration Staging
#================================================
<# Write-Host -ForegroundColor Green "Define Computername:"
$Serial = Get-WmiObject Win32_bios | Select-Object -ExpandProperty SerialNumber
$TargetComputername = $Serial.Substring(4,4)

$AssignedComputerName = "ZG-WS-$TargetComputername"
Write-Host -ForegroundColor Red $AssignedComputerName
Write-Host ""

Write-Host -ForegroundColor Green "Create C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json"
$AutopilotOOBEJson = @'
{
    "AddToGroup":  "G_ORG_Autopilot_Devices",
    "Assign":  {
                   "IsPresent":  true
               },
    "GroupTag":  "Autopilot-ZG",
    "Hidden":  [
                   "AddToGroup",
                   "AssignedUser",
                   "PostAction",
                   "GroupTag",
                   "Assign"
               ],
    "PostAction":  "Quit",
    "Run":  "NetworkingWireless",
    "Docs":  "https://google.com/",
    "Title":  "Autopilot Manual Register",
'@
$AutopilotOOBEJson += '"AssignedComputerName" : "' + $AssignedComputerName + '"}'

If (!(Test-Path "C:\ProgramData\OSDeploy")) {
    New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
}
$AutopilotOOBEJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json" -Encoding ascii -Force

#================================================
#  [PostOS] AutopilotOOBE CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\System32\Autopilot.cmd"
$AutopilotCMD = @'
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force
Set Path = %PATH%;C:\Program Files\WindowsPowerShell\Scripts
Start /Wait PowerShell -NoL -C Install-Module AutopilotOOBE -Force -Verbose
Start /Wait PowerShell -NoL -C Install-Module OSD -Force -Verbose
Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/ComplianceAG/OSDCloud/main/Set-KeyboardLanguage.ps1
Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/ComplianceAG/OSDCloud/main/Install-EmbeddedProductKey.ps1
Start /Wait PowerShell -NoL -C Start-AutopilotOOBE
Start /Wait PowerShell -NoL -C Start-OOBEDeploy
Start /Wait PowerShell -NoL -C Restart-Computer -Force
'@
$AutopilotCMD | Out-File -FilePath 'C:\Windows\System32\Autopilot.cmd' -Encoding ascii -Force
#> 

#================================================
#  [PostOS] SetupComplete CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\Setup\Scripts\SetupComplete.cmd"
$SetupCompleteCMD = @'
RD C:\OSDCloud\OS /S /Q
XCOPY C:\OSDCloud\ C:\Windows\Logs\OSD /E /H /C /I /Y
XCOPY C:\ProgramData\OSDeploy C:\Windows\Logs\OSD /E /H /C /I /Y
RD C:\OSDCloud /S /Q
RD C:\Drivers /S /Q
RD C:\Temp /S /Q
'@
$SetupCompleteCMD | Out-File -FilePath 'C:\Windows\Setup\Scripts\SetupComplete.cmd' -Encoding ascii -Force

#=======================================================================
#   Restart-Computer
#=======================================================================
Write-Host  -ForegroundColor Green "Restarting in 20 seconds!"
Start-Sleep -Seconds 20
wpeutil reboot
