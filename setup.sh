#!/bin/bash

#Ensure script runs as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Use: sudo $0"
   exit 1
fi

#Define installation directory (not in /root)
INSTALL_DIR="/opt"

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

#Function to build repositories
build_repo() {
    repo="$1"
    repo_path="$INSTALL_DIR/$repo"

    if [[ ! -d "$repo_path" ]]; then
        echo "Error: Directory '$repo_path' does not exist."
        exit 1
    fi

    echo "Building '$repo'..."
    cd "$repo_path" || { echo "Error: Failed to navigate to '$repo_path'"; exit 1; }

    autoreconf -i || { echo "Error: Failed autoreconf"; exit 1; }
    ./configure || { echo "Error: Failed configure"; exit 1; }
    make || { echo "Error: Failed make"; exit 1; }
    make install || { echo "Error: Failed make install"; exit 1; }

    echo "'$repo' built successfully."
}

#Function to check if a GitHub repo is already cloned
git_repo_exists() {
    repo_url="$1"
    repo_name=$(basename "$repo_url" .git)  # Extract repo name
    repo_path="$INSTALL_DIR/$repo_name"

    if [[ ! -d "$repo_path" ]]; then
        echo "Cloning repo from '$repo_url' to '$repo_path'..."
        git clone "$repo_url" "$repo_path" || { rm -rf "$repo_path"; echo "Failed to clone '$repo_name'. Check network and URL."; exit 1; }
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
    screen iw usbutils git gpsd-tools gpsd gpsd-clients
)

for pkg in "${packages[@]}"; do
    check_package_exists "$pkg"
done

#Ensure the install directory exists
mkdir -p "$INSTALL_DIR"
chmod 755 "$INSTALL_DIR"

#Clone and build aircrack-ng
git_repo_exists "https://github.com/aircrack-ng/aircrack-ng.git"
build_repo "aircrack-ng"

#Clone and build aircracked-ng
git_repo_exists "https://github.com/theweefies/aircracked-ng"
build_repo "aircracked-ng"

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

#Optionally reboot the system to apply changes
echo "Installation completed. A reboot is recommended."
read -rp "Would you like to reboot now? (y/N): " response
response=$(echo "$response" | tr '[:upper:]' '[:lower:]')  # Normalize input
if [[ "$response" =~ ^(y|yes)$ ]]; then
    reboot
else
    echo "Reboot manually when ready."
fi
