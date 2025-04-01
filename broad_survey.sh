#!/bin/bash

#File Variable Declarations
survey_date=$(date +%y%m%d)
survey_time=$(date +%H%M)

#Get the actual user's home directory (not root's)
USER_HOME=$(eval echo ~$(logname))

#Define base directory where output will be stored
BASE_DIR="$USER_HOME/airodump_collect"

#Shows all interfaces so the user can copy and paste it to declare the interface variable
iwconfig
read -p "Enter interface name: " interface

#Validate interface name
if ! iwconfig "$interface" &>/dev/null; then
    echo "Invalid interface: $interface"
    exit 1
fi

#Checks to see if the interface is already down before bringing it down
if ip link show "$interface" | grep -q "state UP"; then
    echo "Bringing '$interface' down..."
	sudo ifconfig "$interface" down
fi

#Change the MAC and check if it succeeded
sudo macchanger -r "$interface"
if [ $? -ne 0 ]; then
    echo "MAC address change failed."
    sudo ifconfig "$interface" up
    exit 1
fi

#Bring the interface back up
echo "Bringing '$interface' up..."
sudo ifconfig "$interface" up || { echo "Failed to bring '$interface' up"; exit 1; }

#Function to check if a directory exists, and create it if not
create_directory_if_not_exists() {
    local dir_path="$1"
    #If the directory is not available it creates it
    if [ ! -d "$dir_path" ]; then
        echo "Creating directory: $dir_path"
        mkdir -p "$dir_path" || { echo "Error: Failed to create directory '$dir_path'"; exit 1; }
    fi
    #Navigates to the directory 
    echo "Navigating to '$dir_path'..."
    cd "$dir_path" || { echo "Error: Failed to navigate to '$dir_path'"; exit 1; }
}

#Checks if user wants to use target list and then runs airodump using the target list
read -rp "Would you like to use a target list? (y/n): " response

#Normalize the response
response=$(echo "$response" | tr '[:upper:]' '[:lower:]')

#Check if the response is "y" or "yes"
if [[ "$response" =~ ^(y|yes)$ ]]; then
    TARGET_LIST_DIR="$USER_HOME/Aircrack_Scripts/target_lists"
    create_directory_if_not_exists "$TARGET_LIST_DIR"

    #Checks if there are target lists and if not prompts user to create a new one
    if [ "$(ls -A "$TARGET_LIST_DIR")" ]; then
        ls "$TARGET_LIST_DIR"
    else
        echo "No target lists found. Please create a new one."
    fi

    read -rp 'Which target list would you like to use? (If none, input "new"): ' response
    response=$(echo "$response" | tr '[:upper:]' '[:lower:]')

    #Makes a new target list based on input
    if [[ "$response" == "new" ]]; then
        read -rp "Input new file name: " file_name
        #Validates File Name
        if [[ -z "$file_name" || "$file_name" =~ [^a-zA-Z0-9._-] ]]; then
            echo "Invalid file name."
            exit 1
        fi
        #Sets directory path
        file_name="$TARGET_LIST_DIR/$(basename "$file_name")"
        read -rp "Input MAC Addresses (separate them with a space): " mac_addresses

        #Iterates over MAC Addresses provided
        for item in $mac_addresses; do
            #Validates the MAC Addresses
            if [[ ! "$item" =~ ^([A-Fa-f0-9]{2}:){5}[A-Fa-f0-9]{2}$ ]]; then
                echo "Invalid MAC address format: $item"
                exit 1
            fi
            #Adds MAC Addresses to the new target list file
            echo "$item" >> "$file_name"
        done
    else
        file_name="$TARGET_LIST_DIR/$response"
    fi

    #Ensure target list file exists
    if [[ ! -f "$file_name" || ! -s "$file_name" ]]; then
        echo "Error: Target list file is empty or does not exist."
        exit 1
    fi
    #Sets the correct permissions for the target list
    sudo chmod 644 "$file_name"

#Ensure base directory exists
create_directory_if_not_exists "$BASE_DIR"

# reate survey date directory
DATE_DIR="$BASE_DIR/$survey_date"
create_directory_if_not_exists "$DATE_DIR"

#Create broad survey directory
BROAD_SURVEY_DIR="$DATE_DIR/broad_survey"
create_directory_if_not_exists "$BROAD_SURVEY_DIR"

#Create survey time directory
TIME_DIR="$BROAD_SURVEY_DIR/$survey_time"
create_directory_if_not_exists "$TIME_DIR"

    #Runs airodump with a target list
    sudo airodump-ng -g -p -w "broad_$survey_time" -b abgx -z "$file_name" -M -U --wps --output-format pcap,csv,gps "$interface"

else
    #Ensure base directory exists
    create_directory_if_not_exists "$BASE_DIR"

    # reate survey date directory
    DATE_DIR="$BASE_DIR/$survey_date"
    create_directory_if_not_exists "$DATE_DIR"

    #Create broad survey directory
    BROAD_SURVEY_DIR="$DATE_DIR/broad_survey"
    create_directory_if_not_exists "$BROAD_SURVEY_DIR"

    #Create survey time directory
    TIME_DIR="$BROAD_SURVEY_DIR/$survey_time"
    create_directory_if_not_exists "$TIME_DIR"
        #Runs airodump without a target list
    sudo airodump-ng -g -p -w "broad_$survey_time" -b abgx -M -U --wps --output-format pcap,csv,gps "$interface"
fi
