function GetConnection {
    param (
        [string]$server
    )
    return New-PSSession $server;
}

function EndConnection {
    param (
        $session
    )

    try {
        Remove-PSSession $session
        return $true;
    }
    catch {
        return $false;
    }
}