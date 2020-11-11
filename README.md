# Build Proxmox templates with Packer #

## Requirements ##

| Name          | Version |
|---------------|---------|
| proxmox       | \>= 6.2 |
| terraform     | \>= 0.13 |
| packer        | \>= 1.6.5 |
| python        | \>= 3.0  |
| pip           | \>= 20.0 |
| - [`proxmoxer`](https://github.com/proxmoxer/proxmoxer)           | \>= 1.1.1 |
| - [`requests`](https://pypi.org/project/requests/) | \>= 2.24.0|

## Available templates ##

- [`ubuntu-server-18-04`](./ubuntu-server-18-04/)
- [`debian-10`](./debian-10/)
- [`centos-7`](./centos-7/)

## Usage ##

```hcl-terraform
module "packer_ubuntu_server_18_04_5_amd64" {
  source                    = "github.com/blz-ea/proxmox-packer"
  
  # Folder with Packer source configuration files
  template                  = "ubuntu-server-18-04" 
  
  proxmox_api_url           = "https://192.168.1.1:8006"
  proxmox_api_username      = "root@pam"
  proxmox_api_password      = "<password>"
  proxmox_node_name         = "pve"
  
  vm_id                     = 4000
  
  iso_file        = proxmox_virtual_environment_file.ubuntu-18-04-5-server-amd64.id # "local:iso/<filename>.iso"
  vm_storage_pool = "local-lvm"
  
  # OS bootstrap username and password
  username        = "deploy"
  user_password   = "<password>"

  # Optional
  proxmox_api_otp           = ""
  proxmox_api_tls_insecure  = true

  vm_name       = "ubuntu-server-18-04-5-amd64"
  vm_cores      = 2
  vm_memory     = 2048
  vm_sockets    = 1
  time_zone     = "UTC"  
  template_description  = "Generated by Packer"
}

# Ref: https://github.com/blz-ea/terraform-provider-proxmox
resource "proxmox_virtual_environment_file" "ubuntu-18-04-5-server-amd64" {
    content_type = "iso"

    datastore_id = "<data_store_id>"
    node_name    = "<node_name>"

    source_file {
        path = "http://cdimage.ubuntu.com/releases/18.04.5/release/ubuntu-18.04.5-server-amd64.iso"
    }

}

```

### To remove template from the server ###

```hcl-terraform
module "packer_ubuntu_server_18_04_5_amd64" {
  # ...
  remove_template = true
  # ...
}
```

or 

```bash
terraform destory module.packer_ubuntu_server_18_04_5_amd64
```

### Build without Terraform ###

Each template can be built using just Packer

**Step 1: Create `variables.custom.pkr.hcl` with your values**

**Step 2:**

```bash
cd "<template_name>"
packer build -var-file=variables.custom.pkr.hcl .
```
