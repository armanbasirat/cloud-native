VMware vSphere Servers

The account used to connect vCenter Server and ESXi hosts must have the following privileges:

Datastore.Browse datastore
Required for collecting datastore details

Global.Global tag (not required VMware vSphere version 6.5 or later)
Required for running remediation actions

Global.Licenses
Required for collecting license information

Host.CIM.CIM Interaction
Required for gathering of ESXi host hardware data

Host.Configuration.Connection
Required for gathering of ESXi host hardware data

Host profile.Edit
Required for collecting Host profile properties

Host profile.View
Required for collecting Host profile properties

Virtual machine.Interaction.Answer question
Required for using VM Console and viewing snapshot information

Virtual machine.Interaction.Console interaction
Required for accessing VM console from Veeam ONE Client

Virtual machine.Snapshot management.Remove Snapshot
Required for running remediation actions

vSphere Tagging Privileges:
vSphere Tagging.Assign or Unassign vSphere Tag
vSphere Tagging.Create vSphere Tag
vSphere Tagging.Create vSphere Tag Category
vSphere Tagging.Delete vSphere Tag
vSphere Tagging.Delete vSphere Tag Category
vSphere Tagging.Assign or Unassign vSphere Tag on Object

Required for collecting and updating tags on the vCenter Server side. The privileges must be assigned at the vCenter Server level.

Note:

Names of privileges are provided for the latest supported version of VMware vSphere, and may vary for different platform versions.


Reference:

https://helpcenter.veeam.com/docs/one/userguide/connection_to_virtual_servers.html?ver=13#vmware