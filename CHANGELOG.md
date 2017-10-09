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
- Bug #50 : crash was due to the use of Debian Stretch 9
- Bug #54 : crash of the script in case the Chilli service is already running
- Bug #55 : wrong firewall port in Coova

**v1.3**
- Improvement #44 : expose front web portal in HTTPS using self signed certificate

**v1.2**
- Improvement #40 : you can now connect to daloradius using Bonjour
- Improvement #47 : Haserl 0.9.35 is no more needed but you can still install it by setting HASERL_INSTALL to Y in the script

**v1.1**
- Create a ready-to-use image
- Add instructions to clear installation if the script is executed more than one time 
- Bug #41 : use LAN ip for web portal to avoid DHCP issues

**v1.0**
- Implement a new customizable captive portal (HTML / JS / CSS)
- Bug fix #7 / #28 / #29 : customize captive portal

**v0.9.2**
- Replace call of _iptables_ by _ipt_ in _up.sh_
- Bug fix #32 / #30 : block WAN access from LAN 

**v0.9.1**
- Request #38 : Replace Daloradius from Sourceforge with Github version (thank to reigelgallarde)
- Remove double installation request for git

**v0.9**
- Update the interface
- Optimisations
  - All dependencies are installed in one time
  - Check that the script is executed as root
  - Check that disk space is available 
- Bug fix #14 : add a check for the tun module on Raspbian Jessie Lite
- Bug fix #25 : force IPv4 for APT  

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

