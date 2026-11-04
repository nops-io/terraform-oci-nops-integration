locals {
  # Oracle's tenancy that holds every commercial-realm (oc1) tenancy's cost
  # reports, in Object Storage namespace "bling".
  usage_report_tenancy_ocid = "ocid1.tenancy.oc1..aaaaaaaaned4fkpkisbwjlr56u7cj63lf3wffbilvqknstgtvzub7vhqkggq"

  # Accepts the single-line base64 body or a full PEM block, including one
  # whose newlines collapsed in a single-line form field.
  nops_public_key_body = replace(replace(var.nops_public_key, "/-----(BEGIN|END) PUBLIC KEY-----/", ""), "/\\s/", "")

  nops_public_key_pem = join("\n", concat(
    ["-----BEGIN PUBLIC KEY-----"],
    regexall(".{1,64}", local.nops_public_key_body),
    ["-----END PUBLIC KEY-----"]
  ))

  # Identity domains require a primary email by default and accept duplicates,
  # so an unset user_email falls back to the deploying administrator's email.
  configured_email = var.user_email == null ? "" : var.user_email
  deployer_email   = try(coalesce(data.oci_identity_user.deployer[0].email, ""), "")
  user_email = (
    local.configured_email != "" ? local.configured_email :
    local.deployer_email != "" ? local.deployer_email :
    null
  )
}

data "oci_identity_user" "deployer" {
  count    = var.current_user_ocid == null || var.current_user_ocid == "" ? 0 : 1
  provider = oci.home
  user_id  = var.current_user_ocid
}

resource "oci_identity_group" "nops" {
  provider       = oci.home
  compartment_id = var.tenancy_ocid
  name           = var.group_name
  description    = "nOps cost report access. Members can read this tenancy's Oracle cost reports and nothing else."
}

resource "oci_identity_user" "nops" {
  provider       = oci.home
  compartment_id = var.tenancy_ocid
  name           = var.user_name
  description    = "nOps cost report access. nOps signs in as this user with an API key to read this tenancy's cost reports."
  email          = local.user_email
}

resource "oci_identity_user_group_membership" "nops" {
  provider = oci.home
  group_id = oci_identity_group.nops.id
  user_id  = oci_identity_user.nops.id
}

resource "oci_identity_api_key" "nops" {
  provider  = oci.home
  user_id   = oci_identity_user.nops.id
  key_value = local.nops_public_key_pem
}

# The provider exposes only these five capabilities. DB credentials and
# OAuth 2.0 client credentials keep OCI's defaults.
resource "oci_identity_user_capabilities_management" "nops" {
  provider = oci.home
  user_id  = oci_identity_user.nops.id

  can_use_api_keys             = true
  can_use_auth_tokens          = false
  can_use_console_password     = false
  can_use_customer_secret_keys = false
  can_use_smtp_credentials     = false
}

# Cross-tenancy statements (define, endorse) are valid only in a policy
# attached to the root compartment.
resource "oci_identity_policy" "nops" {
  provider       = oci.home
  compartment_id = var.tenancy_ocid
  name           = var.policy_name
  description    = "nOps cost report access. Lets the ${var.group_name} group read this tenancy's cost reports in Oracle's usage-report tenancy."

  statements = [
    "define tenancy usage-report as ${local.usage_report_tenancy_ocid}",
    "endorse group ${oci_identity_group.nops.name} to read objects in tenancy usage-report",
  ]
}
