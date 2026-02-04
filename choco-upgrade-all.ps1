Param(
    [switch]$doit = $false,
    [switch]$asTask = $false,
    [switch]$runTask = $false
)

function elevate() {
    Write-Host "Elevate process."
    [string[]]$argList = @("Set-ExecutionPolicy","Bypass","-Scope","Process",";","& " + $MyInvocation.ScriptName, "-doit")
    Start-Process powershell.exe -Verb runAs -ArgumentList ($argList)
}

$dateFormat = "yyyy-MM-dd HH:mm:ss.fff"
$logFile = "D:\Chocolately.Upgrade.txt"
$runningFile = "D:\Chocolately.running"

function upgrade() {
    if ($asTask) {
        msg * "Software Update mit Chocolately gestartet"
    }

    if ($asTask) {
        Write-Output "$(Get-Date -Format $dateFormat) Upgrading all packages" > $logFile
        "$(Get-Date -Format $dateFormat) Task gestartet" | Out-File -Path $runningFile -Force
    } else {
        Write-Output "$(Get-Date -Format $dateFormat) Upgrading all packages"
    }

    [System.Collections.Generic.List[string]]$packages = choco list --local
	$packages.RemoveAt(0)
	$packages.RemoveAt($packages.Count - 1)
    for ($i = 0; $i -lt $packages.Count; $i++) {
        $package = $packages[$i].Split(" ")[0]
        if ($asTask) {
            choco upgrade -y $package >> $logFile
        } else {
            choco upgrade -y $package
        }
    }
    if (-not $asTask) {
        Write-Host "Hit Enter to finish"
        Read-Host
	} else {
        Write-Output "$(Get-Date -Format $dateFormat) Software Update mit Chocolately beendet" >> $logFile
        msg * "Software Update mit Chocolately beendet"
        if (Test-Path $runningFile) {
            Remove-Item $runningFile -Force
        }
    }
}

if ($runTask) {
    schtasks /run /tn "Choco Update"
    while (!(Test-Path $runningFile)) { Start-Sleep -Milliseconds 500 }

    $job = Start-Job -ScriptBlock {
        param($file)
        Get-Content $file -Wait -Tail 0
    } -ArgumentList $logFile

    while (Test-Path $flagFile) {
        # Neue Zeilen aus dem Hintergrund-Job abholen und anzeigen
        Receive-Job -Job $job
        Start-Sleep -Milliseconds 500
    }

    Receive-Job -Job $job # Ein letztes Mal Reste abholen
    Stop-Job $job
    Remove-Job $job

    Start-Sleep -Milliseconds 5000
} elseif ($doit) {
    upgrade
} else {
    elevate
}

