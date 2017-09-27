<#
.SYNOPSIS 
    A POSH script to Start an Arma3 Server after checking for updates.

.DESCRIPTION
    Open the script and fill in the required variables:
    $SteamCmdDir    - Location of SteamCMD
    $AppInstallDir  - Location to install the Arma 3 Server to
    $UserName       - Username of the account that will be logging in to Steam using SteamCMD
    $Password       - The accounts password
    $ServerCFG      - The name of the config file for the server. Must be in the $AppInstallDir
    $Mods           - The list of mods to add, if any.

.NOTES
    AUTHOR: Caius Ajiz
    LASTEDIT: 27/09/2017
#> 

##### Variables #####
#Directory location of SteamCMD. E.G: C:\steamcmd\steamcmd.exe would be 'C:\steamcmd\'
$SteamCmdDir = 
#Install directory of the application. Often a subdirecrtory of Steam CMD. In this case 'C:\steamcmd\arma3\'
$AppInstallDir = 
#Login Details of the Server (If required) #Needs to get credman integrated into this, passwords in plain text are mental.
$UserName =
$Password =
#Server .CFG file
$ServerCFG = 

#If i don't null the above vars out they will pick up the next declared var. 
$null

##### Modlist #####
<#
Mods should be their ID, see below example. Seperate with a comma ,
So CBA_A3 http://steamcommunity.com/sharedfiles/filedetails/?id=450814997&searchtext=cba would be '450814997' 
Below variable contains CBA_A3,ACE,ASR AI3,ACRE2 & ShackTac User Interface in that order
#>
$Mods = '450814997',
#'463939057',
'642457233',
#'751965892',
'498740884'

##### /ModList #####
##### /Variables #####

##### Should not need to alter below this line #####
#Warning, the account you use for this needs to have Arma3 bought, or mods will fail with "ERROR! Download item [Number] failed (Failure)"
#App ID is 233780 for Arma3 Server
$AppID = '233780'
$SteamCMDDownloadURL = 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip'
$Arma3Id = '107410'
$WorkShopPath = $SteamCmdDir + 'steamapps\workshop\content\107410\'
$loginString = if($UserName.Count -lt 1){
    "anonymous"
}else{ "$UserName" + " " + "$Password" }

##### Main Script #####
#Check folders exists.
$SteamCMDLocationCheck = Test-Path -Path $SteamCmdDir
if($SteamCMDLocationCheck -eq $false){
    New-Item -ItemType Directory -Path $SteamCmdDir
}else{}

$SteamCMDAppinstallLocationCheck = Test-Path -Path $AppInstallDir
if($SteamCMDAppinstallLocationCheck -eq $false){
    New-Item -ItemType Directory -Path $AppInstallDir
}else{}

#Check SteamCMD exists.
Set-Location -Path $SteamCmdDir
$SteamCMDCheck = Test-Path -Path ".\Steamcmd.exe"
If($SteamCMDCheck -eq $false){
    Start-BitsTransfer -Source $SteamCMDDownloadURL -Destination $SteamCmdDir
    Expand-Archive -Path ".\steamcmd.zip" -DestinationPath ".\"
    .\steamcmd.exe +login $loginString +quit
}else{}

#Re-check and re-update this below var to make sure it runs properly
$SteamCMDCheck = Test-Path -Path ".\Steamcmd.exe"
#Updates Arma3 server and validates files
If($SteamCMDCheck -eq "True"){ 
        .\SteamCMD.exe +login $loginString +force_install_dir $AppInstallDir +app_update $Arma3Id validate +quit                
    }else{
        throw "SteamCMD doesn't exist in $SteamCmdDir, exiting"
         }

#Clear the below variable to prevent string creation issues for loading arma3server
$ModArrayToLoad = $null

#Installs mods to C:\steamcmd\steamapps\workshop\content\107410. can't be changed. Then makes a link in the correct area so it can be called later.
Foreach ($Mod in $Mods){
    #Mod DL from workshop 
    .\SteamCMD.exe +login $loginString +workshop_download_item $Arma3Id $Mod validate +quit
    #copy folders as creating shortcuts doesn't work
    $source = $WorkShopPath + "$Mod"
    $destination = $AppInstallDir + "$Mod"
    $destinationKeyFolder = $AppInstallDir + "keys"
    #Copy whole Folder to the install Dir, which is required to load. Arma expects the folders to be in one area.
    Copy-Item -Path $source -Destination $destination -Recurse -Force
    #Copy the bikeys to the Servers keys folder because nothing's ever easy.
    Get-ChildItem -Include "*bikey" -Path $source -Recurse | Copy-Item -Destination $destinationKeyFolder -Force
    #Creating string to pass to arma3 when starting.
    $ModArrayToLoad += "$mod" + ";"
    #Destroy the original location for space reasons- NOT currently in use due to a file retreival issue on next run.
    #Remove-Item -Path $source -Include * -Recurse -Force
}

#removing the final ; from the modlist to allow ARMA to load mods properly.
$mods = $ModArrayToLoad.Substring(0,$ModArrayToLoad.Length-1)

#Launch the server with the necessary options
Set-Location $AppInstallDir
.\arma3server_x64.exe "-config=$ServerCFG" "-mod=$Mods"