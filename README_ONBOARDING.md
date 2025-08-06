# Azure OpenAI – Subscriber On-Boarding Guide

This document walks a new **subscriber** (team, application, or business unit) through provisioning their own isolated instance of the Azure OpenAI service stack using this Terraform project.

---

## 1. Prerequisites

| Requirement | Version / Notes |
|-------------|-----------------|
| Terraform   | `>= 1.9` |
| Azure CLI   | Latest – authenticated to the target tenant & subscription (`az login`) |
| Access      | *Owner* (or equivalent) on the destination subscription + permission to create management-group assignments |

> 💡 **State Storage** – For production, configure a remote backend (e.g., Azure Storage, Terraform Cloud).  The sample below uses local state for simplicity.

---

## 2. Repository Structure (High-Level)

```
├── main.tf                # root stack wiring
├── variables.tf           # global variables
├── terraform.tfvars.example
├── modules/
│   ├── network/           # hub-spoke, DNS, NSG, Key Vault & CMK
│   ├── ai_service/        # Azure OpenAI cognitive account
│   ├── api_gateway/       # Private APIM + policies
│   └── observability/     # Log Analytics + Diagnostics
└── docs/
    └── (this file)
```

---

## 3. Prepare Your Inputs

Copy the example tfvars file and edit values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Key variables:

| Variable | Description |
|----------|-------------|
| `mg_name` | Name for the management-group that will contain the subscription (e.g., `mg-ai`) |
| `allowed_locations` | List of Azure regions subscribers may deploy to (must include the region you pick for `location`) |
| `location` | **Primary region** where resources will be created (e.g., `eastus2`) |
| `tags` | Map of common tags applied to all resources |

Each subscriber may tweak address spaces / naming if you allow multi-instance deployments.

---

## 4. First-Time Deployment

```bash
# 1. Initialise providers and modules
terraform init

# 2. Review the plan
terraform plan -out tfplan

# 3. Apply
terraform apply "tfplan"
```

Expected actions (~40 resources):
* Management-group & policy assignments
* Hub & spoke VNets + peering
* Key Vault + customer-managed key (CMK)
* Private DNS zones & links
* Azure OpenAI cognitive account (with CMK)
* Private APIM (Premium tier)
* Diagnostic settings for KV, OpenAI, APIM, VNet

Provisioning takes ~20 minutes.

---

## 5. Post-Deployment Steps

1. **Model Deployment** – Use the Azure Portal or REST API to deploy models (GPT-4o, Embeddings, etc.) inside the new OpenAI account.
2. **APIM Key Management** – Generate or assign subscription keys for callers; apply rate-limits & CORS policies as needed.
3. **DNS Validation** – Confirm VMs/functions in the spoke resolve:
   * `*.openai.azure.com` → private endpoint IP
   * `*.azure-api.net` (APIM private link)
4. **Quota Requests** – Submit capacity requests if you need higher model throughput.

---

## 6. On-Boarding an Additional Subscriber

If each subscriber requires a **separate VNet, RG, and OpenAI account**, you have two patterns:

1. **Workspaces/Workdirs** – Clone the repo per subscriber and set distinct `terraform.tfstate` backends.
2. **Meta Module Loop** – Wrap the root module in a higher-level module and iterate over a list of subscribers, passing a unique prefix/address-space per instance.

> Ensure address spaces do not overlap.  Update `allowed_locations` and hub peering rules if you add new regions.

---

## 7. Cleanup / Destroy

```bash
terraform destroy -auto-approve
```

⚠️ This deletes *all* resources managed by this stack, including management-group assignments.

---

## 8. Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| `Error: The "for_each" set includes values derived from resource attributes ...` | List passed where map with static keys expected | Confirm diagnostics `resources_to_monitor` uses a map with known keys |
| `The client '...appId...' with object id does not have authorization to perform action 'Microsoft.KeyVault/vaults/deploy/action'` | Managed identity missing CMK permissions | Verify `azurerm_role_assignment.openai_kv_crypto` applied correctly |
| Private DNS names not resolving | DNS zone link missing or VNet not using Azure-provided DNS | Re-apply, or set VNet DNS to `168.63.129.16` |

---

