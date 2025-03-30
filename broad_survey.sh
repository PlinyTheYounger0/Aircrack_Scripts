#!/bin/bash

#File Variable Declarations
survey_date=$(date +%y%m%d)
survey_time=$(date +%H%M)

#Shows all interfaces so the user can copy and paste it to declare the interface variable
iwconfig
read -p "Enter interface name: " interface

#Checks to see if the interface is already down before bringing it down
if ip link show "$interface" | grep -q "state UP"; then
	sudo ifconfig "$interface" down
fi

#Change the MAC and check if it succeeded
sudo macchanger -r "$interface"
if [ $? -ne 0 ]; then
    echo "MAC address change failed."
    exit 1
fi

#Bring the interface back up
sudo ifconfig "$interface" up || { echo "Failed to bring '$interface' up"; exit 1; }
 
#Navigates to the home directory before creating the directory path
cd || { echo "Error: Failed to navigate to ~"; exit 1; }

#Function to check if a directory exists, and create it if not
create_directory_if_not_exists() {
    local dir_path="$1"
    if [ ! -d "$dir_path" ]; then
        echo "Creating directory: $dir_path"
        mkdir -p "$dir_path" || { echo "Error: Failed to create directory '$dir_path'"; exit 1; }
    fi
    echo "Navigating to '$dir_path'..."
    cd "$dir_path" || { echo "Error: Failed to navigate to '$dir_path'"; exit 1; }
}

#Navigate to or create the necessary directories
create_directory_if_not_exists "./airodump_collect"

#Create or navigate to the directory for the survey date
create_directory_if_not_exists "./$survey_date"

#Create or navigate to the broad_survey directory
create_directory_if_not_exists "./broad_survey"

#Create or navigate to the directory for the survey time
create_directory_if_not_exists "./$survey_time"

#Checks if user wants to use target list and then runs airodump using the target list
read -rp "Would you like to use a target list? (y/N): " response
response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
if [[ "$response" =~ ^(y|yes)$ ]]; then
    cd ~/Aircrack_scripts/target_lists || exit 1
    ls
    read -rp 'Which target list would you like to use? (If none, input "new"): ' response
    response=$(echo "$response" | tr '[:upper:]' '[:lower:]')

    if [[ "$response" == "new" ]]; then
        read -rp "Input file name: " file_name
        if [[ -z "$file_name" || "$file_name" =~ [^a-zA-Z0-9._-] ]]; then
            echo "Invalid file name."
            exit 1
        fi
        read -rp "Input MAC Addresses: " mac_addresses
        echo "$mac_addresses" > "$file_name"
    else
        file_name="$response"
    fi

    sudo airodump-ng -g -w "broad_$survey_time" -b abgx -z "$file_name" -M -U --wps --output-format pcap,csv,gps "$interface"

else
    sudo airodump-ng -g -w "broad_$survey_time" -b abgx -M -U --wps --output-format pcap,csv,gps "$interface"
fi
