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

    $lastLine = (Get-Content $logFile).Count

    while (Test-Path $runningFile) {
        $currentContent = Get-Content $logFile
        $newLineCount = $currentContent.Count

        if ($newLineCount -gt $lastLine) {
            # Nur die neuen Zeilen ausgeben
            $currentContent[$lastLine..($newLineCount - 1)] | Write-Host
            $lastLine = $newLineCount
        }

        Start-Sleep -Milliseconds 500
    }

    # 5. Finale Prüfung (falls nach dem Löschen der Flag noch Zeilen kamen)
    $finalContent = Get-Content $logFile
    if ($finalContent.Count -gt $lastLine) {
        $finalContent[$lastLine..($finalContent.Count - 1)] | Write-Host
    }

    Start-Sleep -Milliseconds 5000
} elseif ($doit) {
    upgrade
} else {
    elevate
}

