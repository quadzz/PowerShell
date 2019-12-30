class SonarQubeUtils {
    [string] $SonarAddress;
    [string] $Token;
    hidden [string] $ApiProjectStatusAddress = "/api/qualitygates/project_status";
    hidden [string] $ApiProjectsListAddress = "/api/components/search?qualifiers=TRK";
    hidden [string] $ApiSonarStatusAddress = "/api/system/health";
    hidden [string] $ContentType = "application/json";
    
    SonarQubeUtils([string]$sonarAddress, $token) {
        $this.SonarAddress = $sonarAddress.Trim('/').Trim('\');
        $this.Token = $token;
    }

    [System.Net.WebClient] CreateWebClient() {
        $client = New-Object System.Net.WebClient;
        $client.Headers["Content-Type"] = $this.ContentType;
        
        $byteToken = [System.Text.Encoding]::UTF8.GetBytes("$($this.Token)`:");
        $base64 = [System.Convert]::ToBase64String($byteToken);
        $client.Headers.Add("Authorization", "Basic $base64");

        return $client;
    }

    [string] GetSonarProjectQualityGateStatus($projectKey) {
        Write-Host "Getting project status of $projectKey";
        $client = $this.CreateWebClient();
        if ($client) {
            $uri = "$($this.SonarAddress)$($this.ApiProjectStatusAddress)`?projectKey=$projectKey";
            Write-Host "Uri is $uri";
            $json = $client.DownloadString($uri) | ConvertFrom-Json;
            return $json.projectstatus.status;
        }
        else {
            Write-Host "Could not create client.";
            return $false;
        }
    }
}
