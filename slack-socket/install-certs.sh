#!/usr/bin/env bash
set -euo pipefail

export ADDITIONAL_CA_CERTS="/usr/local/share/ca-certificates"
#
# Install the following VA certs. Place then a location that is easily
# shared and in the system trust.
# Other tools, like install Java, can simply just look for any
# files in $ADDITIONAL_CA_CERTS to install.
#
CA_CERTS=(
  https://github.com/department-of-veterans-affairs/platform-va-ca-certificate/blob/main/VA-Internal-S2-RCA1-v1.cer?raw=true
  https://github.com/department-of-veterans-affairs/platform-va-ca-certificate/blob/main/VA-Internal-S2-ICA4.cer?raw=true
  https://github.com/department-of-veterans-affairs/platform-va-ca-certificate/blob/main/VA-Internal-S2-ICA5.cer?raw=true
  https://github.com/department-of-veterans-affairs/platform-va-ca-certificate/blob/main/VA-Internal-S2-ICA6.cer?raw=true
  https://github.com/department-of-veterans-affairs/platform-va-ca-certificate/blob/main/VA-Internal-S2-ICA7.cer?raw=true
  https://github.com/department-of-veterans-affairs/platform-va-ca-certificate/blob/main/VA-Internal-S2-ICA8.cer?raw=true
  https://github.com/department-of-veterans-affairs/platform-va-ca-certificate/blob/main/VA-Internal-S2-ICA9.cer?raw=true
)

if [ ! -d $ADDITIONAL_CA_CERTS ]; then mkdir -p $ADDITIONAL_CA_CERTS; fi

ANCHORS=/usr/local/share/ca-certificates/
for CERT in ${CA_CERTS[@]}
do
  echo "Installing $CERT"
  OUT=$ADDITIONAL_CA_CERTS/${CERT##*/}
  test 200 == "$(curl -sw %{http_code} $CERT -o $OUT)"
done
for cert in $(find $ADDITIONAL_CA_CERTS -type f -name "*.cer")
  do
    echo "Combining $cert"
    openssl x509 -inform der -in $cert -out $cert.crt
  done
chmod 0444 $cert.crt
echo "Combined CA certs to $cert.crt"

update-ca-certificates
