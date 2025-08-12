# Architecture Overview

This repository provisions the secure networking, policy guardrails, and API Management (APIM) integration required to expose private Azure OpenAI to internal workloads. It is designed for a lab environment with production‑grade controls where possible.

Related repos to integrate with:
- uiaiaks: `/Users/rvance/Documents/GitHub/uiaiaks`
- uiapikms: `/Users/rvance/Documents/GitHub/uiapikms`

The sections below explain how those systems plug into the infrastructure delivered here.

## Components Provisioned by This IaC

- **Virtual Networks and Subnets**
  - Hub VNet (`vnet-hub`) and Spoke VNet (`vnet-ai-spoke`) with hub↔spoke peering.
  - Subnets: `snet-pe` (private endpoints), `snet-gateway` (APIM).

- **Network Security**
  - NSG `nsg-ai-gateway` attached to `snet-gateway`.
  - Rule `apim-mgmt-allow-3443` allows inbound TCP 3443 from `ApiManagement` service tag for APIM control‑plane.
  - Service endpoints for `Microsoft.KeyVault` and `Microsoft.Storage` on subnets.

- **Azure API Management (Internal VNet)**
  - Service: `apim-ai-internal` in `snet-gateway`.
  - API `openai-internal` (path `v1`) proxies to Azure OpenAI private endpoint.
  - Product `openai` enables self‑service subscription keys.
  - Managed identity on APIM with role `Cognitive Services OpenAI User` scoped to the OpenAI account.

- **Azure Cognitive Services (Azure OpenAI)**
  - Private networking only; optional CMK support via variables.

- **Azure Key Vault**
  - Network ACLs restricted to VNets. Intended to store OAuth/client secrets for sandbox and future integrations.

- **Azure Policy (Management Group Scope)**
  - Deny public network access for Key Vault, Storage, Cognitive Services.
  - Enforce CMK for Cognitive Services (optional toggle in lab).

- **Cleanup and Idempotency**
  - `scripts/cleanup.sh` to reliably remove lingering resources (VNets/NSGs/Network Watcher, DNS links, and any orphaned Azure Firewall/PIP).

See `doc/guardrails.md` for a complete list of security guardrails and their purpose.

## How Internal Consumers Use This

1. **Provision** this IaC (`terraform apply`).
2. **Developers/Apps** obtain an APIM subscription key for product `openai`.
3. **Call** the internal API endpoint exposed by APIM over HTTPS using the subscription key.
4. **APIM** authenticates the call via subscription key (product policy) and uses its managed identity to acquire an AAD token for Azure OpenAI.
5. **Azure OpenAI** receives the request over private networking and returns results.

Key output/inputs:
- APIM base URL: output `internal_api_base_url` from `modules/api_gateway/main.tf` (gateway URL).
- APIM product id: `openai` (linked to `openai-internal` API).
- Subscription header: `Ocp-Apim-Subscription-Key`.

## Integration with `uiaiaks`

Purpose (assumed): An application running in AKS that needs to call internal AI services.

Recommended pattern:
- **Network**: Deploy AKS into a VNet peered with the hub/spoke or into the spoke VNet, with DNS able to resolve the APIM private hostname.
- **Config**:
  - Consume APIM base URL (`internal_api_base_url`).
  - Inject APIM subscription key into app config (Kubernetes Secret or workload identity retrieval) under header `Ocp-Apim-Subscription-Key`.
- **Egress**: Ensure NSGs and routes permit AKS egress to APIM’s private endpoint and any required private DNS.
- **Call Flow**: The app calls the APIM URL; APIM handles authN to OpenAI.

Steps:
1. Obtain/issue a subscription to product `openai` for the AKS workload identity or a service principal mapped to the app’s owner.
2. Store the subscription key securely (e.g., Kubernetes Secret sourced from Key Vault; see below with `uiapikms`).
3. Configure the app to call `${APIM_BASE_URL}/v1/...` with `Ocp-Apim-Subscription-Key` header.

## Integration with `uiapikms`

Purpose (assumed): Key/secret management for applications consuming internal APIs.

Recommended pattern:
- **APIM Keys Lifecycle**: Use `uiapikms` to store and rotate APIM subscription keys assigned to internal apps.
- **Storage**: Store keys in Azure Key Vault provisioned by this IaC. Restrict access via Key Vault access policies or RBAC and VNet ACLs.
- **Distribution**: `uiapikms` can expose secure endpoints or automation to push updated keys to consuming systems (e.g., AKS via CSI driver, GitOps pipelines, or workload identity).
- **Option**: Use APIM Management API to programmatically create/disable/regenerate subscriptions, then sync to Key Vault.

Data flow example:
1. Admin/service issues a subscription to product `openai` for an internal consumer.
2. `uiapikms` records the subscription and stores the key as a KV secret.
3. The consumer (e.g., `uiaiaks` app) retrieves the key through a secure channel (KV integration or `uiapikms` broker) and uses it in outbound requests to APIM.

## Text Sequence Diagram

```
App (uiaiaks) -> APIM: HTTPS request + Ocp-Apim-Subscription-Key
APIM -> AAD: Acquire token (MSI) for Azure OpenAI
APIM -> Azure OpenAI (Private): Forward request with AAD token
Azure OpenAI -> APIM: Response
APIM -> App: Response

Admin -> APIM: Create/assign subscription to product 'openai'
APIM -> uiapikms: (optional) management API event/webhook
uiapikms -> Key Vault: Store/rotate subscription key
uiaiaks -> Key Vault/uiapikms: Retrieve key securely for runtime
```

## Environment and Configuration

- **TLS**: Managed APIM and OpenAI require HTTPS; TLS cannot be disabled. For dev, use self‑signed/trusted certs on clients if needed.
- **Variables**: Location, management group name, tags, CMK toggles. See `variables.tf` and module variables.
- **DNS**: Ensure private DNS resolution from consumer networks to APIM and OpenAI private endpoints.

## Operations

- **Provisioning**: `terraform init/plan/apply`. Use `-var enable_cmk=true` and `-var key_vault_key_id=...` to enable CMK.
- **Cleanup**: Run `scripts/cleanup.sh` to remove lingering artifacts before RG deletion.
- **Policies**: Changes at management group scope affect all child subscriptions. Ensure proper scope before apply.

## References

- `doc/guardrails.md` — security controls
- `doc/authnz.md` — APIM subscription key + MSI call pattern
- `doc/note.md` — provider registration and known issues
