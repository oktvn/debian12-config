# Settings
dconf load / < ./configs/dconf-settings.ini

# Remove games & all useless trash.
sudo systemctl stop packagekit
sudo apt remove -y gnome-sudoku gnome-maps gnome-games gnome-mahjongg gnome-mines gnome-nibbles gnome-robots gnome-taquin \ 
xiterm+thai aisleriot four-in-a-row five-or-more gnome-2048 tali swell-foop hitori mozc-server mlterm-* goldendict thunderbird anthy* mozc* \
hspell aspell-he myspell-he libhdate1 culmus hdate-applet
sudo apt autoremove -y

# Adding Spotify Repos
curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list

sudo apt upgrade -y
sudo apt update -y
# Install misc
sudo apt install -y git wget gpg apt-transport-https spotify-client sshpass bleachbit

# Install Gnome extensions:
rm -rf $HOME/.local/share/gnome-shell/extensions/
sudo apt install pipx -y --no-install-recommends && pipx ensurepath
pipx install gnome-extensions-cli --system-site-packages && source $HOME/.bashrc
gext install dash-to-panel@jderose9.github.com
gext install ding@rastersoft.com
gext install gestureImprovements@gestures

# Thunar instead of Nautilus
sudo apt install thunar --no-install-recommends
sudo rm -rf /usr/share/applications/thunar*
sudo cp /usr/share/applications/org.gnome.Nautilus.desktop /usr/share/applications/thunar.desktop
sudo sed -i 's/nautilus/thunar/g' /usr/share/applications/thunar.desktop
sudo sed -i 's/--new-window//g' /usr/share/applications/thunar.desktop
sudo rm -rf /usr/share/applications/org.gnome.Nautilus.desktop
xdg-desktop-menu forceupdate

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

# Install Code-Server
curl -fsSL https://code-server.dev/install.sh | sh

# Configure LEMP
sudo mysqladmin -u root password ''
sudo mysql_upgrade -uroot --force

gsettings reset org.gnome.shell app-picker-layout
