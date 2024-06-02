# Get the date 3 days ago
$date = (Get-Date).AddDays(-3)

# Define the event logs and IDs to check
$eventLogs = @{
    'Security' = '4624', '4778', '4779'
    'Microsoft-Windows-RemoteDesktopServices-RdpCoreTS/Operational' = '98', '131'
    'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational' = '21', '22', '25'
}

# Loop through each log and ID
foreach ($log in $eventLogs.Keys) {
    foreach ($id in $eventLogs[$log]) {
        Write-Host "`nInvestigating $log with ID $id`n"
        try {
            # Query the event log
            $events = Get-WinEvent -FilterHashtable @{ LogName=$log; Id=$id; StartTime=$date }
            # If events are found, display them
            if ($events) {
                # If the event ID is 4624, filter for logon type 10
                if ($id -eq '4624') {
                    $events = $events | Where-Object { $_.Properties[8].Value -eq 10 }
                }
                $events | Format-List TimeCreated, Message
            } else {
                Write-Host "No events found for ID $id in the past 3 days."
            }
        } catch {
            Write-Host "Error: Could not retrieve events with ID $id. Please ensure the $log log exists and try again."
        }
    }
}

Write-Host "`nChecking Prefetch for rdpclip.exe and tstheme.exe`n"
try {
    $rdpclipFiles = Get-ChildItem -Path C:\Windows\Prefetch\ -Filter *'rdpclip'* -Force | Where-Object { $_.LastWriteTime -gt $date }
    $tsthemeFiles = Get-ChildItem -Path C:\Windows\Prefetch\ -Filter *'tstheme'* -Force | Where-Object { $_.LastWriteTime -gt $date }

    # Check if the rdpclip files exist
    if ($rdpclipFiles) {
        $rdpclipFiles
    } else {
        Write-Host "Error: Could not find any prefetch files for rdpclip.exe. Please ensure the files exist and try again."
    }

    # Check if the tstheme files exist
    if ($tsthemeFiles) {
        $tsthemeFiles
    } else {
        Write-Host "Error: Could not find any prefetch files for tstheme.exe. Please ensure the files exist and try again."
    }
} catch {
    Write-Host "Error: Could not retrieve prefetch files for rdpclip.exe and tstheme.exe. Please ensure the files exist and try again."
}
