#!/usr/bin/env bash
# Azure CycleCloud Training Lab Deployment Script (Bash)

set -e

RESOURCE_GROUP="rg-cyclecloud-training"
LOCATION="koreacentral"
KEY_PATH="../keys/cyclecloud_rsa"

echo -e "\033[1;36m=====================================================\033[0m"
echo -e "\033[1;36m Azure CycleCloud Training Lab Deployment Script\033[0m"
echo -e "\033[1;36m=====================================================\033[0m"

# 1. Azure Login Check
echo -e "\n\033[1;33m[1/6] Checking Azure CLI authentication...\033[0m"
if ! az account show > /dev/null 2>&1; then
    echo -e "\033[1;31mAzure CLI is not logged in. Please run 'az login' first.\033[0m"
    exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "Active Subscription ID: $SUBSCRIPTION_ID"

# 2. Accept Marketplace Terms
echo -e "\n\033[1;33m[2/6] Accepting Azure CycleCloud Marketplace terms...\033[0m"
az vm image terms accept --urn azurecyclecloud:azure-cyclecloud:cyclecloud8-gen2:latest --output none || true

# 3. Prepare SSH Key
echo -e "\n\033[1;33m[3/6] Ensuring SSH keypair exists...\033[0m"
mkdir -p "$(dirname "$KEY_PATH")"
if [ ! -f "$KEY_PATH" ]; then
    echo "Generating SSH key at $KEY_PATH..."
    ssh-keygen -t rsa -b 4096 -f "$KEY_PATH" -N ""
fi
PUB_KEY=$(cat "${KEY_PATH}.pub")

# 4. Get Current Client IP
echo -e "\n\033[1;33m[4/6] Fetching current public IP...\033[0m"
MY_IP=$(curl -s --max-time 5 https://api.ipify.org || echo "*")
if [ "$MY_IP" != "*" ]; then
    ALLOWED_CIDR="${MY_IP}/32"
else
    ALLOWED_CIDR="*"
fi
echo "Allowed SSH Source IP set to: $ALLOWED_CIDR"

# 5. Create Resource Group and Deploy Bicep
echo -e "\n\033[1;33m[5/6] Deploying infrastructure via Bicep template...\033[0m"
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output table

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOYMENT_JSON=$(az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --name "cyclecloud-lab-deploy" \
    --template-file "$SCRIPT_DIR/main.bicep" \
    --parameters adminSshPublicKey="$PUB_KEY" allowedSshCidr="$ALLOWED_CIDR" \
    --output json)

PRINCIPAL_ID=$(echo "$DEPLOYMENT_JSON" | jq -r '.properties.outputs.principalId.value')
PORTAL_URL=$(echo "$DEPLOYMENT_JSON" | jq -r '.properties.outputs.portalUrl.value')
SERVER_IP=$(echo "$DEPLOYMENT_JSON" | jq -r '.properties.outputs.serverPublicIp.value')

# 6. Assign Contributor Role to Managed Identity
echo -e "\n\033[1;33m[6/6] Assigning 'Contributor' role to CycleCloud Managed Identity...\033[0m"
sleep 5
az role assignment create \
    --assignee-object-id "$PRINCIPAL_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "Contributor" \
    --scope "/subscriptions/$SUBSCRIPTION_ID" \
    --output table

echo -e "\n\033[1;32m=====================================================\033[0m"
echo -e "\033[1;32m Lab Environment Deployment Completed Successfully!\033[0m"
echo -e "\033[1;32m=====================================================\033[0m"
echo -e "\033[1;36m CycleCloud Portal URL : $PORTAL_URL\033[0m"
echo -e "\033[1;36m Server Public IP     : $SERVER_IP\033[0m"
echo -e "\033[1;36m Resource Group       : $RESOURCE_GROUP\033[0m"
echo -e "\033[1;36m SSH Command          : ssh -i $KEY_PATH azureadmin@$SERVER_IP\033[0m"
echo -e "\033[1;32m=====================================================\033[0m"
