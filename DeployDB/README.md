# SonarQube PowerShell module

This script is deploying scripts or whole folders with scripts to MSSQL instances.

## Usage

Example script provided below - it's example from my TFS automated build

```powershell
.\TFS_PerformDBDeploy.ps1 -SQLServerAddress $DBServer -SQLDatabaseName $DBName -ScriptsContainer $sqlPath;
```

## Parameters

```powershell
$SQLServerAddress
```
This parameter specifies SQL instance to connect to.

```powershell
$SQLDatabaseName
```
This parameter specifies SQL database to query against.

```powershell
$ScriptsContainer
```
This parameter specifies folder with scripts that will be deployed. All files will be executed, in naming order.

```powershell
$ScriptFilePath
```
Single file to deploy. If this parameter is speficied - the container parameter will be ommmitted.

```powershell
$SQLUserName
```
SQL Username that is being used to connecting to instance

```powershell
$SQLPw
```
SQL user password that is being used to connecting to instance
