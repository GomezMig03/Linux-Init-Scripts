#!/bin/bash

# Get arquitecture
arq=$(uname -m)

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

# Add anime game launcher repo
flatpak remote-add --if-not-exists --user launcher.moe https://gol.launcher.moe/gol.launcher.moe.flatpakrepo

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
dnf install winetricks -y
dnf install okular -y
dnf install krita -y
dnf install vlc -y

# Install Flatpak applications
flatpak install -y flathub com.obsproject.Studio
flatpak install -y flathub com.sindresorhus.Caprine
flatpak install -y flathub com.parsecgaming.parsec
flatpak install -y flathub net.davidotek.pupgui2 # ProtonUp-Qt
flatpak install -y flathub one.ablaze.floorp

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

while [ -n "$filtered_output" ]; do
    read -p "NTFS drives were found, do you want to add them to fstab with mount permissions for default (uid=1000 & gid=1000) user? This will allow steam to boot windows games stored there (Y/n): " response

    # Check the user's response
    if [ "$response" = "y" ] || [ -z "$response" ]; then
    sudo cp /etc/fstab /etc/fstabBackup
    echo "fstab backup created at /etc/fstabBackup"

    index=1
        while IFS= read -r line; do
            echo "$line /mnt/disk$index ntfs defaults,uid=1000,gid=1000 0 2" >> /etc/fstab
            echo "Added line to fstab: $line /mnt/disk$index ntfs defaults,uid=1000,gid=1000 0 2"
            # TODO: Options to add permissions for extra users 
            sudo mkdir -p /mnt/disk$index
            ((index++))
            done <<< "$filtered_output"
        sudo mount -a
        break
    elif [ "$response" = "n" ]; then
        break
    fi
done

# Developer tools installation

# Install Visual Studio Code
rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | tee /etc/yum.repos.d/vscode.repo > /dev/null
dnf check-update -y
dnf install -y code

# Download WebStorm
if [ "$arq" = "aarch64" ]; then
webstormArch="-aarch64"
else
webstormArch=""
fi

wget "https://download.jetbrains.com/webstorm/WebStorm-2024.1.5$webstormArch.tar.gz" -O WebStorm.tar.gz
webstorm_version=$(tar tf WebStorm.tar.gz | head -n 1 | cut -d '/' -f 1)
tar -xzvf WebStorm.tar.gz
mv "$webstorm_version" /usr/local/bin/
rm WebStorm.tar.gz

# Create the WebStorm desktop file
webstorm_file="/usr/share/applications/webstorm.desktop"
cat > $webstorm_file << EOF
[Desktop Entry]
Type=Application
Name=JetBrains WebStorm
Exec=/usr/local/bin/${webstorm_version}/bin/webstorm.sh %f
Icon=/usr/local/bin/${webstorm_version}/bin/webstorm.png
Comment=Develop with pleasure!
Categories=Development;IDE;
Terminal=false
StartupNotify=true
StartupWMClass=jetbrains-webstorm
EOF

chmod +x $webstorm_file
update-desktop-database

# Install Node.js using fnm
curl -fsSL https://fnm.vercel.app/install | bash
fnm install --lts
fnm default lts

# Install utilities for developers of Java and C#
dnf install -y neovim python3-neovim dotnet-sdk-8.0 java-latest-openjdk-devel.x86_64 aspnetcore-runtime-8.0 java-latest-openjdk.x86_64

read -p "Do you want to install EmuDeck right now? (y/N):" userSelect

if [ $userSelect = "y" ]; then 
    dnf install -y jq rsync unzip zenity
    sh -c 'curl -L https://raw.githubusercontent.com/dragoonDorise/EmuDeck/main/install.sh | bash'
fi

# Print completion message
echo "All installations and configurations are complete."
