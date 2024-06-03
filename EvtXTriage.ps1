# Location to copy log data
$loglocation = "C:\TriageData-$env:COMPUTERNAME" 

# Log all output from this script
Start-Transcript -Path $loglocation\Log_Copy.log

# Copy EVTX Logs #
$evtxFiles = @(
    "C:\Windows\System32\winevt\Logs\Security.evtx",
    "C:\Windows\System32\winevt\Logs\System.evtx",
    "C:\Windows\System32\winevt\Logs\Application.evtx",
    "C:\Windows\System32\winevt\Logs\Microsoft-Windows-RemoteDesktopServices-RdpCoreTS%4Operational.evtx",
    "C:\Windows\System32\winevt\Logs\Microsoft-Windows-TerminalServices-LocalSessionManager%4Operational.evtx",
    "C:\Windows\System32\winevt\Logs\Microsoft-Windows-TerminalServices-Gateway%4Operational.evtx",
    "C:\Windows\System32\winevt\Logs\Microsoft-Windows-TaskScheduler%4Maintenance.evtx",
    "C:\Windows\System32\winevt\Logs\Microsoft-Windows-WMI-Activity%4Operational.evtx",
    "C:\Windows\System32\winevt\Logs\Microsoft-Windows-WinRM%4Operational.evtx",
    "C:\Windows\System32\winevt\Logs\Microsoft-Windows-PowerShell%4Operational.evtx",
    "C:\Windows\System32\winevt\Logs\Windows PowerShell.evtx"
)

Write-Output "[+] Copying EVTX Logs..."
try {
    foreach ($file in $evtxFiles)
    {
        If (Test-Path -Path $file) {
        Copy-Item -Path $file -Destination "$loglocation\" -Verbose
        } else {
            Write-Host "File not found: $file"
        }
    }
} catch {Write-Output $_.Exception.Message}

Stop-Transcript

# Create Archive
Write-Output "[+] Creating ZIP..."
$zipFileName = "C:\TriageData-$env:COMPUTERNAME"
try {
    # Compression level
    $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory("$loglocation","$zipFileName.zip",$compressionLevel,$false)
} catch {Write-Output $_.Exception.Message}

# Remove Directory
Write-Output "[+] Removing Output Directory..."
Remove-Item $loglocation -Recurse
```
