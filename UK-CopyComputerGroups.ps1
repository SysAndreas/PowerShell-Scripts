<#
.SYNOPSIS

  Used to copy usergroups from one computer to another, and move it within the AD.

.DESCRIPTION

  Copies "memberof" from one computer to another specified computer within the same -server parameter.
  Prompts user within each step, to carefully make sure they have chosen the correct computers.

.INPUTS

  -FromComputer ComputerName
  Copies attributes from provided computer

  -ToComputer ComputerName
  Copies attributes from -fromcomputer to computer

  -Server ServerName
  AD-server

.OUTPUTS

  None

.NOTES

  Version:        1.0
  Author:         Andreas Makslahti (github.com/sysandreas)
  Creation Date:  2019-03-04

  License: CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/)
  
  My second PowerShell-script. I'd be happy to take inputs

.EXAMPLE
  
  .\UK-CopyComputerGroups.ps1 -FromComputer A023929

.EXAMPLE

  .\UK-CopyComputerGroups.ps1 -FromCompuer A023929 -ToComputer A012345

.EXAMPLE

  .\UK-CopyComputerGroups.ps1 -FromCompuer A023929 -ToComputer A012345 -Server student.local

#>


Param(
    [Parameter(Mandatory=$false)]
    [String]$FromComputer,
    [Parameter(Mandatory=$false)]
    [String]$ToComputer,
    [Parameter(Mandatory=$false)]
    [String]$Server
)

Import-Module ActiveDirectory

$tenant1    =   'student.local'
$tenant2    =   'admin.local'

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
            $Server = "$tenant1"
        } '2' {
            $Server = "$tenant2"
        }
    }
}


<#
    If a user enters a computer-name that does not exist in AD, then null the value of the variable and the user will be prompted to enter it manually.
#>

if($FromComputer) {
    try {
        Get-ADComputer $FromComputer -Server $Server | Out-Null
        Write-Output "`nComputer $FromComputer exists in the AD"
    }
    Catch {
        Write-Output "`nComputer $FromComputer does not exist in the AD.`nPlease enter the computer name again....`n"
        $FromComputer = $NULL
    }
}

if($ToComputer) {
    try {
        Get-ADComputer $ToComputer -Server $Server | Out-Null
        Write-Output "`nComputer $ToComputer exists in the AD`n`n"
    }
    Catch {
        Write-Output "`nComputer $ToComputer does not exist in the AD.`nPlease enter the computer name again...`n"
        $ToComputer = $NULL
    }
}

<#
    If no parameters are given, or parameters are wrong, then user will have to manually enter again. If wrong again, the script will exit.
#>


if(!$FromComputer)  {

    $FromComputer = Read-Host "Copy from computer"

    try {
        Get-ADComputer $FromComputer -Server $Server | Out-Null
    }
    Catch {
        Write-Output "`nERROR: $FromComputer does not exist in $server ...`n"
        exit
    }

} 

if (!$ToComputer) {

    $ToComputer = Read-Host "Copy to computer"

    try 
    {
        Get-ADComputer $ToComputer -Server $Server
    }
    Catch 
    {
        Write-Output "`nERROR: $ToComputer does not exist in $server ...`n"
        exit
    }

}

<#
    Creating variables for each property we want to extract
#>

$FromComputerMemberOf           = Get-ADComputer -server $Server $FromComputer -Properties memberof | Select-Object -expandproperty memberof 
$FromComputerDN                 = Get-ADComputer -server $Server  $FromComputer -Properties DistinguishedName | Select-Object -ExpandProperty DistinguishedName

$ToComputerMemberOfOld          = Get-ADComputer -server $server $ToComputer -Properties memberof | Select-Object -expandproperty memberof
$ToComputerDN                   = Get-ADComputer -server $Server $ToComputer -properties DistinguishedName | Select-Object -ExpandProperty DistinguishedName

# For easy readability we use "Out-String" on the groups.

$FromComputerMemberOfString     = Get-ADComputer -server $Server $FromComputer -Properties memberof | Select-Object -expandproperty memberof  | Out-String
$ToComputerMemberOfOldString    = Get-ADComputer -server $server $ToComputer -Properties memberof | Select-Object -expandproperty memberof | Out-String

<#
    Print out information so user has chosen the right computers.
#>

$information = @"
###################################################################################################
    
Copy attributes from: $FromComputer
    
Groups to copy: 

$FromComputerMemberOfString

###################################################################################################

To destination computer: $ToComputer
        
Groups that will be removed from $ToComputer : 

$ToComputerMemberOfOldString

###################################################################################################
"@

Write-Output $information

# Prompt user to make sure they wanna move the groups

$areyousure = Read-Host "`nAre you sure about these changes? (y/n)"

switch($areyousure) {
    'y' {
        Write-Output "Initializing...`n`n"
    }
    'n' {
        exit
    } default { exit }
}

<#
    Removal process of old groups
#>

foreach ($item in $ToComputerMemberOfOld) 
{
    try
    {
        # Remove computer groups from ToComputer
        Get-ADGroup "$item" -Server $Server | Remove-ADGroupMember -Members "$ToComputerDN" -Confirm:$false -ErrorAction stop
    }
    catch
    {
        Write-Host $ToComputer $item "- was unable to remove group"
    }
}

<#
    Adding groups to $ToComputer
#>

foreach ($item in $FromComputerMemberOf)
{

    try
        {
            # Adding computer groups from $FromComputerMemberOf to $ToComputer
            Get-ADGroup "$item" -Server $Server | Add-ADGroupMember -Members "$ToComputerDN" -confirm:$false -ErrorAction stop
        }
        catch
        {
            Write-Host $ToComputer $item "- was unable to add group"
        }
}

Write-Output "`n########################################## Groups Moved ###########################################`n"



<#
    Lets try to move $ToComputer to the same OU as $FromComputer
#>

# Removing "CN=ComputerName" from DistinguishedName and placing it in a new variable

$FromComputerMove = $FromComputerDN -creplace '^[^\,]*,',''

# Prompt user to make sure if they wanna move the computer

$wannamove = Read-Host "Do you want to move $ToComputer to $FromComputerMove ? (y/n)"

switch($wannamove) {
    'y' {
        Write-Output "Trying to move $ToComputer to $FromComputerMove ..."
    } 'n' {
        Write-Output "`nExiting...`n"
        exit
    } default { exit }
}

try {
        # Moving computer.
        Get-ADComputer $ToComputer | Move-ADObject -Server $Server -TargetPath "$FromComputerMove"
        Write-Output "$ToComputer has been moved to $FromComputerMove"
    } 
    catch 
    {
        # If we are unable to move the computer.
        Write-Output "Cannot move $ToComputer to $FromComputerMove"
        break
    }
