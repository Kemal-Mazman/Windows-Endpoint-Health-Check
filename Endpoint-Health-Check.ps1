# Check 1: Disk Space

try {
    $drives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop

    if (-not $drives) {
        throw "No fixed drives found"
    }

    foreach ($drive in $drives) {
        if ($null -eq $drive.Size -or $drive.Size -le 0 -or $null -eq $drive.FreeSpace) {
            Write-Output "$($drive.DeviceID) | UNKNOWN | Invalid disk information"
            continue
        }

        $free = [math]::Round(($drive.FreeSpace / $drive.Size) * 100, 2)

        if ($free -lt 15) {
            $status = "WARN"
        } else {
            $status = "PASS"
        }

        Write-Output "$($drive.DeviceID) | $free% free | $status"
    }
}
catch {
    Write-Output "Disk Space | UNKNOWN | $($_.Exception.Message)"
}

# Check 2: Microsoft Defender

try {
    $defender = Get-MpComputerStatus -ErrorAction Stop

    $mode = $defender.AMRunningMode
    $realtime = $defender.RealTimeProtectionEnabled
    $age = $defender.AntivirusSignatureAge

    if ($mode -eq "Passive Mode") {
        $status = "REVIEW"
    }
    elseif ($null -eq $mode -or $null -eq $realtime -or $null -eq $age) {
        $status = "UNKNOWN"
    }
    elseif (-not $realtime -or $age -gt 3) {
        $status = "WARN"
    }
    else {
        $status = "PASS"
    }

    Write-Output "Defender | Mode: $mode | Real-time: $realtime | Signature age: $age days | $status"
}
catch {
    Write-Output "Defender | UNKNOWN | $($_.Exception.Message)"
}

# Check 3: BitLocker

try {
    $drive = $env:SystemDrive
    $bitlocker = Get-BitLockerVolume -MountPoint $drive -ErrorAction Stop

    if ($null -eq $bitlocker) {
        throw "BitLocker information unavailable"
    }

    $protection = [string]$bitlocker.ProtectionStatus

    if ($protection -eq "On") {
        $status = "PASS"
    }
    elseif ($protection -eq "Off") {
        $status = "WARN"
    }
    else {
        $status = "UNKNOWN"
    }

    Write-Output "BitLocker | Drive: $drive | Protection: $protection | $status"
}
catch {
    Write-Output "BitLocker | UNKNOWN | $($_.Exception.Message)"
}
