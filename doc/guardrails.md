# Security Guardrails and Controls

This document summarizes the security controls implemented by this IaC and their purpose. The design targets a secure, idempotent, and cost‑aware lab environment while aligning with enterprise practices.

## Network Isolation and Access

- **API Management in VNet (Internal)**
  - Resource: `modules/api_gateway/azurerm_api_management.apim`
  - Purpose: Places APIM into a dedicated subnet (`snet-gateway`) for private access and egress control.
  - Notes: Managed gateway is HTTPS‑only; TLS cannot be disabled.

- **Network Security Group (NSG) on Gateway Subnet**
  - Resources: `modules/network/azurerm_network_security_group.gateway`, `azurerm_subnet_network_security_group_association.gateway`
  - Purpose: Enforce east‑west and north‑south egress/inbound restrictions on APIM subnet.
  - Specific rule: `azurerm_network_security_rule.apim_mgmt_inbound` allows APIM control‑plane inbound on TCP 3443 from `ApiManagement` service tag to support Internal mode deployments.

- **Service Endpoints to Key Services**
  - Resources: `modules/network/azurerm_subnet.pe`, `azurerm_subnet.gateway`
  - Purpose: Add `Microsoft.KeyVault` and `Microsoft.Storage` service endpoints to subnets to restrict access paths and support private networking.

- **Hub‑Spoke Topology (without Azure Firewall)**
  - Resources: VNet peering for hub↔spoke; Azure Firewall resources and route tables were removed by design.
  - Purpose: Simplify lab networking and avoid unnecessary costs, while allowing external firewall solutions if needed.

## Data Protection and Encryption

- **Optional Customer‑Managed Keys (CMK) for Cognitive Services**
  - Resources: `modules/ai_service` variables `enable_cmk`, `key_vault_key_id`; conditional role assignment in `identity.tf` granting crypto access when enabled.
  - Purpose: Allow enterprises to enforce CMK encryption for Azure Cognitive Services (incl. Azure OpenAI) when required.

- **Key Vault Integration**
  - Resources: `modules/network/azurerm_key_vault.kv`, key vault secrets referenced by Sandbox APIM module.
  - Purpose: Centralized and auditable storage for OAuth secrets and keys. Network ACLs restrict access to VNet subnets.

## Policy Guardrails (Management Group Scope)

- **Deny Public Network Access**
  - Resources: `modules/org_guardrails` custom policy definitions and assignments.
  - Applies to: Azure Key Vault, Storage Accounts, and Cognitive Services.
  - Purpose: Ensure services are reachable only via private networking and service endpoints/PEs.
  - Alias corrections: Cognitive Services uses `Microsoft.CognitiveServices/accounts/publicNetworkAccess`.

- **Enforce CMK for Cognitive Services**
  - Resources: Custom Azure Policy (definition + assignment) at management group scope.
  - Purpose: Require CMK usage where mandated by governance.

## Identity and Authorization

- **Managed Identity for APIM**
  - Resources: APIM `identity { type = "SystemAssigned" }` and `azurerm_role_assignment.apim_openai_user`.
  - Purpose: APIM obtains AAD tokens to call Azure OpenAI using least‑privilege role (`Cognitive Services OpenAI User`).

- **Self‑Service Subscription Keys via APIM Product**
  - Resources: `azurerm_api_management_product.openai_product`, `product_api` link, optional `azurerm_api_management_subscription.seed` for initial users.
  - Purpose: Internal consumers obtain APIM subscription keys to securely call private OpenAI endpoints through APIM.

## Diagnostics and Logging

- **Modernized Diagnostic Retention**
  - Resources: `azurerm_storage_management_policy` (replacing deprecated `retention_policy`).
  - Purpose: Enforce 90‑day log/data retention without using deprecated constructs.

## Cleanup and Idempotency

- **Automated Cleanup Script**
  - File: `scripts/cleanup.sh`
  - Purpose: Removes lingering resources (VNets, NSGs, Network Watcher, private DNS links) that can block RG deletion and cause costs.
  - Firewall cleanup: Deletes any orphaned Azure Firewall (`fw-hub`) and its Public IP (`pip-fw-hub`) across hub RGs via `HUB_RGS`, with extension auto‑install and non‑interactive fallbacks.

- **Provider Features and Known Behaviors**
  - Provider: `azurerm ~> 3.109`; features enable safer RG deletions with nested resources.
  - Notes: Large network/RG changes may show transient provider inconsistencies—targeted re‑apply may be required.

## Secure Defaults and Environment Separation

- **Secure Defaults**
  - Public network access denied by policy for KV, Storage, Cognitive Services.
  - APIM in VNet Internal mode with explicit NSG controls.
  - Optional CMK off by default for lab simplicity; enable via variables when needed.

- **Environment Awareness**
  - Variables and tags (`var.tags`) used consistently; plan/apply intended to be idempotent.
  - Separate RGs for hub (`rg-network-hub`) and spoke (`rg-ai-spoke`).

## Notable Non‑Goals in Lab

- **Azure Firewall**: Removed from Terraform to avoid cost and complexity; external firewall solutions may be used.
- **Defender for Cloud**: Placeholder module only; does not enable plans or subscribe in lab.
- **Disabling TLS**: Managed APIM and Azure OpenAI require HTTPS; TLS cannot be disabled.

## Operational Notes

- Run `scripts/cleanup.sh` before deleting RGs to ensure all dependent network artifacts are removed.
- For APIM VNet deployments, ensure NSG rule allowing TCP 3443 from `ApiManagement` (control‑plane) exists.
- Provider registration (e.g., `Microsoft.CognitiveServices`) must be handled outside Terraform.
