Backup
Below are vCenter Server granular permissions required for backup:

Privilege Level								Required Permissions
											Direct SAN Access Mode				Virtual Appliance Mode							Network Mode

Cryptographic operations					Direct Access						Direct Access									Direct Access

Datastore									Low-level file operations			Low-level file operations						Low-level file operations

Datastore cluster							Configure a datastore cluster		Configure a datastore cluster					Configure a datastore cluster

Global										Disable methods						Disable methods									Disable methods
											Enable methods						Enable methods									Enable methods
											Licenses							Licenses										Licenses
											Log event							Log event										Log event
											Manage custom attributes			Manage custom attributes						Manage custom attributes
											Set custom attribute				Set custom attribute							Set custom attribute


Virtual Machine		Change Configuration	Acquire disk lease					Acquire disk lease								Acquire disk lease
											Advanced configuration				Add existing disk								Advanced configuration
											Set Annotation						Add or remove device							Set annotation
											Toggle disk change tracking			Advanced configuration							Toggle disk change tracking
																				Configure RAW device (if machines
																			 		have Virtual Compatibility RDM disks)
																				Remove disk
																				Set annotation
																				Toggle disk change tracking
					
					Guest operations		Guest operation modifications		Guest operation modifications					Guest operation modifications
											Guest operation program execution	Guest operation program execution				Guest operation program execution
											Guest operation queries				Guest operation queries							Guest operation queries




					Interaction				Guest operating system management 	Guest operating system management by VIX API	Guest operating system management
					                          by VIX API                          by VIX API                                      by VIX API


					Provisioning			Allow read-only disk access			Allow read-only disk access						Allow read-only disk access
					                        Allow virtual machine download		Allow virtual machine download					Allow virtual machine download


					Snapshot Management		Create snapshot						Create snapshot									Create snapshot
											Remove snapshot						Remove snapshot									Remove snapshot


Reference:

https://helpcenter.veeam.com/docs/backup/permissions/backup.html?ver=120