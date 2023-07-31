

# Datacenter
data "vsphere_datacenter" "dc" {
  name = var.datacenter_name
}

# Cluster Group
data "vsphere_compute_cluster_host_group" "compute_cluster_group" {
  name               = var.group_cluster_name
  compute_cluster_id = data.vsphere_compute_cluster_host_group.compute_cluster_group.id
}

# Cluster
data "vsphere_compute_cluster" "compute_cluster" {
  name          = var.cluster_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Resource Pool
data "vsphere_resource_pool" "pool" {
  name          = var.resource_pool_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Datastore
data "vsphere_datastore" "datastore" {
  name          = var.datastore_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Network
data "vsphere_network" "network" {
  name          = var.network_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Apply the Terraform configuration
terraform {
  required_providers {
    vsphere = {
      source = "hashicorp/vsphere"
    }
  }
}

# Define virtual machine for master node
resource "vsphere_virtual_machine" "master" {
  name             = var.master_vm_name
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = 2
  memory           = 4096
  guest_id         = "ubuntu64Guest"

  network_interface {
    network_id = data.vsphere_network.network.id
  }
  
  wait_for_guest_net_timeout = -1
  wait_for_guest_ip_timeout  = -1

  disk {
    label            = "disk0"
    size             = 40
    eagerly_scrub    = false
    thin_provisioned = true
  }

  clone {
    template_uuid = var.vm_template_uuid

    customize {
      linux_options {
        host_name = "mariadb-master"
        domain    = "example.com"
      }
      network_interface {
        
      }
      # network_interface {
      #   ipv4_address = "10.0.0.10"
      #   ipv4_netmask = 24
      # }

      # dns_server_list = ["8.8.8.8"]
      # ipv4_gateway    = "10.0.0.1"
    }
  }
  # SSH Connection Configuration
connection {
  type        = "ssh"
  host        = data.vsphere_virtual_machine.master.ip_address
  user        = var.ssh_master_username
  password    = var.ssh_master_password
  timeout     = "2m"
  script_path = null
}

}

# Define virtual machine for slave node
resource "vsphere_virtual_machine" "slave" {
  name             = var.slave_vm_name
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = 2
  memory           = 4096
  guest_id         = "ubuntu64Guest"

  network_interface {
    network_id = data.vsphere_network.network.id
  }
  
  wait_for_guest_net_timeout = -1
  wait_for_guest_ip_timeout  = -1

  disk {
    label            = "disk0"
    size             = 40
    eagerly_scrub    = false
    thin_provisioned = true
  }

  clone {
    template_uuid = var.vm_template_uuid

    customize {
      linux_options {
        host_name = "mariadb-slave"
        domain    = "example.com"
      }

      network_interface {
        
      }
      # network_interface {
      #   ipv4_address = "10.0.0.20"
      #   ipv4_netmask = 24
      # }

      # dns_server_list = ["8.8.8.8"]
      # ipv4_gateway    = "10.0.0.1"
    }
  }


# SSH Connection Configuration
connection {
  type        = "ssh"
  host        = data.vsphere_virtual_machine.slave.ip_address
  user        = var.ssh_slave_username
  password    = var.ssh_slave_password
  timeout     = "2m"
  script_path = null
}

}
