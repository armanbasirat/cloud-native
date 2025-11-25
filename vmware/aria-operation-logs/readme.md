Level of Integration						Required Privileges
Events, tasks, and alarms collection		- System > View

Note	
System > View is a system-defined privilege. When you add a custom role and do not assign any privileges to it, the role is created as a Read Only role with three system-defined privileges: System > Anonymous, System > View, and System > Read.

Syslog configuration on ESX hosts			- Host > Configuration > Change settings
											- Host > Configuration > Network configuration
											- Host > Configuration > Advanced Settings
											- Host > Configuration > Security profile and firewall

Note
You must configure the permission on the top-level folder within the vCenter Server inventory, and verify that the Propagate to children check box is selected.


refrence:

https://techdocs.broadcom.com/us/en/vmware-cis/aria/aria-operations-for-logs/8-18/aria-operations-for-logs-8-18/integrating-vrealize-log-insight-with-vmware-products/connect-log-insight-to-a-vcenter-server.html