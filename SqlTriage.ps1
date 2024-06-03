# Start a stopwatch to measure script execution time
$sw = [Diagnostics.Stopwatch]::StartNew()

# Variables
$str_failed_login = "Login failed"
$str_success_login = "Login succeeded"

# Get current date and time
$dt = [datetime]::now
$tz = Get-TimeZone

# Display current time and time zone
Write-Output "The host's current time is: $dt"
Write-Output "Time zone: $tz"
Write-Output "`r"

# Check and list installed MSSQL instances
Write-Output "Checking installed MSSQL Instances:"
Write-Output "-----------------------------------"
$instances = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances
foreach ($instance in $instances) {
    Write-Output "[+] Found instance: $instance"
}
Write-Output "`r"

# Retrieve and display installed MSSQL instance data
Write-Output "Getting installed MSSQL Instance data:"
Write-Output "--------------------------------------"
$instanceNames = (Get-Item 'HKLM:\Software\Microsoft\Microsoft SQL Server\Instance Names\SQL').Property
foreach ($name in $instanceNames) {
    $instance = (Get-ItemProperty 'HKLM:\Software\Microsoft\Microsoft SQL Server\Instance Names\SQL').$name
    Write-Output "[+] Reviewing Instance: $instance"

    $auditLevel = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instance\MSSQLServer").AuditLevel
    Write-Output "[+] Audit Level is: $auditLevel"

    $defaultLogin = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instance\MSSQLServer").DefaultLogin
    Write-Output "[+] Default Login is: $defaultLogin"

    $currentVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instance\MSSQLServer\CurrentVersion").CurrentVersion
    Write-Output "[+] Current Version is: $currentVersion"

    $edition = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instance\Setup").Edition
    Write-Output "[+] Edition is: $edition"

    $sqlProgramPath = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instance\Setup").SqlProgramDir
    Write-Output "[+] SQL Program Directory is: $sqlProgramPath"

    $sqlBinPath = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instance\Setup").SQLBinRoot
    Write-Output "[+] SQL Binn path is: $sqlBinPath"

    $sqlDataRoot = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instance\Setup").SQLDataRoot
    Write-Output "[+] SQL Data Root path is: $sqlDataRoot"
    Write-Output "`r"
}

# Check for the presence of sqlcmd, isql, or osql utilities
Write-Output "Checking for sqlcmd, isql, or osql:"
Write-Output "----------------------------------"
$no_sql_binary = $false
$sqlbin = (Get-Command sqlcmd -ErrorAction SilentlyContinue).Path
if (-not $sqlbin) {
    $sqlbin = (Get-Command osql -ErrorAction SilentlyContinue).Path
    if (-not $sqlbin) {
        $sqlbin = (Get-Command isql -ErrorAction SilentlyContinue).Path
        if (-not $sqlbin) {
            $no_sql_binary = $true
            Write-Output "[!] Could not find any installed SQL utilities for triage."
        }
    }
}

if (-not $no_sql_binary) {
    Write-Output "[+] Found SQL binary: $sqlbin"
}
Write-Output "`r"

# Process each MSSQL instance
foreach ($name in $instanceNames) {
    $instance = (Get-ItemProperty 'HKLM:\Software\Microsoft\Microsoft SQL Server\Instance Names\SQL').$name
    $sqlDataRoot = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instance\Setup").SQLDataRoot
    $sqlBinPath = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instance\Setup").SQLBinRoot
    $sqlLogPath = Join-Path $sqlDataRoot "LOG"
    $logFile = Join-Path $sqlLogPath "ERRORLOG"

    Write-Output "Checking SQL ERRORLOG for Indicators of Compromise on $instance with Log file: $logFile"
    Write-Output "$('-' * ("Checking SQL ERRORLOG for Indicators of Compromise on $instance with Log file: $logFile".Length))"

    if (Test-Path $logFile) {
        try {
            $logItem = Get-Item $logFile
        } catch {
            Write-Output "Could not get log file!"
        }

        if ($logItem) {
            Write-Output "[+] Log file is $($logItem.Length) bytes"
            if ($logItem.Length -le 50000000) {
                Write-Output "[+] Log file is under 50MB, parsing...."
                try {
                    $logContents = Get-Content $logFile
                } catch {
                    Write-Output "Could not read SQL ERRORLOG"
                }

                if ($logContents) {
                    $successfulLogins = $logContents | Select-String $str_success_login
                    $failedLogins = $logContents | Select-String $str_failed_login
                    Write-Output "`r"
                    Write-Output "Checking for IoCs relating to brute force and successful logins:"
                    Write-Output "---------------------------------------------------------------------"
                    Write-Output "[-] Failed login count: $($failedLogins.Count)"
                    Write-Output "[-] Success login count: $($successfulLogins.Count)"

                    if ($failedLogins.Count -gt 0) {
                        $failedIPs = [regex]::Matches($failedLogins,'(?<=\[CLIENT:\s).+?(?=])').Value | Group-Object | Sort-Object Count -Descending
                        Write-Output "[+] IP addresses relating to failed logins:"
                        $failedIPs | Format-Table -HideTableHeaders | Out-String | ForEach-Object { Write-Output $_.Trim() }
                        Write-Output "`r"

                        $failedUsers = [regex]::Matches($failedLogins,'(?<=for user '').+?(?=''. )').Value | Group-Object | Sort-Object Count -Descending
                        Write-Output "[+] Targeted users:"
                        $failedUsers | Format-Table -HideTableHeaders | Out-String | ForEach-Object { Write-Output $_.Trim() }
                        Write-Output "`r"
                    }

                    if ($successfulLogins.Count -gt 0) {
                        $successIPs = [regex]::Matches($successfulLogins,'(?<=\[CLIENT:\s).+?(?=])').Value | Group-Object | Sort-Object Count -Descending
                        Write-Output "[+] IP addresses relating to successful logins:"
                        $successIPs | Format-Table -HideTableHeaders | Out-String | ForEach-Object { Write-Output $_.Trim() }
                        Write-Output "`r"

                        $successUsers = [regex]::Matches($successfulLogins,'(?<=for user '').+?(?=''. )').Value | Group-Object | Sort-Object Count -Descending
                        Write-Output "[+] Targeted users:"
                        $successUsers | Format-Table -HideTableHeaders | Out-String | ForEach-Object { Write-Output $_.Trim() }
                        Write-Output "`r"
                    }
                    Write-Output "`r"

                    Write-Output "Checking for indicators of compromise:"
                    Write-Output "---------------------------------------"
                    $sqlClrEvents = $logContents | Select-String 'Unsafe assembly|appdomain'
                    if ($sqlClrEvents) {
                        Write-Output "[+] Found events relating to SQLCLR, this requires review:"
                        $sqlClrEvents | Format-Table -HideTableHeaders | Out-String | ForEach-Object { Write-Output $_.Trim() }
                        Write-Output "`r"
                    }

                    $procEvents = $logContents | Select-String 'sp_configure|reconfigure|Configuration option|execute extended stored procedure|TRUSTWORTHY'
                    if ($procEvents) {
                        Write-Output "[+] Found events relating to SPs or XPs, this requires review:"
                        $procEvents | Format-Table -HideTableHeaders | Out-String | ForEach-Object { Write-Output $_.Trim() }
                        Write-Output "`r"
                    }

                    $clrAssemblies = [regex]::Matches($logContents, '(?<=Unsafe\sassembly\s'').+?(?=, version)').Value | Group-Object -Property { $_.ToLower() } | Select -ExpandProperty Name
                    if ($clrAssemblies) {
                        Write-Output "[+] The following assemblies were discovered in the logs:"
                        Write-Output "[+] Note: Pivot to EAM FileWritten events to obtain the hash of the assembly"
                        foreach ($assembly in $clrAssemblies) {
                            switch ($assembly) {
                                "evilclr" { Write-Output '[-] evilclr found, potentially Lemon Duck or Purple Fox' }
                                "sqlclrpayload" { Write-Output '[-] sqlclrpayload found, potentially Metasploit/Meterpreter implant' }
                                default { Write-Output "[-] $assembly" }
                            }
                        }
                        Write-Output "`r"
                    }
                }
            }
        }
    }

    if (-not $no_sql_binary) {
        # Query the database for SQLCLR assemblies
        Write-Output "Checking Database for SQLCLR Assemblies"
        Write-Output "(Note: if you get only one result 'microsoft.sqlserver.types.dll', we may not have permissions to query the DB"
        Write-Output "---------------------------------------"
        $query = @"
USE Master;
SELECT
    SCHEMA_NAME(O.schema_id) AS [Schema], O.name,
    assemblies.name AS assembly_name,
    assemblies.permission_set_desc,
    assemblies.create_date,
    assemblies.is_user_defined,
    assemblies.clr_name,
    assembly_modules.assembly_class,
    assembly_modules.assembly_method,
    assembly_modules.execute_as_principal_id,
    assembly_files.name,
    assembly_files.content,
    O.[type_desc]
FROM sys.assembly_modules assembly_modules
INNER JOIN sys.assemblies assemblies ON assemblies.assembly_id = assembly_modules.assembly_id
INNER JOIN sys.assembly_files assembly_files on assembly_files.assembly_id = assembly_modules.assembly_id
INNER JOIN sys.objects O ON O.object_id = assembly_modules.object_id
ORDER BY assemblies.name, assembly_modules.assembly_class
"@

        try {
            if ($instance -eq "MSSQLSERVER") {
                & $sqlbin -h-1 -w 6000 -E -Q $query
            } else {
                & $sqlbin -h-1 -w 6000 -S "$env:computername\$instance" -E -Q $query
            }
        } catch {
            Write-Output "Failed to execute sqlcmd.exe"
        }
        Write-Output "`r"

        # Query the database for SQL Agent jobs
        Write-Output "Checking Database for SQL Agent jobs"
        Write-Output "------------------------------------"
        Write-Output "SQL Agent jobs with schedules:"
        $query = @"
SELECT
    sysjobs.job_id,
    sysjobs.name,
    sysjobs.enabled,
    sysjobs.date_created,
    sysjobs.date_modified,
    sysjobschedules.next_run_date,
    sysjobschedules.next_run_time,
    sysjobservers.last_run_date,
    sysjobservers.last_run_time,
    sysjobservers.last_outcome_message,
    sysjobservers.last_run_outcome,
    sysjobservers.last_run_duration
FROM msdb.dbo.sysjobs sysjobs
INNER JOIN msdb.dbo.sysjobschedules sysjobschedules ON sysjobschedules.job_id = sysjobs.job_id
INNER JOIN msdb.dbo.sysjobservers sysjobservers on sysjobservers.job_id = sysjobs.job_id
"@

        try {
            if ($instance -eq "MSSQLSERVER") {
                & $sqlbin -h-1 -w 6000 -E -Q $query
            } else {
                & $sqlbin -h-1 -w 6000 -S "$env:computername\$instance" -E -Q $query
            }
        } catch {
            Write-Output "Failed to execute sqlcmd.exe"
        }
        Write-Output "`r"

        Write-Output "[+] SQL Agent jobs with job steps:"
        $query = @"
SELECT
    sysjobs.job_id,
    sysjobs.name,
    sysjobsteps.step_name,
    sysjobsteps.database_name,
    sysjobsteps.subsystem,
    sysjobsteps.command,
    sysjobsteps.last_run_date,
    sysjobsteps.last_run_time,
    sysjobsteps.last_run_duration,
    sysjobsteps.last_run_outcome
FROM msdb.dbo.sysjobs sysjobs
INNER JOIN msdb.dbo.sysjobsteps sysjobsteps ON sysjobsteps.job_id = sysjobs.job_id
"@

        try {
            if ($instance -eq "MSSQLSERVER") {
                & $sqlbin -h-1 -w 6000 -E -Q $query
            } else {
                & $sqlbin -h-1 -w 6000 -S "$env:computername\$instance" -E -Q $query
            }
        } catch {
            Write-Output "Failed to execute sqlcmd.exe"
        }
        Write-Output "`r"

        Write-Output "[+] SQL Agent jobs with history:"
        $query = @"
SELECT
    sysjobs.job_id,
    sysjobs.name,
    sysjobs.enabled,
    sysjobs.date_created,
    sysjobs.date_modified,
    sysjobhistory.step_name,
    sysjobhistory.message,
    sysjobhistory.run_date,
    sysjobhistory.run_time,
    sysjobhistory.run_status,
    sysjobhistory.run_duration
FROM msdb.dbo.sysjobs sysjobs
INNER JOIN msdb.dbo.sysjobhistory sysjobhistory on sysjobhistory.job_id = sysjobs.job_id
"@

        try {
            if ($instance -eq "MSSQLSERVER") {
                & $sqlbin -h-1 -w 6000 -E -Q $query
            } else {
                & $sqlbin -h-1 -w 6000 -S "$env:computername\$instance" -E -Q $query
            }
        } catch {
            Write-Output "Failed to execute sqlcmd.exe"
        }
    }
    Write-Output "`n`n"
}

# Stop the stopwatch and display the script execution time
$sw.Stop()
Write-Output "[+] Completed, script took $($sw.Elapsed) to finish"
