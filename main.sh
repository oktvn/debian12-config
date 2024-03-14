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
sudo apt install -y git wget gpg spotify-client sshpass ttf-mscorefonts-installer

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
echo -e "bind-addr: 127.0.0.1:8080\ncert: false\nauth: none" > $HOME/.config/code-server/config.yaml
sudo systemctl restart code-server@$USER
# Favicons


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

echo "Creating config file for phpMyAdmin..."
{
echo -e '
server {
    listen 80 default_server;
    root /var/www/html;
    index index.php;
    server_name pma.dev;
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

# Restart
sudo service mariadb restart
sudo service php8.2-fpm restart
sudo service nginx restart
