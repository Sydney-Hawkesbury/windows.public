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

function upgrade() {
    if ($asTask) {
        msg * "Software Update mit Chocolately gestartet"
    }

    if ($asTask) {
        Write-Output "$(Get-Date -Format $dateFormat) Upgrading all packages" > $logFile
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
	}
}

if ($runTask) {
    schtasks /run /tn "Choco Update"
    Get-Content -Path $logFile -Wait -Tail 10
} else if ($doit) {
    upgrade
} else {
    elevate
}

