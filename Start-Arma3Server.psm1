<#
.SYNOPSIS 
    A POSH script to Start a previously setup Arma3 Server.

.PARAMETER SteamCMDinstallPath

    The location of SteamCMD.

.PARAMETER Arma3ServerName

    Name of the Arma3 server.

.PARAMETER ServerConfigFileLocation
    
    The name of the config file for the server, if you use one. Should ideally be in the Arma 3 Server directory.

.PARAMETER Mods
    
    A list of mods to update, using their steam numbers in the format of: "00000000","000000001","00000125"

.NOTES
    AUTHOR: Caius Ajiz
    WEBSITE: https://github.com/CaiusAjiz/Arma3Powershell/
#> 
function Start-Arma3Server {
Param(
    [Parameter(Mandatory=$true)]
    [String]$SteamCMDinstallPath,
    [Parameter(Mandatory=$true)]
    [String]$Arma3ServerName,
    [Parameter(Mandatory=$false)]
    [String]$ServerConfigFileLocation,
    [Parameter(Mandatory=$false)]
    [String[]]$Mods
)

##### Variables #####
#App ID is 233780 for Arma3 Server
$AppInstallDir = $SteamCMDinstallPath + "\" + $Arma3ServerName
$originalLocation = Get-Location
##### /Variables #####

#Check SteamCMD exists.
Set-Location -Path $SteamCMDinstallPath
Test-Path -Path ".\Steamcmd.exe"

#removing the final ; from the modlist to allow ARMA to load mods properly.
foreach($mod in $Mods){
    $ModsToLoad += "$mod" + ";"
} 
$ModsToLoad = $ModsToLoad.Trimend(";")

#Launch the server with the necessary options
Set-Location $AppInstallDir
.\arma3server_x64.exe "-config=$ServerCFG" "-mod=$ModsToLoad"

#set back to original location
Set-Location $originalLocation

}

Export-ModuleMember -Function Start-Arma3Server