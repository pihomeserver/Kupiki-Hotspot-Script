**v0.9.1**
- Replace Daloradius from Sourceforge with Github version (thank to reigelgallarde)
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
- Few bugs fixes

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

