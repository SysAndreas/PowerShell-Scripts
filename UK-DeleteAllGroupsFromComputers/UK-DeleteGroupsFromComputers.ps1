<#
.SYNOPSIS

  Bulk-delete computers from given text-file.

.DESCRIPTION

  Deletes all "memberof" from computer in a text-file (new-line). If a computer is not valid, the computer is not added to the final list.
  If it's unable to delete the groups from a specific computer, it will give you an error message.

.INPUTS

  -Server "server.local"
  Enter your Active Directory Domain Service name (eg. student.local)

.OUTPUTS

  None

.NOTES

  Version:        1.0
  Author:         Andreas Makslahti
  Github:         http://github.com/SysAndreas

  Creation Date:  2019-03-05

  License: CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/)

  
.EXAMPLE
  
  .\UK-DeleteAllGroupsFromComputer.ps1

.EXAMPLE

  .\UK-DeleteAllGroupsFromComputer.ps1 -Server student.local

#>

Param(
[Parameter(Mandatory=$FALSE)]
[String]$server
)

Import-Module ActiveDirectory

<#
  Decide which ADDS (server) where the computers are specified at.
#>

$tenant1 = "admin.local"
$tenant2 = "student.local"

<#
  If the input from the parameter (eg. .\UK-DeleteAllGroupsFromComputer.ps1 -server blablah.local)
  We prompt the user to chose the correct one.

  If the user enters a correct $server that matches $tenant1 or $tenant2 this won't be necessary.
#>


# IF START
if( ($Server -ne $tenant1) -and ($Server -ne $tenant2) ) {
# Optional Clear-Host

Clear-Host
Write-Output "
=======================================================================================

Specify the Active Directory Domain Services:

    [1] $tenant1 

    [2] $tenant2

=======================================================================================
"

<#
    Prompts user to enter 1 or 2
    default: is when user enters an invalid input, the script will cancel.
#>

  $computerServer = Read-Host "Please enter (1) or (2) from the menu: "

    switch($computerServer) 
    {
          '1' {
            $Server = $tenant1
        } '2' {
            $Server = $tenant2
        } default {
            Exit 
        }
    }

}
# IF END


<#
  Paths to where the computers are.
  ".\" selects the same folder as where this script is placed.
#>

$computerlist   = Get-Content -path ".\computers.txt"

# Create a hash table for invalid computers, so we can show them to the user at the end.

$invalidcomputers = @{}

<#
  Loop through the list, Computers that are valid are added to $computerlist (in the foreach-loop)
  Invalid computers that are not found by Get-ADComputer are sent to $invalidcomputers with the error message (to the hash-tables)
#>

$computerlist = foreach($y in $computerlist) {

    try {
  
      Get-ADComputer -identity $y -Server $Server -Properties MemberOf
  
    } catch {
      
        $invalidcomputers.Add($y,$Error[0].exception.message)
  
    }
  
}

# First loop through all computers

foreach($computer in $computerlist) {

    # Then loop through all groups in $computer.memberof and remove them

    foreach ($group in $computer.memberof) {
        
        try {

        Remove-ADGroupMember -Identity $group -Members $computer -Server $Server

        } catch {

            Write-Host "Cannot delete $group from $computer" -Foregroundcolor Red

        }

    }
}

Write-Output "`nInvalid computers: "
$invalidcomputers