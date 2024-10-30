#!/bin/sh

# Get arquitecture
arq=$(uname -m)

# Ensure the script is run with superuser privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run with superuser rights"
   exec pkexec "$0" "$@"
   exit 1
fi

flatpak remote-add --if-not-exists --user launcher.moe https://gol.launcher.moe/gol.launcher.moe.flatpakrepo

apt update -y
apt install wine -y
wget -qO- "https://cdn.cloudflare.steamstatic.com/client/installer/steam.deb" | sudo dpkg -i -
last_lutris=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep -oP '"tag_name": "\K(.*)(?=")' | sed 's/^v//')
wget -qO- "https://github.com/lutris/lutris/releases/download/v${last_lutris}/lutris_${last_lutris}_all.deb"
