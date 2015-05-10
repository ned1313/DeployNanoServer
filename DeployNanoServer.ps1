

[CmdletBinding()]
param (
  [switch]$ComputerPackage,
  [switch]$StoragePackage,
  [switch]$FailoverClusterPackage,
  [switch]$GuestPackage,
  [switch]$OemPackage,
  [switch]$ReverseForwardersPackage,
 
  [Parameter(Mandatory=$True)]
  [string]$logfile,
 
  [int]$attemptcount = 5
)


# Vars


# Working with DISM tools

$DismFolder = "$env:HOMEPATH\Downloads\dism"
$CustomImageMountFolder = "$env:HOMEPATH\Downloads\dism\mountdir"

$MountedImageLetter = "D:"

$ComputerName = "NanoServer"
$AdministratorPassword = "Passw0rd!"
$OrganizationOwner = "Contoso"
$OrganizationName = "Contoso SL"

$NanoServerVhdName = "NanoServer-TechnicalPreview2.vhd"
$NanoServerVhdPath = "$env:HOMEPATH\Downloads\$NanoServerVhdName"

$UnattendXMLFileName = "Unattend.xml"

#$WindowsServer2016IsoName = "10074.0.150424-1350.fbl_impressive_SERVER_OEMRET_X64FRE_EN-US.ISO"
$WindowsServer2016IsoName = "en_windows_server_technical_preview_2_x64_dvd_6651466.iso"
$WindowsServer2016IsoUrl = "http://care.dlservice.microsoft.com/dl/download/6/D/D/6DDE7201-5753-454A-A7CF-94F909E8EC05/$WindowsServer2016ISO"

$ConvertImageScriptUrl = "https://gallery.technet.microsoft.com/scriptcenter/Convert-WindowsImageps1-0fe23a8f/file/59237/6/"
$ConvertImageScriptName = "Convert-WindowsImage.ps1"



Invoke-WebRequest -Uri $WindowsServer2016IsoUrl -OutFile $env:HOMEPATH\Downloads\$WindowsServer2016IsoName
Invoke-WebRequest -Uri $ConvertImageScriptUrl -OutFile $env:HOMEPATH\Downloads\$ConvertImageScriptName




# Build a local directory to work with DISM
New-Item -Type Directory $DismFolder | Out-Null

# Copying required files from the .ISO file
Copy-Item -Path $MountedImageLetter\sources\api*downlevel*.dll -Destination $DismFolder
Copy-Item -Path $MountedImageLetter\sources\*dism*.dll -Destination $DismFolder
Copy-Item -Path $MountedImageLetter\sources\*provider*.dll -Destination $DismFolder

Set-Location $DismFolder

# Path were the image is going to be mounted
New-Item -Type Directory $CustomImageMountFolder | Out-Null

Mount-WindowsImage -ImagePath "$env:HOMEPATH\Desktop\$NanoServerVhdName" -Path $CustomImageMountFolder -Index 1 

# Adding support to Hyper-V
if ( $ComputerPackage ){

    Add-WindowsPackage -PackagePath "D:\NanoServer\Packages\Microsoft-NanoServer-Compute-Package.cab" -Path $CustomImageMountFolder
    Add-WindowsPackage -PackagePath "D:\NanoServer\Packages\en-us\Microsoft-NanoServer-Compute-Package.cab" -Path $CustomImageMountFolder
}
 
# Adding support to Scale-Out File Server
if ( $StoragePackage ) {
    Add-WindowsPackage -PackagePath "D:\NanoServer\Packages\Microsoft-NanoServer-Storage-Package.cab" -Path $CustomImageMountFolder
    Add-WindowsPackage -PackagePath "D:\NanoServer\Packages\en-us\Microsoft-NanoServer-Storage-Package.cab" -Path $CustomImageMountFolder
}

 # Adding support to Failover Clustering
if ( $FailoverClusterPackage){
    Add-WindowsPackage -PackagePath "D:\NanoServer\Packages\Microsoft-NanoServer-FailoverCluster-Package.cab" -Path $CustomImageMountFolder
    Add-WindowsPackage -PackagePath "D:\NanoServer\Packages\en-us\Microsoft-NanoServer-FailoverCluster-Package.cab" -Path $CustomImageMountFolder
}

# Adding support to run on a Virtual Machine
if ( $GuestPackage ) {
    Add-WindowsPackage -PackagePath "D:\NanoServer\Packages\Microsoft-NanoServer-Guest-Package.cab" -Path $CustomImageMountFolder
    Add-WindowsPackage -PackagePath "D:\NanoServer\Packages\en-us\Microsoft-NanoServer-Guest-Package.cab" -Path $CustomImageMountFolder
}

# Adding support to run on physical hardware
if ( $OemPackage ){
    Add-WindowsPackage -PackagePath "D:\NanoServer\Packages\Microsoft-NanoServer-OEM-Drivers-Package.cab" -Path $CustomImageMountFolder
    Add-WindowsPackage -PackagePath "D:\NanoServer\Packages\en-us\Microsoft-NanoServer-OEM-Drivers-Package.cab" -Path $CustomImageMountFolder
}
 
# Adding support to apps not developed for Nano Server
if ( $ReverseForwardersPackage ){
    Add-WindowsPackage -PackagePath "D:\NanoServer\Packages\Microsoft-OneCore-ReverseForwarders-Package.cab" -Path $CustomImageMountFolder
    Add-WindowsPackage -PackagePath "D:\NanoServer\Packages\en-us\Microsoft-OneCore-ReverseForwarders-Package.cab" -Path $CustomImageMountFolder
}

Dismount-WindowsImage -Path ".\mountdir" -Save

# Apply the unattend installation file
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

$UnattendXmlContent > "$DismFolder\$UnattendXMLFileName"

Use-WindowsUnattend -UnattendPath "$DismFolder\$UnattendXMLFileName" -Path $CustomImageMountFolder
 
# Copiamos el fichero en el directorio esperado dentro de Windows
New-Item -Type Directory "$CustomImageMountFolder\Windows\panther"
Copy-Item -Path "$DismFolder\$UnattendXMLFileName" -Destination "$CustomImageMountFolder\Windows\panther"
 
# Copiamos el fichero en el directorio esperado dentro de Windows
New-Item -Type Directory .\mountdir\Windows\Setup
New-Item -Type Directory .\mountdir\Windows\Setup\Scripts

$SetupCmdContent = "ipconfig"
$SetupCmdContent > "$DismFolder\SetupComplete.cmd"

Copy-Item -Path $DismFolder\SetupComplete.cmd -Destination $CustomImageMountFolder\Windows\Setup\Scripts
 
Dismount-WindowsImage -Path $CustomImageMountFolder -Save


# La IP será la que haya aparecido al arranque Nano Server.
#Set-Item WSMan:\localhost\Client\TrustedHosts 192.168.1.39
# Debemos introducir el usuario "Administrator" y la contraseña definida en el fichero Unattend.xml
#Enter-PSSession -ComputerName 192.168.1.39 -Credential (Get-Credential)

