# Settings
dconf write /org/gnome/desktop/wm/preferences/button-layout "'appmenu:minimize,maximize,close'"
dconf write /org/gnome/mutter/attach-modal-dialogs false
dconf write /org/gnome/desktop/peripherals/mouse/accel-profile "'adaptive'"
dconf write /org/gnome/desktop/peripherals/touchpad/natural-scroll false
dconf write /org/gnome/desktop/peripherals/touchpad/tap-to-click true
dconf write /org/gnome/desktop/interface/enable-hot-corners false
dconf write /org/gnome/shell/favorite-apps "['firefox-esr.desktop', 'org.gnome.Terminal.desktop']"
dconf write /org/gnome/desktop/background/picture-uri "'file:///usr/share/backgrounds/gnome/vnc-l.webp'"
dconf write /org/gnome/desktop/background/picture-uri-dark "'file:///usr/share/backgrounds/gnome/vnc-d.webp'"
dconf write /org/gnome/desktop/background/primary-color "'#77767B'"
dconf write /org/gnome/desktop/screensaver/picture-uri "'file:///usr/share/backgrounds/gnome/vnc-l.webp'"
dconf write /org/gnome/desktop/screensaver/primary-color "'#77767B'"

# Gnome Text Editor
dconf write /org/gnome/TextEditor/show-line-numbers true
dconf write /org/gnome/TextEditor/spellcheck false
dconf write /org/gnome/TextEditor/style-variant "'dark'"
dconf write /org/gnome/TextEditor/indent-style "'space'"
dconf write /org/gnome/TextEditor/style-scheme "'builder-dark'"
dconf write /org/gnome/TextEditor/show-map true

# Gnome Terminal
dconf write /org/gnome/terminal/legacy/profiles:/*/audible-bell false
dconf write /org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9/default-size-columns 100
dconf write /org/gnome/terminal/legacy/keybindings/paste "'<Primary>v'"
dconf write /org/gnome/terminal/legacy/keybindings/close-tab "'<Primary>w'"

# Remove games & all useless trash.
sudo systemctl stop packagekit
sudo apt remove -y gnome-sudoku gnome-maps gnome-games gnome-mahjongg gnome-mines gnome-nibbles gnome-robots gnome-taquin \ 
xiterm+thai aisleriot four-in-a-row five-or-more gnome-2048 tali swell-foop hitori mozc-server mlterm-* goldendict thunderbird anthy* mozc* \
hspell aspell-he myspell-he libhdate1 culmus hdate-applet
sudo apt autoremove -y

# Adding Spotify Repos
curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list

# Adding VSCode Repos
curl -sS https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg && rm -f packages.microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

# Install LEMP
sudo apt upgrade -y
sudo apt update -y
sudo apt install -y php8.2-{fpm,curl,zip,gd,mysqli,mbstring,pgsql,xml,bcmath,intl,soap,imagick} nginx mariadb-server
sudo apt install -y git wget gpg apt-transport-https code spotify-client sshpass

# Install composer
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"
sudo mv composer.phar /usr/local/bin/composer

# Configure LEMP
sudo mysqladmin -u root password ''
sudo mysql_upgrade -uroot --force

# Install Gnome extensions:
rm -rf $HOME/.local/share/gnome-shell/extensions/
dconf reset -f "/org/gnome/shell/extensions/"
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

gsettings reset org.gnome.shell app-picker-layout
