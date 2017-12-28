<#
.SYNOPSIS 
   Sets up a new instance of an Arma3 dedicated server. 

.PARAMETER SteamCMDinstallPath

    The location of SteamCMD. If not downloaded, SteamCMD will be downloaded to this location.

.PARAMETER Arma3InstallPath

    The Path to install Arma3 to, recommend a sub-directory of SteamCMD. E.G "C:\SteamCMD\Arma3Server"

.PARAMETER <Parameter name>
    

.EXAMPLE
    

.NOTES
    AUTHOR: Caius Ajiz
    WEBSITE: https://github.com/CaiusAjiz/Arma3Powershell/
    
#> 

Param
(
    [Parameter(Mandatory=$true)]
    [String]$SteamCMDinstallPath
    
)
####Vars####
$SteamCMDDownloadURL = 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip'
####/vars####


#Checking and downloading SteamCMD if doesn't already exist.
If( (Test-Path($SteamCMDinstallPath +"\steamcmd.exe")) -eq $false ){
    Write-Output "SteamCMD.exe doesn't exit, downloading"
    #making sure folder exists, surpressing error
    New-Item -ItemType Directory -Path $SteamCMDinstallPath -ErrorAction SilentlyContinue
    #Transferring
    Start-BitsTransfer -Source $SteamCMDDownloadURL -Destination $SteamCMDinstallPath
    #Unpacking ZIP, with the laziest way to guarantee the file is unlocked ever.
    Write-Output "Unpacking SteamCMD ZIP file to $SteamCMDinstallPath"
    Start-Sleep -Seconds 5
    Expand-Archive -Path ($SteamCMDinstallPath + "\steamcmd.zip") -DestinationPath $SteamCMDinstallPath
        }else{
    Write-Output "SteamCMD.exe already exists, moving on"
    }

