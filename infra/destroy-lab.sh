#!/usr/bin/env bash
# Azure CycleCloud Training Lab Teardown Script (Bash)

RESOURCE_GROUP="rg-cyclecloud-training"
MODE="${1:-deallocate}"

if [ "$MODE" = "deallocate" ]; then
    echo -e "\033[1;33mDeallocating VM 'cc-server' in $RESOURCE_GROUP to stop compute billing...\033[0m"
    az vm deallocate -g "$RESOURCE_GROUP" -n cc-server --output table
    echo -e "\033[1;32mServer VM deallocated successfully.\033[0m"
elif [ "$MODE" = "delete" ]; then
    echo -e "\033[1;31mDeleting Resource Group '$RESOURCE_GROUP' completely...\033[0m"
    az group delete -n "$RESOURCE_GROUP" --yes --no-wait
    echo -e "\033[1;32mResource Group deletion initiated in background.\033[0m"
else
    echo "Usage: ./destroy-lab.sh [deallocate|delete]"
    exit 1
fi
