# Get the date 3 days ago
$date = (Get-Date).AddDays(-3)

# Define the event IDs related to network share events
$eventIDs = '5140', '5142', '5143', '5144', '4624', '4776', '4768', '4769', '5145'

# Loop through each event ID
foreach ($id in $eventIDs) {
    Write-Host "`nInvestigating Security log with ID $id`n"
    try {
        # Query the event log
        $events = Get-WinEvent -FilterHashtable @{ LogName='Security'; Id=$id; StartTime=$date } -ErrorAction SilentlyContinue
        # If events are found, display them
        if ($events) {
            # If the event ID is 4624, filter for logon type 3
            if ($id -eq '4624') {
                $events = $events | Where-Object { $_.Properties[8].Value -eq 3 }
            }
            $events | Format-List TimeCreated, Message
        } else {
            Write-Host "No events found for ID $id in the past 3 days."
        }
    } catch {
        Write-Host "Error: Could not retrieve events with ID $id. Please ensure the Security log exists and try again."
    }
}
