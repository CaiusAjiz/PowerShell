<#
.SYNOPSIS 
   Sets up a new instance of an Arma3 dedicated server. 

.PARAMETER SteamCMDinstallPath

    The location of SteamCMD. If not downloaded, SteamCMD will be downloaded to this location.

.PARAMETER Arma3ServerName

    Setup-Arma3Server will create a new folder inside of the SteamCMD structure and install the server to there, using this parameter's name.

.PARAMETER SteamUserName

    The username of the Steam account to login to SteamCMD with. 

.PARAMETER SteamPassword
    
    The password for the above account.

.PARAMETER ServerConfigFileLocation

    Full path of the server config file you wish to copy, if you wish to copy one.

.PARAMETER mods

    An array of mods to download for Arma3 Server. seperate like: 'mod','mod2','mod3'
    MUST use the Steam ID. For example to install CBA_A3, it would be 450814997. Taken from https://steamcommunity.com/sharedfiles/filedetails/?id=450814997

.EXAMPLE
    
    Install Arma3 Server into C:\SteamCMD with 3 mods (CBA_A3, ShacktacUI & ASR AI3)
    Setup-Arma3Server -SteamCMDinstallPath "C:\SteamCMD" -Arma3ServerName 'Arma3Live' -SteamUsername [Username] -SteamPassword [Password] -mods '450814997','498740884','642457233'

.NOTES
    AUTHOR: Caius Ajiz
    WEBSITE: https://github.com/CaiusAjiz/Arma3Powershell/
    
#> 

Param
(
    [Parameter(Mandatory=$true)]
    [String]$SteamCMDinstallPath,
    [Parameter(Mandatory=$true)]
    [String]$Arma3ServerName,
    [Parameter(Mandatory=$true)]
    [String]$SteamUsername,
    [Parameter(Mandatory=$true)]
    [String]$SteamPassword,
    [Parameter(Mandatory=$false)]
    [String]$ServerConfigFileLocation,
    [Parameter(Mandatory=$false)]
    [String[]]$mods
)
####Vars####
$SteamCMDDownloadURL = 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip'
$Arma3ServerID = '233780'
$Arma3ID = '107410'
$NSSMDownloadURL = 'https://nssm.cc/release/nssm-2.24.zip'
####/vars####

#1 - Checking and downloading SteamCMD if doesn't already exist.
If( (Test-Path($SteamCMDinstallPath +"\steamcmd.exe")) -eq $false ){
    #making sure folder exists, surpressing error
    Write-Output "SteamCMD.exe doesn't exist, downloading"
    New-Item -ItemType Directory -Path $SteamCMDinstallPath -ErrorAction SilentlyContinue
    #Transferring
    Start-BitsTransfer -Source $SteamCMDDownloadURL -Destination $SteamCMDinstallPath
    #Unpacking ZIP, with the laziest way to guarantee the file is unlocked ever.
    Write-Output "Please wait, Unpacking SteamCMD ZIP file to $SteamCMDinstallPath"
    Start-Sleep -Seconds 5
    Expand-Archive -Path ($SteamCMDinstallPath + "\steamcmd.zip") -DestinationPath $SteamCMDinstallPath
        }else{
    Write-Output "SteamCMD.exe already exists in $SteamCMDinstallPath, moving on to Arma3 server"
    }

#2 - Checking pre-existance then Logging into Steam CMD and downloading Arma3
#Building the needed vars
$SteamCMDLoginString = "$SteamUsername" + " " + "$SteamPassword"
$Arma3InstallLocation = $SteamCMDinstallPath + "\" + $Arma3ServerName
If( (Test-Path($Arma3InstallLocation +"\arma3server.exe")) -eq $false ){
    Write-Output "Logging into Steam and downloading Arma3 server. Please note,this will open up a seperate pop up window"
    Write-Output "WARNING - This can be a large download if not already installed."
    start-process -FilePath ($SteamCMDinstallPath + "\steamcmd.exe") -ArgumentList "+login $SteamCMDLoginString +force_install_dir $Arma3InstallLocation +app_update $Arma3ServerID validate +quit" -Wait
    }else{
    Write-Output "Arma3 Server already exists in $Arma3InstallLocation, moving on to Server Config file"
    }
#3 if the var exists, copying across the server config file, if one has been provided
if ($ServerConfigFileLocation.length -gt '1'){
    If (Test-Path $ServerConfigFileLocation){
        write-output "Copying Server Configuration file from $ServerConfigFileLocation to $Arma3InstallLocation"
        Copy-Item -Path $ServerConfigFileLocation -Destination $Arma3InstallLocation -Force
        }else{Write-Output "Server Config file couldn't be found, moving on to installing the mods"}
    }else {Write-Output "No Server config provided, moving on to installing the mods "}

#4 - Installing the mods, if there are any provided
if ($mods.length -gt 0 ){
    #building the needed vars
    $ModArrayToLoad = $null
    $WorkShopPath = $SteamCMDinstallPath + '\steamapps\workshop\content\107410'
    $modsCount = $mods.Count
    Write-Output "Installing $modsCount mods"
        Foreach ($Mod in $Mods){
        Write-Output "Installing mod $Mod"
        #Mod DL from workshop 
        start-process -FilePath ($SteamCMDinstallPath + "\steamcmd.exe") -ArgumentList "+login $SteamCMDLoginString +workshop_download_item $Arma3ID $Mod validate +quit" -Wait
        #copy folders as creating shortcuts doesn't work
        $source = $WorkShopPath + "\" + "$Mod"
        $destination = $Arma3InstallLocation + "\" + "$Mod"
        $destinationKeyFolder = $Arma3InstallLocation + "\" + "keys"
        #Copy whole Folder to the install Dir, which is required to load. Arma expects the folders to be in one area.
        Copy-Item -Path $source -Destination $destination -Recurse -Force
        #Copy the bikeys to the Servers keys folder because nothing's ever easy.
        Get-ChildItem -Include "*bikey" -Path $source -Recurse | Copy-Item -Destination $destinationKeyFolder -Force
        #Creating string to pass to arma3 when starting.
        $ModArrayToLoad += "$mod" + ";"
        }
    #removing the final ; from the modlist to allow ARMA to load mods properly (To be used when installing the service).
    $mods = $ModArrayToLoad.Substring(0,$ModArrayToLoad.Length-1)
}else{}

#4
Write-Output "Arma3 server `"$Arma3ServerName`" has been installed in $SteamCMDinstallPath"
Write-Output "mods downloaded were: $mods"
