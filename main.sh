# Todo: Split into multiple scripts for ease of maintenance

sudo apt remove -y xiterm+thai mlterm-* goldendict anthy* mozc* hspell aspell-he myspell-he libhdate1 culmus hdate-applet
sudo apt autoremove -y

# Adding Spotify Repos
curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list

# Non-free repo
sudo apt-add-repository contrib non-free -y

sudo apt upgrade -y
sudo apt update -y
# Install misc
sudo apt install -y git wget gpg spotify-client sshpass ttf-mscorefonts-installer dnsutils

# Remove password prompt when running sudo
echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$USER

# Kate as default editor
sudo rm -rf /usr/lib/mime/packages/vim*
echo -e "application/octet-stream;view %s;edit=kate %s > /dev/null 2>&1 &; compose=kate %s > /dev/null 2>&1 &;priority=1
text/plain;view %s;edit=kate %s > /dev/null 2>&1 &;compose=kate %s > /dev/null 2>&1 &;priority=2
text/*;view %s;edit=kate %s > /dev/null 2>&1 &;compose=kate %s > /dev/null 2>&1 &;priority=3
" | sudo tee /usr/lib/mime/packages/kate
sudo update-mime

# Install LEMP & Composer
sudo apt install -y php8.2-{fpm,curl,zip,gd,mysqli,mbstring,pgsql,xml,bcmath,intl,soap,imagick} nginx mariadb-server
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"
sudo mv composer.phar /usr/local/bin/composer
mkdir -p $HOME/Sites
echo -e "[Desktop Entry]\nIcon=folder_html\n" > $HOME/Sites/.directory

# Configure NGINX
sudo sed -i "s/user www-data;/user $USER;/" /etc/nginx/nginx.conf
sudo rm -rf /etc/nginx/sites-enabled/*

# Configure MySQL
sudo mysqladmin -u root password ''
sudo mysql_upgrade -uroot --force

# Configure PHP FPM
sudo sed -i "s/memory_limit = 128M/memory_limit = 512M/" /etc/php/8.2/fpm/php.ini
sudo sed -i "s/www-data/$USER/" /etc/php/8.2/fpm/pool.d/www.conf


# Install Code-Server
curl -fsSL https://code-server.dev/install.sh | sh
sudo sed -i "s/sistem-ui/'Segoe UI'/g" /lib/code-server/lib/vscode/out/vs/workbench/workbench.web.main.css
sudo systemctl enable --now code-server@$USER
echo -e "bind-addr: 127.0.0.1:9998\ncert: false\nauth: none" > $HOME/.config/code-server/config.yaml
sudo systemctl restart code-server@$USER

echo "Creating reverse proxy for code-server..."
{
echo -e '
server {
    listen 80;
    listen [::]:80;
    listen 443 ssl;
    listen [::]:443 ssl;
    ssl_certificate /etc/letsencrypt/live/local.corcodel.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/local.corcodel.com/privkey.pem;
    server_name code.local.corcodel.com;
    location / {
        proxy_pass http://localhost:9998;
        proxy_set_header Host $host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection upgrade;
        proxy_set_header Accept-Encoding gzip;
    }
}
' | sudo tee /etc/nginx/sites-enabled/code-server
}&> /dev/null

# TODO: Favicons
# TODO: Custom configs for code-server



# Phpmyadmin

echo "Downloading phpMyAdmin..."
{
    mkdir -p /var/www/html/
    sudo chown -R $USER:$USER /var/www/html/
    cd /var/www/html/
    rm -rf *
    wget --no-check-certificate "https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-english.zip"
    unzip *
    rm *.zip
    mv */* .
    mv /var/www/html/config.sample.inc.php /var/www/html/config.inc.php
    sed -i "s/'cookie'/'config'/" /var/www/html/config.inc.php
    sed -i "s/'compress'] = false;/'user'] = 'root';/" /var/www/html/config.inc.php
    sed -i "s/'AllowNoPassword'] = false;/'AllowNoPassword'] = true;/" /var/www/html/config.inc.php
}&> /dev/null

# Re-run sudo certbot certonly --manual --preferred-challenges dns -d '*.local.corcodel.com' if cert expires

echo "Creating config file for phpMyAdmin..."
{
echo -e '
server {
    listen 80;
    listen [::]:80;
    listen 443 ssl;
    listen [::]:443 ssl;
    ssl_certificate /etc/letsencrypt/live/local.corcodel.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/local.corcodel.com/privkey.pem;
    
    root /var/www/html;
    index index.php;
    server_name pma.local.corcodel.com;
    location / {
        try_files $uri $uri/ =404;
    }
    location ~* ^.+\.(jpg|jpeg|gif|css|png|js|ico)$ {
        access_log off;expires 1d;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param REQUEST_SCHEME "https";
        fastcgi_param HTTPS "on";
        fastcgi_param PHP_VALUE "upload_max_filesize = -1 \n post_max_size = -1 \n display_errors = on \n display_startup_errors = on";
    }
}
' | sudo tee /etc/nginx/sites-enabled/pma
}&> /dev/null

echo "Creating config file for sites in home directory..."
{
echo -e '
server {
    listen 80;
    listen [::]:80;
    listen 443 ssl;
    listen [::]:443 ssl;
    ssl_certificate /etc/letsencrypt/live/local.corcodel.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/local.corcodel.com/privkey.pem;

    server_name ~^(?<subdomain>.+)\.local\.corcodel\.com$;
    set $root "/home/user/Sites/$subdomain";

    # Craft-specific
    if (-d /home/user/Sites/$subdomain/web) {
        set $root /home/user/Sites/$subdomain/web;
    }

    root $root;
    
    index index.html index.php;
    charset utf-8;
    gzip_static on;
    ssi on;
    client_max_body_size 0;
    error_page 404 /index.php?$query_string;
    access_log off;
    error_log  /var/log/nginx/$subdomain-error.log error;
    location / {
        try_files $uri/index.html $uri $uri/ /index.php?$query_string;
    }
    location ~* ^.+\.(jpg|jpeg|gif|css|png|js|ico)$ {
        access_log off;expires 1d;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        include fastcgi_params;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT $realpath_root;
        fastcgi_param REQUEST_SCHEME "https";
        fastcgi_param HTTPS "on";
        fastcgi_param PHP_VALUE "upload_max_filesize = -1 \n post_max_size = -1 \n display_errors = on \n display_startup_errors = on";
        add_header Last-Modified $date_gmt;
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
}
' | sudo tee /etc/nginx/sites-enabled/default
}&> /dev/null

# To-do: self-sign certificate for *.local.corcodel.com if Letsencrypt expired.

# Restart
sudo service mariadb restart
sudo service php8.2-fpm restart
sudo service nginx restart
