#!/bin/bash

# Get arquitecture
arq=$(uname -m)

# Ensure the script is run with superuser privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run with superuser rights"
   exec pkexec "$0" "$@"
   exit 1
fi

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
                dnf install kernel-devel kernel-headers gcc gc make dkms acpid libglvnd-glx libglvnd-opengl libglvnd-devel pkgconfig -y
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

# Add anime game launcher repo
flatpak remote-add --if-not-exists --user launcher.moe https://gol.launcher.moe/gol.launcher.moe.flatpakrepo

# Enable openh264
dnf config-manager --enable fedora-cisco-openh264

# Add Wine's repository
dnf config-manager --add-repo "https://dl.winehq.org/wine-builds/fedora/${fedora_version}/winehq.repo"

# Install v4l2loopback kernel module for virtual camera support on OBS
dnf install -y kmod-v4l2loopback

# Install Davinci resolve needed dependencies
dnf install -y apr apr-util mesa-libGLU libxcrypt-compat

# Install various packages
dnf install steam -y
dnf install lutris -y
dnf install discord -y
dnf install git -y
dnf install wine -y
dnf install winetricks -y
dnf install okular -y
dnf install vlc -y
dnf install feh -y

# Install Flatpak applications
flatpak install -y flathub com.obsproject.Studio
flatpak install -y flathub com.parsecgaming.parsec
flatpak install -y flathub dev.vencord.Vesktop
flatpak install -y flathub net.davidotek.pupgui2 # ProtonUp-Qt
flatpak install -y flathub one.ablaze.floorp
flatpak install -y flathub com.fightcade.Fightcade
flatpak install -y flathub org.prismlauncher.PrismLauncher
flatpak install -y flathub io.github.zen_browser.zen 

# Add flathub beta for protontricks
flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
flatpak install flathub-beta com.github.Matoking.protontricks

# Install Heroic Games Launcher
if [ "$arq" = "aarch64" ]; then
    echo "Your system architecture is not yet compatible with Heroic Games Launcher"
else 
    latest_version=$(curl -sL https://api.github.com/repos/Heroic-Games-Launcher/HeroicGamesLauncher/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")' | sed 's/^v//')
    wget "https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/v${latest_version}/heroic-${latest_version}.x86_64.rpm"
    dnf install -y "heroic-${latest_version}.x86_64.rpm"
    rm "heroic-${latest_version}.x86_64.rpm"
fi

# Check if user has ntfs drives
filtered_output=$(sudo blkid | awk '!/Windows RE tools|SYSTEM|RECOVERY|Fedora/' | grep 'TYPE="ntfs"' | grep -woP 'UUID="\K[^"]+')

if [ -n "$filtered_output" ]; then
    echo -e "\nNTFS drives were found, if you want to play steam games store there properly, you may have to give them mount permissions for your user"
    echo -e "For more information check https://wiki.archlinux.org/title/Steam/Troubleshooting#Steam_Library_in_NTFS_partition \n"
fi

# Install Emudeck dependencies
dnf install -y jq rsync unzip zenity

echo "All installations and configurations are complete."
