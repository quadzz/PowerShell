function Log {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("Debug","Info","Warning","Error")]
        [string]
        $Level,
        [Parameter(Mandatory)]
        [string]
        $message
    )

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff");

    $color = (Get-Host).UI.RawUI.ForegroundColor;

    switch ($Level) {
        "Info" {
            $color = "Green";
            break;
        }
        "Warning" {
            $color = "Yellow";
            break;
        }
        "Error" {
            $color = "Red";
            break;
        }
    }

    Write-Host "[$timestamp][$Level] - $message" -ForegroundColor $color;
}

function LogDebug($message) {
    Log -Level "Debug" -message $message;
}

function LogInfo($message) {
    Log -Level "Info" -message $message;
}

function LogWarning($message) {
    Log -Level "Warning" -message $message;
}

function LogError($message) {
    Log -Level "Error" -message $message;
}

Export-ModuleMember -Function "LogDebug";
Export-ModuleMember -Function "LogInfo";
Export-ModuleMember -Function "LogWarning";
Export-ModuleMember -Function "LogError";
