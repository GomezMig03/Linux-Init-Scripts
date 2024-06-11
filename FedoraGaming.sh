#!/bin/bash

# Ensure the script is run with superuser privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Adds faster updates
dnf_directory="/etc/dnf/dnf.conf"
cat > "$dnf_directory" << EOF
[main] 
gpgcheck=1 
installonly_limit=3 
clean_requirements_on_remove=True 
best=False 
skip_if_unavailable=True 
fastestmirror=1 
max_parallel_downloads=10 
deltarpm=true
EOF

# Get Fedora version
fedora_version=$(rpm -E %fedora)

# Add RPM Fusion repo
dnf install -y "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_version}.noarch.rpm" \
                "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_version}.noarch.rpm"
dnf update -y
dnf upgrade -y --refresh

# Check if user has nvidia gpu
gpu=$(lspci | grep -E -i "nvidia" | grep -E "VGA|3D");

# Installation of nvidia drivers
if [ -n "$gpu" ]; then
while true; do
        read -rp "NVIDIA card found, do you wish to install NVIDIA proprietary drivers? (Y/n): " res
        case $res in
            [Yy]* | "" )
                echo "Installing drivers..."
                dnf install akmod-nvidia -y
                dnf install xorg-x11-drv-nvidia-cuda -y
                dnf install xorg-x11-drv-nvidia-cuda-libs -y
                break;
                ;;
            [Nn]* )
                echo "NVIDIA drivers won't be installed"
                break;
                ;;
            *)
                echo "Please, enter a valid value (Y/n)"
                ;; 
        esac
    done
fi

# Add Flathub repo
dnf install -y flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Enable openh264
dnf config-manager --enable fedora-cisco-openh264

# Add Wine's repository
dnf config-manager --add-repo "https://dl.winehq.org/wine-builds/fedora/${fedora_version}/winehq.repo"

# Install v4l2loopback kernel module for virtual camera support on OBS
dnf install -y kmod-v4l2loopback

# Install various packages
dnf install steam -y
dnf install lutris -y
dnf install discord -y
dnf install git -y
dnf install wine -y
dnf install okular -y
dnf install krita -y
dnf install vlc -y

# Install Flatpak applications
flatpak install -y flathub com.obsproject.Studio
flatpak install -y flathub com.sindresorhus.Caprine
flatpak install -y flathub com.parsecgaming.parsec
flatpak install -y flathub net.davidotek.pupgui2 # ProtonUp-Qt

# Download last version of Floorp
floorp_version=$(curl -sL https://api.github.com/repos/Floorp-Projects/Floorp/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")' | sed 's/^v//')
wget "https://github.com/Floorp-Projects/Floorp/releases/download/v${floorp_version}/floorp-${floorp_version}.linux-x86_64.tar.bz2"
tar -xjvf "floorp-${floorp_version}.linux-x86_64.tar.bz2"
rm -r "floorp-${floorp_version}.linux-x86_64.tar.bz2"
mv "floorp" /usr/local/bin/
rm -r "floorp"

# Create the Floorp desktop file
floorp_file="/usr/share/applications/floorp.desktop"
cat > $floorp_file << EOF
[Desktop Entry]
Type=Application
Name=Floorp
Exec=/usr/local/bin/floorp/floorp %f
Icon=/usr/local/bin/floorp/browser/chrome/icons/default/default128.png
Comment= A Browser built for keeping the Open, Private and Sustainable Web alive. Based on Mozilla Firefox. 
Categories=Network;WebBrowser;
Terminal=false
StartupNotify=true
StartupWMClass=floorp
EOF

chmod +x $floorp_file
update-desktop-database

# Install Heroic Games Launcher
latest_version=$(curl -sL https://api.github.com/repos/Heroic-Games-Launcher/HeroicGamesLauncher/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")' | sed 's/^v//')
wget "https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/v${latest_version}/heroic-${latest_version}.x86_64.rpm"
dnf install -y "heroic-${latest_version}.x86_64.rpm"
rm "heroic-${latest_version}.x86_64.rpm"

# Install prerequisites for EmuDeck
dnf install -y jq rsync unzip zenity