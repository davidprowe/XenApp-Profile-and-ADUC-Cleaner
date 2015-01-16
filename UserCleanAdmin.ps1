$userslisted = Import-Csv 'C:\tools\CitrixCleaner.csv'
		
foreach ($username in $userslisted) {
$userlisted = $username.Username
Import-Module ActiveDirectory
        $Homedr = "n"
        Set-ADUser -Identity $userlisted -HomeDirectory $null -HomeDrive $null
        #Set home dir, home drive and remove roaming profile.
		Set-ADUser -Identity $userlisted -HomeDirectory \\homeshare\homesharefolder\$userlisted -HomeDrive $Homedr -ProfilePath $null
        #copy standard INI files to homeshare windows folder
		Copy-Item -Path \\networkpathto\configfiles\*.* -Destination \\homeshare\homesharefolder\$userlisted\windows
		}