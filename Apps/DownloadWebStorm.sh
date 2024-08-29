#!/bin/bash

# Get arquitecture
arq=$(uname -m)
if [ "$arq" == "x86_64" ]; then
    arq=""
elif [ "$arq" == "aarch64" ]; then
    arq="-$arq"
fi


# Download WebStorm
wget "https://download.jetbrains.com/webstorm/WebStorm-2024.2.0.1${arq}.tar.gz" -O WebStorm.tar.gz
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
