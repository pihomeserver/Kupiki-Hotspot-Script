#!/bin/bash

# PLEASE EDIT NEXT LINES TO DEFINE YOUR OWN CONFIGURATION

LOGNAME="pihotspot.log"
LOGPATH="/var/log/" # be sure to add a / at the end of the path

MYSQL_PASSWORD="pihotspot"

HOTSPOT_NAME="pihotspot"
HOTSPOT_IP="192.168.10.1"
HOTSPOT_NETWORK="192.168.10.0"

COOVACHILLI_ARCHIVE="https://github.com/coova/coova-chilli.git"
COOVACHILLI_SECRETKEY="change-me" 

DALORADIUS_ARCHIVE="https://sourceforge.net/projects/daloradius/files/latest/download"

HASERL_URL="http://downloads.sourceforge.net/project/haserl/haserl-devel/haserl-0.9.35.tar.gz"
HASERL_ARCHIVE="haserl-0.9.35"

# *************************************
#
# PLEASE DO NOT MODIFY THE LINES BELOW
#
# *************************************

check_returned_code() {
    RETURNED_CODE=$@
    if [ $RETURNED_CODE -ne 0 ]; then
        display_message ""
        display_message "Something went wrong with the last command. Please check the log file"
        display_message ""
        exit -1
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
    display_message "Executing command : $1"
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

jumpto "nextstep"

nextstep:

execute_command "apt-get update"
execute_command "apt-get upgrade -y"

execute_command "ifconfig -a | grep wlan0" false
if [ $COMMAND_RESULT -ne 0 ]; then
    display_message "Wifi interface not found. Upgrading the system first"
    execute_command "apt dist-upgrade -y --force-yes"
    execute_command "apt-get install apt-utils firmware-brcm80211 -y --force-yes"
    display_message "Please reboot and run the script again"
    exit 1
fi

COMMAND="echo '' >> /etc/network/interfaces"
eval $COMMAND
check_returned_code $?
COMMAND="echo 'auto wlan0' >> /etc/network/interfaces"
eval $COMMAND
check_returned_code $?
COMMAND="echo 'allow-hotplug wlan0' >> /etc/network/interfaces"
eval $COMMAND
check_returned_code $?
COMMAND="echo 'iface wlan0 inet static' >> /etc/network/interfaces"
eval $COMMAND
check_returned_code $?
COMMAND="echo '    address $HOTSPOT_IP' >> /etc/network/interfaces"
eval $COMMAND
check_returned_code $?
COMMAND="echo '    netmask 255.255.255.0' >> /etc/network/interfaces"
eval $COMMAND
check_returned_code $?
COMMAND="echo '    network $HOTSPOT_NETWORK' >> /etc/network/interfaces"
eval $COMMAND
check_returned_code $?
COMMAND="echo '    post-up echo 1 > /proc/sys/net/ipv4/ip_forward' >> /etc/network/interfaces"
eval $COMMAND
check_returned_code $?

execute_command "ifup wlan0"

execute_command "apt-get install -y --force-yes debconf-utils"

execute_command "debconf-set-selections <<< 'mysql-server mysql-server/root_password password $MYSQL_PASSWORD'"
execute_command "debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password $MYSQL_PASSWORD'"
execute_command "apt-get install -y --force-yes debhelper libssl-dev libcurl4-gnutls-dev mysql-server freeradius freeradius-mysql gcc make libnl1 libnl-dev pkg-config iptables"

display_message "Creating freeradius database"
COMMAND="echo 'create database radius;' | mysql -u root -p$MYSQL_PASSWORD"
eval $COMMAND
check_returned_code $?

display_message "Install freeradius schema"
COMMAND="mysql -u root -p$MYSQL_PASSWORD radius < /etc/freeradius/sql/mysql/schema.sql"
eval $COMMAND
check_returned_code $?

display_message "Create administrator privileges"
COMMAND="mysql -u root -p$MYSQL_PASSWORD radius < /etc/freeradius/sql/mysql/admin.sql"
eval $COMMAND
check_returned_code $?

display_message "Create additional tables"
COMMAND="mysql -u root -p$MYSQL_PASSWORD radius < /etc/freeradius/sql/mysql/nas.sql"
eval $COMMAND
check_returned_code $?

display_message "Update freeradius configuration"
sed -i '/^#.*\$INCLUDE sql\.conf$/s/^#//g' /etc/freeradius/radiusd.conf
#COMMAND="sed 's/\#.*\$INCLUDE sql\.conf/\$INCLUDE sql\.conf/g' /etc/freeradius/radiusd.conf > /tmp/radiusd.conf"
#eval $COMMAND
check_returned_code $?

#execute_command "cp /tmp/radiusd.conf /etc/freeradius/radiusd.conf"
execute_command "service freeradius stop"

display "Activating SQL authentication"
sed -i '/^#.*sql$/s/^#//g' /etc/freeradius/sites-available/default
check_returned_code $?

execute_command "freeradius -C"
execute_command "service freeradius start"

display_message "Activating IP forwarding"
sed -i '/^#net\.ipv4\.ip_forward=1$/s/^#//g' /etc/sysctl.conf
check_returned_code $?
execute_command "/etc/init.d/networking restart"

execute_command "apt-get install -y --force-yes git haserl gengetopt devscripts libtool bash-completion autoconf automake"
execute_command "cd /usr/src && git clone $COOVACHILLI_ARCHIVE"
execute_command "cd /usr/src/coova-chilli && dpkg-buildpackage -us -uc"
execute_command "cd /usr/src && dpkg -i coova-chilli_1.3.0_armhf.deb"

display_message "Configure Coova up action"
COMMAND="echo 'iptables -I POSTROUTING -t nat -o \$HS_WANIF -j MASQUERADE' >> /etc/chilli/up.sh"
eval $COMMAND
check_returned_code $?

display_message "Activating CoovaChilli"
COMMAND="sed 's/START_CHILLI=0/START_CHILLI=1/g' /etc/default/chilli > /tmp/chilli"
eval $COMMAND
check_returned_code $?
COMMAND="cp /tmp/chilli /etc/default/chilli"
eval $COMMAND
check_returned_code $?

display_message "Configuring CoovaChilli"
COMMAND="sed 's/\# HS_WANIF=eth0/HS_WANIF=eth0/g' /etc/chilli/defaults > /tmp/defaults.1"
eval $COMMAND
check_returned_code $?

COMMAND="sed 's/HS_LANIF=eth1/HS_LANIF=wlan0/g' /tmp/defaults.1 > /tmp/defaults.2"
eval $COMMAND
check_returned_code $?

COMMAND="sed 's/HS_NETWORK=10.1.0.0/HS_NETWORK=$HOTSPOT_NETWORK/g' /tmp/defaults.2 > /tmp/defaults.3"
eval $COMMAND
check_returned_code $?

COMMAND="sed 's/HS_UAMLISTEN=10.1.0.1/HS_UAMLISTEN=$HOTSPOT_IP/g' /tmp/defaults.3 > /tmp/defaults.4"
eval $COMMAND
check_returned_code $?

COMMAND="sed 's/\# HS_UAMALLOW=www\.coova\.org/HS_UAMALLOW=$HOTSPOT_NETWORK\/24/g' /tmp/defaults.4 > /tmp/defaults.5"
eval $COMMAND
check_returned_code $?

COMMAND="sed 's/HS_UAMSECRET=change-me/HS_UAMSECRET=$COOVACHILLI_SECRETKEY/g' /tmp/defaults.5 > /tmp/defaults.6"
eval $COMMAND
check_returned_code $?

COMMAND="sed 's/\# HS_SSID=<ssid>/HS_SSID=$HOTSPOT_NAME/g' /tmp/defaults.6 > /tmp/defaults.7"
eval $COMMAND
check_returned_code $?

cp /tmp/defaults.7 /etc/chilli/defaults
check_returned_code $?

execute_command "update-rc.d chilli start 99 2 3 4 5 . stop 20 0 1 6 ."

execute_command "cd /usr/src && wget $HASERL_URL"

execute_command "cd /usr/src && tar zxvf $HASERL_ARCHIVE.tar.gz"

execute_command "cd /usr/src/$HASERL_ARCHIVE && ./configure && make && make install"

display_message "Update chilli configuration"
sed -i '/haserl=/s/^haserl=.*$/haserl=\/usr\/local\/bin\/haserl/g' /etc/chilli/wwwsh
check_returned_code $?

execute_command "service chilli start"

execute_command "sleep 3 && ifconfig -a | grep tun0" false
if [ $COMMAND_RESULT -ne 0 ]; then
    display_message "Unable to find chilli interface tun0"
    exit 1
fi

execute_command "apt-get install -y --force-yes hostapd"

display_message "Configure hostapd"
echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' >> /etc/default/hostapd
check_returned_code $?

echo "interface=wlan0
driver=nl80211
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

execute_command "service hostapd start"

execute_command "apt-get install -y --force-yes php5-mysql php-pear php5-gd php-db php5-fpm libgd2-xpm-dev libpcrecpp0 libxpm4 nginx php5-xcache"

execute_command "cd /usr/src && wget $DALORADIUS_ARCHIVE"

execute_command "cd /usr/src && tar zxvf download -C /usr/share/nginx/html/"

execute_command "mv /usr/share/nginx/html/daloradius-0.9-9 /usr/share/nginx/html/daloradius"

display_message "Loading daloradius configuration"
mysql -u root -p$MYSQL_PASSWORD radius < /usr/share/nginx/html/daloradius/contrib/db/fr2-mysql-daloradius-and-freeradius.sql
check_returned_code $?

display_message "Grant users privileges"
echo "GRANT ALL ON radius.* to 'radius'@'localhost';" > /tmp/grant.sql
check_returned_code $?
echo "GRANT ALL ON radius.* to 'radius'@'127.0.01';" >> /tmp/grant.sql
check_returned_code $?

mysql -u root -p$MYSQL_PASSWORD < /tmp/grant.sql
check_returned_code $?

display_message "Configuring daloRadius"
sed "s/\$configValues\['CONFIG_DB_USER'\] = 'root';/\$configValues\['CONFIG_DB_USER'\] = 'radius';/g" /usr/share/nginx/html/daloradius/library/daloradius.conf.php > /tmp/daloradius.1
check_returned_code $?
sed "s/\$configValues\['CONFIG_DB_PASS'\] = '';/\$configValues\['CONFIG_DB_PASS'\] = 'radpass';/g" /tmp/daloradius.1 > /tmp/daloradius.2
check_returned_code $?
execute_command "cp /tmp/daloradius.2 /usr/share/nginx/html/daloradius/library/daloradius.conf.php"

display_message "Build NGINX configuration"
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

execute_command "nginx -t"

execute_command "service nginx restart"

execute_command "service hostapd restart"

display_message "Get IP of the Raspberry Pi"
MY_IP=`ifconfig eth0 | grep "inet addr" | awk -F":" '{print $2}' | awk '{print $1}'`

# Last message to display once installation ended successfully

display_message ""
display_message ""
display_message "Congratulation ! You now have your hotspot ready !"
display_message ""
display_message "- Wifi Hotspot available : $HOTSPOT_NAME"
display_message "- For the user management, please connect to http://$MY_IP/daloradius/"
display_message "  (login : administrator / password : radius)"
