#!/bin/bash

# Ensure the script is run with superuser privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Get Fedora version
fedora_version=$(rpm -E %fedora)

# Add RPM Fusion repo
dnf install -y "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_version}.noarch.rpm" \
                "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_version}.noarch.rpm"
dnf update -y

# Add Flathub repo
dnf install -y flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Enable openh264
dnf config-manager --enable fedora-cisco-openh264

# Add Wine's repository
dnf config-manager --add-repo "https://dl.winehq.org/wine-builds/fedora/${fedora_version}/winehq.repo"

# Download and install Floorp Browser
floorp_version=$(curl -sL https://api.github.com/repos/Floorp-Projects/Floorp/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")' | sed 's/^v//')
wget "https://github.com/Floorp-Projects/Floorp/releases/download/v${floorp_version}/floorp-${floorp_version}.linux-x86_64.tar.bz2"
tar -xvf "floorp-${floorp_version}.linux-x86_64.tar.bz2" -C /usr/local/bin/
chmod +x /usr/local/bin/floorp/floorp
rm "floorp-${floorp_version}.linux-x86_64.tar.bz2"

# Create the desktop file for Floorp
desktop_file="/usr/share/applications/floorp.desktop"
cat > $desktop_file << EOF
[Desktop Entry]
Version=${floorp_version}
Type=Application
Name=Floorp
Exec=/usr/local/bin/floorp/floorp
Icon=/usr/local/bin/floorp/browser/chrome/icons/default/default48.png
Terminal=false
Categories=Network;WebBrowser;
EOF

chmod +x $desktop_file
update-desktop-database

# Install v4l2loopback kernel module for virtual camera support on OBS
dnf install -y kmod-v4l2loopback

# Install various packages
dnf install -y git steam wget lutris gamemode winehq-stable discord okular

# Install Flatpak applications
flatpak install -y flathub com.obsproject.Studio
flatpak install -y flathub com.sindresorhus.Caprine
flatpak install -y flathub com.parsecgaming.parsec

# Install Heroic Games Launcher
latest_version=$(curl -sL https://api.github.com/repos/Heroic-Games-Launcher/HeroicGamesLauncher/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")' | sed 's/^v//')
wget "https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/v${latest_version}/heroic-${latest_version}.x86_64.rpm"
dnf install -y "heroic-${latest_version}.x86_64.rpm"
rm "heroic-${latest_version}.x86_64.rpm"

# Install prerequisites for EmuDeck
dnf install -y jq rsync unzip zenity
