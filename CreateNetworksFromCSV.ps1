# $IP = "192.168.163.153"
# Above = Hard Coded option, Next 4 lines = Prompt for Dynamic Input
[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
$title = 'Connect to OneView'
$msg   = 'Enter OneView IP Adddress or Hostname:'
$IP = [Microsoft.VisualBasic.Interaction]::InputBox($msg, $title)


# $username = "Administrator" 
# $password = "password"
# $secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
# $credentials = New-Object System.Management.Automation.PSCredential ($username, $secpasswd)
# Above = Hard Coded option, Next 4 lines = Prompt for Dynamic Input
$credentials    = get-credential

# Check to see if OneView for PowerShell is installed, Install it if not.
If (-not (get-module HPEOneView.530 -ListAvailable )) { Install-Module -Name HPEOneView.530 -scope Allusers -Force }
# Import Module for use
import-module HPEOneView.530

# Connect and Login to OneView
Connect-OVMgmt -Hostname $IP -Credential $credentials

# CSV Syntax
# Line 1: NetName,VLAN_ID          (This Column Header Line is Required)
# Line x: Network Name,VLAN ID     (Network Name = As you want it to appear in OneView, VLAN ID = Numberic only)

$csvfile = "networks_creation.csv"
# Above = Hard Coded option PLUS Default Value for Dynamic, Next 4 lines = Prompt for Dynamic Input
$title = 'CSV Import'
$msg   = 'Enter Name of CSV File:'
$DefaultResponse = 'networks_creation.csv'
$csvfile = [Microsoft.VisualBasic.Interaction]::InputBox($msg, $title, $DefaultResponse)


# Import CSV File into PowerShell Array
$data = (Import-Csv $csvfile)

# Loop through each line in the CSV to create individual Networks
ForEach ($VLAN In $data) {
    New-OVNetwork -Name $VLAN.NetName -Type Ethernet -VLANId $VLAN.VLAN_ID -SmartLink $True | out-Null
    Write-host "`nCreating Network: " -NoNewline
    Write-host -f Cyan ($VLAN.netName) -NoNewline
	}
	
# Line wrap after last VLAN
write-host "`n"

# Disconnect Session from OneView
Disconnect-OVMgmt
