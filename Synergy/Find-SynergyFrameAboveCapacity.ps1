<# 

This script 

Requirements:
   - HPE OneView administrator account 
   - HPE OneView Powershell Library


  Author: 
          Structure:  lionel.jullien@hpe.com
          PowerInfra: dan.robinson@hpe.com
  Date:   September 2023
    
#################################################################################
#                         Find-SynergyFrameAboveCapacity.ps1                    #
#                                                                               #
#        (C) Copyright 2017 Hewlett Packard Enterprise Development LP           #
#################################################################################
#                                                                               #
# Permission is hereby granted, free of charge, to any person obtaining a copy  #
# of this software and associated documentation files (the "Software"), to deal #
# in the Software without restriction, including without limitation the rights  #
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell     #
# copies of the Software, and to permit persons to whom the Software is         #
# furnished to do so, subject to the following conditions:                      #
#                                                                               #
# The above copyright notice and this permission notice shall be included in    #
# all copies or substantial portions of the Software.                           #
#                                                                               #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR    #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,      #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE   #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER        #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, #
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN     #
# THE SOFTWARE.                                                                 #
#                                                                               #
#################################################################################
#>

# OneView appliance list
$appliances = @("10.10.109.1", "10.10.119.1")


# Location of the folder to generate the CSV file
# $path = '.\Synergy\Power'
# $Filename = 'SynergyPowerOversubscription_Report.csv'

#################################################################################


# OneView Credentials
# if (!($OV_domain = Read-Host "OV Login Domain [LOCAL]")) { $OV_domain = "LOCAL" }
# $OV_username = read-host  "Please enter the OneView Account" 
# $secpasswd = read-host  "Please enter the OneView Password" -AsSecureString
 
# Connection to the OneView / Synergy Composer
# $credentials = New-Object System.Management.Automation.PSCredential ($OV_username, $secpasswd)
$credentials = Get-Credential -Message 'OneView Login Credentials'

If ( ($PSVersionTable.PSVersion.ToString()).Split('.')[0] -eq 5) {

    add-type -TypeDefinition  @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@

    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

}


#################################################################################


foreach ($appliance in $appliances) {

    try {
        Connect-OVMgmt -Hostname $appliance -Credential $credentials -ErrorAction stop | Out-Null    
        # Assumes default Auth Domain Context.
        # If your default Auth Domain is NOT the one you wish to use for login...
        # Add the following to the above Connect command with the appropriate domain:
        #  -AuthLoginDomain DOMAINNAME
        # Non Directory Account, set AuthLoginDomain = LOCAL
    }
    catch {
        Write-Warning "Cannot connect to '$OV_IP'! Exiting... "
        return
    }
    
    (Get-OVApplianceNetworkConfig).applianceNetworks.Hostname

    # Get List of Enclosures
    $MyEnclosures = Get-OVEnclosure


    foreach($SyEnc in $MyEnclosures)
        {
        Write-Host "`nEnclosureSerialNum:    $($SyEnc.serialNumber)"
        Write-Host "Enclosure Name:        $($SyEnc.name)"
        Write-Host "powerCapacityWatts:    $($SyEnc.powerCapacityWatts)"
        Write-Host "powerAllocatedWatts:   $($SyEnc.powerAllocatedWatts)"
        if (($SyEnc.powerCapacityWatts - $SyEnc.powerAllocatedWatts) -lt 1)
         { Write-Host "Power Available:       $($SyEnc.powerCapacityWatts - $SyEnc.powerAllocatedWatts)" -ForegroundColor Red}
         else {Write-Host "Power Available:       $($SyEnc.powerCapacityWatts - $SyEnc.powerAllocatedWatts)" -ForegroundColor Green}
        }       
        Write-Host ""

    $ConnectedSessions | Disconnect-OVMgmt | Out-Null   
}

