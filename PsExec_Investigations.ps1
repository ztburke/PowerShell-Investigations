# Get the date 3 days ago
$date = (Get-Date).AddDays(-3)

# Define the event IDs related to PsExec events
$eventIDs = '7045', '4697', '5145'

# Loop through each event ID
foreach ($id in $eventIDs) {
    Write-Host "`nInvestigating Security log with ID $id`n"
    try {
        # Query the event log
        $events = Get-WinEvent -FilterHashtable @{ LogName='Security'; Id=$id; StartTime=$date } -ErrorAction SilentlyContinue
        # If events are found, display them
        if ($events) {
            $events | Format-List TimeCreated, Message
        } else {
            Write-Host "No events found for ID $id in the past 3 days."
        }
    } catch {
        Write-Host "Error: Could not retrieve events with ID $id. Please ensure the Security log exists and try again."
    }
}

# Check the registry for PSEXESVC
Write-Host "`nChecking the registry for PSEXESVC`n"
try {
    $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\PSEXESVC"
    if (Test-Path $registryPath) {
        Get-ItemProperty -Path $registryPath
    } else {
        Write-Host "PSEXESVC not found in the registry."
    }
} catch {
    Write-Host "Error: Could not check the registry for PSEXESVC. Please ensure you have the necessary permissions and try again."
}

# Check the Prefetch folder for PSEXESVC
Write-Host "`nChecking Prefetch for PSEXESVC`n"
try {
    $prefetchFiles = Get-ChildItem C:\Windows\Prefetch\PSEXESVC*.pf -Force | Where-Object { $_.LastWriteTime -gt $date }
    if ($prefetchFiles) {
        $prefetchFiles
    } else {
        Write-Host "No prefetch files found for PSEXESVC in the past 3 days."
    }
} catch {
    Write-Host "Error: Could not retrieve prefetch files for PSEXESVC. Please ensure the files exist and try again."
}
