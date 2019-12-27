function Log {
    param (
        [string]
        $msg
    )
    $date = (Get-Date).ToString("yyyyMMdd HH:mm:ss.fff");
    Log "[FileUtils] | [$date] | $msg";
}

function ZipDir
{
    param (
        [string]
        $zipfilename, 
        [string]
        $sourcedir
    )
    Add-Type -Assembly System.IO.Compression.FileSystem
    $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
    [System.IO.Compression.ZipFile]::CreateFromDirectory($sourcedir, $zipfilename, $compressionLevel, $false)
}

function ZipFile {
    param (
        [string]
        $filePath,
        [string]
        $zipPath
    )
    $7z = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | ? {$_.DisplayName -like "7-Zip*"}
    if ($7z) {
        & "$env:ProgramFiles\7-Zip\7z.exe" a -mx=9 $zipPath $filePath
    }
    else {
        Write-Warning "No 7z installed"
    }
}

function UnZip {
    param(
        [Parameter(Mandatory)]
        [string]
        $what,
        [Parameter(Mandatory)]
        [string]
        $where,
        [switch]
        $UseDefault
    )

    $7z = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | ? {$_.DisplayName -like "7-Zip*"}
    if ((!$7z) -or $UseDefault) {
        try {
            [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null;
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$what", "$where");
        }
        catch {
            Write-Warning -Message "Unexpected Error. Error details: $($_.Exception.Message)";
        }
    }
    else {
        $args = "x -o`"$where`" `"$what`" -r";
        & "$env:ProgramFiles\7-Zip\7z.exe" $args;
    }
}

function ClearTargetFolder {
    param(
        [Parameter(Mandatory)]
        [string]
        $path
    )

    if (Test-Path $path) {
        Get-ChildItem $path -Recurse | ForEach-Object { Remove-Item $_.FullName -Force -Recurse -ErrorVariable clearing; };
        if (!$clearing) {
            Log "Clearing target folder went OK";
        }
        else {
            Log "Something wrong went with clearing folder. $clearing";
        }
    }
}
Export-ModuleMember -Function "ZipDir";
Export-ModuleMember -Function "ZipFile";
Export-ModuleMember -Function "UnZip";
Export-ModuleMember -Function "ClearTargetFolder";