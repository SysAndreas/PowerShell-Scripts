<#
.SYNOPSIS

  Displays latest Boot Time from Win32_OperatingSystem using CIM.

.DESCRIPTION

  Displays latest Boot Time from Win32_OperatingSystem using CIM on computer in AD.

.INPUTS

  -Computer
  Enter computer-name in AD (Property: name)

  -Server ServerName
  Enter your Active Directory Domain Service name (eg. student.local)


.OUTPUTS

  None

.NOTES

  Version:        1.0
  Author:         Andreas Makslahti (github.com/sysandreas)
  Github:         http://github.com/SysAndreas
  Creation Date:  2019-03-04

  License: CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/)

.EXAMPLE

  .\UK-GetComputerBootTime.ps1 -Computer Workstation123 -Server admin.local

#> 

Param(
    [Parameter(Mandatory=$TRUE)]
    [String]$computer,
    [Parameter()][String]$server
)

$tenant1    =   "student.local"
$tenant2    =   "admin.local"

if( ($server -ne $tenant1) -and ($server -ne $tenant2) ) {

    Write-Output "
==============================================================================================

Specify the Active Directory Domain Services:

    [1] $tenant1 

    [2] $tenant2

==============================================================================================
"

# Prompts user to chose which AD-server they wanna use.

$xServer = Read-Host "Please enter (1) or (2) from the menu: "

    switch($xServer) 
    {
          '1' {
            $server = $tenant1
        } '2' {
            $server = $tenant2
        } default { 
          exit 
        }
    }
}

<# 
  Append $computer and $server with eachother

    Example:

    $computer = "a023929"
    $server = "student.local"

  Then $adComputer = "a023929.student.local"

  Only necessary where you have computers on a different AD DS than the server you are running the scripts from.

 #>

$adComputer = "$computer.$server"

# Command to run

$Command = {
    Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object LastBootUpTime
}

# Checking that $adComputer is a valid computer.

try {

    Get-ADComputer $computer -Server $server | Out-Null
    Write-Output "`n$computer exists, trying to connect..."

    # Testing connection to computer before executing script.
    if((Test-Connection -ComputerName $adComputer -BufferSize 16 -Count 1 -Quiet)) {
            Invoke-Command -ComputerName $adComputer -ScriptBlock $Command -ErrorAction SilentlyContinue | Select-Object * -exclude RunspaceID | Format-List 
    } else {
        Write-Output "Computer is not responding... terminating"
    }

} catch {

    Write-Output "$computer does not exist in $server"
    exit

}