# Imported 
Import-Module WebAdministration 

# Configuration items to change for different websites. Enter your desired information here.
$machineName = Hostname
$websiteUrl = "site url/DNS Name"
$iisWebsiteName = "Site Name"
$physicalPath = "Site Path"
$artifactFolder = "Build Artifacts path "


# ---------- IIS Configuration --------------#

# Check to see if IIS is installed
if ((Get-WindowsFeature Web-Server).InstallState -ne "Installed") {
    # If not, we'll install the role and server. You may want to install other modules here
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer
} else {
    # If it's installed we do nothing.
    Write-Host "IIS is installed on $machineName"
}

# ---------- Artifact Copying --------------#

# Check to see if website physical path exists
if (!(Test-Path -Path $physicalPath)) {
    # If not we'll create it
    New-Item -Force -ItemType directory -Path $physicalPath
}

# Check to see if artifact storage physical path exists
if (!(Test-Path -Path $artifactFolder)) {
    # If not we'll send a message and exit
    Write-Host "Path $artifactFolder does not exist"
    Exit
}

# Copy over artifacts
Try{ 
    # We use force here to make sure and overwrite old files
    Copy-item -Force -Recurse $artifactFolder\* -Destination $physicalPath
}
Catch{
    # If something goes wrong, we'll display the errors and exit
    Write-Host "Artifact Copy Failed: $_Exception.Message"
    Exit
}

# ---------- Website and Bindings Creation --------------#

# Create a new website
if(Test-Path IIS:\AppPools\$iisWebsiteName){
    Remove-WebAppPool -Name $iisWebsiteName
}

New-WebAppPool -Name $iisWebsiteName

# See if a website with this name already exists
if (!(Get-Website -Name $iisWebsiteName)){

    #Create a new Website
    New-WebSite -Name $iisWebsiteName -Port 80 -IPAddress * -HostHeader $websiteUrl -PhysicalPath $physicalPath -ApplicationPool $iisWebsiteName
    Set-ItemProperty "IIS:\Sites\$iisWebsiteName" -Name  Bindings -value @{protocol="http";bindingInformation="*:80:$websiteUrl"}
}

# ---------- ASP.NET Configuration Check --------------#

# Check if ASP.NET 4.5 is installed
if ((Get-WindowsFeature Web-Asp-Net45).InstallState -ne "Installed") {
    Install-WindowsFeature -Name Web-Asp-Net45
}

# Set the App Pool to the 3.0 runtime--Change as required.
Set-ItemProperty IIS:\AppPools\$iisWebsiteName -Name managedRuntimeVersion -Value "v3.0"
