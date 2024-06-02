#Check a user's downloads folder for the past 2 days
gci 'C:\Users\username\Downloads' | ? {$_.LastWriteTime -gt (Get-Date).AddDays(-2)} | sort lastwritetime

#Other locations to look for files, filtering on the past 2 days
pwsh gci  'FolderPath' | ? {$_.LastWriteTime -gt (Get-Date).AddDays(-2)} | sort lastwritetime   
pwsh gci  'C:\$Recycle.Bin' | ? {$_.LastWriteTime -gt (Get-Date).AddDays(-2)} | sort lastwritetime

#Grab ADS stream from a file
Get-Item 'PathToFileextension' -Stream zone* | cat
Get-Content 'PathToFileextension' -Stream Zone.Identifier

#Strings equivalent on a file (useful to check I- files in Recycle Bin to verify R- files
Get-Content 'filename' -ReadCount 0 | Out-String | format-hex

#Look for shortcut/lnk files
gci 'C:\Users\username\AppData\Roaming\Microsoft\Windows\Recent\' | ? {$_.LastWriteTime -gt (Get-Date).AddDays(-2)} | sort lastwritetime
gci 'C:\Users\username\AppData\Roaming\Microsoft\Office\Recent\' | ? {$_.LastWriteTime -gt (Get-Date).AddDays(-2)} | sort lastwritetime
gci 'C:\Users\*\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\'
$sh = New-Object -COM WScript.Shell ; $targetPath = $sh.CreateShortcut('pathtoshortcutlnk'); $targetPath

#Recursively search for files
Get-ChildItem -path C:\Users -filter *'filterword'* -r -Force -EA 0 | select -exp fullname

#Search through a directory and get all the file hashes
$dirPath = "C:\path\to\directory"
Get-ChildItem -Path $dirPath -Recurse | ForEach-Object {
if (-not $_.PSIsContainer) {
$hash = Get-FileHash $_.FullName
   Write-Output "File: $($_.FullName), Hash: $($hash.Hash)"
   }
}

# Search LNK files for a specific string
$ErrorActionPreference = 'SilentlyContinue'
Get-ChildItem -Path 'PATH_TO_FOLDER' -Recurse -Force | ForEach-Object {
    $sh = New-Object -COM WScript.Shell;
    $targetPath = $sh.CreateShortcut($_.FullName);
    $targetPathWithArguments = $targetPath.TargetPath + " " + $targetPath.Arguments
    if($targetPathWithArguments -match 'LNK_ARGUMENTS'){
        echo "Name of .lnk: " $targetPath.FullName
        echo "Target Path: " $targetPath.TargetPath
        echo $targetPath.Arguments
        echo ''
    }
}

#PowerShell Execution
ls C:\Users\*\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\*
