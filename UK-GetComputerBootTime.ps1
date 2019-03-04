<#
.SYNOPSIS

  Displays latest Boot Time from Win32_OperatingSystem using CIM.

.DESCRIPTION

  Displays latest Boot Time from Win32_OperatingSystem using CIM on computer in AD.

.INPUTS

  -Computer ComputerName (without)

  -Server ServerName

  AD-server

.OUTPUTS

  None

.NOTES

  Version:        1.0
  Author:         Andreas Makslahti (github.com/sysandreas)
  Creation Date:  2019-03-04

  License: CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/)

.EXAMPLE

  .\UK-GetComputerBootTime.ps1 -Computer A023929 -Server adm.local

#> 

Param(
    [Parameter(Mandatory=$TRUE)]
    [String]$Computer,
    [Parameter()][String]$Server
)

$tenant1    =   "student.local"
$tenant2    =   "admin.local"

if( ($Server -ne $tenant1) -and ($Server -ne $tenant2) ) {

    Write-Output "
Please chose between:

`t1) $tenant1

`t2) $tenant2 `n
"

# Prompts user to chose which AD-server they wanna use.

$ServerChoise = Read-Host "Please enter 1 or 2 from the menu"

    switch($ServerChoise) 
    {
          '1' {
            $Server = $tenant1
        } '2' {
            $Server = $tenant2
        } default { exit }
    }
}

<# 
  Append $computer and $server with eachother

    Example:

    $Computer = "a023929"
    $Server = "student.local"

  Then $adComputer = "a023929.student.local"

  Only necessary where you have computers on a different AD than the server you are running the scripts from.

 #>

$adComputer = "$computer.$Server"

# Command to run

$Command = {
    Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object LastBootUpTime
}

# Checking that $adComputer is a valid computer.

try {

    Get-ADComputer $Computer -Server $Server | Out-Null
    Write-Output "`n$Computer exists, trying to connect..."

    # Testing connection to computer before executing script.
    if((Test-Connection -ComputerName $adComputer -BufferSize 16 -Count 1 -Quiet)) {
            Invoke-Command -ComputerName $adComputer -ScriptBlock $Command -ErrorAction SilentlyContinue | Select-Object * -exclude RunspaceID | Format-List 
    } else {
        Write-Output "Computer is not responding... terminating"
    }

} catch {

    Write-Output "$Computer does not exist in $Server"
    exit

}