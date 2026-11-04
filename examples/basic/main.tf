terraform {
  required_version = ">= 1.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0.0"
    }
  }
}

# The stack configures its own OCI providers (one for var.region and one for
# the tenancy's home region), so call it without a providers argument.
# Credentials come from ~/.oci/config.
module "nops_oci_integration" {
  source = "../.." # or "git::https://github.com/nops-io/terraform-oci-nops-integration.git?ref=v1.0.2"

  # Required
  tenancy_ocid    = var.tenancy_ocid    # Your tenancy OCID (ocid1.tenancy.oc1..)
  region          = var.region          # Any region your tenancy subscribes to; IAM changes go to the home region
  nops_public_key = var.nops_public_key # The public key nOps shows when you add an Oracle Cloud integration

  # Optional: profile in ~/.oci/config to authenticate with (default: DEFAULT)
  config_file_profile = var.config_file_profile

  # Identity domains require a primary email on every user; use a mailbox your team owns
  # user_email = "cloud-team@example.com"
}

# Outputs
output "nops_connection_code" {
  description = "Paste this code into nOps to finish connecting Oracle Cloud"
  value       = module.nops_oci_integration.nops_connection_code
}

output "nops_user_ocid" {
  description = "OCID of the user nOps signs in as"
  value       = module.nops_oci_integration.nops_user_ocid
}

output "nops_api_key_fingerprint" {
  description = "Fingerprint of the nOps API key on that user"
  value       = module.nops_oci_integration.nops_api_key_fingerprint
}

output "home_region" {
  description = "The tenancy's home region, where the IAM resources were created"
  value       = module.nops_oci_integration.home_region
}
