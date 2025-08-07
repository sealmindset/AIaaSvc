#!/usr/bin/env bash
# cleanup_spoke_network.sh
# -----------------------------------------------------------
# Force-removes the spoke VNet, its peerings, and the NSG that
# prevent Terraform from deleting the resource group.
#
# Usage:
#   ./scripts/cleanup_spoke_network.sh [spoke_rg] [vnet_name] [nsg_name]
# Defaults:
#   spoke_rg   = rg-ai-spoke
#   vnet_name  = vnet-ai-spoke
#   nsg_name   = nsg-ai-spoke
# -----------------------------------------------------------

set -euo pipefail

# -----------------------------------------------------------
# 0. Attempt full Terraform destroy first
# -----------------------------------------------------------

if command -v terraform >/dev/null 2>&1; then
  echo "[cleanup] Running initial 'terraform destroy -auto-approve'…"
  if terraform destroy -auto-approve; then
    echo "[cleanup] Terraform destroy completed successfully—no further action needed."
    NEED_MANUAL=0
  else
    echo "[cleanup] Terraform destroy failed—trying targeted network destroy…"
    terraform destroy \
      -target=module.network.azurerm_virtual_network.spoke \
      -target=module.network.azurerm_network_security_group.spoke \
      -auto-approve || true

    # One more attempt at full destroy
    if terraform destroy -auto-approve; then
      NEED_MANUAL=0
    else
      echo "[cleanup] Network resources still blocking RG deletion—proceeding with manual Azure CLI cleanup." >&2
      NEED_MANUAL=1
    fi
  fi
else
  echo "[cleanup] Terraform not found in PATH—skipping automated destroy attempts."
  NEED_MANUAL=1
fi

if [[ "$NEED_MANUAL" -eq 0 ]]; then
  echo "[cleanup] Terraform cleaned everything. Proceeding to verification section…"
fi

SPOKE_RG="${1:-rg-ai-spoke}"
VNET_NAME="${2:-vnet-ai-spoke}"
NSG_NAME="${3:-nsg-ai-spoke}"

echo "[cleanup] Spoke RG: $SPOKE_RG | VNet: $VNET_NAME | NSG: $NSG_NAME"

# 1. Remove VNet peerings (both directions) to unblock VNet deletion
PEERINGS=$(az network vnet peering list -g "$SPOKE_RG" --vnet-name "$VNET_NAME" --query "[].name" -o tsv || true)
for p in $PEERINGS; do
  echo "[cleanup] Deleting VNet peering: $p"
  az network vnet peering delete -g "$SPOKE_RG" --vnet-name "$VNET_NAME" -n "$p" || true
done

# 2. Delete the NSG (detach from subnets automatically)
echo "[cleanup] Deleting NSG: $NSG_NAME"
az network nsg delete -g "$SPOKE_RG" -n "$NSG_NAME" || true

# 3. Delete the VNet itself
echo "[cleanup] Deleting VNet: $VNET_NAME"
az network vnet delete -g "$SPOKE_RG" -n "$VNET_NAME" || true

# 4. (Optional) Remove private DNS zone links in hub RG (adjust RG if different)
HUB_RG="rg-network-hub"
PRIVATE_ZONES=(privatelink.azure-api.net privatelink.blob.core.windows.net privatelink.openai.azure.com)
for zone in "${PRIVATE_ZONES[@]}"; do
  LINKS=$(az network private-dns link vnet list -g "$HUB_RG" -z "$zone" --query "[].name" -o tsv 2>/dev/null || true)
  for link in $LINKS; do
    echo "[cleanup] Deleting DNS zone link $link in $zone"
    az network private-dns link vnet delete -g "$HUB_RG" -z "$zone" -n "$link" --yes || true
  done
done

echo "[cleanup] Spoke network resources removed.\n"

# -----------------------------------------------------------
# 5. Verification section
# -----------------------------------------------------------

echo "[verify] Remaining resources in spoke RG (should be empty):"
az resource list -g "$SPOKE_RG" -o table || true

echo "[verify] Resource groups in subscription (should not list $SPOKE_RG or rg-network-hub):"
az group list --query "[].name" -o table || true

echo "[verify] Remaining VNets in subscription:"
az resource list --resource-type "Microsoft.Network/virtualNetworks" \
  --query "[].{Name:name,RG:resourceGroup}" -o table || true

echo "[verify] Remaining NSGs in subscription:"
az resource list --resource-type "Microsoft.Network/networkSecurityGroups" \
  --query "[].{Name:name,RG:resourceGroup}" -o table || true

echo "[verify] Private DNS zones (subscription-wide):"
az network private-dns zone list \
  --query "[].{Name:name,RG:resourceGroup}" -o table || true

# -----------------------------------------------------------
# 6. Optional Terraform destroy to clear remaining state
# -----------------------------------------------------------

if command -v terraform >/dev/null 2>&1; then
  echo "[cleanup] Initiating 'terraform destroy -auto-approve' to clear state (if any)..."
  terraform destroy -auto-approve || true
  echo "[verify] Terraform state should now be empty:"
  terraform state list || echo "(no resources)"
else
  echo "[cleanup] Terraform not found in PATH; skipping automatic destroy."
fi
