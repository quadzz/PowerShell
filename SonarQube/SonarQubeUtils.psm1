function Log {
    param (
        [string]
        $msg,
        [switch]
        $e
    )
    $date = (Get-Date).ToString("yyyyMMdd HH:mm:ss.fff");
    if ($E) {
        Write-Error "[SonarQubeUtils] | [$date] | $msg";
    }
    else {
        Write-Host "[SonarQubeUtils] | [$date] | $msg";
    }
}

function CreateSonarClient {
    param (
        [string]$username, 
        [string]$ContentType = "application/json"
    )

    $client = New-Object System.Net.WebClient;
    $client.Headers["Content-Type"] = $ContentType;
    $client.UseDefaultCredentials = $true;
    return $client;
}

function GetProjectStatus {
    param (
        [string]
        $ProjectKey
    )
    

}

