#!/bin/bash

DNS_RG=$(az network dns zone list --query "[?name=='${CERTBOT_DOMAIN}'].resourceGroup" -o tsv)

if [ -z "${DNS_RG}" ]; then
    echo "No DNS zone found for domain ${CERTBOT_DOMAIN}!"
    exit 1
fi

echo "Adding TXT record _acme-challenge to ${CERTBOT_DOMAIN} zone with value ${CERTBOT_VALIDATION}.."
az network dns record-set txt add-record --resource-group "${DNS_RG}" --zone-name "${CERTBOT_DOMAIN}" --record-set-name "_acme-challenge" --value "${CERTBOT_VALIDATION}"

until nslookup -q=txt "_acme-challenge.${CERTBOT_DOMAIN}"
do
    ((c++)) && ((c==10)) && break # Retry up to 10 times before aborting

    echo "Waiting 5 seconds for TXT record to propagate.."

    sleep 5
done