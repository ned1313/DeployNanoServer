[CmdletBinding()]
param (
  [switch]$ComputerPackage,
  [switch]$StoragePackage,
  [switch]$FailoverClusterPackage,
  [switch]$GuestPackage,
  [switch]$OemPackage,
  [switch]$ReverseForwardersPackage
)


# Environment for with DISM tools
$DismFolder = "$env:TEMP\dism"
$CustomImageMountFolder = "$env:TEMP\dism\mountdir"

$MountedImageLetter = "D:"

# Custom image
$NanoServerVhdName = "NanoServer-TechnicalPreview2.vhd"
$NanoServerVhdPath = "$env:TEMP\$NanoServerVhdName"


# Unnatend file XML Configuration Data
$ComputerName = "NanoServer"
$AdministratorPassword = "Passw0rd!"
$OrganizationOwner = "Contoso"
$OrganizationName = "Contoso SL"

$UnattendXMLFileName = "Unattend.xml"

# Files needed
#$WindowsServer2016IsoName = "10074.0.150424-1350.fbl_impressive_SERVER_OEMRET_X64FRE_EN-US.ISO"

$WindowsServer2016IsoName = "en_windows_server_technical_preview_2_x64_dvd_6651466.iso"
$WindowsServer2016IsoUrl = "http://care.dlservice.microsoft.com/dl/download/6/D/D/6DDE7201-5753-454A-A7CF-94F909E8EC05/$WindowsServer2016ISO"

$ConvertImageScriptUrl = "https://raw.githubusercontent.com/jangelfdez/DeployNanoServer/master/"
$ConvertImageScriptName = "Convert-WindowsImage.ps1"

# Download Windows Server 2016 Technical Preview 2 from TechNet Evaluation Center
#Invoke-WebRequest -Uri $WindowsServer2016IsoUrl -OutFile $env:TEMP\Downloads\$WindowsServer2016IsoName

# Download Convert-WindowsImage script from Script Gallery
Invoke-WebRequest -Uri $ConvertImageScriptUrl$ConvertImageScriptName -OutFile $env:TEMP\$ConvertImageScriptName | Out-Null

# If you are using Windows 10 10074 it fails
#Mount-DiskImage -ImagePath $env:TEMP\Downloads\$WindowsServer2016IsoName -StorageType ISO

# Convert WMI image to a VHD
Invoke-Expression "$env:TEMP\$ConvertImageScriptName -Sourcepath '$MountedImageLetter\NanoServer\NanoServer.wim' -VHD $NanoServerVhdPath –VHDformat VHD -Edition 1"


# Build a local directory to work with DISM
New-Item -Type Directory $DismFolder | Out-Null

# Copying required files from the .ISO file
Copy-Item -Path $MountedImageLetter\sources\api*downlevel*.dll -Destination $DismFolder
Copy-Item -Path $MountedImageLetter\sources\*dism*.dll -Destination $DismFolder
Copy-Item -Path $MountedImageLetter\sources\*provider*.dll -Destination $DismFolder

Set-Location $DismFolder

# Path were the image is going to be mounted
New-Item -Type Directory $CustomImageMountFolder | Out-Null

Mount-WindowsImage -ImagePath "$env:TEMP\$NanoServerVhdName" -Path $CustomImageMountFolder -Index 1 | Out-Null

# Adding support to Hyper-V
if ( $ComputerPackage ){

    Add-WindowsPackage -PackagePath "$MountedImageLetter\NanoServer\Packages\Microsoft-NanoServer-Compute-Package.cab" -Path $CustomImageMountFolder
    Add-WindowsPackage -PackagePath "$MountedImageLetter\NanoServer\Packages\en-us\Microsoft-NanoServer-Compute-Package.cab" -Path $CustomImageMountFolder
}
 
# Adding support to Scale-Out File Server
if ( $StoragePackage ) {
    Add-WindowsPackage -PackagePath "$MountedImageLetter\NanoServer\Packages\Microsoft-NanoServer-Storage-Package.cab" -Path $CustomImageMountFolder
    Add-WindowsPackage -PackagePath "$MountedImageLetter\NanoServer\Packages\en-us\Microsoft-NanoServer-Storage-Package.cab" -Path $CustomImageMountFolder
}

 # Adding support to Failover Clustering
if ( $FailoverClusterPackage){
    Add-WindowsPackage -PackagePath "$MountedImageLetter\NanoServer\Packages\Microsoft-NanoServer-FailoverCluster-Package.cab" -Path $CustomImageMountFolder
    Add-WindowsPackage -PackagePath "$MountedImageLetter\NanoServer\Packages\en-us\Microsoft-NanoServer-FailoverCluster-Package.cab" -Path $CustomImageMountFolder
}

# Adding support to run on a Virtual Machine
if ( $GuestPackage ) {
    Add-WindowsPackage -PackagePath "$MountedImageLetter\NanoServer\Packages\Microsoft-NanoServer-Guest-Package.cab" -Path $CustomImageMountFolder
    Add-WindowsPackage -PackagePath "$MountedImageLetter\NanoServer\Packages\en-us\Microsoft-NanoServer-Guest-Package.cab" -Path $CustomImageMountFolder
}

# Adding support to run on physical hardware
if ( $OemPackage ){
    Add-WindowsPackage -PackagePath "$MountedImageLetter\NanoServer\Packages\Microsoft-NanoServer-OEM-Drivers-Package.cab" -Path $CustomImageMountFolder
    Add-WindowsPackage -PackagePath "$MountedImageLetter\NanoServer\Packages\en-us\Microsoft-NanoServer-OEM-Drivers-Package.cab" -Path $CustomImageMountFolder
}
 
# Adding support to apps not developed for Nano Server
if ( $ReverseForwardersPackage ){
    Add-WindowsPackage -PackagePath "$MountedImageLetter\NanoServer\Packages\Microsoft-OneCore-ReverseForwarders-Package.cab" -Path $CustomImageMountFolder
    Add-WindowsPackage -PackagePath "$MountedImageLetter\NanoServer\Packages\en-us\Microsoft-OneCore-ReverseForwarders-Package.cab" -Path $CustomImageMountFolder
}


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

$UnattendXmlContent | Out-File "$DismFolder\$UnattendXMLFileName" -Encoding utf8

Use-WindowsUnattend -UnattendPath "$DismFolder\$UnattendXMLFileName" -Path $CustomImageMountFolder | Out-Null
 
# Copiamos el fichero en el directorio esperado dentro de Windows
New-Item -Type Directory "$CustomImageMountFolder\Windows\panther" | Out-Null
Copy-Item -Path "$DismFolder\$UnattendXMLFileName" -Destination "$CustomImageMountFolder\Windows\panther"
 
# Copiamos el fichero en el directorio esperado dentro de Windows
New-Item -Type Directory $CustomImageMountFolder\Windows\Setup | Out-Null
New-Item -Type Directory $CustomImageMountFolder\Windows\Setup\Scripts | Out-Null

$SetupCmdContent = "ipconfig"
$SetupCmdContent | Out-File "$DismFolder\SetupComplete.cmd" -Encoding ascii

Copy-Item -Path $DismFolder\SetupComplete.cmd -Destination $CustomImageMountFolder\Windows\Setup\Scripts
 
Dismount-WindowsImage -Path $CustomImageMountFolder -Save | Out-Null


# La IP será la que haya aparecido al arranque Nano Server.
#Set-Item WSMan:\localhost\Client\TrustedHosts 192.168.1.39
# Debemos introducir el usuario "Administrator" y la contraseña definida en el fichero Unattend.xml
#Enter-PSSession -ComputerName 192.168.1.39 -Credential (Get-Credential)
