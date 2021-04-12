#!/bin/sh

set -e

PWD=$0

if [ -z "${VAULT}" ]; then
    echo "Azure Key Vault name must be set in environment variable VAULT!"
    exit 1
fi

if [ -z "${DOMAINS}" ]; then
    echo "A list of comma separated domans must be set in environment variable DOMAINS!"
    exit 1
fi

if [ -z "${EMAIL}" ]; then
    echo "An email address must be set in environment variable EMAIL!"
    exit 1
fi

if [ -z "${CERT_NAME}" ]; then
    echo "Certificate name must be set in environment variable CERT_NAME!"
    exit 1
fi

if [ "${SPN_ID}" ]; then
    az login --service-principal --username "${SPN_ID}" --password "${SPN_SECRET}" --tenant "${TENANT_ID}"
else
    az login --identity
fi

VAULT_ID=$(az keyvault list --query "[?name=='${VAULT}'].id" -o tsv)
if [ -z "${VAULT_ID}" ]; then
    SUBSCRIPTION_NAME=$(az account show --query name -o tsv)

    echo "No Azure Key Vault found with the name ${VAULT} in subscription '${SUBSCRIPTION_NAME}'!"
    exit 1  
fi

echo "Got Key Vault id ${VAULT_ID}"

mkdir /data

if [ -n "${STAGING}" ]; then
    echo "Running in staging mode, using staging version of Let's Encrypt. The generated certificate will not be valid."

    certbot certonly \
        --non-interactive \
        --manual \
        --preferred-challenges dns \
        --manual-auth-hook "/scripts/certbot_auth.sh" \
        --manual-cleanup-hook "/scripts/certbot_cleanup.sh" \
        -d "${DOMAINS}" \
        -m "${EMAIL}" \
        --agree-tos \
        --test-cert
else
    certbot certonly \
        --non-interactive \
        --manual \
        --preferred-challenges dns \
        --manual-auth-hook "/scripts/certbot_auth.sh" \
        --manual-cleanup-hook "/scripts/certbot_cleanup.sh" \
        -d "${DOMAINS}" \
        -m "${EMAIL}" \
        --agree-tos
fi

CERT_PASSWORD=$(date +%s | sha256sum | base64 | head -c 64)
echo "${CERT_PASSWORD}" | openssl pkcs12 -export -out "/data/certificate.pfx" -inkey "/etc/letsencrypt/live/${DOMAINS}/privkey.pem" -in "/etc/letsencrypt/live/${DOMAINS}/cert.pem" -certfile "/etc/letsencrypt/live/${DOMAINS}/chain.pem" -passout stdin

echo "Importing certificate into key vault ${VAULT}.."
az keyvault certificate import --file "/data/certificate.pfx" --vault-name "${VAULT}" --name "${CERT_NAME}" --password "${CERT_PASSWORD}"
