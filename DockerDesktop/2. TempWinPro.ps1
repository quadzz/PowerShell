#Requires -RunAsAdministrator;

$currVer = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion';
$edId = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').EditionID;

Set-ItemProperty -Path $currVer -Name 'EditionID' -Value 'Professional';
Write-Host "You temporarily have Win10 Pro, congratulations (prev edition: $edId)!";
Write-Host 'You may now run the Docker Desktop Installer. After installation is finished - you can confirm the dialog window to revert changes';
Set-ItemProperty -Path $currVer -Name 'EditionID' -value $edId -Confirm;
Write-Host "`nScript finished!";