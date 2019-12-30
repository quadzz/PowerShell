param (
    [Parameter(
        Mandatory,
        HelpMessage = "Specify SQL Server address to deploy to"
    )]
    [ValidateNotNullOrEmpty()]
    [string]$SQLServerAddress = $(throw "No SQL Server address specified"),
    [Parameter(
        Mandatory,
        HelpMessage = "Specify SQL Server database name"
    )]
    [ValidateNotNullOrEmpty()]
    [string]$SQLDatabaseName,
    [Parameter(
        Mandatory,
        HelpMessage = "Specify folder with T-SQL scripts to deploy. Script will iterate through all files with .sql extension"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({
        Test-Path $_ -PathType Container;
    })]
    [string]$ScriptsContainer,
    [Parameter(
        Mandatory=$false,
        HelpMessage = "Specify full path of script to deploy (including extension of file) - leave empty if script should iterate through files in folder"
    )]
    [string]$ScriptFilePath,
    [Parameter(Mandatory=$false)]
    [AllowEmptyString()]
    [string]$SQLUserName,
    [Parameter(Mandatory=$false)]
    [AllowEmptyString()]
    [string]$SQLPw
)

function Log {
    param (
        [string]
        $msg,
        [switch]
        $d,
        [switch]
        $w,
        [switch]
        $e
    )

    $fileNameDate = (Get-Date).ToString("yyyyMMdd");
    $logPath = "C:\Logs\DeployDB_$fileNameDate.log";
    $logMsg = "";
    $date = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff");
    if ($e) {
        $logMsg = "DeployDB|$date|ERROR|$msg";
        Write-Host $logMsg -ForegroundColor Red;
    }
    elseif ($d) {
        $logMsg = "DeployDB|$date|DEBUG|$msg";
        Write-Host $logMsg;
    }
    elseif ($w) {
        $logMsg = "DeployDB|$date|WARNING|$msg";
        Write-Host $logMsg -ForegroundColor Yellow
    }
    else {
        $logMsg = "DeployDB|$date|$msg";
        Write-Host $logMsg
    }

    if (!([string]::IsNullOrEmpty($logMsg))) {
        if (!(Test-Path $logPath)) {
            Write-Host "Creating file $logPath";
            New-Item $logPath -ItemType File;
        }
        $logMsg >> $logPath | Out-Null;
    }
}
Log -d "Initializing script";
#Create connection
Log -d "About to create SQL Connection to $SQLServerAddress to db $SQLDatabaseName";
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection;
$connString = "Server=$SQLServerAddress;Database=$SQLDatabaseName;";

if (([string]::IsNullOrEmpty($SQLUserName)) -or ([string]::IsNullOrEmpty($SQLPw))) {
    Log -d "Choosing integrated security for SQL connection";
    $connString += "Integrated Security=True;";
}
else {
    Log -d "Choosing actual credentials - user $SQLUserName";
    $connString += "User Id=$SQLUserName; Password=$SQLPw;";
}
$SqlConnection.ConnectionString = $connString;

try {
    Log -d "About to open connection to $SQLServerAddress";
    $SqlConnection.Open();
}
catch {
    Log -e "Could not open connection to $SQLServerAddress";
    exit 1;
}

Log -d "Connection to $SQLServerAddress opened";

function ProcessFile {
    param (
        [string]$file
    )
    Log -d "In ProcessFile function. File passed - $file"
    $toReturn = "";
    
    $text = Get-Content $file;

    foreach ($line in $text) {
        if (!([string]::IsNullOrEmpty($line))) {
            # Log -d "Adding line `"$line`" to execute";
            $toReturn += $line;
            $toReturn += [Environment]::NewLine
        }
    }

    $toReturn += [System.Environment]::NewLine;
    Log -d "About to return prepared scripts";
    return $toReturn;
}

$SQLtoExecute = "";
if (!([string]::IsNullOrEmpty($ScriptFilePath)) -and ($ScriptFilePath.EndsWith(".sql"))) {
    Log -d "Script was run with single file name to deploy - file is $ScriptFilePath";
    $sqltxt = ProcessFile -file $ScriptFilePath;
    $batches = $sqltxt -split ([System.Environment]::NewLine + "GO" + [System.Environment]::NewLine);
    Log -d "Got $($batches.Count) to process";
    foreach ($batch in $batches) {
        if (!([string]::IsNullOrEmpty($batch.Trim()))) {
            $SQLtoExecute = $batch;
            try {
                Log -d "About to invoke script against the DB:`n$SQLtoExecute";
                $sqlCmd.CommandText = $SQLtoExecute;
                $msg = $sqlCmd.ExecuteScalar();
                Log -d $msg;
            }
            catch {
                Log -e "Error occured during executing command. Error was: $($_.Exception.Message)";
                exit 1;
            }
        }
    }
    
}
else {
    if (!([string]::IsNullOrEmpty($ScriptsContainer))) {
        Log -d "Parameter scripts containter is not empty. About to execute all scripts from folder $ScriptsContainer";
        $files = Get-ChildItem $ScriptsContainer | Where-Object Name -like "*.sql" | Sort-Object Name;
        $sqlCmd = New-Object System.Data.SqlClient.SqlCommand("", $SqlConnection);

        foreach ($file in $files) {
            Log "Processing file $($file.Name)";
            $toAdd = (ProcessFile -file $file.FullName);
            $SQLtoExecute = $toAdd;
            Log -d "SQL to execute is `n$SQLtoExecute";
            
            try {
                Log -d "About to invoke script against the DB";
                $sqlCmd.CommandText = $SQLtoExecute;
                $msg = $sqlCmd.ExecuteScalar();
                Log -d $msg;
            }
            catch {
                Log -e "Error occured during executing command. Error was: $($_.Exception.Message)";
                exit 1;
            }
        }
    }
}

if ($SqlConnection.State -eq "Open") {
    Log -d "Connection state is OPEN. Closing SQL connection";
    $SqlConnection.Close();
}
else {
    Log -d "Connection is closed. No need for closing";
}
