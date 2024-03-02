#!/bin/bash

cd `mktemp -d`

SITES_DIR="$HOME/sites/"
HOSTS_FILE="/etc/hosts"

mkdir -p $SITES_DIR

if ! command -v "certutil" &> /dev/null; then
    sudo apt install -y libnss3-tools
fi

if ! command -v "openssl" &> /dev/null; then
    sudo apt install -y openssl
fi


sudo update-ca-certificates

function becomeCertificateAuthority {
        openssl genrsa -des3 -out ${SITE_NAME}_CA.key -passout pass:1111 2048
        echo "Generating root certificate..."
        openssl req -x509 -passin pass:1111 -new -nodes -key ${SITE_NAME}_CA.key -sha256 -days 825 -out ${SITE_NAME}_CA.crt -subj "/C=US/ST=New York/L=New York City/O=${SITE_NAME}/OU=${SITE_NAME}/CN=${SITE_NAME}" 
        sudo cp ${SITE_NAME}_CA.crt /usr/local/share/ca-certificates/
}

function generateCertificateAndKeys {
        echo "Generating private key..."
        openssl genrsa -out ${SITE_NAME}.key 2048
        echo "Generating certificate signing request..."
        openssl req -new -key ${SITE_NAME}.key -out ${SITE_NAME}.csr -subj "/C=US/ST=New York/L=New York City/O=${SITE_NAME}/OU=${SITE_NAME}/CN=${SITE_NAME}"
        echo "Creating $NAME.ext..."
        >$SITE_NAME.ext cat <<-EOF
        authorityKeyIdentifier=keyid,issuer
        basicConstraints=CA:FALSE
        keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
        subjectAltName = @alt_names
        [alt_names]
        DNS.1 = $SITE_NAME 
        DNS.2 = bar.$SITE_NAME
        IP.1 = 192.168.0.13
EOF
        echo "Creating the signed certificate..."
        openssl x509 -passin pass:1111 -req -in ${SITE_NAME}.csr -CA ${SITE_NAME}_CA.crt -CAkey ${SITE_NAME}_CA.key -CAcreateserial -out ${SITE_NAME}.crt -days 825 -sha256 -extfile ${SITE_NAME}.ext
        sudo cp -f ${SITE_NAME}.key /etc/ssl/private/
        sudo cp -f ${SITE_NAME}.crt /etc/ssl/certs/
}

function emptyBrowserCerts {
        echo "Emptying cert databases for browsers for the current user ($(whoami))..."

        for certDB in $(sudo find $HOME -name "cert8.db")
        do
            certdir=$(dirname ${certDB});
            echo "Emptying $certdir/cert8.db"
            echo "" > "$certdir/cert8.db"
        done
        
        for certDB in $(sudo find $HOME -name "cert9.db")
        do
            certdir=$(dirname ${certDB});
            echo "Emptying $certdir/cert9.db"
            echo "" > "$certdir/cert9.db"
        done
}

function addCertsToBrowsers {
        echo "Adding ${SITE_NAME}_CA.crt to browsers for the current user ($(whoami))..."

        for certDB in $(sudo find $HOME -name "cert8.db")
        do
            certdir=$(dirname ${certDB});
            echo "Found $certdir"
            sudo certutil -A -n "$SITE_NAME" -t "TCu,Cu,Tu" -i ${SITE_NAME}_CA.crt -d dbm:${certdir}
        done
        
        for certDB in $(sudo find $HOME -name "cert9.db")
        do
            certdir=$(dirname ${certDB});
            echo "Found $certdir"
            sudo certutil -A -n "$SITE_NAME" -t "TCu,Cu,Tu" -i ${SITE_NAME}_CA.crt -d sql:${certdir}
        done
}

function removeHostsEntries {
        MAGIC_COMMENT="## Added automatically ##"
        line_number=$(grep -n "$MAGIC_COMMENT" "$HOSTS_FILE" | cut -d ':' -f 1)
        
        if [ -n "$line_number" ]; then
            sudo sed -i "${line_number}q" "$HOSTS_FILE"
            echo "Removed old entries in hosts file"
        else
            echo "$MAGIC_COMMENT" | sudo tee -a "$HOSTS_FILE" >/dev/null
        fi
}

function addHostsEntries {
        echo "127.0.0.1 $SITE_NAME" | sudo tee -a "$HOSTS_FILE" >/dev/null
        echo "Added $SITE_NAME to hosts file"
}

removeHostsEntries;
emptyBrowserCerts;

for folder in "$SITES_DIR"/*/; do
    SITE_NAME=$(basename "$folder")           
if [[ $SITE_NAME == *"."* ]]; then
    becomeCertificateAuthority;
    generateCertificateAndKeys;
    addHostsEntries;
    addCertsToBrowsers;

    sudo tee "/etc/nginx/sites-enabled/$SITE_NAME" >/dev/null <<EOF
server {
    listen 80;
    listen [::]:80;
    listen 443 ssl;
    listen [::]:443 ssl;

    ssl_certificate /etc/ssl/certs/$SITE_NAME.crt;
    ssl_certificate_key /etc/ssl/private/$SITE_NAME.key;
    
    server_name $SITE_NAME;
    root "/home/oktvn/sites/$SITE_NAME";
    
    index index.html;
    charset utf-8;
    gzip_static  on;
    ssi on;
    client_max_body_size 0;
    error_page 404 /index.php?\$query_string;
    access_log off;
    error_log  /var/log/nginx/\$SITE_NAME-error.log error;
    #error_log syslog:server=unix:/dev/log,facility=local7,tag=nginx,severity=error;
    location / {
        try_files \$uri/index.html \$uri \$uri/ /index.php?\$query_string;
    }
    location ~ [^/]\.php(/|$) {
        try_files \$uri \$uri/ /index.php?\$query_string;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT \$realpath_root;
        fastcgi_param HTTP_PROXY "";
        fastcgi_param HTTP_HOST $SITE_NAME;

        add_header Last-Modified \$date_gmt;
        add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0";
        if_modified_since off;
        expires off;
        etag off;

        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }
    location ~ /\.ht {
        deny all;
    }
    sendfile off;
}
EOF
echo "Created /etc/nginx/sites-enabled/$SITE_NAME"
fi
done

sudo update-ca-certificates
sudo nginx -t
sudo service nginx restart
