$script:_TFSAddress = "";

function Log {
    param (
        [string]
        $msg,
        [switch]
        $e
    )
    $date = (Get-Date).ToString("yyyyMMdd HH:mm:ss.fff");
    if ($e) {
        Write-Error "[TFSUtils] | [$date] | $msg";
    }
    else {
        Write-Host "[TFSUtils] | [$date] | $msg";
    }
}

function CheckIfTFSAddressIsSet {
    if ([string]::IsNullOrEmpty($script:_TFSAddress)) {
        Write-Error "TFS Address is not set - first, set address using `nSetTFSAddressForModule -tfsAddress [TFSAddress]";
        exit 1;  
    }
}

function CreateTFSclient {
    param (
        [string]$username, 
        [string]$ContentType = "application/json"
    )

    CheckIfTFSAddressIsSet;

    $client = New-Object System.Net.WebClient;
    $client.Headers["Content-Type"] = $ContentType;
    $client.UseDefaultCredentials = $true;
    return $client;
}

function SetTFSAddressForModule {
    param (
        [string]$tfsAddress
    )
    Log "About to set TFS address to $tfsAddress";
    $script:_TFSAddress = $tfsAddress;
    Log "Address set";
}

function GetBuildInfo { 
    param (
        $buildId,
        $username
    )

    $wc = CreateTFSclient -username $username;
    $uri = "$($script:_TFSAddress)`/_apis/build/builds?buildId=$buildId";
    $jsondata = $wc.DownloadString($uri) | ConvertFrom-Json;
    return $jsondata;
}

# function GetLastSuccessfulBuild
# {
#     param
#     (
#         $tfsAddress,
#         $definitionId,
#         $username
#     )

#     $client = CreateTFSclient -username $username;
#     $url = "$tfsAddress`/_apis/build/builds?definitions=$definitionId`&statusFilter=completed&`$top=1";
#     $jsonData = $client.DownloadString($url) | ConvertFrom-Json;
#     return $jsonData;
# }

function GetBuildWorkItems {
    param (
        $buildId,
        $username
    )

    $client = CreateTFSclient -username $username;
    $url = "$script:_TFSAddress`/_apis/build/builds`/$buildId`/workitems";
    $jsonData = $client.DownloadString($url) | ConvertFrom-Json;
    return $jsonData; 
}

function GetBuildCodeChanges {
    param (
        $buildId,
        $username
    )

    $client = CreateTFSclient -username $username;
    $url = "$script:_TFSAddress`/_apis/build/builds/$buildId`/changes";
    $jsonData = $client.DownloadString($url) | ConvertFrom-Json;
    return $jsonData;
}

function GetWorkItemDetails {
    param (
        $url,
        $username
    )
    $client = CreateTFSclient -username $username;
    $jsonData = $client.DownloadString($url) | ConvertFrom-Json;
    return $jsonData;
}

function GetBuildDetails {
    param (
        $buildNumber,
        $username,
        [PSCustomObject]
        $CustomReleaseNotes
    )
    Write-Host "Getting details of build [$buildNumber] from server [$script:_TFSAddress]";
    $buildName = "";
    $buildBranch = "";
    $workItemsInfo = "";
    $buildTime = "";
    $codeChangesInfo = "";

    $buildWorkItems = GetBuildWorkItems -tfsAddress $script:_TFSAddress -buildId $buildNumber -username $username;

    $ccInfo = GetBuildCodeChanges -buildId $buildNumber -username $username;

    if ($ccInfo.count -gt 0) {
        $ccText = @();

        foreach ($item in $ccInfo.value) {
            Log $item.message;
            $ccText += "* $($item.message) <br/>";
        }

        $codeChangesInfo = $ccText;
    }
    else {
        $codeChangesInfo = "<i>No Code Changes associated with build $buildNumber<i>" 
    }

    if ($buildWorkItems.count -gt 0) {
        $wiText = @();
        foreach ($item in $buildWorkItems.value) {
            $info = GetWorkItemDetails -url $item.url -username $username;
            $title = $info.fields."System.Title";
            $href = $info."_links".html.href;
            $id = $info.id;
            $wiText += "$id - $title <a href=`"$href`" target=`"_blank`">VIEW WORK ITEM IN TFS</a><br/>";
        }
        $workItemsInfo = $wiText;
    }
    else {
        $workItemsInfo = "<i>No Work Items strictly associated in TFS with build $buildNumber<i>";
    }

    $buildInfo = GetBuildInfo -tfsAddress $tfsAddress -buildId $buildNumber -username $username;
    
    if ($buildInfo.startTime) {
        $startTime = [datetime]$buildInfo.startTime;
    }
    if ($buildInfo.finishTime) {
        $finishTime = [datetime]$buildInfo.finishTime;
    }

    $buildTimeStr = "";
    if (!([string]::IsNullOrEmpty($finishTime)) -and (!([string]::IsNullOrEmpty($startTime)))) {
        $buildTime = $finishTime - $startTime;
        $buildTimeStr = "$([math]::Round($buildTime.TotalMinutes,2)) minutes ($([math]::Round($buildTime.TotalSeconds,2)) seconds)";
    }
    else {
        if (!([string]::IsNullOrEmpty($startTime))) {
            $buildTimeStr = "started $startTime";
        }
    }
    

    $buildBranch = $buildInfo.sourceBranch;
    $buildNumber = $buildInfo.buildNumber;
    $buildLink = $buildInfo.'_links'.web.href;
    $buildName = $buildInfo.definition.name;
    $generateTime = (Get-Date).ToString("yyyy.MM.dd HH:mm:ss");
    if ($CustomReleaseNotes) {
        Log "Custom release notes info was provided."
        if ([string]::IsNullOrEmpty($CustomReleaseNotes.WorkItemsInfo)) {
            Log "Writing custom work items info";
            $workItemsInfo = $CustomReleaseNotes.WorkItemsInfo;
        }
        if ([string]::IsNullOrEmpty($CustomReleaseNotes.CodeChangesInfo)) {
            Log "Writing custom code changes info";
            $codeChangesInfo = $CustomReleaseNotes.CodeChangesInfo;
        }
    }

    $details = [PSCustomObject] @{
        BuildName       = $buildName;
        BuildLink       = $buildLink;
        BuildNumber     = $buildNumber;
        BuildBranch     = $buildBranch;
        WorkItemsInfo   = $workItemsInfo;
        BuildTime       = $buildTimeStr;
        GenerateTime    = $generateTime;
        CodeChangesInfo = $codeChangesInfo;
    };

    return $details
}

function ReplaceTokens {
    param (
        $line,
        $data
    )

    $tokens = $line | Select-String -Pattern '(\${.*?})' -AllMatches | ForEach-Object matches | ForEach-Object value;
    if (!$tokens) {
        return $line;
    }
    foreach ($token in $tokens) {
        $info = $token -replace '[${}]', "";
        $info = $data.$info;
        if ($info) {
            return $line.Replace($token, $info);
        }
    }
}

function RenderTemplate {
    param (
        $pathToTemplate,
        $outputFile,
        $buildNumber,
        $userName,
        [PSCustomObject]
        $CustomReleaseNotes
    )
    $info = "";
    if ($CustomReleaseNotes) {
        $info = GetBuildDetails -tfsAddress $script:_TFSAddress -buildNumber $buildNumber -username $userName;
    }
    else {
        $info = GetBuildDetails -tfsAddress $script:_TFSAddress -buildNumber $buildNumber -username $userName -CustomReleaseNotes $CustomReleaseNotes;
    }
    
    $content = Get-Content $pathToTemplate;
    $newContent = @();
    $lines = $content.Split([System.Environment]::NewLine);
    Write-Host "About to prepare output before setting $outputFile";
    foreach ($line in $lines) {
        $newContent += ReplaceTokens -line $line -data $info;
    }
    Write-Host "Setting content of $outPutFile with info of build [$buildNumber]";
    Set-Content $outputFile $newContent;
}

function RenderCustomMessageTemplate {
    param (
        $codeChangesInfo,
        $workItemsInfo,
        $pathToTemplate,
        $outputFile,
        $buildNumber,
        $userName
    )
    $buildInfo = GetBuildInfo -tfsAddress $tfsAddress -buildId $buildNumber -username $username;

    if ($buildInfo.startTime) {
        $startTime = [datetime]$buildInfo.startTime;
    }

    if (!([string]::IsNullOrEmpty($startTime))) {
        $buildTimeStr = "started $startTime";
    }

    if ([string]::IsNullOrEmpty($workItemsInfo)) {
        $buildWorkItems = GetBuildWorkItems -tfsAddress $script:_TFSAddress -buildId $buildNumber -username $username;
        if ($buildWorkItems.count -gt 0) {
            $wiText = @();
            foreach ($item in $buildWorkItems.value) {
                $info = GetWorkItemDetails -url $item.url -username $username;
                $title = $info.fields."System.Title";
                $href = $info."_links".web.href;
                $id = $info.id;
                $wiText += "$id - $title <a href=`"$href`" target=`"_blank`">VIEW WORK ITEM IN TFS</a><br/>";
            }
            $workItemsInfo = $wiText;
        }
        else {
            $workItemsInfo = "<i>No Work Items strictly associated in TFS with build $buildNumber<i>";
        }
    }

    $buildBranch = $buildInfo.sourceBranch;
    $buildNumber = $buildInfo.buildNumber;
    $buildLink = $buildInfo.'_links'.web.href;
    $buildName = $buildInfo.definition.name;
    $generateTime = (Get-Date).ToString("yyyy.MM.dd HH:mm:ss");

    $details = [PSCustomObject] @{
        BuildName       = $buildName;
        BuildLink       = $buildLink;
        BuildNumber     = $buildNumber;
        BuildBranch     = $buildBranch;
        WorkItemsInfo   = $workItemsInfo;
        BuildTime       = $buildTimeStr;
        GenerateTime    = $generateTime;
        CodeChangesInfo = $codeChangesInfo;
    };

    $content = Get-Content $pathToTemplate;
    $newContent = @();
    $lines = $content.Split([System.Environment]::NewLine);
    Write-Host "About to prepare output before setting $outputFile";
    foreach ($line in $lines) {
        if ($line.Contains("Code changes associated with build")) {
            if ([string]::IsNullOrEmpty($codeChangesInfo)) {
                Write-Host "Deleting code changes text from template";
                continue;
            }
        }
        $newContent += ReplaceTokens -line $line -data $details;
    }
    Write-Host "Setting content of $outPutFile with info of build [$buildNumber]";
    Set-Content $outputFile $newContent;
}

function GetWorkItemFromString {
    param (
        [string]
        $content
    )
    $toReturn = New-Object System.Collections.Generic.List[System.Object];
    $lines = $content.Split([System.Environment]::NewLine);
    foreach ($line in $lines) {
        $found = $line -match "(#[\w]*)";
        if ($found) {
            if (!($toReturn -contains $Matches[1])) {
                Write-Host "Adding $($Matches[1])";
                $toReturn.Add($Matches[1]);
            }
            
        }
    }
    Write-Host "Returning: $toReturn";
    return $toReturn;
}

function GetSpecificWorkItemData {
    param (
        [string]
        $id,
        [string]
        $user
    )

    $client = CreateTFSclient -username $user;
    $url = "$script:_TFSAddress`/_apis/wit/workitems/$id";
    $jsonData = $client.DownloadString($url) | ConvertFrom-Json;
    return $jsonData;
}

function GetCommitMessageWithRenderedWorkItemLinks {
    param (
        [string]
        $commitMsg,
        [string]
        $user
    )
    
    $workItems = GetWorkItemFromString $commitMsg $user;

    foreach ($item in $workItems) {
        $actual = $item.Replace("#","");
        $info = (GetSpecificWorkItemData $actual);
        $href = $info."_links".html.href;
        $replacementString = "<a href=`"$href`" target=`"_blank`">$item</a>"
        $commitMsg.Replace($item, $replacementString);
    }
    return $commitMsg;
}

Export-ModuleMember -Function "SetTFSAddressForModule";
Export-ModuleMember -Function "GetBuildInfo";
Export-ModuleMember -Function "GetBuildWorkItems";
Export-ModuleMember -Function "GetBuildCodeChanges";
Export-ModuleMember -Function "RenderTemplate";
Export-ModuleMember -Function "RenderCustomMessageTemplate";
Export-ModuleMember -Function "GetWorkItemFromString";
Export-ModuleMember -Function "GetCommitMessageWithRenderedWorkItemLinks";