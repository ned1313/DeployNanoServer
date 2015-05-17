.SYNOPSIS 
    Prepares an Hyper-V ready-to-boot Windows Server 2016 Technical Preview 2 - Nano Server
    Virtual Hard Disk (.vhd) from an ISO file previously downloaded.

.DESCRIPTION
    This script automatizes the process of building a Nano Server image based on the second
    Technical Preview of Windows Server 2016 as specified by the TechNet article
    (https://technet.microsoft.com/en-us/library/mt126167.aspx)

    A modified version of the Convert-Image script is used to avoid an incorrect detection
    of Windows 10 as an older version than Windows 8. 

    The latest version of this scripts is available on the following GitHub repository. 
    
    https://github.com/jangelfdez/DeployNanoServer

    If you find any bug or you want to propose a new feature don't hesitate to open an issue
    or pull request 

.PARAMETER ComputePackage
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
    Adds support for applications not targeted to Nano Server to be able to run creating a 
    mockup for the APIs not available.

.PARAMETER Lang
    Selects the locaziation of the image, right now only "en-us" is supported.

.EXAMPLE Creates an image with support for running inside a virtual machine
    .\DeployNanoServer.ps1 -GuestPackage -IsoPath C:\ISO\file.iso

.EXAMPLE Creates an image with support for running on a physical host
    .\DeployNanoServer.ps1 -OemPackage -IsoPath C:\ISO\file.iso

.EXAMPLE Creates an image with support of the Hyper-V role for running on a physical host
    .\DeployNanoServer.ps1 -ComputerPackage -OemPackage -IsoPath C:\ISO\file.iso

.EXAMPLE Creates an image with support of the Hyper-V role and Failover Clustering for running
    on a physical host
    .\DeployNanoServer.ps1 -ComputerPackage -FailoverClusterPackage -IsoPath C:\ISO\file.iso

.EXAMPLE Creates an image with support for running inside a virtual machine and customized
    .\DeployNanoServer.ps1 -GuestPackage -$ComputerName "NanoSever" -$AdministratorPassword 
    "Passw0rd!" -$OrganizationOwner "Contoso" -$OrganizationName "Contoso Inc." -IsoPath C:\ISO\file.iso

.NOTES 
    Windows Server 2016 Technical Preview is not a final release, it can contains
    errors or bugs until the final release. Use it under your own responsability.

  