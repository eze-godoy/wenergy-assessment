locals {
  resource_group = "kml_rg_main-eb7aba3b3d84466c"
  location       = "westus"

  admin_ips = ["190.15.219.128"]

  vnet_cidr = "10.0.0.0/16"

  web_tier_vm_count         = 2
  application_tier_vm_count = 1
}