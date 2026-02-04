Param(
    [switch]
    [bool]$doit = $false,
    [bool]$asTask = $false
)

function elevate() {
    Write-Host "Elevate process."
    [string[]]$argList = @("Set-ExecutionPolicy","Bypass","-Scope","Process",";","& " + $MyInvocation.ScriptName, "-doit")
    Start-Process powershell.exe -Verb runAs -ArgumentList ($argList)
}

$dateFormat = "yyyy-MM-dd HH:mm:ss.fff"

function upgrade() {
    if ($asTask) {
        msg * "Software Update mit Chocolately gestartet"
        Start-Transcript -Path "D:\Chocolately.Upgrade.txt"
    }

    Write-Host "$(Get-Date -Format $dateFormat) Upgrading all packages"

    [System.Collections.Generic.List[string]]$packages = choco list --local
	$packages.RemoveAt(0)
	$packages.RemoveAt($packages.Count - 1)
    for ($i = 0; $i -lt $packages.Count; $i++) {
        $package = $packages[$i].Split(" ")[0]
        choco upgrade -y $package
    }
    if (-not $asTask) {
        Write-Host "Hit Enter to finish"
        Read-Host
	} else {
        Write-Host "$(Get-Date -Format $dateFormat) Software Update mit Chocolately beendet"
        Stop-Transcript
        msg * "Software Update mit Chocolately beendet"
	}
}

if ($doit) {
    upgrade
} else {
    elevate
}

