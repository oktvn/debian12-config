#!/bin/bash
# To do: Check if openssl is installed
# To do: Check if libnss3-tools is installed
cd `mktemp -d`
NAME='*.local.dev'
openssl genrsa -des3 -out ${NAME}_CA.key -passout pass:1111 2048
echo "Generating root certificate..."
openssl req -x509 -passin pass:1111 -new -nodes -key ${NAME}_CA.key -sha256 -days 825 -out ${NAME}_CA.crt -subj "/C=US/ST=New York/L=New York City/O=$NAME/OU=$NAME/CN=$NAME" 

echo "Generating private key..."
openssl genrsa -out $NAME.key 2048
echo "Generating certificate signing request..."
openssl req -new -key $NAME.key -out $NAME.csr -subj "/C=US/ST=New York/L=New York City/O=$NAME/OU=$NAME/CN=$NAME"
echo "Creating $NAME.ext..."
>$NAME.ext cat <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = $NAME 
DNS.2 = bar.$NAME
IP.1 = 192.168.0.13
EOF
echo "Creating the signed certificate..."
openssl x509 -passin pass:1111 -req -in $NAME.csr -CA ${NAME}_CA.crt -CAkey ${NAME}_CA.key -CAcreateserial -out $NAME.crt -days 825 -sha256 -extfile $NAME.ext

certfile="${NAME}_CA.crt"
certname=$NAME

echo "Adding certificates to system..."
sudo cp ${NAME}_CA.crt /usr/local/share/ca-certificates/
sudo cp -f $NAME.key /etc/ssl/private/
sudo cp -f $NAME.crt /etc/ssl/certs/
sudo update-ca-certificates

echo "Adding $certfile to browsers for the current user ($(whoami))..."

for certDB in $(sudo find ~/ -name "cert8.db")
do
    certdir=$(dirname ${certDB});
    echo "Found $certdir"
    sudo certutil -A -n "${certname}" -t "TCu,Cu,Tu" -i ${certfile} -d dbm:${certdir}
done

### For cert9 (SQL)
for certDB in $(sudo find ~/ -name "cert9.db")
do
    certdir=$(dirname ${certDB});
    echo "Found $certdir"
    sudo certutil -A -n "${certname}" -t "TCu,Cu,Tu" -i ${certfile} -d sql:${certdir}
done

# Todo: check if the certificate paths are added in nginx conf or in apache conf, otherwise inform the user to do so
# Todo: Add to hosts
