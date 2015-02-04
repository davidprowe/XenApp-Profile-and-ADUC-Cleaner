 Write-Host "Adding All Snapins.  Please wait..."
if ((Get-PSSnapin "Citrix.XenApp.Commands" -EA silentlycontinue) -eq $null) {
	try { Add-PSSnapin Citrix.XenApp.Commands -ErrorAction Stop }
	catch { write-error "Error loading XenApp Powershell snapin"; Return }
}
Import-Module ActiveDirectory

# Change the below variables to suit your environment
#==============================================================================================
#Profile Servers
$ProfileServers = @("profileserver1","profileserver2","profileserver3")
#list citrix profile share root folder \\server\citrixprofiles would be root of profile shares
$ProfileRoot = "citrixprofiles"
#list all citrix profile directories
$ProfileShares = @("adminprofiles","officeprofiles","remoteprofiles","emrprofiles")
#==============================================================================================

function CleanUserAccount {

#make user type in username again
#==============================================================================================
#Logout user function
if ($name -eq $null)
{
exit
}
else
{
"Found user! Beginning to log out.  Please wait up to 30 seconds"
Get-XASession |?{$_.AccountName -match $name}|?{$_.Protocol -match "ica"}|Stop-XASession

#==============================================================================================
#Close Profile share files in use
#openfiles /disconnect /a rowelab
#user fileadmin is local admin on the profile servers
"Closing Connections to profile servers' shares"
foreach ($server in $profileServers) {
        write-host  Closing Connection to $server
		openfiles /disconnect /s $server /u $server\fileadmin /p password /a $name
}

#==============================================================================================
#Delete profiles on Profile Shares
write-host "Deleting profiles on server $server please wait"
foreach ($server in $ProfileServers) {
	Foreach ($share in $ProfileShares){
	#fix to not have root dir removed
		$prof = "\\" + $server + "\" + $ProfileRoot + "\" + $share + "\"
		$profname = "\\" + $server + "\" + $ProfileRoot + "\" + $share + "\" + $name
		if ($prof -eq $profname)
		{
		write-host $profname
		write-host do nothing
		}
		else{
		Remove-Item \\$server\$ProfileRoot\$share\$name\ -force -recurse -erroraction 'silentlycontinue'
		#write-host name
		write-host  removing \\$server\$ProfileRoot\$share\$name
		#write-host share
		#write-host  \\$server\$ProfileRoot\$share\
		}
		}
		}
		
#===============================================================================================
#remove homedrive then set it
#Clear then set homedrive. Also clears roaming profiles.
#Launch AD script as different user to fix AD account - users who are not ADUC User account admins can fix user account issues
#generate password 
<#
$secret = 'passwordhere'  
$key    = [Convert]::ToBase64String((1..32 |% { [byte](Get-Random -Minimum 0 -Maximum 255) }))  
$encryptedSecret = ConvertTo-SecureString -AsPlainText -Force -String $secret | ConvertFrom-SecureString -Key ([Convert]::FromBase64String($key))  
  
$encryptedSecret | Select-Object @{Name='Key';Expression={$key}},@{Name='EncryptedSecret';Expression={$encryptedSecret}} | fl  
#>
$username="CHOA\ADUCSelfServiceAccount"
$key = "LwQQ6hlY752IX2oXSMDRE0uFKZhH0k2I6cN/GULyQzQ="
$encryptedSecret = "76492d1116743f0423413b16050a5345MgB8AFoAcgBIAGIANgBNAEkAeQBpADIASQB0AGMAeAB0AFoARwBzAFEANQBqAFEAPQA9AHwAZQA3ADcAZABjADgAMQA0ADEAMQBhADEANQA2ADgAYQAxAGYAZAAwAGMANwBhADAAOABmADMAZABkADEAZAA3ADAAMwAxAGEAMQAwADQANQBkAGQAMwBmAGEAYwBjADYANwA3AGYAZABmADMAMgBhAGMAMQAzAGIAOQA2ADIAOQA="
$ss = ConvertTo-SecureString -Key ([Convert]::FromBase64String($key)) -String $encryptedSecret 
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $ss
#Pass Variable to CSV - allow next user to call
"Username">C:\tools\CitrixCleaner.csv
$name>>C:\tools\CitrixCleaner.csv
write-host "Fixing AD Account - Home drive and Roaming Profile"
$ADUserAdminPS1 = "C:\tools\UserCleanAdmin.ps1"
Start-Process -Credential $cred C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe $ADUserAdminPS1
        #if you dont want to correct AD issues with the current user do these lines instead.
        #Set-ADUser -Identity $name -HomeDirectory $null -HomeDrive $null
        #$Homedr = "N"
		#Set-ADUser -Identity $name -HomeDirectory \\homeshare\homesharefolder\$name -HomeDrive $Homedr -ProfilePath $null
        #Copy-Item -Path \\networkpathto\configfiles\configfiles\*.* -Destination \\homeshare\homesharefolder\windows
}

}


#==============================================================================================
#ask for AD Username of user account to fix.

while (($name -eq $null) -or ($name -eq '') -or ($choice.ToLower() -eq "no")){
if  ($again.Tolower() -eq "no")
{exit}
else{
do {$name = Read-Host 'What is the username that you are fixing?'}
while (($name -eq $null) -or ($name -eq ''))
#verify ADUC user with first and last name
try{
write-host "Are you sure you want to perform user cleanup on" (Get-ADUser -identity $name).Name": " (Get-ADUser -identity $name).UserPrincipalName "?"
$choice = Read-Host 'Yes, No, Cancel'
}
catch{
$choice = 'no'
}
if (($choice.ToLower() -eq "yes") -or ($choice.ToLower() -eq "y")){
	CleanUserAccount
	$i = 0
    do {write-host *************
	$i++}
	while ( $I -le 19)
	$name = ''
    write-host "Completed process."
    write-host "1. Logged off User"
    write-host "2. Close profile share usage"
    write-host "3. Deleted Profiles"
    write-host "4. Fixed N drive and removed Roaming Profile"
	write-host "5. Copied common .ini files to the N:\Windows folder."
    $again = read-host "Do you want to clean another account? Yes or No"
	}
    elseif ($choice.ToLower() -eq "cancel"){
    
    break
    }
    else{
    Clear-Variable name
    }
    }
}

