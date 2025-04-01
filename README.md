# Aircrack_Scripts

These are the scripts that I use when using aircrack to make the data storage and set up process easier

====================================================================================================================

start.sh - Checks system and installs all dependencies for any scripts as well as aircrack-ng and aircracked-ng
    
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

================================================================================================================================

Both of the following scripts build their own file system to help organize the file output of the functions

broad_survey.sh - Randomizes the Network Interface Card's (NIC) MAC and starts survey all wifi channels (more functionality such as target lists and wifi 6 survey to be added)

-------------------------------------------------------------------------------------------------------------------------------------

target_surveys.sh - Randomized the MAC of the NIC and starts a survey on a specific channel filtered for a specific bssid

==================================================================================================================================
