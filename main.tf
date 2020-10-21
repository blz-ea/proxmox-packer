locals {
  template_folder = "${path.module}/${var.template}"
  packer_cfg = {
    PKR_VAR_proxmox_hostname  = var.proxmox_api_url
    PKR_VAR_proxmox_username  = var.proxmox_api_username
    PKR_VAR_proxmox_password  = var.proxmox_api_password
    PKR_VAR_proxmox_node_name = var.proxmox_node_name
    PKR_VAR_proxmox_insecure_skip_tls_verify = var.proxmox_api_tls_insecure

    PKR_VAR_template_description  = var.template_description

    PKR_VAR_vm_id                 = var.vm_id
    PKR_VAR_vm_name               = var.vm_name
    PKR_VAR_vm_storage_pool       = var.vm_storage_pool
    PKR_VAR_vm_cores              = var.vm_cores
    PKR_VAR_vm_memory             = var.vm_memory
    PKR_VAR_vm_sockets            = var.vm_sockets

    PKR_VAR_iso_file              = var.iso_file

    PKR_VAR_pool                  = var.pool

    PKR_VAR_username              = var.username
    PKR_VAR_user_password         = var.user_password
    PKR_VAR_time_zone             = var.time_zone
  }
}

resource "null_resource" "packer_build" {
  count = !var.remove_template ? 1 : 0

  provisioner "local-exec" {
    working_dir = path.module
    command = "delete_template.py"
    interpreter = ["python"]
    environment = local.packer_cfg
  }

  provisioner "local-exec" {
    working_dir = local.template_folder
    interpreter = ["packer", "build",]
    command     = "."
    environment = local.packer_cfg
  }

  provisioner "local-exec" {
    when  = destroy
    command = "delete_template.py"
    interpreter = ["python"]
    working_dir = path.module
    environment = merge(yamldecode(self.triggers.packer_cfg), {
      PKR_VAR_vm_id       = self.triggers.vm_id
    })
  }

  triggers = {
    packer_cfg = yamlencode(local.packer_cfg)
    vm_id           = local.packer_cfg.PKR_VAR_vm_id
    template_folder = local.template_folder
//    sources_hash    = sha1(file("${local.template_folder}/sources.pkr.hcl"))
//    http_seed_hash  = sha1(file("${local.template_folder}/http/preseed.cfg"))
  }
}
