# Resource Manager fills in tenancy_ocid, region, compartment_ocid and
# current_user_ocid. Set tenancy_ocid and region yourself when you run the
# Terraform CLI.

variable "tenancy_ocid" {
  description = "OCID of the tenancy to connect to nOps. Resource Manager fills this in."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.tenancy\\.oc1\\.\\.[a-z0-9]+$", var.tenancy_ocid))
    error_message = "The tenancy_ocid value must be a commercial-realm tenancy OCID (ocid1.tenancy.oc1..). Other realms are not supported yet."
  }
}

variable "region" {
  description = "Region the stack runs in. Resource Manager fills this in. IAM resources are always created in the tenancy's home region."
  type        = string

  validation {
    condition     = can(regex("^[a-z]+(-[a-z]+)+-[0-9]+$", var.region))
    error_message = "The region value must be an OCI region identifier, such as us-ashburn-1."
  }
}

variable "compartment_ocid" {
  description = "Filled in by Resource Manager. Not used: every resource this stack creates is in the root compartment."
  type        = string
  default     = null
}

variable "current_user_ocid" {
  description = "Filled in by Resource Manager. Not used."
  type        = string
  default     = null
}

variable "nops_public_key" {
  description = "The public key nOps shows when you add an Oracle Cloud integration. Paste the single-line value as shown; a full PEM block (-----BEGIN PUBLIC KEY----- ...) also works."
  type        = string

  validation {
    condition     = !can(regex("PRIVATE KEY", var.nops_public_key))
    error_message = "This is a private key. Paste the public key that nOps shows, and never share a private key."
  }

  # Validations cannot read locals before Terraform 1.9, so this repeats the
  # normalization in local.nops_public_key_body (main.tf).
  validation {
    condition = can(regex(
      "^MII[A-Za-z0-9+/]{3}ANBgkqhkiG9w0BAQEF(?:[A-Za-z0-9+/]{4}){80,}(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$",
      replace(replace(var.nops_public_key, "/-----(BEGIN|END) PUBLIC KEY-----/", ""), "/\\s/", "")
    ))
    error_message = "The nops_public_key value must be the RSA public key that nOps shows: its single-line value, or the full PEM block (-----BEGIN PUBLIC KEY----- ... -----END PUBLIC KEY-----). Check that nothing was cut off when you copied it."
  }
}

variable "user_email" {
  description = "Optional primary email for the nOps user. Leave unset unless your identity domain requires a primary email on every user; then use a mailbox your team owns."
  type        = string
  default     = null

  validation {
    condition     = var.user_email == null || can(regex("^$|^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.user_email))
    error_message = "The user_email value must be an email address, or left unset."
  }
}

variable "group_name" {
  description = "Name of the IAM group that the policy grants cost report access to."
  type        = string
  default     = "nops-cost-reports-reader"

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]{1,100}$", var.group_name))
    error_message = "The group_name value may contain only letters, digits, '.', '_' and '-' (at most 100 characters), so the policy can name it without quotes."
  }
}

variable "user_name" {
  description = "Name of the IAM user that nOps signs in as."
  type        = string
  default     = "nops-cost-reports"

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]{1,100}$", var.user_name))
    error_message = "The user_name value may contain only letters, digits, '.', '_' and '-' (at most 100 characters)."
  }
}

variable "policy_name" {
  description = "Name of the root-compartment policy that grants cost report access."
  type        = string
  default     = "nops-cost-reports-policy"

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]{1,100}$", var.policy_name))
    error_message = "The policy_name value may contain only letters, digits, '.', '_' and '-' (at most 100 characters)."
  }
}

variable "config_file_profile" {
  description = "Terraform CLI only: profile in ~/.oci/config to authenticate with. Defaults to the DEFAULT profile. Resource Manager ignores it."
  type        = string
  default     = null
}
