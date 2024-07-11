#!/bin/bash

# Download floorp
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