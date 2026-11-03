output "nops_connection_code" {
  description = "Paste this code into nOps to finish connecting Oracle Cloud. Base64-encoded JSON with the tenancy, user, API key fingerprint and home region; it contains no secrets."
  value = base64encode(jsonencode({
    v           = 1
    tenancy     = var.tenancy_ocid
    user        = oci_identity_user.nops.id
    fingerprint = oci_identity_api_key.nops.fingerprint
    region      = local.home_region
  }))

  # nOps verifies access as soon as the code is pasted, so the code is only
  # produced once the policy, membership and capabilities are in place.
  depends_on = [
    oci_identity_policy.nops,
    oci_identity_user_group_membership.nops,
    oci_identity_user_capabilities_management.nops,
  ]
}

output "nops_user_ocid" {
  description = "OCID of the user nOps signs in as"
  value       = oci_identity_user.nops.id
}

output "nops_group_name" {
  description = "Name of the group the cost report policy grants to"
  value       = oci_identity_group.nops.name
}

output "nops_api_key_fingerprint" {
  description = "Fingerprint of the nOps API key on that user"
  value       = oci_identity_api_key.nops.fingerprint
}

output "home_region" {
  description = "The tenancy's home region, where the IAM resources were created"
  value       = local.home_region
}
