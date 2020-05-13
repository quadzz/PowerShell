Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing
[xml]$xaml = "";
[xml]$xaml = Get-Content .\GUI.xaml -Force;
[void] [Reflection.Assembly]::LoadWithPartialName( 'System.Windows.Forms' )
Import-Module ".\Modules\ConnectionHelpers.psm1" -Force;

$reader = (New-Object System.Xml.XmlNodeReader $xaml);
$window = [Windows.Markup.XamlReader]::Load($reader);

#AutoFind all controls 
$xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")  | ForEach-Object {  
    New-Variable -Name $_.Name -Value $window.FindName($_.Name) -Force  
}
[System.Object]$session = $null;
function Log {
    param (
        [string]$msg
    )
    $LogTB.AppendText("$msg`r");
}

$TabControl.IsEnabled = $false;

$ConnectButton.Add_Click({
    $session = GetConnection -server $ConnectServerName.Text;
    Log "Created session with Id = $($session.Id)`r";
    $ConnectServerName.BorderBrush = "#FF00FF0C";
    $ConnectButton.IsEnabled = $false;
    $TabControl.IsEnabled = $true;
});

$EndConnectionButton.Add_Click({
    if ($session) {
        EndConnection $session;
        Log "Connection $($session.Id) finished`r";
    }
    
    $ConnectServerName.BorderBrush = "Gray";
    $ConnectButton.IsEnabled = $true;
    $TabControl.IsEnabled = $false;
})

$SearchFileButton.Add_Click({
    $dialog = New-Object Windows.Forms.OpenFileDialog
    $dialog.ShowHelp = $false;
    $dialog.ShowDialog();
    $SearchFilePathText.Text = $dialog.FileName;
    $SearchFilePathText.ScrollToEnd();
});
#RUN APP
$result = $window.ShowDialog();
Write-Host "SessionId = $($session.Id)";
if ($result -eq $false) {
    if ($session) {
        EndConnection $session;
    }
}

