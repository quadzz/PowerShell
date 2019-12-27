try {
    git | Out-Null;
}
catch [System.Management.Automation.CommandNotFoundException] {
    Write-Error "Git is not installed! You must install git first! Module will not be imported!";
    return;
}

function Log {
    param (
        [string]
        $msg,
        [switch]
        $e
    )
    $date = (Get-Date).ToString("yyyyMMdd HH:mm:ss.fff");
    if ($e) {
        Write-Error "[GitUtils] | [$date] | $msg";
    }
    else {
        Write-Host "[GitUtils] | [$date] | $msg";
    }
}

function IsGitInstalled {
    try {
        git | Out-Null;
        return $true;
    }
    catch [System.Management.Automation.CommandNotFoundException] {
        return $false;
    }
}

function GetProjectStatusFromGit {
    param (
        [Parameter(Mandatory)]
        [string]
        $CommitFrom,
        [string]
        $CommitTo = "HEAD",
        [string]
        $Path
    )
    Log "About to get project status from git in $Path. Passed parameters - CommitFrom = $CommittFrom, CommitTo = $CommitTo.";

    $prevLocation = (Resolve-Path .).Path;
    Log "Stashing previous location - $prevLocation";

    Set-Location $Path;
    $diff = git diff --name-status $CommitTo $CommitFrom;
    $toReturn = @();
    foreach ($line in $diff.Split([System.Environment]::NewLine)) {
        switch ($line.Substring(0,1)) {
            {@("X","U") -contains $_} {
                # X: "unknown" change type (most probably a bug, please report it)
                # https://git-scm.com/docs/git-diff
                Log -e "File status was `"X`". Not adding to status list. Please report it to responsible people";
                continue;
            }
            default {
                $file = $line.Split();
                Log "Adding $($file[1]) to return list"
                $toReturn += $line.Split()[1];
            }
        }
    }
    
    Set-Location $prevLocation;
}

function GetCommitsSinceCommit {
    param (
        $CommitFrom
    )

    git rev-list "$CommitFrom..HEAD" .;
}

function GetCommitMessageByHash {
    param (
        $SHA
    )

    git log -n 1 --pretty=format:%s $SHA;
}

function GetHeadSha {
    git rev-parse HEAD;
}

function CloneRepo {
    param (
        [string]
        $Repository
    )
    $Repository = $Repository.Replace("\","/");
    $arr = $Repository.Split("/");
    $folder = $arr[$arr.Length-1];

    if (!(Test-Path $folder)) {
        cmd /c git clone $Repository
        if ($LASTEXITCODE -ne 0) {
            Log -e "Cloning went bad! #0"
        }
    }
    Set-Location $folder;
    cmd /C git clean -xdf
    if ($LASTEXITCODE -ne 0) {
        Log -e "Cloning went bad! #1";
    }

    cmd /C git pull
    if ($LASTEXITCODE -ne 0) {
        Log -e "Cloning went bad! #2"
    }
}

function AddAndPushTag {
    param (
        [string]$Repository,
        [string]$Tag
    )

    $prevLocation = (Resolve-Path .).Path;
    Log "Stashing previous location - $prevLocation";
    Log "Setting location to $Repository";
    Set-Location $Repository;
    
    Log "Adding tag $Tag";
    git tag $Tag
    Log "Pushing tags";
    git push --tags 2>&1 | Write-Host
}

Export-ModuleMember -Function "GetProjectStatusFromGit";
Export-ModuleMember -Function "IsGitInstalled";
Export-ModuleMember -Function "GetCommitsSinceCommit";
Export-ModuleMember -Function "GetCommitMessageByHash";
Export-ModuleMember -Function "GetHeadSha";
Export-ModuleMember -Function "CloneRepo";
Export-ModuleMember -Function "AddAndPushTag";
