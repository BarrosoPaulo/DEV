output "host" {
  value = data.vsphere_virtual_machine.master.ip_address
}

output "host" {
  value = data.vsphere_virtual_machine.slave.ip_address
}

