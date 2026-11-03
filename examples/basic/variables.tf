variable "tenancy_ocid" {
  description = "OCID of the tenancy to connect to nOps"
  type        = string
}

variable "region" {
  description = "Region to run in. IAM resources are always created in the tenancy's home region"
  type        = string
}

variable "nops_public_key" {
  description = "The public key nOps shows when you add an Oracle Cloud integration"
  type        = string
}

variable "config_file_profile" {
  description = "Profile in ~/.oci/config to authenticate with. Defaults to DEFAULT"
  type        = string
  default     = null
}
