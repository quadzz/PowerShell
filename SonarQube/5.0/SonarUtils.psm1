class SonarQubeUtils {

    [string] $_SonarAddress;
    [string] $_Token;
    hidden [string] $_ApiProjectStatusAddress = "/api/qualitygates/project_status";
    hidden [string] $_ApiProjectsListAddress = "/api/components/search?qualifiers=TRK";
    hidden [string] $_ApiSonarStatusAddress = "/api/system/health";
    hidden [string] $_ContentType = "application/json";
    
    SonarQubeUtils([string]$sonarAddress, $token) {
        $this._SonarAddress = $sonarAddress.Trim('/').Trim('\');
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

    [bool] GetSonarProjectQualityGateStatus($projectKey) {
        Write-Host "Getting project status of $projectKey";
        $client = $this.CreateWebClient();
        Write-Host $client.Headers;
        if ($client) {
            $uri = "$($this._SonarAddress)$($this._ApiProjectStatusAddress)`?projectKey=$projectKey";
            Write-Host "Uri is $uri";
            $json = $client.DownloadString($uri) | ConvertFrom-Json;
            if ($json.projectstatus.status -eq "OK") {
                return $true;
            }
            else {
                Write-Host "Status is $($json.projectstatus.status)";
                return $false;
            }
        }
        else {
            Write-Host "Could not create client.";
            return $false;
        }
    }
}