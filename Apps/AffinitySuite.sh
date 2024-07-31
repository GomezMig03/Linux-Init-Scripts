#!/bin/bash

# Check package manager

havePM() {
    [ -x "$(which $1)" ]
}

pacmanInstall(){
  sudo pacman -Syu --noconfirm alsa-lib alsa-plugins cups desktop-file-utils dosbox ffmpeg fontconfig freetype2 gcc-libs gettext giflib gnutls gst-plugins-base-libs gtk3 libgphoto2 libpcap libpulse libva libxcomposite libxcursor libxi libxinerama libxrandr mingw-w64-gcc opencl-headers opencl-icd-loader samba sane sdl2 v4l-utils vulkan-icd-loader wine-mono
}

dnfInstall(){
  sudo dnf install -y alsa-lib-devel cups-devel dbus-libs fontconfig-devel freetype-devel glibc-devel.i686 gnutls-devel gstreamer1-devel gstreamer1-plugins-base-devel libgphoto2-devel libunwind-devel libusbx-devel libX11-devel libXcomposite-devel libXcursor-devel libXext-devel libXfixes-devel libXi-devel libXrandr-devel libXrender-devel mesa-libGL-devel mesa-libOSMesa-devel mingw32-gcc mingw64-gcc ocl-icd-devel samba-devel sane-backends-devel SDL2-devel vulkan-headers vulkan-loader vulkan-loader-devel
}

aptInstall(){
  sudo apt install -y gcc-mingw-w64 gcc-multilib libasound2-dev libcups2-dev libdbus-1-dev libfontconfig-dev libfreetype-dev libgl-dev libgnutls28-dev libgphoto2-dev libgstreamer-plugins-base1.0-dev libgstreamer1.0-dev libosmesa6-dev libpcap-dev libpulse-dev libsane-dev libsdl2-dev libudev-dev libunwind-dev libusb-1.0-0-dev libvulkan-dev libx11-dev libxcomposite-dev libxcursor-dev libxext-dev libxfixes-dev libxi-dev libxrandr-dev libxrender-dev ocl-icd-opencl-dev samba-dev
}

zypperInstall(){
  sudo zypper install -y -t pattern devel_basis ccache gcc-32bit bison-32bit
}

# Installing the necesary dependencies for wine building
if havePM pacman; then 
  pacmanInstall
elif havePM dnf; then 
  dnfInstall
elif havePM apt; then 
  aptInstall
elif havePM zypper; then 
  zypperInstall
else 
  echo 'No package manager found. Please install the dependencies listed at: https://wiki.winehq.org/Building_Wine#Satisfying_Build_Dependencies'
fi


git clone https://gitlab.com/xkero/rum $HOME/Documents/rum

sudo cp $HOME/Documents/rum/rum /usr/local/bin/rum

rm -rf "$HOME/Documents/rum"

get_user_cores() {
  echo "How many cores do you want to use for the compilation? 
Take into consideration this is a long process and using more cores will make it faster, 
but using all of them will probably make you unable to use the computer during the compilation (1-$(nproc)):"
  read userCores
}

get_user_cores

while ! [[ "$userCores" =~ ^[0-9]+$ ]] || [ "$userCores" -lt 1 ] || [ "$userCores" -gt $(nproc) ]; then
  echo "Invalid input. Please enter a number between 1 and $(nproc)."
  get_user_cores
fi

echo "Compiling modified wine version, this may take a while..."

git clone https://gitlab.winehq.org/ElementalWarrior/wine.git ElementalWarrior-wine

cd ElementalWarrior-wine/
git switch affinity-photo2-wine8.14

mkdir -p winewow64-build/ wine-install/
cd winewow64-build/ || exit

../configure --prefix="$HOME/Documents/ElementalWarrior-wine/wine-install" --enable-archs=i386,x86_64

make --jobs "$userCores"

make install --jobs "$userCores"

echo "Compilation finished"

sudo mkdir /opt/wines

sudo cp --recursive "$HOME/Documents/ElementalWarrior-wine/wine-install" "/opt/wines/ElementalWarrior-8.14"

sudo ln -s /opt/wines/ElementalWarrior-8.14/bin/wine /opt/wines/ElementalWarrior-8.14/bin/wine64

echo "Press install in the next window"
rum ElementalWarrior-8.14 $HOME/.wineAffinity wineboot --init -y

echo "Accept the terms and install in the next window"
rum ElementalWarrior-8.14 $HOME/.wineAffinity winetricks dotnet48 corefonts

rum ElementalWarrior-8.14 $HOME/.wineAffinity wine winecfg -v win11

echo "Now to end the instalation, follow the next steps:"
echo "1. Copy your WinMetadata folder from a windows instalation into $HOME/.wineAffinity/drive_c/windows/system32/WinMetadata"
echo '2. Install the Affinity software you want with "rum ElementalWarrior-8.14 $HOME/.wineAffinity wine [Path to the installer].exe"'
echo '3. Use one of the following commands to open the software you installed:'
echo '  rum ElementalWarrior-8.14 $HOME/.wineAffinity wine "$HOME/.wineAffinity/drive_c/Program Files/Affinity/Publisher 2/Publisher.exe"'
echo '  rum ElementalWarrior-8.14 $HOME/.wineAffinity wine "$HOME/.wineAffinity/drive_c/Program Files/Affinity/Designer 2/Designer.exe"'
echo '  rum ElementalWarrior-8.14 $HOME/.wineAffinity wine "$HOME/.wineAffinity/drive_c/Program Files/Affinity/Photo 2/Photo.exe"'
echo '4. If you have problems, use the "rum ElementalWarrior-8.14 $HOME/.wineAffinity winecfg" command, go to graphics and select to emulate virtual desktop, then put the pixels of your monitor'
echo '5. If you still have problems, Change the renderer to OpenGL with "rum ElementalWarrior-8.14 $HOME/.wineAffinity winetricks renderer=gl"'