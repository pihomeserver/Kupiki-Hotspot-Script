**v2.0.13**
- Bug fix on a check on wlan0 instead of LAN_INTERFACE
- Bug fix on a check on existing wpa_supplicant file
- Add counters for CoovaChilli. New counters allow to control bandwitdth limit (upload/download) based on a frequency (daily/weekly/etc.). Counters are from Daloradius release updated/corrected to work with FR3. Counters are located in a new file of the repo /updates/sqlcounter
- Update the script to be executed on a Debian 9 VM

**v2.0.12**
- Bug fixing in the updater

**v2.0.11**
- Add HS_UAMDOMAINS parameter to allow some domains to be browsed before getting authenticated
- Remove an unwanted exit in the control of an existing previous install

**v2.0.10**
- Add default value (off) for Mac authentication. Required for the Kupiki Admin frontend

**v2.0.9**
- MR #154 : remove hardcoded control of the WAN interface
- MR #154 : first remove the folder of Kupiki Admin first before downloading the source from Git
- Add a test when executing the script more than one time (not recommanded)

**v2.0.8**
- Fix the updater script to change coova configuration file like in MR #149 (v2.0.7 missing)
- MR #151 : Fix for "unary operator expected" for all tests

**v2.0.7**
- Issue #122 : check if package deployment is correct before continue the script execution
- MR #149 : use config file instead of editing /etc/chilli/defaults

**v2.0.6**
- Issue #143 : check if SSH service is available and installed before updating banner
- Update of the README file to add link to Patreon

**v2.0.5**
- Add WEB UI Admin installation capability from the main script

**v2.0.4**
- Add instruction block to prepare installation of the new frontend

**v2.0.3**
- Issue #133 : Remove default frontend installation due to mariadb issue

**v2.0.2**
- Issue #116 / #87 : reactivate COA support on port 1700 to avoid ports conflicts
- Add _nfdump_ package

**v2.0.1**
- Update the updater script
- Dummy version to validate updater process

**v2.0.0**
- Issue #116 : remove coa file for Freeradius configuration
- Issue #115 : remove error if /var/local/kupiki exists
- New major release
- Integration of an updater process. Available only for release greater than 2.0.0

**v1.8.9**
- Add controls to validate some parameters before starting the installation

**v1.8.8**
- Change iptables rules from REJECT to DROP to avoid easy discovery of the local network
- Add an option (useless for now) to install web frontend of Kupiki. Default to Y
- Update MariadDB authentication plugin request by the Kupiki Admin interface
- Bug fix : issue with the update of repositories. Now it's forced.

**v1.8.7**
- Issue #91 : block access to local lan via 2 iptables rules

**v1.8.6**
- Issue #100 : add trace for the **_apt-get update_** command

**v1.8.5**
- Add issue template

**v1.8.4**
- Update : add country code in /etc/wpa_supplicant/wpa_supplicant.conf to make script compatible with Raspberry Pi 3B+

**v1.8.3**
- Bug : secret key is wrong configured in the freeradius configuration (clients.conf)

**v1.8.2**
- Issue #88 : generate random key and use it for Freeradius and Coova link

**v1.8**
- Add option to allow authentication by the MAC address of the users. A user must be created with its username as the MAC address (11-22-33-44-55-66) and password with the one defined in the line _MAC_AUTHENTICATION_PASSWORD_

**v1.7.2**
- Extand requested disk space from 500MB to 1GB
- Add option to define how long logs should be kept 
- Issue #81 : add option to install fail2ban (activated by default)

**v1.7.1**
- Correct issue with the service nfdump started by systemd instead of init.d

**v1.7**
- Update of the data logger. In addition of the radacct table (username, date, duration, assigner IP),
some additional data are stored (source and destination IP).
All information are compliant with french laws [R. 10-13 et R. 10-14 , IV of CPCE](https://www.cdse.fr/wifi-et-conservation-des-donnees). No content is saved to respect privacy. Administrators are in charge to complete the user profile to get more details if needed (firstname, lastname, phone number, etc.)
Currently the technical caracteristics if the device are still missing and should be grabbed by the portal it self.
- Option to enable the integrated Bluetooth (disabled by default)

**v1.6**
- Secure the system by adding security rules based on [ANSSI security recommendation](https://www.ssi.gouv.fr/uploads/IMG/cspn/anssi-cspn_2009-04fr.pdf) 
- Issue #49 : add a message on SSH login with current script version

**v1.5**
- Update script to add a connection logger to follow users traffic. Logs contents have to be checked with the radacct table to link user name with date/ip information. The log file contains
  - The date of the request
  - Source IP
  - Destination IP
- Issue #21 / #45 : corrected with the logger

**v1.4.10**
- Update script to make Daloradius optional (installed by default)
- Issue #76 : correct crash with daloradius and portal copies

**v1.4.9**
- Issue #72 : correct crash with daloradius and portal copies

**v1.4.8**
- Issue #71 : create a one step download for all sources requirements and perform the download before any technical action
- Bug : Correct typo for free disk space check 

**v1.4.7**
- Update Portal URL to link it to the Kupiki organization
- Bug : error on tun0 when restarting chilli (timeout too short)

**v1.4.6**
- Correct Collectd configuration to avoid issue on startup
- Cleaning in packages to install (thanks for the email)

**v1.4.5**
- Changed default apt-get option _--force-yes_ with _--allow-remove-essential --allow-change-held-packages_
- Add package _localepurge_ installation. One of the first to apply savings on all packages 

**v1.4.4**
- Change update of hotspot IP in the configuration file of the portal

**v1.4.3**
- Bug : Freeradius not starting after reboot (replace rc.local with systemd service)

**v1.4.2**
- Add Kupiki logo (temporary one ?)

**v1.4.1**
- Bug : Freeradius not starting after reboot (added in rc.local to start after MariaDB)

**v1.4**
- Now check that Debian 9+ is used
- Use MariaDB instead of MySql (based on default packages of Debian Stretch)
- Use of Freeradius 3.0.12 (default package from Debian)
- Make Avahi optional (default is to install it)
- Make HTTPS for the web portal optional (default is not to install)
- Issue #50 : crash was due to the use of Debian Stretch 9
- Issue #54 : crash of the script in case the Chilli service is already running
- Issue #55 : wrong firewall port in Coova

**v1.3**
- Improvement #44 : expose front web portal in HTTPS using self signed certificate

**v1.2**
- Issue #40 : you can now connect to daloradius using Bonjour
- Issue #47 : Haserl 0.9.35 is no more needed but you can still install it by setting HASERL_INSTALL to Y in the script

**v1.1**
- Create a ready-to-use image
- Add instructions to clear installation if the script is executed more than one time 
- Issue #41 : use LAN ip for web portal to avoid DHCP issues

**v1.0**
- Implement a new customizable captive portal (HTML / JS / CSS)
- Issues #7 / #28 / #29 : customize captive portal

**v0.9.2**
- Replace call of _iptables_ by _ipt_ in _up.sh_
- Issues #32 / #30 : block WAN access from LAN 

**v0.9.1**
- Issue #38 : Replace Daloradius from Sourceforge with Github version (thank to reigelgallarde)
- Remove double installation request for git

**v0.9**
- Update the interface
- Optimisations
  - All dependencies are installed in one time
  - Check that the script is executed as root
  - Check that disk space is available 
- Issue #14 : add a check for the tun module on Raspbian Jessie Lite
- Issue #25 : force IPv4 for APT  

**v0.8**
- Add a test to control that the script is executed by root or using sudo
- Add a visual progress for packages installation
- Add a visual progress for packages upgrades
- Add a control for cache updates
- Add a control for free disk space needed for install
- Install extra packages for Wifi drivers (realtek and ralink)
(thanks to PiVPN script for some methods - http://www.pivpn.io)
- Improve counters support. Help for sessions with time limit

**v0.6**
- Add daily counters. Used to add checks for prepaid accounts

**v0.5**
- Add CoA support in Coova to allow users to be disconnected
- Create changelog
- Bug fixing

**v0.4**
- Improve README content
- Document how to bypass some steps
- Bug fixing

**v0.3**
- Add HTTPS packages
- Bug fixing

**v0.2**
- Bug fixing

**v0.1**
- Initial release

