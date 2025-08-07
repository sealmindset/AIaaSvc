
# Pre-register the needed providers

```
az provider register --namespace Microsoft.Web
az provider register --namespace Microsoft.BotService
```

# OpenAI a.k.a., CognitiveServices

```
az provider register --namespace Microsoft.CognitiveServices  --wait
```

# Optional: verify registration state

```
az provider show --namespace Microsoft.CognitiveServices --query "registrationState"
```

# Storage Account
Terraform is failing at the plan-time read of the existing diagnostics storage account because shared_access_key_enabled is still false in Azure.
The provider must query queue properties (a shared-key call) before it can update the account, so simply declaring shared_access_key_enabled = true is not enough—the read fails first.

az storage account update \
  --resource-group rg-network-hub \
  --name stdiagf0def5f7 \
  --allow-shared-key-access true


# Network
delete just those two Azure resources by ID (skips provider bugs)
  ```
az network nsg delete --ids $(az network nsg show --resource-group rg-ai-spoke --name nsg-ai-spoke --query id -o tsv)

az network vnet delete --ids $(az network vnet show --resource-group rg-ai-spoke --name vnet-ai-spoke --query id -o tsv)
```