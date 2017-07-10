<#
.SYNOPSIS 
    A POSH script to Start an Arma3 Server after checking for updates.

.DESCRIPTION
    Open the script and fill in the required variables.

.NOTES
    AUTHOR: Caius Ajiz
    LASTEDIT: 25/06/2017
#> 

##### Variables #####
#App ID is 233780 for Arma3 Server
$AppID = '233780'
#Directory location of SteamCMD. E.G: C:\steamcmd\steamcmd.exe would be 'C:\steamcmd\'
$SteamCmdDir = 
#Install directory of the application. Often a subdirecrtory of Steam CMD. In this case 'C:\steamcmd\arma3\'
$AppInstallDir = 
#Login Details of the Server (If required) #Needs to get credman integrated into this, passwords in plain text are mental.
$UserName = 
$Password = 
#Server .CFG file<#
.SYNOPSIS 
    A POSH script to Start an Arma3 Server after checking for updates.

.DESCRIPTION
    Open the script and fill in the required variables.

.NOTES
    AUTHOR: Caius Ajiz
    LASTEDIT: 25/06/2017
#> 

##### Variables #####
#App ID is 233780 for Arma3 Server
$AppID = '233780'
#Directory location of SteamCMD. E.G: C:\steamcmd\steamcmd.exe would be 'C:\steamcmd\'
$SteamCmdDir = 
#Install directory of the application. Often a subdirecrtory of Steam CMD. In this case 'C:\steamcmd\arma3\'
$AppInstallDir = 
#Login Details of the Server (If required) #Needs to get credman integrated into this, passwords in plain text are mental.
$UserName = 
$Password = 
#Server .CFG file
$ServerCFG = 
##### /Variables #####



##### Modlist #####
<#Mods should be their ID, see below example. seperate with semicolon ;
#CBA_A3 http://steamcommunity.com/sharedfiles/filedetails/?id=450814997&searchtext=cba would be '450814997' #>
$Mods = 

##### /ModList #####


##### Should not need to alter below this line #####
#Warning, the account you use for this needs to have Arma3 bought, or mods will fail with "ERROR! Download item [Number] failed (Failure)"
$Arma3Id = '107410'
$WorkShopPath = $SteamCmdDir + 'steamapps\workshop\content\107410\'

##### Main Script #####
#Check SteamCMD exists.
Set-Location -Path $SteamCmdDir
$SteamCMDCheck = Test-Path -Path ".\Steamcmd.exe"

#Updates Arma3 server and validates files
If($SteamCMDCheck -eq "True"){ 
        .\SteamCMD.exe +login $UserName $Password +force_install_dir $AppInstallDir +app_update $AppID validate +quit                
    }else{
        throw "SteamCMD doesn't exist in $SteamCmdDir, exiting"
         }
#Clearing the array, mainly for when I'm testing and the string becomes 40 miles long
$ModArrayToLoad = $null
#Installs mods to C:\steamcmd\steamapps\workshop\content\107410. can't be changed. Then makes a link in the correct area so it can be called later.

Foreach ($Mod in $Mods){
    #Mod DL from workshop 
    .\SteamCMD.exe +login $UserName $Password +workshop_download_item $Arma3Id $Mod validate +quit

    #copy folders as creating shortcuts doesn't work
    $source = $WorkShopPath + "$Mod"
    $destination = $AppInstallDir + "$Mod"
    $destinationKeyFolder = $AppInstallDir + "keys"
    #Copy whole Folder to the install Dir, which is required to load. Arma expects the folders to be in one area.
    Copy-Item -Path $source -Destination $destination -Recurse -Force
    #Copy the bikeys to the Servers keys folder because nothing's ever easy.
    Get-ChildItem -Include "*bikey" -Path $source -Recurse | Copy-Item -Destination $destinationKeyFolder -Force
    
    $ModArrayToLoad += "$mod" + ";"

    #Destroy the original location for space reasons- NOT currently in use due to a file retreival issue on next run.
    #Remove-Item -Path $source -Include * -Recurse -Force
}

#removing the final ; from the modlist to allow ARMA to load mods properly.
$mods = $ModArrayToLoad.Substring(0,$ModArrayToLoad.Length-1)

#Launch the server with the necessary options
Set-Location $AppInstallDir

.\arma3server_x64.exe "-config=$ServerCFG" "-mod=$ModArrayToLoad"
$ServerCFG = 
##### /Variables #####



##### Modlist #####
<#Mods should be their ID, see below example. seperate with semicolon ;
#CBA_A3 http://steamcommunity.com/sharedfiles/filedetails/?id=450814997&searchtext=cba would be '450814997' #>
$Mods = '450814997'
##### /ModList #####


##### Should not need to alter below this line #####
#Warning, the account you use for this needs to have Arma3 bought, or mods will fail with "ERROR! Download item [Number] failed (Failure)"
$Arma3Id = '107410'
$WorkShopPath = $SteamCmdDir + 'steamapps\workshop\content\107410\'

##### Main Script #####
#Check SteamCMD exists.
Set-Location -Path $SteamCmdDir
$SteamCMDCheck = Test-Path -Path ".\Steamcmd.exe"

#Updates Arma3 server and validates files
If($SteamCMDCheck -eq "True"){ 
        .\SteamCMD.exe +login $UserName $Password +force_install_dir $AppInstallDir +app_update $AppID validate +quit                
    }else{
        throw "SteamCMD doesn't exist in $SteamCmdDir, exiting"
         }
#Installs mods to C:\steamcmd\steamapps\workshop\content\107410. can't be changed. Then makes a link in the correct area so it can be called later.
Foreach ($Mod in $Mods){
    #Mod DL from workshop
    .\SteamCMD.exe +login $UserName $Password +workshop_download_item $Arma3Id $Mod validate +quit

    #copy folders as creating shortcuts doesn't work
    $source = $WorkShopPath + "$Mod"
    $destination = $AppInstallDir + "$Mod"
    $destinationKeyFolder = $AppInstallDir + "keys"
    #Copy whole Folder to the install Dir, which is required to load. Arma expects the folders to be in one area.
    Copy-Item -Path $source -Destination $destination -Recurse -Force
    #Copy the bikeys to the Servers keys folder because nothing's ever easy.
    Get-ChildItem -Include "*bikey" -Path $source -Recurse | Copy-Item -Destination $destinationKeyFolder -Force

    #Destroy the original location for space reasons- NOT currently in use due to a file retreival issue on next run.
    #Remove-Item -Path $source -Include * -Recurse -Force
}


#Launch the server with the necessary options
Set-Location $AppInstallDir

.\arma3server_x64.exe "-config=$ServerCFG" "-mod=$Mods"