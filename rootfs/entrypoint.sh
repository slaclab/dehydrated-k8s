#!/bin/bash

export KUBECONFIG=/etc/dehydrated/kube/kubeconfig
export DOMAINS_TXT_DATA=$(cat /etc/dehydrated/domains/domains.txt | tr -d '\n')

if [[ -z ${DOMAINS_TXT_DATA} ]]; then
   echo "No domains.txt found"
   exit 0
fi

if [[ -n $(cat /etc/dehydrated/domains/email | tr -d '\n') ]]; then
   export DEHYDRATED_CONTACT_EMAIL=$(cat /etc/dehydrated/domains/email | tr -d '\n')
fi

if [[ -n $(cat /etc/dehydrated/domains/staging | tr -d '\n') ]]; then
   export DEHYDRATED_STAGING=$(cat /etc/dehydrated/domains/staging | tr -d '\n')
fi

if [[ -n $(cat /etc/dehydrated/domains/secret | tr -d '\n') ]]; then
   export DOMAIN_SECRET=$(cat /etc/dehydrated/domains/secret | tr -d '\n')
fi

echo "Contact email ${DEHYDRATED_CONTACT_EMAIL}"
echo "Staging ${DEHYDRATED_STAGING}"
echo "Secret to manage: ${DOMAIN_SECRET}"

set -a
. /etc/dehydrated/config
set +a

if kubectl get secret "${DOMAIN_SECRET}" > /dev/null 2>&1; then
  mkdir -p "${CERTDIR}/${DOMAINS_TXT_DATA}"
  # unstage secret and decompose tls.crt (fullchain.pem)
  kubectl get secret "${DOMAIN_SECRET}" -o jsonpath='{.data.tls\.crt}' | base64 -d > "${CERTDIR}/${DOMAINS_TXT_DATA}/fullchain.pem"
  kubectl get secret "${DOMAIN_SECRET}" -o jsonpath='{.data.tls\.key}' | base64 -d > "${CERTDIR}/${DOMAINS_TXT_DATA}/privkey.pem"
  openssl x509 -in "${CERTDIR}/${DOMAINS_TXT_DATA}/fullchain.pem" -outform pem -out "${CERTDIR}/${DOMAINS_TXT_DATA}/cert.pem"
  openssl x509 -x509toreq -in "${CERTDIR}/${DOMAINS_TXT_DATA}/cert.pem" \
    -signkey "${CERTDIR}/${DOMAINS_TXT_DATA}/privkey.pem" -out "${CERTDIR}/${DOMAINS_TXT_DATA}/cert.csr"
else
  # bootstrap cert/private key
  bootstrap.sh
fi

if [[ ! -f /etc/dehydrated/account ]]; then
    dehydrated --register --accept-terms
fi

nginx
dehydrated -c -k /etc/dehydrated/hook.sh
