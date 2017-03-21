#!/bin/bash

# PLEASE EDIT NEXT LINES TO DEFINE YOUR OWN CONFIGURATION

# Name of the log file
LOGNAME="pihotspot.log"
# Path where the logfile will be stored
# be sure to add a / at the end of the path
LOGPATH="/var/log/"
# Password for user root (MySql not system)
MYSQL_PASSWORD="pihotspot"
# Name of the hotspot that will be visible for users/customers
HOTSPOT_NAME="pihotspot"
# IP of the hotspot
HOTSPOT_IP="192.168.10.1"
# Network where the hotspot is located
HOTSPOT_NETWORK="192.168.10.0"
# Secret word for CoovaChilli
COOVACHILLI_SECRETKEY="change-me"
# Secret word for FreeRadius
FREERADIUS_SECRETKEY="testing123"
# WAN interface (the one with Internet)
WAN_INTERFACE="eth0"
# LAN interface (the one for the hotspot)
LAN_INTERFACE="wlan0"
# Wifi driver
LAN_WIFI_DRIVER="nl80211"

# *************************************
#
# PLEASE DO NOT MODIFY THE LINES BELOW
#
# *************************************

# CoovaChilli GIT URL
COOVACHILLI_ARCHIVE="https://github.com/coova/coova-chilli.git"
# Daloradius URL
DALORADIUS_ARCHIVE="https://sourceforge.net/projects/daloradius/files/latest/download"
# Haserl URL
HASERL_URL="http://downloads.sourceforge.net/project/haserl/haserl-devel/haserl-0.9.35.tar.gz"
# Haserl archive name based on the URL (keep the same version)
HASERL_ARCHIVE="haserl-0.9.35"

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
    echo "** $MESSAGE"
    # Save it to log file
    echo "** $MESSAGE" >> $LOGPATH$LOGNAME
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
    echo "** Preparing log file"
    if [ -f $LOGPATH$LOGNAME ]; then
        echo "** Log file already exists. Creating a backup."
        execute_command "mv $LOGPATH$LOGNAME $LOGPATH$LOGNAME.`date +%Y%m%d.%H%M%S`"
    fi
    echo "** Creating the log file"
    execute_command "touch $LOGPATH$LOGNAME"
    display_message "Log file created : $LOGPATH$LOGNAME"
    display_message "Use command 'tail -f $LOGPATH$LOGNAME' in a new console to get installation details"
}

prepare_install() {
    # Prepare the log file
    prepare_logfile
}

jumpto() {
    label=$1
    cmd=$(sed -n "/$label:/{:a;n;p;ba};" $0 | grep -v ':$')
    eval "$cmd"
    exit
}

prepare_install

# Use the following instructions to help debug the script and bypass some instructions that have been already executed
# 1) Uncomment both lines (jumpto and nextstep)
# 2) Move the line "nextstep:" right before the first instruction that you want to be executed

#jumpto "nextstep"
#nextstep:

execute_command "apt-get update" true "Updating system"
execute_command "apt-get upgrade -y" true "Upgrading all packages"
execute_command "apt-get install -y --force-yes apt-transport-https" true "Adding HTTPS support for apt-get (Raspbian Lite compatiblity)"

execute_command "ifconfig -a | grep $LAN_INTERFACE" false "Checking if wlan0 interface already exists"
if [ $COMMAND_RESULT -ne 0 ]; then
    display_message "Wifi interface not found. Upgrading the system first"
    execute_command "apt dist-upgrade -y --force-yes" true "Upgrading the distro. Be patient"
    execute_command "apt-get install apt-utils firmware-brcm80211 -y --force-yes" true "Install Wifi firmware"
    display_message "Please reboot and run the script again"
    exit 1
fi

display_message "Update interface configuration"
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

execute_command "ifup $WAN_INTERFACE" true "Activating the WAN interface"
execute_command "ifup $LAN_INTERFACE" true "Activating the LAN interface"

execute_command "apt-get install -y --force-yes debconf-utils" true "Installing debconf tools"

execute_command "echo 'mysql-server mysql-server/root_password password $MYSQL_PASSWORD' | debconf-set-selections" true "Adding MySql password"
#execute_command "debconf-set-selections <<< 'mysql-server mysql-server/root_password password $MYSQL_PASSWORD'" true "Adding MySql password"
execute_command "echo 'mysql-server mysql-server/root_password_again password $MYSQL_PASSWORD' | debconf-set-selections" true "Adding MySql password (confirmation)"
#execute_command "debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password $MYSQL_PASSWORD'" true "Adding MySql password (confirmation)"
execute_command "apt-get install -y --force-yes debhelper libssl-dev libcurl4-gnutls-dev mysql-server freeradius freeradius-mysql gcc make libnl1 libnl-dev pkg-config iptables" true "Installing MySql, freeradius, iptables and other dependencies"

display_message "Creating freeradius database"
echo 'create database radius;' | mysql -u root -p$MYSQL_PASSWORD
check_returned_code $?

display_message "Installing freeradius schema"
mysql -u root -p$MYSQL_PASSWORD radius < /etc/freeradius/sql/mysql/schema.sql
check_returned_code $?

display_message "Creating administrator privileges"
mysql -u root -p$MYSQL_PASSWORD radius < /etc/freeradius/sql/mysql/admin.sql
check_returned_code $?

display_message "Creating additional tables"
mysql -u root -p$MYSQL_PASSWORD radius < /etc/freeradius/sql/mysql/nas.sql
check_returned_code $?

display_message "Updating freeradius configuration - Activate SQL support"
sed -i '/^#.*\$INCLUDE sql\.conf$/s/^#//g' /etc/freeradius/radiusd.conf
check_returned_code $?

display_message "Updating freeradius configuration - Activate SQL counters"
sed -i '/^#.*\$INCLUDE sql\/mysql\/counter\.conf$/s/^#//g' /etc/freeradius/radiusd.conf
check_returned_code $?

display_message "Updating freeradius configuration - Activate daily counters"
sed -i '/^#.*daily$/s/^#//g' /etc/freeradius/radiusd.conf
check_returned_code $?

execute_command "service freeradius stop" true "Stoping freeradius service to update the configuration"

display_message "Activating SQL authentication"
sed -i '/^#.*sql$/s/^#//g' /etc/freeradius/sites-available/default
check_returned_code $?

#display_message "Activating CoA site"
#ln -s /etc/freeradius/sites-available/coa /etc/freeradius/sites-enabled/coa
#check_returned_code $?

execute_command "freeradius -C" true "Checking freeradius configuration"
execute_command "service freeradius start" true "Starting freeradius service"

display_message "Activating IP forwarding"
sed -i '/^#net\.ipv4\.ip_forward=1$/s/^#//g' /etc/sysctl.conf
check_returned_code $?
execute_command "/etc/init.d/networking restart" true "Restarting network service to take IP forwarding into account"

execute_command "apt-get install -y --force-yes git libjson-c-dev haserl gengetopt devscripts libtool bash-completion autoconf automake" true "Installing compilation tools"
execute_command "cd /usr/src && git clone $COOVACHILLI_ARCHIVE" true "Cloning CoovaChilli project"

execute_command "cd /usr/src/coova-chilli && dpkg-buildpackage -us -uc" true "Building CoovaChilli package"
execute_command "cd /usr/src && dpkg -i coova-chilli_1.3.0_armhf.deb" true "Installing CoovaChilli package"

display_message "Configuring CoovaChilli up action"
echo 'iptables -I POSTROUTING -t nat -o $HS_WANIF -j MASQUERADE' >> /etc/chilli/up.sh
check_returned_code $?

display_message "Activating CoovaChilli"
sed -i 's/START_CHILLI=0/START_CHILLI=1/g' /etc/default/chilli
check_returned_code $?

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

display_message "Configuring CoovaChilli secret key"
sed -i "s/HS_UAMSECRET=change-me/HS_UAMSECRET=$COOVACHILLI_SECRETKEY/g" /etc/chilli/defaults
check_returned_code $?

display_message "Configuring CoovaChilli hotspot SSID"
sed -i "s/\# HS_SSID=<ssid>/HS_SSID=$HOTSPOT_NAME/g" /etc/chilli/defaults
check_returned_code $?

display_message "Add CoA support"
sed -i '20iHS_COAPORT=3799' /etc/chilli/defaults
check_returned_code $?

execute_command "update-rc.d chilli start 99 2 3 4 5 . stop 20 0 1 6 ." true "Activating CoovaChilli on boot"

execute_command "cd /usr/src && wget $HASERL_URL" true "Download Haserl"

execute_command "cd /usr/src && tar zxvf $HASERL_ARCHIVE.tar.gz" true "Uncompressing Haserl archive"

execute_command "cd /usr/src/$HASERL_ARCHIVE && ./configure && make && make install" true "Compiling and installing Haserl"

display_message "Updating chilli configuration"
sed -i '/haserl=/s/^haserl=.*$/haserl=\/usr\/local\/bin\/haserl/g' /etc/chilli/wwwsh
check_returned_code $?

execute_command "service chilli start" true "Starting CoovaChilli service"

execute_command "sleep 3 && ifconfig -a | grep tun0" false "Checking if interface tun0 has been created by CoovaChilli"
if [ $COMMAND_RESULT -ne 0 ]; then
    display_message "Unable to find chilli interface tun0"
    exit 1
fi

execute_command "apt-get install -y --force-yes hostapd" true "Installing hostapd"

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

execute_command "service hostapd start" true "Starting hostapd service"

execute_command "apt-get install -y --force-yes php5-mysql php-pear php5-gd php-db php5-fpm libgd2-xpm-dev libpcrecpp0 libxpm4 nginx php5-xcache" true "Installing Nginx webserver with PHP support"

execute_command "cd /usr/src && wget $DALORADIUS_ARCHIVE" true "Downloading daloradius"

execute_command "cd /usr/src && tar zxvf download -C /usr/share/nginx/html/" true "Uncompressing daloradius archive"

execute_command "mv /usr/share/nginx/html/daloradius-0.9-9 /usr/share/nginx/html/daloradius" true "Renaming daloradius folder"

execute_command "service freeradius stop" true "Stopping freeradius service"

execute_command "mv /etc/freeradius/sql/mysql/counter.conf /etc/freeradius/sql/mysql/counter.conf.bak && cp /usr/share/nginx/html/daloradius/contrib/configs/freeradius-2.1.8/cfg1/raddb/sql/mysql/counter.conf /etc/freeradius/sql/mysql/counter.conf" true "Updating /etc/freeradius/sql/mysql/counter.conf" 
#below is needed because counter.conf contains duplicate entry "sqlcounter noresetcounter", this will remove the first one.
sed -i "110,117d" /etc/freeradius/sql/mysql/counter.conf
check_returned_code $?

execute_command "mv /etc/freeradius/sites-available/default /etc/freeradius/sites-available/default.bak && cp /usr/share/nginx/html/daloradius/contrib/configs/freeradius-2.1.8/cfg1/raddb/sites-available/default /etc/freeradius/sites-available/default" true "Updating /etc/freeradius/sites-available/default" 

execute_command "mv /etc/freeradius/modules/sql.conf /etc/freeradius/modules/sql.conf.bak && cp /usr/share/nginx/html/daloradius/contrib/configs/freeradius-2.1.8/cfg1/raddb/modules/sql.conf /etc/freeradius/modules/sql.conf" true "Updating /etc/freeradius/modules/sql.conf" 

execute_command "service freeradius start" true "Starting freeradius service"

display_message "Loading daloradius configuration into MySql"
mysql -u root -p$MYSQL_PASSWORD radius < /usr/share/nginx/html/daloradius/contrib/db/fr2-mysql-daloradius-and-freeradius.sql
check_returned_code $?

display_message "Creating users privileges for localhost"
echo "GRANT ALL ON radius.* to 'radius'@'localhost';" > /tmp/grant.sql
check_returned_code $?
display_message "Creating users privileges for 127.0.0.1"
echo "GRANT ALL ON radius.* to 'radius'@'127.0.0.1';" >> /tmp/grant.sql
check_returned_code $?
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

       	root /usr/share/nginx/html;

       	index index.html index.htm index.php;

       	server_name _;

       	location / {
       		try_files $uri $uri/ =404;
       	}

       	location ~ \.php$ {
       		include snippets/fastcgi-php.conf;
       		fastcgi_pass unix:/var/run/php5-fpm.sock;
       	}
}' > /etc/nginx/sites-available/default
check_returned_code $?

execute_command "nginx -t" true "Checking Nginx configuration file"

execute_command "service nginx restart" true "Restarting Nginx"

execute_command "service hostapd restart" true "Restarting hostapd"

display_message "Getting WAN IP of the Raspberry Pi (for daloradius access)"
MY_IP=`ifconfig $WAN_INTERFACE | grep "inet addr" | awk -F":" '{print $2}' | awk '{print $1}'`

# Last message to display once installation ended successfully

display_message ""
display_message ""
display_message "Congratulation ! You now have your hotspot ready !"
display_message ""
display_message "- Wifi Hotspot available : $HOTSPOT_NAME"
display_message "- For the user management, please connect to http://$MY_IP/daloradius/"
display_message "  (login : administrator / password : radius)"

# Remove current script
#echo "#!/bin/sh -e" > /etc/rc.local
#echo "exit 0" >> /etc/rc.local

exit 0
