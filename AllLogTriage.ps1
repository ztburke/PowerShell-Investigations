<#
.DESCRIPTION
    Collect logs for analysis (Exchange, HTTPERR, IIS, and EVTX)
#>

# Define the location to copy Exchange log data (can be a server share or a local path)
$loglocation = "C:\TriageData-$env:COMPUTERNAME"

# Log all output from this script to Log_Copy.log
Start-Transcript -Path "$loglocation\Log_Copy.log"

# Define how many days to look back for log files
$cutoffdate = (Get-Date).AddDays(-30)

# Function to copy logs
function Copy-Logs {
    param (
        [string]$sourcePath,
        [string]$destinationPath
    )
    Get-ChildItem -Path $sourcePath -Recurse | Where-Object { $_.LastWriteTime -gt $cutoffdate } | ForEach-Object {
        $relativePath = $_.FullName -replace [regex]::Escape($sourcePath), ''
        $destFile = Join-Path $destinationPath $relativePath
        if (Test-Path $_.FullName) {
            New-Item -Path $destFile -Type File -Force | Out-Null
            Copy-Item -Path $_.FullName -Destination $destFile -Force -Verbose
        }
    }
}

# Copy Exchange Logs
Write-Output "[+] Copying Exchange Logs..."
try {
    $exchangeBasePath = (Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ExchangeServer\v15\Setup).MsiInstallPath
    Copy-Logs -sourcePath ($exchangeBasePath + "Logging\*.log") -destinationPath "$loglocation\Logging"
} catch {
    Write-Output $_.Exception.Message
}

# Copy System HTTPERR logs
Write-Output "[+] Copying HTTPERR Logs..."
try {
    Copy-Item -Path "C:\Windows\System32\LogFiles\HTTPERR\*.log" -Destination "$loglocation\HTTPERR" -Verbose -Force
} catch {
    Write-Output $_.Exception.Message
}

# Copy IIS Logs
Write-Output "[+] Copying IIS Logs..."
try {
    Import-Module WebAdministration
    $IISLogPath = (Get-WebConfigurationProperty "/system.applicationHost/sites/siteDefaults" -name logfile.directory).Value
    if ($IISLogPath -match "%SystemDrive%") {
        $IISLogPath = $IISLogPath -replace "%SystemDrive%", $env:SystemDrive
    }
    Copy-Logs -sourcePath ($IISLogPath + "\*.log") -destinationPath "$loglocation\IISLogs"
} catch {
    Write-Output $_.Exception.Message
}

# Copy EVTX Logs
Write-Output "[+] Copying EVTX Logs..."
try {
    Copy-Item -Path "C:\Windows\System32\winevt\Logs\*.evtx" -Destination "$loglocation\EVTX" -Verbose -Force
} catch {
    Write-Output $_.Exception.Message
}

# Stop transcript
Stop-Transcript

# Create Archive
Write-Output "[+] Creating Archive..."
try {
    $zipFileName = "$loglocation.zip"
    Compress-Archive -Path $loglocation -DestinationPath $zipFileName -CompressionLevel Optimal
} catch {
    Write-Output $_.Exception.Message
}

# Remove Directory
Write-Output "[+] Removing Output Directory..."
Remove-Item $loglocation -Recurse
