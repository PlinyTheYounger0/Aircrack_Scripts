#!/bin/bash -e

#File Variable Declarations
survey_date=$(date +%y%m%d)
survey_time=$(date +%H%M)

#Get the actual user's home directory (not root's)
USER_HOME=$(eval echo ~$(logname))

#Define base directory where output will be stored
BASE_DIR="$USER_HOME/Aircrack_Scripts/airodump_collect"


#Check to make sure the commands are installed
for cmd in iwconfig macchanger airodump-ng; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: '$cmd' is not installed. Please install it first."
        exit 1
    fi
done



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
	sudo ip link set "$interface" down
fi

#Change the MAC and check if it succeeded
sudo macchanger -r "$interface"
if [ $? -ne 0 ]; then
    echo "MAC address change failed"
    sudo ip link set "$interface" up
    exit 1
fi

#Bring the interface back up
echo "Bringing '$interface' up..."
sudo ip link set "$interface" up || { echo "Failed to bring '$interface' up"; exit 1; }



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

#Function to validate MAC Address input
validate_mac() {
    local mac=$(normalize_mac "$1")
    if [[ $mac =~ ^([a-f0-9]{2}:){5}[a-f0-9]{2}$ ]]; then
        return 0  # Valid MAC
    else
        return 1  # Invalid MAC
    fi
}

#Function to normalize MAC Address
normalize_mac() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}




#Checks if user wants to use target list and then runs airodump using the target list
read -rp "Would you like to use a target list? (y/n): " response

#Normalize the response
response=$(echo "$response" | tr '[:upper:]' '[:lower:]')

#Check if the response is "y" or "yes"
if [[ "$response" =~ ^(y|yes)$ ]]; then
    echo "Using target list..."
    TARGET_LIST_DIR="$USER_HOME/Aircrack_Scripts/target_lists"
    create_directory_if_not_exists "$TARGET_LIST_DIR"



    #Checks if there are target lists and if not prompts user to create a new one
    if [ "$(ls -A "$TARGET_LIST_DIR")" ]; then
        echo ""
        echo "Available target lists"
        ls "$TARGET_LIST_DIR"
        echo ""
    else
        echo "No target lists found. Please create a new one"
    fi

    read -rp 'Which target list would you like to use? (If none, input "new"): ' response
    response=$(echo "$response" | tr '[:upper:]' '[:lower:]')

    #Makes a new target list based on input
    if [[ "$response" == "new" ]]; then
        read -rp "Input new file name: " target_file_name
        #Validates File Name
        if [[ -z "$target_file_name" || "$target_file_name" =~ [^a-zA-Z0-9._-] ]]; then
            echo "Invalid file name. Use only letters, numbers, dots, underscores, or hyphens."
            exit 1
        else
            touch "$target_file_name"
        fi
        #Sets directory path
        target_file_name="$TARGET_LIST_DIR/$(basename "$target_file_name")"

    #Creates an invalid mac array
    invalid_macs=()

    #Input loop for MAC's with validation
    while true; do
        read -p "Enter MAC Address (or type 'done' to finish): " mac_address
        
        if [[ "$mac_address" == "done" ]]; then
            break  #Exit input loop
        fi
        
        if validate_mac "$mac_address"; then
            echo "$mac_address" >> "$target_file_name"
            echo "MAC Address saved: $mac_address"
        else
            echo "Invalid MAC Address: $mac_address"
            invalid_macs+=("$mac_address")  #Add to invalid list
        fi
    done

    # Display invalid MAC addresses if any
    if (( ${#invalid_macs[@]} > 0 )); then
        echo "List of invalid MAC addresses:"
        printf "%s\n" "${invalid_macs[@]}"
    else
        echo "All entered MAC addresses were valid"
    fi
    else
        target_file_name="$TARGET_LIST_DIR/$response"
    fi



    #Ensure target list file exists
    if [[ ! -f "$target_file_name" || ! -s "$target_file_name" ]]; then
        echo "Error: Target list '$target_file_name' is empty or does not exist"
        exit 1
    fi
    #Sets the correct permissions for the target list
    if [[ -f "$target_file_name" ]]; then
    sudo chmod 644 "$target_file_name"
    fi




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
    sudo airodump-ng -g -p -w "broad_$survey_time" -b abgx -z "$target_file_name" -M -U --wps --output-format pcap,csv,gps "$interface"



else
    echo "Proceeding without target list..."
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
