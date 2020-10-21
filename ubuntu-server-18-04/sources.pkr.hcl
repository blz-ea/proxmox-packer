source "proxmox" "template" {
  proxmox_url               = "${var.proxmox_hostname}/api2/json"
  insecure_skip_tls_verify 	= var.proxmox_insecure_skip_tls_verify
  username                  = var.proxmox_username
  password                  = var.proxmox_password
  node                      = var.proxmox_node_name

  vm_name   = var.vm_name
  vm_id     = var.vm_id

  memory    = var.vm_memory
  sockets   = var.vm_sockets
  cores     = var.vm_cores
  os        = "l26"

  network_adapters {
    model   = "virtio"
    bridge  = "vmbr0"
  }

  qemu_agent            = true
  scsi_controller       = "virtio-scsi-pci"

  disks {
    type              = "scsi"
    disk_size         = "30G"
    storage_pool      = var.vm_storage_pool
    storage_pool_type = "lvm-thin"
    format            = "raw"
  }

  ssh_username          = var.username
  ssh_password          = var.user_password
  ssh_timeout           = "35m"

  iso_file              = var.iso_file
  iso_url               = var.iso_url
  iso_storage_pool      = var.iso_storage_pool
  iso_checksum          = var.iso_checksum

  onboot                = true

  template_name         = var.vm_name
  template_description  = var.template_description
  unmount_iso           = true

  http_directory        = "./http"
  boot_wait             = "10s"
  boot_command = [
    "<esc><wait>",
    "<esc><wait>",
    "<enter><wait>",
    "/install/vmlinuz initrd=/install/initrd.gz",
    " auto=true priority=critical interface=auto",
    " netcfg/dhcp_timeout=120",
    " hostname=${var.vm_name}",
    " username=${var.username}",
    " time_zone=${var.time_zone}",
    " passwd/username=${var.username}",
    " passwd/user-fullname=${var.username}",
    " passwd/user-password=${var.user_password}",
    " passwd/user-password-again=${var.user_password}",
    " preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg",
    " <enter>"
  ]
}

build {
  sources = [
    "source.proxmox.template"
  ]

  provisioner "shell" {
    pause_before = "20s"
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
    ]
    inline = [
      "sleep 30",
      "sudo apt-get update",
      "sudo apt-get -y upgrade",
      "sudo apt-get -y dist-upgrade",
      "sudo apt-get -y install linux-generic linux-headers-generic linux-image-generic",
      "sudo apt-get -y install wget curl",

      # DHCP Server assigns same IP address if machine-id is preserved, new machine-id will be generated on first boot
      "sudo truncate -s 0 /etc/machine-id",
      "exit 0",
    ]
  }
}

