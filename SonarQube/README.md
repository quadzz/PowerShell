# SonarQube PowerShell module

This module is created to run script against the SonarQube server. It is created for PowerShell > 5.0. It uses OOP-like approach.

## Usage

Example script provided below - it's example from my TFS automated build

```powershell
using module .\Utils\SonarUtils.psm1

$SonarAddress = $env:SonarAddress;
Write-Host "Got SonarAddress = $SonarAddress";

if (!($SonarAddress)) {
    exit 1;
}

$SonarToken = $env:SonarToken;
Write-Host "Got SonarToken = $SonarToken";

if (!($SonarToken)) {
    exit 1;
}

$SonarProjectKey = $env:SonarProjectKey;
Write-Host "Got SonarProjectKey = $SonarProjectKey";

if (!($SonarProjectKey)) {
    exit 1;
}

$utils = [SonarQubeUtils]::new($SonarAddress, $SonarToken);
$status = $utils.GetSonarProjectQualityGateStatus($SonarProjectKey)
$processing = $status -notin @("OK", "FAILED");

while ($processing) {
    Write-Host "Waiting for SonarQube to process build scan request. Waiting 5 seconds";
    Start-Sleep -Seconds 5;
    $status = $utils.GetSonarProjectQualityGateStatus($SonarProjectKey)
    $processing = $status -notin @("OK", "FAILED");
}

$exitCode = if ($status -eq "OK") { 0 } else { 1 };

Write-Host "Status is $status. Exit code is $exitCode";
exit $exitCode;

```
