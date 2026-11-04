# OCI nOps Integration Terraform Stack

This Terraform stack connects an Oracle Cloud Infrastructure (OCI) tenancy to nOps so that nOps can read the tenancy's cost reports. It automatically:
- **Creates an IAM user** (`nops-cost-reports`) that nOps signs in as. The user can use API keys and nothing else.
- **Uploads the nOps public key** as that user's API key. nOps keeps the private key; you never handle it.
- **Creates an IAM group** (`nops-cost-reports-reader`) and adds the user to it
- **Creates a root-compartment policy** that lets the group read the tenancy's cost reports, and nothing else
- **Outputs a connection code** that you paste into nOps to finish connecting

You paste one value (the nOps public key) and copy one value back (the connection code).

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/nops-io/terraform-oci-nops-integration/releases/download/v1.0.0/nops-oci-integration-stack.zip)

## Module Structure

The stack code is organized into separate files:
- **`versions.tf`** - Terraform and OCI provider version constraints
- **`provider.tf`** - The default provider, the home-region lookup, and the `oci.home` provider that every IAM resource uses
- **`variables.tf`** - Input variables and their validation
- **`main.tf`** - The group, user, membership, API key, user capabilities and policy
- **`outputs.tf`** - The connection code and a few identifiers of what was created
- **`schema.yaml`** - The Resource Manager form: one visible field, and the connection code as a copyable output
- **`examples/basic`** - Running the stack with the Terraform CLI instead of Resource Manager

## Overview

The stack creates these resources, all in the root compartment and all through the tenancy's home region:

| Resource | Default name | Purpose |
|----------|--------------|---------|
| `oci_identity_user` | `nops-cost-reports` | The identity nOps signs in as |
| `oci_identity_api_key` | - | The nOps public key, uploaded to that user |
| `oci_identity_user_capabilities_management` | - | Allows API keys and turns off every other credential type the provider can manage |
| `oci_identity_group` | `nops-cost-reports-reader` | The group the policy grants to |
| `oci_identity_user_group_membership` | - | Adds the user to the group |
| `oci_identity_policy` | `nops-cost-reports-policy` | The two statements below |

**Policy statements (the only access granted):**

```
define tenancy usage-report as ocid1.tenancy.oc1..aaaaaaaaned4fkpkisbwjlr56u7cj63lf3wffbilvqknstgtvzub7vhqkggq
endorse group nops-cost-reports-reader to read objects in tenancy usage-report
```

## Least Privilege

- **Only cost reports.** Oracle writes each tenancy's cost reports into Oracle's own `usage-report` tenancy, in Object Storage namespace `bling`, in a bucket named after your tenancy OCID. The `define` statement names that tenancy, and the `endorse` statement lets the nOps group read objects there. These are the statements from Oracle's [Cost and Usage Reports](https://docs.oracle.com/en-us/iaas/Content/Billing/Concepts/costusagereportsoverview.htm) documentation.
- **No access to your own resources.** No statement grants anything in your tenancy: nOps cannot list or read your compartments, Object Storage buckets, compute, networking, databases or IAM.
- **Root compartment only because OCI requires it.** Cross-tenancy statements (`define`, `endorse`) are valid only in a policy attached to the root compartment.
- **API keys only.** The user cannot sign in to the Console and cannot use auth tokens, customer secret keys or SMTP credentials. The OCI provider does not expose the DB credentials and OAuth 2.0 client credentials capabilities, so those keep OCI's defaults; they give no access on their own, because every OCI permission comes from a policy and the only policy naming this group is the one above.
- **You hold the off switch.** Destroying the stack deletes the user and its API key, which ends nOps's access.

## Prerequisites

- An OCI tenancy in the commercial realm (`oc1`). Government and other realms are not supported yet.
- A tenancy administrator (a member of the tenancy's `Administrators` group) to run the stack. The stack creates IAM users, groups and root-compartment policies.
- Your home region. IAM changes are accepted only in the home region; the stack sends them there even if you run it elsewhere, but run it in the home region so the stack sits with what it manages.
- The public key nOps shows when you add an Oracle Cloud integration.
- For the Terraform CLI path only: [Terraform](https://www.terraform.io/) or [OpenTofu](https://opentofu.org/) >= 1.0, and an [OCI CLI configuration file](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/sdkconfig.htm) (`~/.oci/config`) for a tenancy administrator.

## Usage

### Option 1: Resource Manager (recommended)

1. In nOps, add an Oracle Cloud integration and copy the public key it shows.
2. Select **Deploy to Oracle Cloud** above and sign in to the OCI Console as a tenancy administrator. If the Console opens in another region, switch to your home region.
3. On **Create stack**, accept the Oracle Terms of Use if asked, keep or change the stack name and compartment (the stack can live in any compartment; what it creates goes in the root compartment), and select **Next**.
4. Paste the key into **nOps public key** and select **Next**.
5. On **Review**, leave **Run apply** selected and select **Create**.
6. When the apply job succeeds (usually within a minute or two), open the stack's **Application information** tab and copy **nOps connection code**. The job's **Outputs** list shows the same value as `nops_connection_code`.
7. Paste the code into nOps and select **Verify**. New API keys and policies can take a few minutes to apply, so if verification fails right away, wait and select **Verify** again.

### Option 2: Terraform CLI

Use [`examples/basic`](examples/basic) if you do not use Resource Manager:

```bash
git clone https://github.com/nops-io/terraform-oci-nops-integration.git
cd terraform-oci-nops-integration/examples/basic

cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: tenancy_ocid, region and nops_public_key

terraform init
terraform plan
terraform apply

terraform output -raw nops_connection_code
```

The provider authenticates with the `DEFAULT` profile in `~/.oci/config`; set `config_file_profile` to use another profile. To call the stack from your own configuration, use `source = "git::https://github.com/nops-io/terraform-oci-nops-integration.git?ref=v1.0.0"`. The stack configures its own OCI providers, so call it without a `providers` argument, and without `count`, `for_each` or `depends_on`.

### The connection code

`nops_connection_code` is base64-encoded JSON:

```json
{"fingerprint":"aa:bb:...","region":"us-ashburn-1","tenancy":"ocid1.tenancy.oc1..","user":"ocid1.user.oc1..","v":1}
```

It names the tenancy, the nOps user, the API key fingerprint and the home region. It contains no secrets. `v` is the format version.

## Input Variables

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `nops_public_key` | The public key nOps shows when you add an Oracle Cloud integration: the single-line base64 value, or a full PEM block. Private keys and keys that are not RSA public keys fail validation | `string` | - | yes |
| `tenancy_ocid` | OCID of the tenancy to connect (`ocid1.tenancy.oc1..`). Resource Manager fills it in | `string` | - | yes |
| `region` | Region the stack runs in. Resource Manager fills it in. IAM resources always go to the home region | `string` | - | yes |
| `compartment_ocid` | Filled in by Resource Manager. Not used | `string` | `null` | no |
| `current_user_ocid` | Filled in by Resource Manager. Its email is the default for `user_email` | `string` | `null` | no |
| `user_email` | Primary email for the nOps user. Unset, it is the email of the user running the stack (see [Identity Domains](#identity-domains)) | `string` | `null` | no |
| `group_name` | Name of the IAM group | `string` | `"nops-cost-reports-reader"` | no |
| `user_name` | Name of the IAM user | `string` | `"nops-cost-reports"` | no |
| `policy_name` | Name of the root-compartment policy | `string` | `"nops-cost-reports-policy"` | no |
| `config_file_profile` | Terraform CLI only: profile in `~/.oci/config`. Resource Manager ignores it | `string` | `null` | no |

In Resource Manager only `nops_public_key` and `user_email` are shown; the other variables are hidden and keep their defaults.

## Outputs

| Output | Description |
|--------|-------------|
| `nops_connection_code` | The code to paste into nOps (see [The connection code](#the-connection-code)) |
| `nops_user_ocid` | OCID of the user nOps signs in as |
| `nops_group_name` | Name of the group the policy grants to |
| `nops_api_key_fingerprint` | Fingerprint of the nOps API key on that user |
| `home_region` | The tenancy's home region, where the IAM resources were created |

## Identity Domains

Newer tenancies use IAM identity domains. The stack creates the user and group in the Default domain through the IAM API (`oci_identity_user`, `oci_identity_group`), and the policy refers to the group by name, which OCI resolves in the Default domain.

Identity domains require a primary email on every user by default (the domain setting **Primary email address required**), and creating a user without one fails with `The primary email must be specified`. Duplicate emails are accepted, so:
- In Resource Manager, leave **Email for the nOps user** blank to use the email of the person running the stack (`current_user_ocid`), or enter a mailbox your team owns.
- With the Terraform CLI, `current_user_ocid` is usually unset, so set `user_email`.

Setting an email can make the domain send that mailbox a welcome message; the nOps user still cannot sign in to the Console. If the person running the stack is federated and has no email in OCI, enter one.

## Verifying in a Test Tenancy

These steps prove that the stack grants exactly what nOps needs. Run them in a test tenancy, with your own key pair instead of the one from nOps, so that you hold the private key.

1. **Make a key pair and run the stack with its public key:**

   ```bash
   openssl genrsa -out nops-test-key.pem 2048
   openssl rsa -in nops-test-key.pem -pubout -out nops-test-key.pub.pem

   # The single-line value, as nOps shows it
   grep -v -- '-----' nops-test-key.pub.pem | tr -d '\n'; echo
   ```

   Paste that value (or the whole `nops-test-key.pub.pem`) as **nOps public key**, then apply.

2. **Decode the connection code and check the fingerprint:**

   ```bash
   echo '<nops_connection_code>' | base64 --decode; echo
   openssl rsa -in nops-test-key.pem -pubout -outform DER | openssl md5 -c
   ```

   The two fingerprints must match.

3. **Add a profile for the nOps user** to `~/.oci/config`, using the values from the decoded code:

   ```ini
   [NOPS_TEST]
   user=<user>
   fingerprint=<fingerprint>
   tenancy=<tenancy>
   region=<region>
   key_file=/path/to/nops-test-key.pem
   ```

4. **Check that the key works:**

   ```bash
   oci os ns get --profile NOPS_TEST
   ```

   Expect `{"data": "<namespace>"}`: your tenancy's own Object Storage namespace, not `bling`. Any authenticated user can make this call, so it proves the user, key and fingerprint, not the policy. A `NotAuthenticated` (401) error means the key, fingerprint or user is wrong, or the key has not applied yet; wait a minute and retry.

5. **Check that the policy grants the cost reports:**

   ```bash
   oci os object list --namespace bling --bucket-name <tenancy OCID> \
     --prefix "FOCUS Reports/" --region <home region> --profile NOPS_TEST
   ```

   Expect a list of objects (it can be empty, see below). A `NotAuthorizedOrNotFound` (404) error means the policy is missing or has not applied yet.

6. **Check that one report can be read,** using a name from the list:

   ```bash
   oci os object head --namespace bling --bucket-name <tenancy OCID> \
     --name "<object name>" --region <home region> --profile NOPS_TEST
   ```

7. **Check that nothing else is granted.** Both calls must fail with an authorization error:

   ```bash
   oci os bucket list --compartment-id <tenancy OCID> --profile NOPS_TEST
   oci iam user list --compartment-id <tenancy OCID> --profile NOPS_TEST
   ```

   In the Console, the user's details page must show API keys as the only allowed credential.

8. **Check for drift:** run a plan (a Resource Manager **Plan** job, or `terraform plan`). Expect no changes.

Oracle generates cost reports about every 6 hours, and they can lag by up to 24 hours, so a new tenancy may have none on its first day. Tenancies that are not metered get no cost reports at all. An empty listing in step 5 still proves access.

When you are done, destroy the stack (see below) and delete the test key pair.

## Offboarding

**Resource Manager:** open the stack, select **Destroy**, and confirm. The destroy job deletes the policy, the API key, the group membership, the user and the group, which ends nOps's access. You can then delete the stack itself (**More actions** > **Delete stack**), and remove the integration in nOps.

**Terraform CLI:** run `terraform destroy` in the directory you applied from.

## Permissions Required

The person running the stack needs to:
- List the tenancy's region subscriptions (to find the home region)
- Create and delete IAM users, groups and group memberships in the root compartment
- Upload and delete API keys, and update user capabilities, for the nOps user
- Create and delete policies in the root compartment, including cross-tenancy (`define`, `endorse`) statements
- Create stacks and run jobs in Resource Manager (Resource Manager path only)

Members of the tenancy's `Administrators` group have all of these.

## Troubleshooting

### Error: the `nops_public_key` validation fails

Copy the key from nOps again. It is one line that starts with `MII`; a full PEM block also works. A private key is always rejected.

### Error: "409-Conflict" or a name that already exists

A user, group or policy with the same name already exists, usually from an earlier run of this stack. Destroy the earlier stack, or delete those resources, and apply again. With the Terraform CLI you can set `user_name`, `group_name` and `policy_name` instead.

### Error: creating the user fails with an email error

The error reads `The primary email must be specified`. Your identity domain requires a primary email and the stack could not find yours. Enter **Email for the nOps user** and apply again. See [Identity Domains](#identity-domains).

### nOps reports that it cannot read the cost reports

New API keys and policies can take a few minutes to apply; select **Verify** in nOps again after a few minutes. If it still fails, check that the stack's apply job succeeded and that the policy shows both statements.

## Limitations

- Commercial realm (`oc1`) tenancies only
- One tenancy per stack
- In Resource Manager, the optional variables are hidden in this version

## Releasing

1. Update `VERSION`, add a section for the version to `CHANGELOG.md`, and update the Deploy to Oracle Cloud link in this README.
2. Push a tag `vX.Y.Z` that matches `VERSION`.

The release workflow validates the configuration, builds `nops-oci-integration-stack.zip` with the `.tf` files and `schema.yaml` at the zip root, and attaches it to the tag's GitHub release. nOps pins each release's asset URL, so never replace the asset of an existing release; cut a new version instead.

## Support

For issues or questions, please contact nOps Support.
