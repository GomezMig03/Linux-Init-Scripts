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

steam_deb="$(mktemp --suffix=.deb)"
lutris_deb="$(mktemp --suffix=.deb)"

apt update -y
apt install git -y
apt install wine -y

wget -q "https://cdn.cloudflare.steamstatic.com/client/installer/steam.deb" -O "$steam_deb"
apt install -y "$steam_deb"
rm -r "$steam_deb"

last_lutris=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep -oP '"tag_name": "\K(.*)(?=")' | sed 's/^v//')
wget -q "https://github.com/lutris/lutris/releases/download/v${last_lutris}/lutris_${last_lutris}_all.deb" -O "$lutris_deb"
apt install -y "$lutris_deb"
rm -r "$lutris_deb"
