# Aircrack_Scripts

These are the scripts that I use when using aircrack to make the data storage and set up process easier
====================================================================================================================

Installation Instructions

git clone https://github.com/PlinyTheYounger0/Aircrack_Scripts
cd Aircrack_Scripts
sudo ./setup.sh

After that you can run the broad survey and targeted survey with the provided scripts
====================================================================================================================

setup.sh - Checks system and installs all dependencies for any scripts as well as aircrack-ng and aircracked-ng
    
    aircrack-ng and aircracked-ng will be cloned to the /opt directory
    
    It is important to note that gpsd needs to be configured before you can use it
        To do this edit the /etc/default/gpsd file
        It should look like this

# Devices gpsd should collect to at boot time.
# They need to be read/writeable, either by user gpsd or the group dialout.
DEVICES="<insert serial port here>"
    by default Debian Linux systems use /dev/ttyUSB0 (be aware that you may need to change the permissions on the file)

# Other options you want to pass to gpsd
GPSD_OPTIONS="-N -b"
    -N is always needed, -b is used to set GPSD in binary mode for the GlobalSat BU-353N
START_DAEMON="true"
    Starts gpsd as soon as you launch the system
# Automatically hot add/remove USB GPS devices via gpsdctl
USBAUTO="true"

====================================================================================================================

broad_survey.sh 
    Randomizes the MAC of the NIC
    Accepts target list
        If there is no target list / you want to create a new target list the script allows you to create one
    Creates the file system Aircrack_Scripts/airodump_collect/date/braod_survey/time
    Runs airodump surveying the a, b, g, and x bands

--------------------------------------------------------------------------------------------------------------------

target_surveys.sh
    Randomizes the MAC of the NIC
    Accepts target list
        If there is no target list / you want to create a new target list the script allows you to create one
    Creates the file system Aircrack_Scripts/airodump_collect/date/target_survey/time
    Accepts Channel
    Accepts BSSID
    Runs airodump locked on one channel filtering for only the specified BSSID    

====================================================================================================================
