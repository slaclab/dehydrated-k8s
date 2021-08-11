#!/bin/bash
OSTYPE="$(uname)"

_sed() {
  if [[ "${OSTYPE}" = "Linux" || "${OSTYPE:0:5}" = "MINGW" ]]; then
    sed -r "${@}"
  else
    sed -E "${@}"
  fi
}

# Setup Private Key and self-signed certificates
if [[ ! -f "${CERTDIR}/privkey.pem" ]]; then
  openssl req \
      -x509 \
      -nodes \
      -newkey rsa:${KEYSIZE} \
      -keyout ${CERTDIR}/privkey.pem \
      -out ${CERTDIR}/fullchain.pem \
      -days 3650 \
      -sha256 \
      -config <(cat <<EOF
[ req ]
prompt = no
distinguished_name = subject
x509_extensions    = x509_ext
 
[ subject ]
commonName = localhost
 
[ x509_ext ]
subjectAltName = @alternate_names
 
[ alternate_names ]
DNS.1 = localhost
IP.1 = 127.0.0.1
EOF
  )
fi

chmod 600 ${CERTDIR}/*.pem

# Boosted from dehydrated script to parse domains.txt
ORIGIFS="${IFS}"
IFS=$'\n'
for line in $(<"${DOMAINS_TXT}" tr -d '\r' | awk '{print tolower($0)}' | _sed -e 's/^[[:space:]]*//g' -e 's/[[:space:]]*$//g' -e 's/[[:space:]]+/ /g' -e 's/([^ ])>/\1 >/g' -e 's/> />/g' | (grep -vE '^(#|$)' || true)); do
  IFS="${ORIGIFS}"
  alias="$(grep -Eo '>[^ ]+' <<< "${line}" || true)"
  line="$(_sed -e 's/>[^ ]+[ ]*//g' <<< "${line}")"
  domain="$(printf '%s\n' "${line}" | cut -d' ' -f1)"
  # skip existing directories
  if [[ ! -d ${CERTDIR}/${domain} ]]; then
    echo "Bootstrapping ${domain}"
    mkdir ${CERTDIR}/${domain}
    cp ${CERTDIR}/privkey.pem ${CERTDIR}/fullchain.pem ${CERTDIR}/${domain}/.
  fi
done
