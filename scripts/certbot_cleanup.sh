#!/bin/sh

DNS_RG=$(az network dns zone list --query "[?name=='${CERTBOT_DOMAIN}'].resourceGroup" -o tsv)

if [ -z "${DNS_RG}" ]; then
    echo "No DNS zone found for domain ${CERTBOT_DOMAIN}!"
    exit 1
fi

echo "Cleanup removing TXT record to ${CERTBOT_DOMAIN} zone.."
az network dns record-set txt delete --resource-group "${DNS_RG}" --zone-name "${CERTBOT_DOMAIN}" --name "_acme-challenge" --yes