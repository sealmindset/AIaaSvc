# Azure OpenAI as a Service

## High-level resource inventory
(✔ = always deployed, (opt) = only when create_sandbox =true)

1. Resource groups
- rg-ai-spoke, rg-network-hub, rg-observability, etc. (✔)
- rg-apim-sandbox-* (opt)

2. Network layer
- Spoke VNet + subnets, NSG, private-link service/endpoints (✔)
- VNet peering to hub (✔)
- Optional cleanup script to force-delete VNets/NSGs.

3. API layer
- Azure API Management (apim-prod) with:
  - System-assigned managed identity (MSI)
  - Private endpoint to VNet
  - Product openai-product, seed subscriptions (azurerm_api_management_subscription)
  - Inbound policy (
policies/openai.xml
) performing MI-token acquisition.
  - Sandbox APIM (apim-sandbox-*) + OAuth2 IdP + product/subscription (opt).

4. Compute / data
- Azure Cognitive Services – OpenAI private endpoint (referenced, not created here)
- No Azure Functions/AKS/VMs—API traffic is proxied by APIM.

5. Observability
- Log Analytics workspace (365-day retention)
-Storage account (Standard_GRS, TLS 1.2, shared-key enabled)
- azurerm_monitor_diagnostic_setting streaming logs/metrics to both LAW and Storage
azurerm_storage_management_policy deleting blobs after 90 days.

6. IAM
- APIM MSI role assignment on the OpenAI resource
- Seed subscriptions linked to AAD users (initial_user_object_ids)
- Role-based access for diagnostics via inherited tags/resource-groups.

7. Scalability & ceilings
| Component	| Scale Units	| Ceiling / Notes |
| --- | --- | --- |
| APIM (Developer_1 SKU) | 1 single-unit dev instance | Good for 1–5 RPS bursts only; not production-grade. For prod you’d switch to Consumption (serverless) or Premium/Dedicated with scale-out to 20 units per region. |
| Cognitive Services (OpenAI) | Throughput tokens / RPM | Governed by Azure OpenAI capacity and per-deployment limits. VNet + private endpoint has no impact on scale. |
| Log Analytics | Ingest GB/day | Automatic behind-the-scenes scale; cost grows linearly. |
| Storage | 5 PB soft limit | GRS handles redundancy; lifecycle rule prunes after 90 days. |
| VNets / private endpoints | 65k IPs per VNet | Peering can hit 500 peerings/VNet; well below ceiling here. |

If higher load is expected, upgrade APIM SKU, enable autoscale rules, or move heavy workloads to AKS/Functions.

8. Security safeguards
- Network isolation – All critical services (APIM, OpenAI, Storage) use private endpoints in a locked-down spoke VNet with NSG rules; no open internet ingress.
- Managed identity – APIM uses MSI to obtain AAD tokens for backend calls; no secrets stored in code.
- Least-privilege IAM – Role assignment scoped to OpenAI resource only; seed subscriptions limited to APIM product.
- Encryption –
  - Storage account: infrastructure encryption + TLS 1.2, public-access disabled.
  - All service-level encryption at rest (Azure default) + TLS in transit.
- Logging & audit – Diagnostic settings stream control/operation logs and metrics to immutable storage and LAW; retention + lifecycle enforce secure archival.
Soft delete / RG deletion safeguards – Provider feature flag still permits deletion even with nested resources, but cleanup script removes blockers first.

9. HIPAA-readiness assessment
Azure services used (API Management, Storage, Log Analytics, VNet, Private Link, Cognitive Services) are all covered under the Microsoft BAA and appear on the Azure HIPAA-HITRUST compliance list. Meeting HIPAA obligations still requires:

- BAA signed with Microsoft (customer responsibility).
- PHI encryption – already met (AES-256 at rest, TLS1.2+ in flight).
- Access controls & auditing – AAD RBAC + diagnostic logs satisfy.
- Data retention & disposal – 90-day log lifecycle and Terraform destroy workflow comply.
- Backup & DR – GRS storage, APIM dev SKU has no SLA; for HIPAA production you’d use Premium with multi-region redundancy.
- Incident response – Not coded; policy/procedures required externally.

The stack can be HIPAA-compliant if you (a) switch APIM to a production SKU, (b) ensure BAA coverage, and (c) maintain org-level policies.

10. Gaps & recommendations
- Production SKU & autoscale – Developer tier unsuitable for load or SLA; plan migration path.
- WAF / DDoS – Consider Azure Front Door or Application Gateway WAF in front of APIM if exposed publicly.
- CI/CD – Use terraform plan in CI to catch drift; run terraform validate & tflint.
- Policies – Add Azure Policy definitions for tag compliance, allowed SKUs, & HIPAA controls.
- Sandbox toggle – Verify create_sandbox defaults false in prod pipeline to avoid unintended costs.

Overall the design follows best practices for private, secure access to Azure OpenAI via APIM and scales to moderate workloads; lifting ceilings primarily hinges on upgrading the APIM tier and ensuring OpenAI capacity quotas.