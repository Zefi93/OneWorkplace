#================================================================================================
#   Purpose:    This script set the needed configuration to install the base image 
#               for 20H2 and also install drivers and Windows updates to latest as needed.
#================================================================================================

# Version 1.1   (30/01/2022) : Fix Typo
# Version 1.2   (31/01/2022) : Add OSLicense
# Version 1.3   (27/09/2022) : Add new release version
# Version 1.4   (12/12/2024) : Add new release version
# Version 1.4.1 (21/02/2025) : Fix issue with W10
# Version 1.4.2 (30/06/2025) : Add W11 24H2


#Change Display Resolution for Virtual Machine
if ((Get-MyComputerModel) -match 'Virtual') {
    Write-Host  -ForegroundColor Cyan "Setting Display Resolution to 1600px"
    Set-DisRes 1600
}
Clear-Host
Write-Host "===========================================================" -ForegroundColor Yellow
Write-Host "================= Windows Edition (1.4.1) =================" -ForegroundColor Yellow
Write-Host "===========================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "1: Windows 10 22H2 | French  | Pro" -ForegroundColor Green
Write-Host "2: Windows 11 23H2 | French  | Pro" -ForegroundColor Yellow
Write-Host "3: Windows 11 24H2 | French  | Pro" -ForegroundColor Yellow
Write-Host "5: Start OSDCloud GUI" -ForegroundColor Yellow
Write-Host "99: Secret menu ;)" -ForegroundColor Yellow
#Write-Host "3: Windows 10 21H1 | French  | Pro (Not supported)" -ForegroundColor Yellow
#Write-Host "4: Windows 10 21H1 | English | Pro (Not supported)" -ForegroundColor Yellow
Write-Host ""
Write-Host "5: Exit`n" -ForegroundColor Cyan
$input = Read-Host "Please make a selection"

Write-Host  -ForegroundColor Yellow "Loading OSDCloud..."

Import-Module OSD -Force
Install-Module OSD -Force

switch ($input)
{
    '1' {   Start-OSDCloud -OSLanguage fr-fr -OsVersion 'Windows 10' -OSBuild 22H2 -OSEdition Pro -ZTI -SkipAutopilot -SkipODT -Oslicense Retail }
    '2' {   Start-OSDCloud -OSLanguage fr-fr -OsVersion 'Windows 11' -OSBuild 23H2 -OSEdition Pro -ZTI -SkipAutopilot -SkipODT -Oslicense Retail }
    '3' {   Start-OSDCloud -OSLanguage fr-fr -OsVersion 'Windows 11' -OSBuild 24H2 -OSEdition Pro -ZTI -SkipAutopilot -SkipODT -Oslicense Retail }
    '5' {   Start-OSDCloudGui }
#    '3' {   Start-OSDCloud -OSLanguage fr-fr -OSBuild 21H1 -OSEdition Pro -ZTI -SkipAutopilot -SkipODT -Oslicense Retail }
#    '4' {   Start-OSDCloud -OSLanguage en-us -OSBuild 21H1 -OSEdition Pro -ZTI -SkipAutopilot -SkipODT -Oslicense Retail }

    '5' { Exit }
    '99' {  Start-OSDCloud }
    'HP' {  Start-OSDCloud -OSLanguage fr-fr -OSBuild 23H2 -OSEdition Pro -ZTI -SkipAutopilot -SkipODT -Manufacturer HP -Product 8723 -Screenshot -Oslicense Retail }
}

#================================================================================================
#   WinPE PostOS
#   Set Install-Updates.ps1
#================================================================================================
$SetCommand = @'
Function Install-MSUpdates{
    param (
        $LocationLCU = 'C:\MSUpdates\LCU',
        $LocationDotNet = 'C:\MSUpdates\DotNet'
    )
    $UpdatesLCU = (Get-ChildItem $LocationLCU | Where-Object {$_.Extension -eq '.msu'} | Sort-Object {$_.LastWriteTime} )
    $UpdatesDotNet = (Get-ChildItem $LocationDotNet | Where-Object {$_.Extension -eq '.msu'} | Sort-Object {$_.LastWriteTime} )
    Set-Location -Path $LocationLCU
    foreach ($Update in $UpdatesLCU)
    {
        Write-Host "Expanding $Update"
        expand -f:* $Update.FullName .
    }  
    $UpdatesLCU = (Get-ChildItem $LocationLCU | Where-Object {$_.Extension -eq '.cab'} | Sort-Object {$_.LastWriteTime} )
    foreach ($Update in $UpdatesLCU)
    {
        Write-Host "Installing $Update"
        Add-WindowsPackage -Online -PackagePath $Update.FullName -NoRestart -ErrorAction SilentlyContinue
    }  
    Set-Location -Path $LocationDotNet
    foreach ($Update in $UpdatesDotNet)
    {
        Write-Host "Expanding $Update"
        expand -f:* $Update.FullName .
    }  
    $UpdatesDotNet = (Get-ChildItem $LocationDotNet | Where-Object {$_.Extension -eq '.cab'} | Sort-Object {$_.LastWriteTime} )
    foreach ($Update in $UpdatesDotNet)
    {
        Write-Host "Installing $Update"
        Add-WindowsPackage -Online -PackagePath $Update.FullName -NoRestart -ErrorAction SilentlyContinue
    }     
}
Install-MSUpdates
'@
$SetCommand | Out-File -FilePath "C:\Windows\Install-Updates.ps1" -Encoding ascii -Force

#================================================================================================
#   Download latest Windows update from Microsoft
#================================================================================================
#Save-MsUpCatUpdate -Arch x64 -Build $Global:OSBuild -Category DotNetCU -Latest -DestinationDirectory C:\MSUpdates\DotNet
#Save-MsUpCatUpdate -Arch x64 -Build $Global:OSBuild -Category LCU -Latest -DestinationDirectory C:\MSUpdates\LCU
Save-MsUpCatUpdate -Arch x64 -Category DotNetCU -Latest -DestinationDirectory C:\MSUpdates\DotNet
Save-MsUpCatUpdate -Arch x64 -Category LCU -Latest -DestinationDirectory C:\MSUpdates\LCU

#================================================================================================
#   PostOS
#   Installing driver and update Microsoft patches
#   during specialize phase
#================================================================================================
$UnattendXml = @'
<?xml version='1.0' encoding='utf-8'?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="specialize">
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <Description>OSDCloud Specialize</Description>
                    <Path>Powershell -ExecutionPolicy Bypass -Command Invoke-OSDSpecialize -Verbose</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>2</Order>
                    <Description>Install Windows Update</Description>
                    <Path>Powershell -ExecutionPolicy Bypass -File C:\Windows\Install-Updates.ps1</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>3</Order>
                    <Description>Remove Windows Update Files</Description>
                    <Path>Powershell -ExecutionPolicy Bypass -Command Remove-Item -Path C:\MSUpdates -Recurse</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>4</Order>
                    <Description>Remove OSDCloud Temp Files</Description>
                    <Path>Powershell -ExecutionPolicy Bypass -Command Remove-Item -Path C:\OSDCloud -Recurse</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>5</Order>
                    <Description>Remove Drivers Temp Files</Description>
                    <Path>Powershell -ExecutionPolicy Bypass -Command Remove-Item -Path C:\Drivers -Recurse</Path>
                </RunSynchronousCommand>                  
            </RunSynchronous>
        </component>
    </settings>    
</unattend>
'@
#================================================================================================
#   Set Unattend.xml
#================================================================================================
$PantherUnattendPath = 'C:\Windows\Panther'
if (-NOT (Test-Path $PantherUnattendPath)) {
    New-Item -Path $PantherUnattendPath -ItemType Directory -Force | Out-Null
}
$UnattendPath = Join-Path $PantherUnattendPath 'Invoke-OSDSpecialize.xml'
$UnattendXml | Out-File -FilePath $UnattendPath -Encoding utf8
#Use-WindowsUnattend -Path 'C:\' -UnattendPath $UnattendPath -Verbose

#================================================================================================
#   WinPE PostOS
#   Restart Computer
#================================================================================================
Restart-Computer
