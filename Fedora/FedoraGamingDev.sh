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
dnf install krita -y
dnf install Pencil2D -y
dnf install opentoonz -y
dnf install vlc -y
dnf install feh -y
dnf install helvum -y

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

filtered_output=$(sudo blkid | awk '!/Windows RE tools|SYSTEM|RECOVERY|Fedora/' | grep 'TYPE="ntfs"' | grep -woP 'UUID="\K[^"]+')

while [ -n "$filtered_output" ]; do
    read -p "NTFS drives were found, do you want to add them to fstab with mount permissions for default (uid=1000 & gid=1000) user? This will allow steam to boot windows games stored there (Y/n): " response

    # Check the user's response
    if [ "$response" = "y" ] || [ -z "$response" ]; then
    sudo cp /etc/fstab /etc/fstabBackup
    echo "fstab backup created at /etc/fstabBackup"

    index=1
        while IFS= read -r line; do
            echo "UUID=$line /mnt/disk$index ntfs defaults,uid=1000,gid=1000 0 2" >> /etc/fstab
            echo "Added line to fstab: 'UUID=$line /mnt/disk$index ntfs defaults,uid=1000,gid=1000 0 2'"
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

# Install Neovim with kickstart and delete old vim files to avoid problems
dnf install -y neovim python3-neovim
rm -r /usr/share/vim/vimfiles

read -p "If you have a fork of kickstart.nvim (and use neovim), write your github user to install it. If you want default write 'nvim-lua'. If you don't want it leave this blank: " ghuser

if [ -n "$ghuser" ]; then
    git clone https://github.com/"$ghuser"/kickstart.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
fi


# Install utilities for developers of Java and C#
dnf install -y dotnet-sdk-8.0 java-latest-openjdk-devel.x86_64 aspnetcore-runtime-8.0 java-latest-openjdk.x86_64

# Install tauri dependecies
dnf install -y webkit2gtk4.0-devel gtk3-devel openssl-devel curl wget file gtk3-devel libappindicator-gtk3-devel librsvg2-devel lz4-devel libsoup3 libsoup3-devel
dnf install -y  javascriptcoregtk4.0 javascriptcoregtk4.0-devel javascriptcoregtk4.1 javascriptcoregtk4.1-devel webkit2gtk4.1 webkit2gtk4.1-devel
echo 'export PKG_CONFIG_PATH=/usr/lib/pkgconfig' >> ~/.bashrc

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
dnf install -y rustc cargo

# Installing C utilities
dnf install -y clang llvm-devel glib-devel make cmake

# Add Cargo to the PATH
echo 'source $HOME/.cargo/env' >> ~/.bashrc
 
# Install Emudeck dependencies
dnf install -y jq rsync unzip zenity

# Print completion message
echo "All installations and configurations are complete."
