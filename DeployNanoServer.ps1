  <#
    .SYNOPSIS 
        Prepares an Hyper-V ready-to-boot Windows Server 2016 Technical Preview 2 - Nano Server Virtual Hard Disk (.vhd) from an ISO file previously downloaded.

    .DESCRIPTION
        This script automatizes the process of building a Nano Server image based on the second Technical Preview of Windows Server 2016 as specified by the TechNet article (https://technet.microsoft.com/en-us/library/mt126167.aspx)

        A modified version of the Convert-Image script is used to avoid an incorrect detection of Windows 10 as an older version than Windows 8. 

        The latest version of this scripts is available on the following GitHub repository. 
        
        https://github.com/jangelfdez/DeployNanoServer

        If you find any bug or you want to propose a new feature don't hesitate to open an issue or pull request 

    .PARAMETER ComputerPackage
        Adds support of the Hyper-V role

    .PARAMETER StoragePackage
        Adds support of the File Server role and other storage components

    .PARAMETER FailoverClusterPackage
        Adds support of Failover Clustering

    .PARAMETER GuestPackage
        Adds drivers for hosting Nano Server as a virtual machine

    .PARAMETER OemPackage
        Adds basic drivers for a variety of network adapters and storage controllers

    .PARAMETER ReverseForwardersPackage
        Adds support for applications not targeted to Nano Server to be able to run creating a mockup for the APIs not available.

    .PARAMETER Lang
        Selects the locaziation of the image, right now only "en-us" is supported.

    .EXAMPLE
      Prepares the Nano Server image with support for running inside a Virtual Machine
      .\DeployNanoServer.ps1 -ComputerPackage -StoragePackage -FailoverClusterPackage -GuestPackage -IsoPath C:\ISO\file.iso

      Prepares the Nano Server image with support for creating an Hyper-V node
      .\DeployNanoServer.ps1 -ComputerPackage -StoragePackage -FailoverClusterPackage -GuestPackage -IsoPath C:\ISO\file.iso

      Prepares the Nano Server image with support for creating a Scale-Out File Server in a cluster
      .\DeployNanoServer.ps1 -ComputerPackage -StoragePackage -FailoverClusterPackage -GuestPackage -IsoPath C:\ISO\file.iso


    .NOTES 
        Windows Server 2016 Technical Preview is not a final release, it can contains
        errors or bugs until the final release. Use it under your own responsability.

      
  #>

[CmdletBinding()]
param (
  [switch]$ComputerPackage,
  [switch]$StoragePackage,
  [switch]$FailoverClusterPackage,
  [switch]$GuestPackage,
  [switch]$OemPackage,
  [switch]$ReverseForwardersPackage,
  [string]$ComputerName = "NanoServer",
  [string]$AdministratorPassword = "Passw0rd!",
  [string]$OrganizationOwner = "Contoso",
  [string]$OrganizationName = "Contoso Inc.",
  [string]$NanoServerVhdName = "NanoServer-TechnicalPreview2.vhd",
  [Parameter(Mandatory=$true)]
  [System.Uri] $IsoPath,
  [ValidateSet("en-us")]
  [string] $Lang = "en-us"
  
  
)

# Environment for with DISM tools
$DismFolder = "$env:TEMP\dism"
$CustomImageMountFolder = "$env:TEMP\dism\mountdir"

$MountedImageLetter = "D:"

# Custom image
#$NanoServerVhdName = "NanoServer-TechnicalPreview2.vhd"
$NanoServerVhdPath = "$env:TEMP\$NanoServerVhdName"

## Unnatend file XML Configuration Data
#$ComputerName = "NanoServer"
#$AdministratorPassword = "Passw0rd!"
#$OrganizationOwner = "Contoso"
#$OrganizationName = "Contoso SL"

#$Lang = "en-us"

$UnattendXMLFileName = "Unattend.xml"

# Files required
$ConvertImageScriptUrl = "https://raw.githubusercontent.com/jangelfdez/DeployNanoServer/master/"
$ConvertImageScriptName = "Convert-WindowsImage.ps1"

Write-Output "-> Downloading modified versión of Convert-WindowsImage script"
Invoke-WebRequest -Uri $ConvertImageScriptUrl$ConvertImageScriptName -OutFile $env:TEMP\$ConvertImageScriptName | Out-Null

# Parsing ISO file path
$splitUri = ($IsoPath.AbsolutePath.Split("/"))
$WindowsServer2016IsoName = $splitUri[$splitUri.Count - 1]

# If you are using Windows 10 10074 there is a bug
$os = Get-WmiObject -Class Win32_OperatingSystem
$osVersion = [System.Version]::new($os.Version)

if ( $osVersion.Major -ge 10 )
{
    Write-Output "`nThere is a problem with Mount-Disk Cmdlet on Windows 10. Please, mount the ISO file with a double click on the $WindowsServer2016IsoName ISO"
    Read-Host -Prompt "Press any key to launch Explorer..."
   
    explorer $env:HOMEPATH
    Read-Host -Prompt "Press Enter after you have mounted the image, doing it before the script will fail" 

} else {
    Write-Output "-> Mounting $WindowsServer2016IsoName .ISO image"
    Mount-DiskImage -ImagePath $env:TEMP\$WindowsServer2016IsoName -StorageType ISO
}
 

Write-Output "-> Converting .wim file to .vhd"
Invoke-Expression "$env:TEMP\$ConvertImageScriptName -Sourcepath '$MountedImageLetter\NanoServer\NanoServer.wim' -VHD $NanoServerVhdPath –VHDformat VHD -Edition 1"

Write-Output "`n-> Using $DismFolder folder"
New-Item -Type Directory $DismFolder | Out-Null

Write-Output "-> Copying required files"
Copy-Item -Path $MountedImageLetter\sources\api*downlevel*.dll -Destination $DismFolder
Copy-Item -Path $MountedImageLetter\sources\*dism*.dll -Destination $DismFolder
Copy-Item -Path $MountedImageLetter\sources\*provider*.dll -Destination $DismFolder

Set-Location $DismFolder

Write-Output "-> Creating mount point"
New-Item -Type Directory $CustomImageMountFolder | Out-Null

Write-Output "-> Mounting image"
Mount-WindowsImage -ImagePath "$env:TEMP\$NanoServerVhdName" -Path $CustomImageMountFolder -Index 1 | Out-Null

Write-Output "-> Adding selected packages..."
if ( $ComputerPackage ){
    Write-Output "|-> Microsoft-NanoServer-Compute-Package.cab"
    Add-WindowsPackage -PackagePath "$MountedImageLetter\NanoServer\Packages\Microsoft-NanoServer-Compute-Package.cab" -Path $CustomImageMountFolder | Out-Null
    Add-WindowsPackage -PackagePath "$MountedImageLetter\NanoServer\Packages\$Lang\Microsoft-NanoServer-Compute-Package.cab" -Path $CustomImageMountFolder | Out-Null
}
 
if ( $StoragePackage ) { 
    Write-Output "|-> Microsoft-NanoServer-Storage-Package.cab"
    Add-WindowsPackage -PackagePath "$MountedImageLetter\NanoServer\Packages\Microsoft-NanoServer-Storage-Package.cab" -Path $CustomImageMountFolder | Out-Null
    Add-WindowsPackage -PackagePath "$MountedImageLetter\NanoServer\Packages\$Lang\Microsoft-NanoServer-Storage-Package.cab" -Path $CustomImageMountFolder | Out-Null
}

if ( $FailoverClusterPackage){
    Write-Output "|-> Microsoft-NanoServer-Storage-Package.cab"
    Add-WindowsPackage -PackagePath "$MountedImageLetter\NanoServer\Packages\Microsoft-NanoServer-FailoverCluster-Package.cab" -Path $CustomImageMountFolder | Out-Null
    Add-WindowsPackage -PackagePath "$MountedImageLetter\NanoServer\Packages\$Lang\Microsoft-NanoServer-FailoverCluster-Package.cab" -Path $CustomImageMountFolder | Out-Null
} 

if ( $GuestPackage ) {
    Write-Output "|-> Microsoft-NanoServer-Guest-Package.cab"
    Add-WindowsPackage -PackagePath "$MountedImageLetter\NanoServer\Packages\Microsoft-NanoServer-Guest-Package.cab" -Path $CustomImageMountFolder | Out-Null
    Add-WindowsPackage -PackagePath "$MountedImageLetter\NanoServer\Packages\$Lang\Microsoft-NanoServer-Guest-Package.cab" -Path $CustomImageMountFolder | Out-Null
}

if ( $OemPackage) { 
    Write-Output "|-> Microsoft-NanoServer-Storage-Package.cab"
    Add-WindowsPackage -PackagePath "$MountedImageLetter\NanoServer\Packages\Microsoft-NanoServer-OEM-Drivers-Package.cab" -Path $CustomImageMountFolder | Out-Null
    Add-WindowsPackage -PackagePath "$MountedImageLetter\NanoServer\Packages\$Lang\Microsoft-NanoServer-OEM-Drivers-Package.cab" -Path $CustomImageMountFolder | Out-Null
}
 
if ( $ReverseForwardersPackage ){
    Write-Output "|-> Microsoft-OneCore-ReverseForwarders-Package.cab"
    Add-WindowsPackage -PackagePath "$MountedImageLetter\NanoServer\Packages\Microsoft-OneCore-ReverseForwarders-Package.cab" -Path $CustomImageMountFolder | Out-Null
    Add-WindowsPackage -PackagePath "$MountedImageLetter\NanoServer\Packages\$Lang\Microsoft-OneCore-ReverseForwarders-Package.cab" -Path $CustomImageMountFolder | Out-Null
}


Write-Output "-> Applying unattend installation file"
$UnattendXmlContent = "<?xml version='1.0' encoding='UTF-8'?> 
 <unattend xmlns='urn:schemas-microsoft-com:unattend' xmlns:wcm='http://schemas.microsoft.com/WMIConfig/2002/State' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'> 
 <settings pass='offlineServicing'> 
 <component name='Microsoft-Windows-Shell-Setup' processorArchitecture='amd64' publicKeyToken='31bf3856ad364e35' language='neutral' versionScope='nonSxS'>
    <ComputerName>$ComputerName</ComputerName>
 </component>
 </settings>
 <settings pass='oobeSystem'>
 <component name='Microsoft-Windows-Shell-Setup' processorArchitecture='amd64' publicKeyToken='31bf3856ad364e35' language='neutral' versionScope='nonSxS'>
<UserAccounts>
            <AdministratorPassword>
               <Value>$AdministratorPassword</Value>
               <PlainText>true</PlainText>
            </AdministratorPassword>
         </UserAccounts>
 <TimeZone>Pacific Standard Time</TimeZone>
 </component>
 </settings>
 <settings pass='specialize'>
 <component name='Microsoft-Windows-Shell-Setup' processorArchitecture='amd64' publicKeyToken='31bf3856ad364e35' language='neutral' versionScope='nonSxS'>
         <RegisteredOwner>$OrganizationOwner</RegisteredOwner>
         <RegisteredOrganization>$OrganizationName</RegisteredOrganization>
 </component>
 </settings>
 </unattend>"

$UnattendXmlContent | Out-File "$DismFolder\$UnattendXMLFileName" -Encoding utf8
Use-WindowsUnattend -UnattendPath "$DismFolder\$UnattendXMLFileName" -Path $CustomImageMountFolder | Out-Null
 
Write-Output "-> Copying unattend installation file inside the image"
New-Item -Type Directory "$CustomImageMountFolder\Windows\panther" | Out-Null
Copy-Item -Path "$DismFolder\$UnattendXMLFileName" -Destination "$CustomImageMountFolder\Windows\panther"
 
Write-Output "-> Copying SetupComplete.cmd file inside the image"
New-Item -Type Directory $CustomImageMountFolder\Windows\Setup | Out-Null
New-Item -Type Directory $CustomImageMountFolder\Windows\Setup\Scripts | Out-Null

$SetupCmdContent = "ipconfig"
$SetupCmdContent | Out-File "$DismFolder\SetupComplete.cmd" -Encoding ascii

Copy-Item -Path $DismFolder\SetupComplete.cmd -Destination $CustomImageMountFolder\Windows\Setup\Scripts

Write-Output "-> Dismounting image"
Dismount-WindowsImage -Path $CustomImageMountFolder -Save | Out-Null

Write-Output "-> Your Nano Server .vhd is available at $env:TEMP"

# La IP será la que haya aparecido al arranque Nano Server.
#Set-Item WSMan:\localhost\Client\TrustedHosts 192.168.1.39
# Debemos introducir el usuario "Administrator" y la contraseña definida en el fichero Unattend.xml
#Enter-PSSession -ComputerName 192.168.1.39 -Credential (Get-Credential)
