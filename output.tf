output "vm_id" {
  depends_on = [
    null_resource.packer_build,
  ]
  value = var.vm_id
}