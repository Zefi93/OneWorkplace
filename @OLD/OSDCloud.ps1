Write-Host  -ForegroundColor Yellow "Starting Brooks' Custom OSDCloud ..."
cls
Write-Host "===================== Main Menu =======================" -ForegroundColor Yellow
Write-Host "===================== Thomas ==========================" -ForegroundColor Yellow
Write-Host "=======================================================" -ForegroundColor Yellow
Write-Host "1: Windows 10 21H1 | French | Pro"-ForegroundColor Yellow
Write-Host "2: Windows 10 20H2 | French | Pro | (Use This One !)"-ForegroundColor Green
Write-Host "3: Windows 10 21H1 | English | Pro"-ForegroundColor Yellow
Write-Host "4: Windows 10 20H2 | English | Pro"-ForegroundColor Yellow
Write-Host "5: I'll select it myself"-ForegroundColor Yellow
Write-Host "6: Exit`n"-ForegroundColor Yellow
$input = Read-Host "Please make a selection"

Write-Host  -ForegroundColor Yellow "Loading OSDCloud..."

Import-Module OSD -Force
Install-Module OSD -Force

switch ($input)
{
    '1' { Start-OSDCloud -OSLanguage fr-fr -OSBuild 21H1 -OSEdition Pro -ZTI } 
    '2' { Start-OSDCloud -OSLanguage fr-fr -OSBuild 20H2 -OSEdition Pro -ZTI }
    '3' { Start-OSDCloud -OSLanguage en-us -OSBuild 21H1 -OSEdition Pro -ZTI } 
    '4' { Start-OSDCloud -OSLanguage en-us -OSBuild 20H2 -OSEdition Pro -ZTI }
    '5' { Start-OSDCloud } 
    '6' { Exit }
}
Read-Host -Prompt "Please remove the USB key then hit any key to continue ..."
wpeutil reboot
