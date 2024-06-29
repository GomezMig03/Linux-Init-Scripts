#!/bin/bash
# Download waterfox
waterfox_version=$(curl -sL https://api.github.com/repos/MrAlex94/Waterfox/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")' | sed 's/^v//')
wget "https://cdn1.waterfox.net/waterfox/releases/${waterfox_version}/Linux_x86_64/waterfox-${waterfox_version}.tar.bz2"
tar -xjvf "waterfox-${waterfox_version}.tar.bz2"
rm -r "waterfox-${waterfox_version}.tar.bz2"
mv "waterfox" /usr/local/bin/

# Create the Waterfox desktop file
waterfox_file="/usr/share/applications/waterfox.desktop"
cat > $waterfox_file << EOF
[Desktop Entry]
Type=Application
Name=Waterfox
Exec=/usr/local/bin/waterfox/waterfox %f
Icon=/usr/local/bin/waterfox/browser/chrome/icons/default/default128.png
Comment=  Fast and Private Web Browser. Get privacy out of the box with Waterfox.
Categories=Network;WebBrowser;
Terminal=false
StartupNotify=true
StartupWMClass=waterfox
EOF

chmod +x $waterfox_file
update-desktop-database