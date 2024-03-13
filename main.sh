# Settings
dconf load / < ./configs/dconf-settings.ini

sudo systemctl stop packagekit
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
sudo apt install -y git wget gpg spotify-client sshpass bleachbit ttf-mscorefonts-installer

# Remove password prompt when running sudo
echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$USER

# Install Ublock for Firefox
sudo apt install -y webext-ublock-origin-firefox
# Install chromium
sudo apt install -y chromium webext-ublock-origin-chromium

# 2. Modify ~/.profile. Append:
echo -e "export MOZ_ENABLE_WAYLAND=1" >> ~/.profile


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

# Restart
sudo service mariadb restart
sudo service php8.2-fpm restart
sudo service nginx restart

# Install Code-Server
curl -fsSL https://code-server.dev/install.sh | sh
sudo sed -i "s/sistem-ui/'Segoe UI'/g" /lib/code-server/lib/vscode/out/vs/workbench/workbench.web.main.css
sudo systemctl enable --now code-server@$USER
echo -e "bind-addr: 127.0.0.1:8080\ncert: false\nauth: none" > $HOME/.config/code-server/config.yaml
sudo systemctl restart code-server@$USER
# Favicons
