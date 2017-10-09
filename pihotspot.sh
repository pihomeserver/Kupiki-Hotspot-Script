#!/bin/bash

# PLEASE EDIT NEXT LINES TO DEFINE YOUR OWN CONFIGURATION

# Name of the log file
LOGNAME="pihotspot.log"
# Path where the logfile will be stored
# be sure to add a / at the end of the path
LOGPATH="/var/log/"
# Password for user root (MySql/MariaDB not system)
MYSQL_PASSWORD="pihotspot"
# Name of the hotspot that will be visible for users/customers
HOTSPOT_NAME="pihotspot"
# IP of the hotspot
HOTSPOT_IP="192.168.10.1"
# Use HTTPS to connect to web portal
# Set value to Y or N
HOTSPOT_HTTPS="N"
# Network where the hotspot is located
HOTSPOT_NETWORK="192.168.10.0"
# Secret word for CoovaChilli
COOVACHILLI_SECRETKEY="change-me"
# Secret word for FreeRadius
FREERADIUS_SECRETKEY="testing123"
# WAN interface (the one with Internet - default 'eth0' or long name for Debian 9+)
WAN_INTERFACE=`ip link show | grep '^[1-9]' | awk -F ':' '{print $2}' | awk '{$1=$1};1' | grep '^e'`
# LAN interface (the one for the hotspot)
LAN_INTERFACE="wlan0"
# Wifi driver
LAN_WIFI_DRIVER="nl80211"
# Install Haserl (required if you want to use the default Coova Portal)
# Set value to Y or N
HASERL_INSTALL="N"
# Password used for the generation of the certificate
CERT_PASSWORD="pihotspot"
# Number of days to certify the certificate for (default 2 years)
CERT_DAYS="730"
# Make Avahi optional
# Set value to Y or N
AVAHI_INSTALL="Y"

# *************************************
#
# PLEASE DO NOT MODIFY THE LINES BELOW
#
# *************************************

# Default Portal port
HOTSPOT_PORT="80"
HOTSPOT_PROTOCOL="http:\/\/"
# If we need HTTPS support, change port and protocol
if [ $HOTSPOT_HTTPS = "Y" ]; then
    HOTSPOT_PORT="443"
    HOTSPOT_PROTOCOL="https:\/\/"
fi

# Default version of MariaDB
MARIADB_VERSION='10.1'
# CoovaChilli GIT URL
COOVACHILLI_ARCHIVE="https://github.com/coova/coova-chilli.git"
# Captive Portal URL
HOTSPOTPORTAL_ARCHIVE="https://github.com/pihomeserver/Kupiki-Hotspot-Portal.git"
# Daloradius URL
DALORADIUS_ARCHIVE="https://github.com/lirantal/daloradius.git"
# Haserl URL
HASERL_URL="http://downloads.sourceforge.net/project/haserl/haserl-devel/haserl-0.9.35.tar.gz"
# Haserl archive name based on the URL (keep the same version)
HASERL_ARCHIVE="haserl-0.9.35"

### PKG Vars ###
PKG_MANAGER="apt-get"
PKG_CACHE="/var/lib/apt/lists/"
UPDATE_PKG_CACHE="${PKG_MANAGER} update"
PKG_INSTALL="${PKG_MANAGER} --yes install"
PKG_UPGRADE="${PKG_MANAGER} --yes upgrade"
PKG_DIST_UPGRADE="apt dist-upgrade -y --force-yes"
PKG_COUNT="${PKG_MANAGER} -s -o Debug::NoLocking=true upgrade | grep -c ^Inst || true"

check_returned_code() {
    RETURNED_CODE=$@
    if [ $RETURNED_CODE -ne 0 ]; then
        display_message ""
        display_message "Something went wrong with the last command. Please check the log file"
        display_message ""
        exit 1
    fi
}

display_message() {
    MESSAGE=$@
    # Display on console
    echo "::: $MESSAGE"
    # Save it to log file
    echo "::: $MESSAGE" >> $LOGPATH$LOGNAME
}

execute_command() {
    display_message "$3"
    COMMAND="$1 >> $LOGPATH$LOGNAME 2>&1"
    eval $COMMAND
    COMMAND_RESULT=$?
    if [ "$2" != "false" ]; then
        check_returned_code $COMMAND_RESULT
    fi
}

prepare_logfile() {
    echo "::: Preparing log file"
    if [ -f $LOGPATH$LOGNAME ]; then
        echo "::: Log file already exists. Creating a backup."
        execute_command "mv $LOGPATH$LOGNAME $LOGPATH$LOGNAME.`date +%Y%m%d.%H%M%S`"
    fi
    echo "::: Creating the log file"
    execute_command "touch $LOGPATH$LOGNAME"
    display_message "Log file created : $LOGPATH$LOGNAME"
    display_message "Use command 'tail -f $LOGPATH$LOGNAME' in a new console to get installation details"
}

prepare_install() {
    # Prepare the log file
    prepare_logfile

    # Force IPv4 on APT resources
    execute_command "echo 'Acquire::ForceIPv4 \"true\";' | sudo tee /etc/apt/apt.conf.d/99force-ipv4" true "Updating APT config to force IPv4"
}

check_root() {
    # Must be root to install the hotspot
    echo ":::"
    if [[ $EUID -eq 0 ]];then
        echo "::: You are root - OK"
    else
        echo "::: sudo will be used for the install."
        # Check if it is actually installed
        # If it isn't, exit because the install cannot complete
        if [[ $(dpkg-query -s sudo) ]];then
            export SUDO="sudo"
            export SUDOE="sudo -E"
        else
            echo "::: Please install sudo or run this as root."
            exit 1
        fi
    fi
}

jumpto() {
    label=$1
    cmd=$(sed -n "/$label:/{:a;n;p;ba};" $0 | grep -v ':$')
    eval "$cmd"
    exit
}

verifyFreeDiskSpace() {
    # Needed free space
    local required_free_megabytes=500
    # If user installs unattended-upgrades we will check for 500MB free
    echo ":::"
    echo -n "::: Verifying free disk space ($required_free_megabytes Kb)"
    local existing_free_megabytes=$(df -Pk | grep -m1 '\/$' | awk '{print $4}')

    # - Unknown free disk space , not a integer
    if ! [[ "${existing_free_megabytes}" =~ ^([0-9])+$ ]]; then
        echo ""
        echo "::: Unknown free disk space!"
        echo "::: We were unable to determine available free disk space on this system."
        echo "::: You may continue with the installation, however, it is not recommended."
        read -r -p "::: If you are sure you want to continue, type YES and press enter :: " response
        case $response in
            [Y][E][S])
                ;;
            *)
                echo "::: Confirmation not received, exiting..."
                exit 1
                ;;
        esac
    # - Insufficient free disk space
    elif [[ ${existing_free_megabytes} -lt ${required_free_megabytes} ]]; then
        echo ""
        echo "::: Insufficient Disk Space!"
        echo "::: Your system appears to be low on disk space. Pi-HotSpot recommends a minimum of $required_free_megabytes MegaBytes."
        echo "::: You only have ${existing_free_megabytes} MegaBytes free."
        echo ":::"
        echo "::: If this is a new install on a Raspberry Pi you may need to expand your disk."
        echo "::: Try running 'sudo raspi-config', and choose the 'expand file system option'"
        echo ":::"
        echo "::: After rebooting, run this installation again."

        echo "Insufficient free space, exiting..."
        exit 1
    else
        echo " - OK"
    fi
}

update_package_cache() {
  timestamp=$(stat -c %Y ${PKG_CACHE})
  timestampAsDate=$(date -d @"${timestamp}" "+%b %e")
  today=$(date "+%b %e")

  if [ ! "${today}" == "${timestampAsDate}" ]; then
    #update package lists
    echo ":::"
    if command -v debconf-apt-progress &> /dev/null; then
        $SUDO debconf-apt-progress -- ${UPDATE_PKG_CACHE}
    else
        $SUDO ${UPDATE_PKG_CACHE} &> /dev/null
    fi
  fi
}

notify_package_updates_available() {
  echo ":::"
  echo -n "::: Checking ${PKG_MANAGER} for upgraded packages...."
  updatesToInstall=$(eval "${PKG_COUNT}")
  echo " done!"
  echo ":::"
  if [[ ${updatesToInstall} -eq "0" ]]; then
    echo "::: Your system is up to date! Continuing with Pi-Hotspot installation..."
  else
    echo "::: There are ${updatesToInstall} updates available for your system!"
    echo ":::"
    execute_command "apt-get upgrade -y --force-yes" true "Upgrading the packages. Please be patient."
  fi
}

package_check_install() {
    dpkg-query -W -f='${Status}' "${1}" 2>/dev/null | grep -c "ok installed" || ${PKG_INSTALL} "${1}"
}

PIHOTSPOT_DEPS_START=( apt-transport-https )
PIHOTSPOT_DEPS_WIFI=( apt-utils firmware-brcm80211 firmware-ralink firmware-realtek )
PIHOTSPOT_DEPS=( wget build-essential grep whiptail debconf-utils git libjson-c-dev gengetopt devscripts libtool bash-completion autoconf automake hostapd php-mysql php-pear php-gd php-db php-fpm libgd2-xpm-dev libpcrecpp0v5 libxpm4 nginx debhelper libssl-dev libcurl4-gnutls-dev mariadb-server freeradius freeradius-mysql gcc make libnl1 libnl-dev pkg-config iptables libjson-c-dev gengetopt devscripts libtool bash-completion autoconf automake )

install_dependent_packages() {

  declare -a argArray1=("${!1}")

  if command -v debconf-apt-progress &> /dev/null; then
    $SUDO debconf-apt-progress -- ${PKG_INSTALL} "${argArray1[@]}"
  else
    for i in "${argArray1[@]}"; do
      echo -n ":::    Checking for $i..."
      $SUDO package_check_install "${i}" &> /dev/null
      echo " installed!"
    done
  fi
}

check_root

DEBIAN_VERSION=`cat /etc/*-release | grep VERSION_ID | awk -F= '{print $2}' | sed -e 's/^"//' -e 's/"$//'`
if [[ $DEBIAN_VERSION -ne 9 ]];then
        display_message ""
        display_message "This script is used to get installed on Raspbian Stretch Lite"
        display_message ""
	exit 1
fi

verifyFreeDiskSpace

prepare_install

update_package_cache

notify_package_updates_available

install_dependent_packages PIHOTSPOT_DEPS_START[@]

execute_command "dpkg --purge --force-all coova-chilli" true "Remove old configuration of Coova Chilli"
execute_command "dpkg --purge --force-all haserl" true "Remove old configuration of haserl"
execute_command "dpkg --purge --force-all hostapd" true "Remove old configuration of hostapd"

execute_command "/sbin/lsmod | grep tun" false "Checking for tun module"
if [ $COMMAND_RESULT -ne 0 ]; then
    display_message "Insert tun module if existing (for Raspbian Jessie Lite)"
    find /lib/modules/ -iname "tun.ko.gz" -exec /sbin/insmod {} \;
    check_returned_code $?

    display_message "Modprobe module (no check - useless if already loaded)"
    /sbin/modprobe tun

    execute_command "/sbin/lsmod | grep tun" false "Checking for tun module"
    if [ $COMMAND_RESULT -ne 0 ]; then
        display_message "Unable to get tun module up. Please solve before running the script again."
        display_message "If your distribution has been upgraded you should try to reboot first."
        exit 1
    fi
fi

execute_command "/sbin/ifconfig -a | grep $LAN_INTERFACE" false "Checking if wlan0 interface already exists"
if [ $COMMAND_RESULT -ne 0 ]; then
    display_message "Wifi interface not found. Upgrading the system first"

    execute_command "apt dist-upgrade -y --force-yes" true "Upgrading the distro. Be patient"

    install_dependent_packages PIHOTSPOT_DEPS_WIFI[@]

    display_message "Please reboot and run the script again"
    exit 1
fi

execute_command "echo 'maria-db-$MARIADB_VERSION mysql-server/root_password password $MYSQL_PASSWORD' | debconf-set-selections" true "Adding MariaDb password"
execute_command "echo 'maria-db-$MARIADB_VERSION mysql-server/root_password_again password $MYSQL_PASSWORD' | debconf-set-selections" true "Adding MariaDb password (confirmation)"

display_message "Getting WAN IP of the Raspberry Pi (for daloradius access)"
MY_IP=`ifconfig $WAN_INTERFACE | grep "inet " | awk '{ print $2 }'`

if [ $AVAHI_INSTALL = "Y" ]; then
    display_message "Adding Avahi dependencies"
    PIHOTSPOT_DEPS+=( avahi-daemon libavahi-client-dev )

    display_message "Updating the system hostname to $HOTSPOT_NAME"
    echo $HOTSPOT_NAME > /etc/hostname
    check_returned_code $?

    execute_command "grep $HOTSPOT_NAME /etc/hosts" false "Updating /etc/hosts"
    if [ $COMMAND_RESULT -ne 0 ]; then
        sed -i "s/raspberrypi/$HOTSPOT_NAME/" /etc/hosts
        check_returned_code $?
    fi
fi

install_dependent_packages PIHOTSPOT_DEPS[@]

notify_package_updates_available

execute_command "service mariadb restart" true "Starting MySql service"

execute_command "grep $WAN_INTERFACE /etc/network/interfaces" false "Update interface configuration ($WAN_INTERFACE)"
if [ $COMMAND_RESULT -ne 0 ]; then
cat >> /etc/network/interfaces << EOT

auto $WAN_INTERFACE
allow-hotplug $WAN_INTERFACE
iface $WAN_INTERFACE inet dhcp
EOT
    check_returned_code $?
fi

execute_command "grep $LAN_INTERFACE /etc/network/interfaces" false "Update interface configuration ($LAN_INTERFACE)"
if [ $COMMAND_RESULT -ne 0 ]; then
cat >> /etc/network/interfaces << EOT

auto $LAN_INTERFACE
allow-hotplug $LAN_INTERFACE
iface $LAN_INTERFACE inet static
    address $HOTSPOT_IP
    netmask 255.255.255.0
    network $HOTSPOT_NETWORK
    post-up echo 1 > /proc/sys/net/ipv4/ip_forward
EOT
    check_returned_code $?
fi

execute_command "ifup $WAN_INTERFACE" true "Activating the WAN interface"
execute_command "ifup $LAN_INTERFACE" true "Activating the LAN interface"

execute_command "service freeradius stop" true "Stopping freeradius service to update the configuration"

display_message "Creating freeradius database"
echo 'drop database if exists radius;' | mariadb -u root -p$MYSQL_PASSWORD
echo "GRANT USAGE ON *.* TO 'radius'@'localhost';" | mariadb -u root -p$MYSQL_PASSWORD
echo "DROP USER 'radius'@'localhost';" | mariadb -u root -p$MYSQL_PASSWORD
echo 'create database radius;' | mariadb -u root -p$MYSQL_PASSWORD
check_returned_code $?

display_message "Installing freeradius schema"
mariadb -u root -p$MYSQL_PASSWORD radius < /etc/freeradius/3.0/mods-config/sql/main/mysql/schema.sql
check_returned_code $?

display_message "Adding setup data"
mariadb -u root -p$MYSQL_PASSWORD radius < /etc/freeradius/3.0/mods-config/sql/main/mysql/setup.sql
check_returned_code $?

display_message "Updating freeradius configuration - Activate SQL support"
ln -sf /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/sql
check_returned_code $?
chown -h freerad:freerad /etc/freeradius/3.0/mods-enabled/sql
check_returned_code $?

display_message "Configuration of the Freeradius SQL driver"
sed -i 's/"rlm_sql_null"$/"rlm_sql_mysql"/' /etc/freeradius/3.0/mods-enabled/sql
check_returned_code $?

display_message "Change dialect of the Freeradius SQL driver to mysql"
sed -i 's/"sqlite"$/"mysql"/' /etc/freeradius/3.0/mods-enabled/sql
check_returned_code $?

display_message "Configuration of the Freeradius SQL connection"
DIALECT_LINE=`awk 's=index($0,"dialect = ") { print NR }' /etc/freeradius/3.0/mods-enabled/sql`
((DIALECT_LINE+=1))
#by default the radius_db is set to radius
#sed -i "${DIALECT_LINE}iradius_db = \"radius\"" /etc/freeradius/3.0/mods-enabled/sql
sed -i "${DIALECT_LINE}ipassword = \"radpass\"" /etc/freeradius/3.0/mods-enabled/sql
sed -i "${DIALECT_LINE}ilogin = \"radius\"" /etc/freeradius/3.0/mods-enabled/sql
sed -i "${DIALECT_LINE}iport = 3306" /etc/freeradius/3.0/mods-enabled/sql
sed -i "${DIALECT_LINE}iserver = \"localhost\"" /etc/freeradius/3.0/mods-enabled/sql
check_returned_code $?

display_message "Updating freeradius configuration - Activate SQL counters"
#sed -i '/^#.*\$INCLUDE sql\/mysql\/counter\.conf$/s/^#//g' /etc/freeradius/radiusd.conf
ln -sf /etc/freeradius/3.0/mods-available/sqlcounter /etc/freeradius/3.0/mods-enabled/sqlcounter
check_returned_code $?
chown -h freerad:freerad /etc/freeradius/3.0/mods-enabled/sqlcounter
check_returned_code $?

display_message "Bug fix for SQL dialect once SQL Counters are activated"
sed -i 's/dialect = \${modules\.sql\.dialect}/dialect = mysql/g' /etc/freeradius/3.0/mods-available/sqlcounter
check_returned_code $?

display_message "Updating inner-tunnel configuration (1)"
sed -i 's/^[ \t]*-sql/sql/g' /etc/freeradius/3.0/sites-available/inner-tunnel
check_returned_code $?

display_message "Updating inner-tunnel configuration (2)"
sed -i 's/^#[ \t]*sql$/sql/g' /etc/freeradius/3.0/sites-available/inner-tunnel
check_returned_code $?

display_message "Updating freeradius default configuration (1)"
sed -i 's/^[ \t]*-sql/sql/g' /etc/freeradius/3.0/sites-available/default
check_returned_code $?

display_message "Updating freeradius default configuration (2)"
sed -i 's/^#[ \t]*sql$/sql/g' /etc/freeradius/3.0/sites-available/default
check_returned_code $?

execute_command "freeradius -C" true "Checking freeradius configuration"

display_message "Activating IP forwarding"
sed -i '/^#net\.ipv4\.ip_forward=1$/s/^#//g' /etc/sysctl.conf
check_returned_code $?
execute_command "/etc/init.d/networking restart" true "Restarting network service to take IP forwarding into account"

execute_command "cd /usr/src && rm -rf coova-chilli*" true "Removing any previous sources of CoovaChilli project"

execute_command "cd /usr/src && git clone $COOVACHILLI_ARCHIVE coova-chilli" true "Cloning CoovaChilli project"

execute_command "cd /usr/src/coova-chilli && dpkg-buildpackage -us -uc" true "Building CoovaChilli package"
execute_command "cd /usr/src && dpkg --force-depends -i coova-chilli_*_armhf.deb" true "Installing CoovaChilli package"

display_message "Configuring CoovaChilli up action"
echo 'ipt -I POSTROUTING -t nat -o $HS_WANIF -j MASQUERADE' >> /etc/chilli/up.sh
check_returned_code $?

display_message "Block access from LAN to WAN except portal"
cat >> /etc/chilli/up.sh << EOF
LOCAL_IP=\`ifconfig \$HS_WANIF | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'\`
ipt -C INPUT -i \$TUNTAP -d \$LOCAL_IP -j DROP
if [ \$? -ne 0 ]
then
    ipt -A INPUT -i \$TUNTAP -d \$LOCAL_IP -p tcp -m tcp --dport $HOTSPOT_PORT -j ACCEPT
    ipt -A INPUT -i \$TUNTAP -d \$LOCAL_IP -j DROP
fi
EOF

display_message "Activating CoovaChilli"
sed -i 's/START_CHILLI=0/START_CHILLI=1/g' /etc/default/chilli
check_returned_code $?

execute_command "cp -f /etc/chilli/defaults /etc/chilli/defaults.backup" true "Backup of default configuration file"

display_message "Configuring CoovaChilli WAN interface"
sed -i "s/\# HS_WANIF=eth0/HS_WANIF=$WAN_INTERFACE/g" /etc/chilli/defaults
check_returned_code $?

display_message "Configuring CoovaChilli LAN interface"
sed -i "s/HS_LANIF=eth1/HS_LANIF=$LAN_INTERFACE/g" /etc/chilli/defaults
check_returned_code $?

display_message "Configuring CoovaChilli hotspot network"
sed -i "s/HS_NETWORK=10.1.0.0/HS_NETWORK=$HOTSPOT_NETWORK/g" /etc/chilli/defaults
check_returned_code $?

display_message "Configuring CoovaChilli hotspot IP"
sed -i "s/HS_UAMLISTEN=10.1.0.1/HS_UAMLISTEN=$HOTSPOT_IP/g" /etc/chilli/defaults
check_returned_code $?

display_message "Configuring CoovaChilli authorized network"
sed -i "s/\# HS_UAMALLOW=www\.coova\.org/HS_UAMALLOW=$HOTSPOT_NETWORK\/24/g" /etc/chilli/defaults
check_returned_code $?

display_message "Removing CoovaChilli secret key"
sed -i "s/HS_UAMSECRET=change-me/HS_UAMSECRET=/g" /etc/chilli/defaults
check_returned_code $?

display_message "Updating UAMFORMAT"
sed -i "s/^HS_UAMFORMAT=.*$/HS_UAMFORMAT=$HOTSPOT_PROTOCOL$HOTSPOT_IP:$HOTSPOT_PORT/g" /etc/chilli/defaults
check_returned_code $?

display_message "Updating UAMHOMEPAGE"
sed -i 's/^HS_UAMHOMEPAGE=.*$/HS_UAMHOMEPAGE=$HS_UAMFORMAT/g' /etc/chilli/defaults
check_returned_code $?

display_message "Configuring CoovaChilli hotspot SSID"
sed -i "s/\# HS_SSID=<ssid>/HS_SSID=$HOTSPOT_NAME/g" /etc/chilli/defaults
check_returned_code $?

display_message "Add CoA support"
sed -i '20iHS_COAPORT=3799' /etc/chilli/defaults
check_returned_code $?

display_message "Add firewall allowed port"
sed -i "150iHS_TCP_PORTS=\"$HOTSPOT_PORT\"" /etc/chilli/defaults
check_returned_code $?

execute_command "update-rc.d chilli start 99 2 3 4 5 . stop 20 0 1 6 ." true "Activating CoovaChilli on boot"

if [ $HASERL_INSTALL = "Y" ]; then

    execute_command "cd /usr/src && wget $HASERL_URL" true "Download Haserl"

    execute_command "cd /usr/src && tar zxvf $HASERL_ARCHIVE.tar.gz" true "Uncompressing Haserl archive"

    execute_command "cd /usr/src/$HASERL_ARCHIVE && ./configure && make && make install" true "Compiling and installing Haserl"

    display_message "Updating chilli configuration"
    sed -i '/haserl=/s/^haserl=.*$/haserl=\/usr\/local\/bin\/haserl/g' /etc/chilli/wwwsh
    check_returned_code $?

fi

display_message "Creating configuration file for hostapd"
echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' >> /etc/default/hostapd
check_returned_code $?
display_message "Configuring hostapd"
echo "interface=$LAN_INTERFACE
driver=$LAN_WIFI_DRIVER
ssid=$HOTSPOT_NAME
hw_mode=g
channel=6
auth_algs=1
beacon_int=100
dtim_period=2
max_num_sta=255
rts_threshold=2347
fragm_threshold=2346" > /etc/hostapd/hostapd.conf
check_returned_code $?

execute_command "cd /usr/share/nginx/html/ && rm -rf daloradius && git clone $DALORADIUS_ARCHIVE daloradius" true "Cloning daloradius project"

display_message "Loading daloradius configuration into MySql"
mysql -u root -p$MYSQL_PASSWORD radius < /usr/share/nginx/html/daloradius/contrib/db/fr2-mysql-daloradius-and-freeradius.sql
check_returned_code $?

display_message "Creating users privileges for localhost"
echo "GRANT ALL ON radius.* to 'radius'@'localhost';" > /tmp/grant.sql
check_returned_code $?
#display_message "Creating users privileges for 127.0.0.1"
#echo "GRANT ALL ON radius.* to 'radius'@'127.0.0.1';" >> /tmp/grant.sql
#check_returned_code $?
display_message "Granting users privileges"
mysql -u root -p$MYSQL_PASSWORD < /tmp/grant.sql
check_returned_code $?

display_message "Configuring daloradius DB user name"
sed -i "s/\$configValues\['CONFIG_DB_USER'\] = 'root';/\$configValues\['CONFIG_DB_USER'\] = 'radius';/g" /usr/share/nginx/html/daloradius/library/daloradius.conf.php
check_returned_code $?
display_message "Configuring daloradius DB user password"
sed -i "s/\$configValues\['CONFIG_DB_PASS'\] = '';/\$configValues\['CONFIG_DB_PASS'\] = 'radpass';/g" /usr/share/nginx/html/daloradius/library/daloradius.conf.php
check_returned_code $?

display_message "Building NGINX configuration (default listen port : 80)"
echo '
server {
       	listen 80 default_server;
       	listen [::]:80 default_server;

       	root /usr/share/nginx/html/daloradius;

       	index index.html index.htm index.php;

       	server_name _;

       	location / {
       		try_files $uri $uri/ =404;
       	}

       	location ~ \.php$ {
       		include snippets/fastcgi-php.conf;
       		fastcgi_pass unix:/var/run/php/php7.0-fpm.sock;
       	}
}' > /etc/nginx/sites-available/default
check_returned_code $?

display_message "Building NGINX configuration for the portal (default listen port : $HOTSPOT_PORT)"
if [ $HOTSPOT_HTTPS = "Y" ]; then
    display_message "Creating folder for Nginx certificates"
    mkdir /etc/nginx/certs/
    check_returned_code $?

    display_message "Generating self-signed certificate"
    openssl req -x509 -nodes -days $CERT_DAYS -newkey rsa:2048 -keyout /etc/nginx/certs/$HOTSPOT_NAME.key -out /etc/nginx/certs/$HOTSPOT_NAME.crt -subj '/CN=$HOTSPOT_NAME'
    check_returned_code $?

    echo "
server {
       	listen $HOTSPOT_IP:$HOTSPOT_PORT ssl default_server;

        ssl_certificate /etc/nginx/certs/$HOTSPOT_NAME.crt;
	    ssl_certificate_key /etc/nginx/certs/$HOTSPOT_NAME.key;

       	root /usr/share/nginx/portal;

       	index index.html;

       	server_name _;

       	location / {
       		try_files \$uri \$uri/ =404;
       	}

       	location ~ \.php\$ {
       		include snippets/fastcgi-php.conf;
       		fastcgi_pass unix:/var/run/php/php7.0-fpm.sock;
       	}
}" > /etc/nginx/sites-available/portal
else
    echo "
server {
       	listen $HOTSPOT_IP:$HOTSPOT_PORT default_server;

       	root /usr/share/nginx/portal;

       	index index.html;

       	server_name _;

       	location / {
       		try_files \$uri \$uri/ =404;
       	}

       	location ~ \.php\$ {
       		include snippets/fastcgi-php.conf;
       		fastcgi_pass unix:/var/run/php/php7.0-fpm.sock;
       	}
}" > /etc/nginx/sites-available/portal
fi
check_returned_code $?

execute_command "ln -sfT /etc/nginx/sites-available/portal /etc/nginx/sites-enabled/portal" true "Activating portal website"

execute_command "cd /usr/share/nginx && rm -rf portal && git clone $HOTSPOTPORTAL_ARCHIVE portal" true "Cloning Pi Hotspot portal project"

display_message "Updating Captive Portal file"
sed -i "/XXXXXX/s/XXXXXX/$HOTSPOT_IP/g" /usr/share/nginx/portal/js/configuration.json
check_returned_code $?

execute_command "nginx -t" true "Checking Nginx configuration file"

#execute_command "mv /etc/freeradius/sql/mysql/counter.conf /etc/freeradius/sql/mysql/counter.conf.bak && cp /usr/share/nginx/html/daloradius/contrib/configs/freeradius-2.1.8/cfg1/raddb/sql/mysql/counter.conf /etc/freeradius/sql/mysql/counter.conf" true "Updating /etc/freeradius/sql/mysql/counter.conf"

#execute_command "mv /etc/freeradius/sites-available/default /etc/freeradius/sites-available/default.bak && cp /usr/share/nginx/html/daloradius/contrib/configs/freeradius-2.1.8/cfg1/raddb/sites-available/default /etc/freeradius/sites-available/default" true "Updating /etc/freeradius/sites-available/default"

#execute_command "mv /etc/freeradius/sql.conf /etc/freeradius/sql.conf.bak && cp /usr/share/nginx/html/daloradius/contrib/configs/freeradius-2.1.8/cfg1/raddb/modules/sql.conf /etc/freeradius/sql.conf" true "Updating /etc/freeradius/modules/sql.conf"

#execute_command "update-rc.d freeradius start 99 2 3 4 5 . stop 20 0 1 6 ." true "Activating Freeradius on boot"

display_message "Adding Freeradius in systemd startup"
#awk '{new=$0; print old; old=new}END{print "/usr/sbin/service freeradius start"; print old}' /etc/rc.local > /tmp/rc.local
#check_returned_code $?
#cp /tmp/rc.local /etc/rc.local
echo "
[Unit]
Description=Start of freeradius after mysql
After=syslog.target network.target
After=mariadb.service

[Service]
Type=oneshot
ExecStart=/usr/sbin/freeradius
# disable timeout logic
TimeoutSec=0
#StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/freeradius.service
check_returned_code $?
/bin/systemctl enable freeradius.service
check_returned_code $?

execute_command "service freeradius start" true "Starting freeradius service"

execute_command "service nginx restart" true "Restarting Nginx"

execute_command "service hostapd restart" true "Restarting hostapd"

execute_command "service chilli start" true "Starting CoovaChilli service"

execute_command "sleep 3 && ifconfig -a | grep tun0" false "Checking if interface tun0 has been created by CoovaChilli"
if [ $COMMAND_RESULT -ne 0 ]; then
    display_message "Unable to find chilli interface tun0"
    exit 1
fi

# Last message to display once installation ended successfully

display_message ""
display_message ""
display_message "Congratulation ! You now have your hotspot ready !"
display_message ""
display_message "- Wifi Hotspot available : $HOTSPOT_NAME"
if [ $AVAHI_INSTALL = "Y" ]; then
    display_message "- For the user management, please connect to http://$MY_IP/ or http://$HOTSPOT_NAME.local/"
else
    display_message "- For the user management, please connect to http://$MY_IP/"
fi
display_message "  (login : administrator / password : radius)"

exit 0
