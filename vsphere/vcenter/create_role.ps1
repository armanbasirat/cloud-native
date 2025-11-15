# Connect to vCenter
Connect-VIServer -Server vcenter.example.com -User "administrator@vsphere.local" -Password "YourPassword"

# Step 1: Create a custom role for vROps log collection
$roleName = "vrops"
$privileges = @(
    "Global.View",
    "Host.Configuration.ExportDiagnosticLogs",
    "Inventory.Read",
    "Tasks.View",
    "Events.Read"
)

# Check if role exists
if (-not (Get-VIRole -Name $roleName -ErrorAction SilentlyContinue)) {
    New-VIRole -Name $roleName -Privilege $privileges
}

# Step 2: Assign role to a user/group at the vCenter root level
$rootFolder = Get-Folder -NoRecursion | Where-Object {$_.Name -eq "Datacenters"}
$vcUser = "vrops@vsphere.local"

New-VIPermission -Entity $rootFolder -Principal $vcUser -Role $roleName -Propagate $true

# Disconnect when done
Disconnect-VIServer -Confirm:$false
