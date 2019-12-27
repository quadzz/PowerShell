param (
    [Parameter(Mandatory)]
    [string]
    $sonarAddress,
    [Parameter(Mandatory)]
    [string]
    $token
)

class SonarQubeUtils {
    [string] $_SonarAddress;
    [string] $_Token;
    hidden [string] $_ApiProjectStatusAddress = "/api/qualitygates/project_status";
    hidden [string] $_ContentType = "application/json";

    SonarQubeUtils([string]$sonarAddress, $token) {
        $this._SonarAddress = $sonarAddress;
        $this._Token = $token;
    }

    [System.Net.WebClient] CreateWebClient() {
        $client = New-Object System.Net.WebClient;
        $client.Headers["Content-Type"] = $this._ContentType;
        $token = [System.Text.Encoding]::UTF8.GetBytes("$($this._Token)`:");
        $base64 = [System.Convert]::ToBase64String($token);
        $client.Headers.Add("Authorization", "Basic $base64");

        return $client;
    }

    [bool] GetSonarProjectQualityGateStatus($project) {
        $client = [SonarQubeUtils]::CreateWebClient();
        Write-Host $client.Headers;
        if ($client) {
            
        }
    }
}

$sonarUtils = [SonarQubeUtils]::new($sonarAddress, $token);