#!/bin/bash

#Ensure script runs as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Use: sudo $0"
   exit 1
fi

#Update and Upgrade System
echo "Updating package lists..."
apt update && apt upgrade -y

#Function to check and install packages
check_package_exists() {
    package="$1"
    if dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "install ok installed"; then
        echo "'$package' is already installed"
    else
        echo "Installing '$package'..."
        apt install -y "$package"
    fi
}

#Function to build aircrack-ng and aircracked-ng
build_aircrack_repo() {
    repo="$1"

    if [[ ! -d "$HOME/$repo" ]]; then
        echo "Error: Directory '$HOME/$repo' does not exist."
        exit 1
    fi

    echo "Building '$repo'..."
    cd "$HOME/$repo" || { echo "Error: Failed to navigate to '$HOME/$repo'"; exit 1; }

    autoreconf -i || { echo "Error: Failed autoreconf"; exit 1; }
    ./configure || { echo "Error: Failed configure"; exit 1; }
    make || { echo "Error: Failed make"; exit 1; }
    make install || { echo "Error: Failed make install"; exit 1; }

    echo "'$repo' built successfully."
}


#Function to check if the github repo is installed already or not
git_repo_exists() {
    repo_name=$(basename "$1" .git)  # Extract repo name
    if [[ ! -d "$HOME/$repo_name" ]]; then
        echo "Cloning repo from '$1'..."
        git clone "$1" || { rm -rf "$HOME/$repo_name"; echo "Failed to clone '$repo_name', please check your network and URL"; exit 1; }
    else
        echo "Repo '$repo_name' already exists, skipping clone."
    fi
}


#Install required packages
echo "Installing dependencies..."
packages=(
    wireless-tools net-tools macchanger
    build-essential autoconf automake libtool pkg-config
    libnl-3-dev libnl-genl-3-dev libssl-dev ethtool shtool
    rfkill zlib1g-dev libpcap-dev libsqlite3-dev libpcre3-dev
    libhwloc-dev libcmocka-dev hostapd wpasupplicant tcpdump
    screen iw usbutils git gpsd-tools gpsd
)

for pkg in "${packages[@]}"; do
    check_package_exists "$pkg"
done

#Clone aircrack-ng repo
git_repo_exists https://github.com/aircrack-ng/aircrack-ng.git


#Build aircrack-ng
build_aircrack_repo "aircrack-ng"

#Navigate back to home directory
cd || { echo "Error: Failed to navigate to ~"; exit 1; }

#Clone aircracked-ng repo
echo "Cloning aircracked-ng repository"
git_repo_exists https://github.com/theweefies/aircracked-ng


#Build aircracked-ng
build_aircrack_repo "aircracked-ng"

#Updating library paths
echo "Updating library paths..."
ldconfig

#Update PATH
echo "Updating PATH..."
if ! grep -q '/usr/local/bin' /etc/profile.d/custom_path.sh 2>/dev/null; then
    echo 'export PATH=$PATH:/usr/local/bin' >> /etc/profile.d/custom_path.sh
    chmod +x /etc/profile.d/custom_path.sh
fi
source /etc/profile.d/custom_path.sh

#Optionally reboot the system to update the PATH
echo "Installation completed. A reboot is recommended to apply changes."
read -rp "Would you like to reboot now? (y/N): " response
response=$(echo "$response" | tr '[:upper:]' '[:lower:]')  #Normalize input
if [[ "$response" =~ ^(y|yes)$ ]]; then
    reboot
else
    echo "Reboot manually when ready."
fi

