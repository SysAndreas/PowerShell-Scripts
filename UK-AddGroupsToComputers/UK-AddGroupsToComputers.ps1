<#
.SYNOPSIS

  Bulk add groups to computers from text-file

.DESCRIPTION

  Add groups (from text-file), to computers (from text-file) in one powerful script.

  Groups are given by "name"-property.
  Groups and computers must be in different text-files (see variables) and separated by a new line.

.INPUTS

  -Server
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

  .\UK-AddGroupsToComputers.ps1

.EXAMPLE

  .\UK-AddGroupsToComputers.ps1 -server student.local
#> 
Param(
[Parameter(Mandatory=$FALSE)]
[String]$server
)

<#
  Decide which tenants you want
#>

$tenant1 = "student.local"
$tenant2 = "admin.local"

<#
  If the input from the parameter (eg. .\UK-AddGroupsToComputers.ps1 -server blablah.local)
  We prompt the user to chose the correct one.
  If the user enters a correct $server that matches $tenant1 or $tenant2 this won't be necessary.
#>

# LOOP START
if( ($Server -ne $tenant1) -and ($Server -ne $tenant2) ) {

  Write-Output "
==============================================================================================

Specify the Active Directory Domain Services:

    [1] $tenant1 

    [2] $tenant2

==============================================================================================
"

# Prompts user to enter 1 or 2.

  $xServer = Read-Host "Please enter (1) or (2) from the menu: "

    switch($xServer) 
    {
          '1' {
            $Server = $tenant1
        } '2' {
            $Server = $tenant2
        } default {
          exit
        }
    }
}
# LOOP END

<#
  Paths to where the files and groups are.
  ".\" selects the same folder as where this script is placed.
#>

$computerlist   = Get-Content -path ".\computers.txt"
$grouplist      = Get-Content -path ".\groups.txt"

<#
  Empty variables so  that they are empty if you would re-run the script.
#>

$invalidgroups = $null
$invalidcomputers = $null

$computer = $null
$group = $null

<#
  Create hash-tables for these, as we will input errors in to them inside the loops.
#>

$invalidgroups = @{}
$invalidcomputers = @{}

<#
  Loop through the list, groups that are valid are added to $grouplist (in the foreach-loop)
  Invalid groups that are not found by Get-ADGroup are sent to $invalidgroups with the error message (to the hash-tables)
#>

$grouplist = foreach($x in $grouplist){

  try {

    Get-ADGroup -Identity $x -Server $server

  } catch {
    
    $invalidgroups.Add($x,$Error[0].exception.message)

  }

}

<#
  Loop through the list, Computers that are valid are added to $computerlist (in the foreach-loop)
  Invalid computers that are not found by Get-ADComputer are sent to $invalidcomputers with the error message (to the hash-tables)
#>

$computerlist = foreach($y in $computerlist) {

  try {

    Get-ADComputer $y -Server $server

  } catch {
    
      $invalidcomputers.Add($y,$Error[0].exception.message)

  }

}

<#
  Here we start doing stuff. For each computer in $computerlist (which is clean) we do another loop to check for each group.
  Each group is then added to each computer in the list.

  If we do not have access to add the specified groups to one or more computers, we simply say that you are unable  to. We did not parse the error message in this case (i was lazy)
#>

foreach($computer in $computerlist) {

    foreach($group in $grouplist) {

      try {
        
        Add-ADGroupMember -Identity $group -members $computer -Server $server
        Write-Host "Added group $group to $computer" -ForegroundColor Green

      } catch {

        Write-Host "Could not add $group to $computer" -ForegroundColor Red

      }

    }
}

<#
  Lists invalid computers (does not exist)
#>
Write-Output "`nInvalid computers: "
$invalidcomputers

<#
  Lists invalid groups (that were not added to any of these computers (typo?))
#>
Write-Output "`nInvalid groups: "
$invalidgroups