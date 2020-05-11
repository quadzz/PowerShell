#Requires -RunAsAdministrator

#Based on @talon script
function Import-Feature {
    param( 
        $Name 
    )
    
    $packages = Get-ChildItem "C:\Windows\servicing\Packages\*$Name*.mum";
    foreach ($package in $packages) {
        Dism /online /NoRestart /Add-Package:"$package";
    }
    Dism /online /NoRestart /Enable-Feature /FeatureName:$Name -All /LimitAccess /ALL;
}

Import-Feature -Name Microsoft-Hyper-V;
Import-Feature -Name Containers;
Write-Host "Restart computer now!";