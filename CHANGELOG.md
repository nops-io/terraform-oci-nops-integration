# Changelog

All notable changes to this project will be documented in this file.

## [1.0.2] - 2026-11-03

### Added

- **Policy statement `allow group <group> to inspect organizations-entity in tenancy`.** It covers only `ListOrganizations`, so nOps can tell a child tenancy from its parent. Oracle writes an organization's cost reports only in the parent tenancy, and nOps warns when a child is connected.

### Changed

- **The user, group and policy names end in a random 6-character suffix** (`random_id`, chosen once per stack), for example `nops-cost-reports-reader-3f9a1c`. A new stack no longer fails with `Group with the same displayName already exists` when a failed or deleted (not destroyed) stack left resources behind. `user_name`, `group_name` and `policy_name` are now prefixes.
- **Requires the `hashicorp/random` provider** (>= 3.1.0).

## [1.0.1] - 2026-11-03

### Fixed

- **Creating the nOps user no longer fails in identity domains** with `The primary email must be specified`. Identity domains require a primary email by default. When `user_email` is unset, the user now gets the email of the person running the stack (read from `current_user_ocid`).

### Changed

- **`user_email` is shown in Resource Manager** as an optional field, for a team mailbox or for administrators with no email in OCI.

## [1.0.0] - 2026-11-03

### Added

- **Resource Manager stack** that connects an OCI tenancy to nOps for cost report access. The form has one visible field, `nops_public_key`; Resource Manager fills in `tenancy_ocid`, `region`, `compartment_ocid` and `current_user_ocid`.
- **IAM group** `nops-cost-reports-reader` and **IAM user** `nops-cost-reports`, created in the root compartment through a provider pinned to the tenancy's home region (found with `oci_identity_region_subscriptions`).
- **API key** on that user, built from the nOps public key. The key is accepted as the single-line base64 body or as a full PEM block, and is rebuilt into a 64-column PEM before upload. Private keys and malformed keys fail validation.
- **User capabilities** set to API keys only: console password, auth tokens, customer secret keys and SMTP credentials are turned off.
- **Root-compartment policy** with exactly two statements: `define tenancy usage-report as ocid1.tenancy.oc1..aaaaaaaaned4fkpkisbwjlr56u7cj63lf3wffbilvqknstgtvzub7vhqkggq` and `endorse group nops-cost-reports-reader to read objects in tenancy usage-report`.
- **`nops_connection_code` output**: base64-encoded JSON `{ v = 1, tenancy, user, fingerprint, region }`, shown as a copyable value on the stack's Application information tab.
- **Outputs** `nops_user_ocid`, `nops_group_name`, `nops_api_key_fingerprint` and `home_region`.
- **Optional hidden variables** `user_email` (for identity domains that require a primary email), `group_name`, `user_name`, `policy_name` and `config_file_profile` (Terraform CLI only).
- **`examples/basic`** for running the stack with the Terraform CLI instead of Resource Manager.
- **Release workflow** that validates the configuration and attaches `nops-oci-integration-stack.zip` (the `.tf` files and `schema.yaml` at the zip root) to each `v*` tag's GitHub release.
