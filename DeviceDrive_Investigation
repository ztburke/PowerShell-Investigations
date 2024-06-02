Get-Volume -DriveLetter D | { Get-DiskImage -DevicePath $($_.Path -replace "\\$")}
Get-Disk
Get-DiskImage -DevicePath \\.\CDROM0
Get-DiskImage -DevicePath \\.\PhysicalDrive1 | get-volume
Dismount-DiskImage -ImagePath '<Path to .iso>'
Get-WmiObject -Class Win32_logicaldisk
get-wmiobject win32_diskdrive | Where {$_.InterfaceType -eq 'USB'}
Get-Disk –number 1 | select *
get-disk -number 1 | select DiskNumber,FriendlyName,Location,Manufacturer,Path,Number,CimClass,IsBoot 

#Look at "Event Log Microsoft-Windows-VHDMP/Operational" : Event ID 1

#Query all SIDs with mapped drives:
$users = (gwmi Win32_UserProfile | ? { $_.SID -notmatch 'S-1-5-(18|19|20).*' });
$sids = $users.sid;
for ($counter=0; $counter -lt $users.length; $counter++){
    $sid = $users[$counter].sid;
    $networkdrives=Get-ChildItem "Registry::HKEY_USERS\$sid\Network\*" -ea silentlycontinue
    if ($networkdrives) {
    echo '======================================================================================';
    echo "SID = $sid";
    echo '======================================================================================';
    foreach ($drive in $networkdrives) {
        $drivepath = $drive.Name
        $driveletter = $drive | select -exp PSChildName
        $remotepath = get-itemproperty -path "Registry::$drivepath" -Name "RemotePath" | select -exp RemotePath
        echo "Drive: $driveletter";
        echo "Path: $remotepath";
    }
    } else {
        echo '======================================================================================';
        echo "No network keys for SID = $sid";
        echo '======================================================================================';
    }
}
