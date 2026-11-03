# Resource Manager authenticates the provider itself. With the Terraform CLI,
# credentials come from ~/.oci/config (the DEFAULT profile unless
# config_file_profile is set).
provider "oci" {
  tenancy_ocid        = var.tenancy_ocid
  region              = var.region
  config_file_profile = var.config_file_profile
}

data "oci_identity_region_subscriptions" "home" {
  tenancy_id = var.tenancy_ocid

  filter {
    name   = "is_home_region"
    values = ["true"]
  }
}

locals {
  home_region = data.oci_identity_region_subscriptions.home.region_subscriptions[0].region_name
}

# OCI accepts IAM changes only in the tenancy's home region, so every IAM
# resource uses this provider, whichever region the stack runs in.
provider "oci" {
  alias               = "home"
  tenancy_ocid        = var.tenancy_ocid
  region              = local.home_region
  config_file_profile = var.config_file_profile
}
