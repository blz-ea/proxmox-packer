import os
from proxmoxer import ProxmoxAPI, ResourceException


class Config:
    proxmox_node_name: str
    proxmox_username: str
    proxmox_password: str
    proxmox_token_name: str
    proxmox_token_value: str
    proxmox_verify_ssl: bool
    vm_id: str
    _proxmox_hostname: str

    @property
    def proxmox_hostname(self) -> str:
        return self._proxmox_hostname

    @proxmox_hostname.setter
    def proxmox_hostname(self, value: str) -> None:
        split = value.split("://")
        if len(split) == 2:
            self._proxmox_hostname = split[1]
        elif len(split) == 1:
            self._proxmox_hostname = value


def get_config() -> Config:
    new_cfg: Config = Config()
    if (proxmox_node_name := os.getenv("PKR_VAR_proxmox_node_name")) or \
            (proxmox_node_name := os.getenv("proxmox_node_name")):
        new_cfg.proxmox_node_name = proxmox_node_name

    if (proxmox_hostname := os.getenv("PKR_VAR_proxmox_hostname")) or \
            (proxmox_hostname := os.getenv("proxmox_hostname")):
        new_cfg.proxmox_hostname = proxmox_hostname

    if (verify_ssl := os.getenv("PKR_VAR_verify_ssl")) or \
            (verify_ssl := os.getenv("verify_ssl")):
        new_cfg.proxmox_verify_ssl = verify_ssl
    else:
        new_cfg.proxmox_verify_ssl = False

    if (proxmox_username := os.getenv("PKR_VAR_proxmox_username")) or \
            (proxmox_username := os.getenv("proxmox_username")):
        new_cfg.proxmox_username = proxmox_username

    if (proxmox_password := os.getenv("PKR_VAR_proxmox_password")) or \
            (proxmox_password := os.getenv("proxmox_password")):
        new_cfg.proxmox_password = proxmox_password

    if (proxmox_token_name := os.getenv("PKR_VAR_proxmox_token_name")) or \
            (proxmox_token_name := os.getenv("proxmox_token_name")):
        new_cfg.proxmox_token_name = proxmox_token_name

    if (proxmox_token_value := os.getenv("PKR_VAR_proxmox_token_value")) or \
            (proxmox_token_value := os.getenv("proxmox_token_value")):
        new_cfg.proxmox_token_value = proxmox_token_value

    if (vm_id := os.getenv("PKR_VAR_vm_id")) or \
            (vm_id := os.getenv("vm_id")):
        new_cfg.vm_id = vm_id

    return new_cfg


def validate(cfg: Config):
    errors = []

    if "proxmox_node_name" not in dir(cfg):
        errors.append("PKR_VAR_proxmox_node_name is not set")

    if "proxmox_hostname" not in dir(cfg):
        errors.append("PKR_VAR_proxmox_hostname is not set")

    if "proxmox_username" not in dir(cfg):
        errors.append("PKR_VAR_proxmox_username is not set")

    if "vm_id" not in dir(cfg):
        errors.append("PKR_VAR_vm_id is not set")

    if "proxmox_password" not in dir(cfg):
        if "proxmox_token_name" not in dir(cfg):
            errors.append("PKR_VAR_proxmox_token_name is not set")
        if "proxmox_token_value" not in dir(cfg):
            errors.append("PKR_VAR_proxmox_token_value is not set")

    if "proxmox_password" not in dir(cfg) and "proxmox_token_name" not in dir(cfg) and \
            "proxmox_token_value" not in dir(cfg):
        errors.append("PKR_VAR_proxmox_password is not set")

    if len(errors) > 0:
        raise ValueError("\n".join(errors))

    return None


def delete(cfg: Config) -> None:
    proxmox: ProxmoxAPI
    host = cfg.proxmox_hostname
    user = cfg.proxmox_username
    verify_ssl = cfg.proxmox_verify_ssl
    node_name = cfg.proxmox_node_name
    vm_id = cfg.vm_id

    if "proxmox_token_name" in dir(cfg) and "proxmox_token_value" in dir(cfg):
        print("Using API token")
        token_name = cfg.proxmox_token_name
        token_value = cfg.proxmox_token_value
        proxmox = ProxmoxAPI(host, user=user, token_name=token_name, token_value=token_value, verify_ssl=verify_ssl)
    else:
        print("Using username and password")
        password = cfg.proxmox_password
        proxmox = ProxmoxAPI(host, user=user, password=password, verify_ssl=verify_ssl)

    try:
        vm = proxmox.nodes(node_name).qemu(vm_id)
        vm_config = vm.config().get()
        vm.delete()
        print(f"Successfully deleted VM template {vm_id}")

        # if "template" in vm_config and vm_config['template'] == 1:
        # else:
        #     raise ResourceException(f"Provided VM id({vm_id}) is not a template")
    except ResourceException as err:
        print(f"Nothing to delete")
        # raise ValueError(f"Error while deleting VM template {vm_id} from {node_name}\n", err)


if __name__ == '__main__':
    config = get_config()
    validate(config)
    delete(config)
