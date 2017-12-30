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

    An array of mods to download for Arma3 Server.

.EXAMPLE
    

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
#2.1 Copying across the server config file, if one has been provided
If( (Test-Path $ServerConfigFileLocation).length -gt 0 ){
    write-output "Copying Server Configuration file from $ServerConfigFileLocation to $Arma3InstallLocation"
    Copy-Item -Path $ServerConfigFileLocation -Destination $Arma3InstallLocation -Force
    }else{Write-Output "No Server config provided or the file couldn't be found, moving on to installing the mods"}

#3 - Installing the mods, if there are any provided
if($mods.length -gt 0 ){
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
}else{ Write-Output "No Mods provided, moving on to Installing Arma3 as a Windows service"}

#4 - downloading NSSM and Installing Arma3 Server as a service. Checks to see if Service with same name already exists.
$Arma3ServiceCheck = Get-Service -Name $Arma3ServerName -ErrorAction SilentlyContinue
$BinaryPathNameString = $null
$OS64BitCheck = [environment]::Is64BitOperatingSystem

#Making sure service doesn't already exist, then doing if statements to build the string to pass to -binaryPathName in the New Service CMDlet
if( $Arma3ServiceCheck.length -eq 0 ){
    #downloading NSSM into the SteamCMD folders
    Start-BitsTransfer -Source $NSSMDownloadURL -Destination $SteamCMDinstallPath
    Start-Sleep -Seconds 5
    #extracting into a new folder inside of the SteamCMD structure.
    Expand-Archive -Path ($SteamCMDinstallPath + "\nssm-2.24.zip") -DestinationPath ($SteamCMDinstallPath + "\NSSM" )

    <#

    #64-32 bit OS check
    if($OS64BitCheck -eq $true){ 
        $BinaryPathNameString = $BinaryPathNameString + "$Arma3InstallLocation\arma3server_x64.exe"
    }else{
        $BinaryPathNameString = $BinaryPathNameString + "$Arma3InstallLocation\arma3server.exe"
        }
    #Checking if server config file location has been provided. if not, server service will be created without one
    if($ServerConfigFileLocation.Length -gt 0){
        #Getting File Name
        $configFileName = $ServerConfigFileLocation.Split('\')
        $configFileName = $configFileName[($configFileName.Count - 1)]
        #Adding file name to Var to pass
        $BinaryPathNameString = $BinaryPathNameString + " -config=$configFileName"
    }else{}
    #If there are mods, add them to the string by taking advantage of the Array built at the end of #3 - installing the mods. If not, skip
    if($ModArrayToLoad.Length -gt 0 ){
        $BinaryPathNameString = $BinaryPathNameString + "$ModArrayToLoad"
    }else{}
}else{
    Write-Output "Service already exists!"
}  
#>