#!/bin/bash
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

#Create or navigate to the directory airodump collect
create_directory_if_not_exists "./airodump_collect"

#Create or navigate to the directory for the survey date
create_directory_if_not_exists "./$survey_date"

#Create or navigate to the broad_survey directory
create_directory_if_not_exists "./target_survey"

#Create or navigate to the directory for the survey time
create_directory_if_not_exists "./$survey_time"

read -p "Target channel: " channel
read -p "Target MAC Address: " bssid

#Runs airodump using gpsd (-g) to a file called broad_$survey_time (-w) in the a,b and g bands (-b) and gives the manufacturer (-M), uptime (-U) and wps status (--wps). The dump files come in the form of pcap, csv, and gps
sudo airodump-ng -g -w target_"$survey_time" -c "$channel" --bssid "$bssid" -M -U --wps --output-format pcap,csv,gps "$interface"

