$myshell = New-Object -com "Wscript.Shell";
$count = 0;

while (1) {
  Write-Host "Turn $count";
  Start-Sleep -Seconds 60
  $myshell.sendkeys(".");
  $count++;
}
