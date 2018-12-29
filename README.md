[![Slack](https://img.shields.io/badge/slack-kupiki--tools-blue.svg)](https://kupiki-tools.slack.com) ![Stars](https://img.shields.io/github/stars/pihomeserver/kupiki-hotspot-script.svg?style=social&label=Star) [![Patreon](https://img.shields.io/badge/%24-Donate-brightgreen.svg)](https://www.patreon.com/pihomeserver)

What is Kupiki Hotspot
==================

This project is the latest version of [the tutorial](http://www.pihomeserver.fr/2015/08/05/raspberry-pi-coovachilli-et-freeradius-pour-un-hotspot-wifi-avec-portail-captif/) created first on my blog [Pi Home Server](http://www.pihomeserver.fr)
Created on a Raspberry Pi 2, some functionalities and tools where not available for the Raspberry Pi 3. Also the tutorial was a little bit difficult to 
implement because of too many steps. That's why i decided to create a script that will help you to build your own hotspot automatically.

Once the script is executed, you will get :
- A Wifi hotspot using the integrated wifi chipset
- A custom captive portal based on coovachilli
    - The portal is served by the high performance web server Nginx
    - The design of the portal can be easily modified for anyone who has knowledge in HTML and Javascript    
- An authentication process based on freeRadius
    - User/password authentication
    - MAC address authentication (optionnal)
- An interface for freeRadius management
    - daloRadius is installed by default, served by Nginx web server
    - A full management of the hotspot, with batch for user creation, vouchers, NAS, etc.

The installed system have been secured using [ANSSI security recommendation](https://www.ssi.gouv.fr/uploads/IMG/cspn/anssi-cspn_2009-04fr.pdf) and is compliant with french laws about free wifi hotspots ([R. 10-13 et R. 10-14 , IV of CPCE](https://www.cdse.fr/wifi-et-conservation-des-donnees))

Support my work
=======

Love Kupiki Hotspot or want to support it? Check out my [patreon page](https://www.patreon.com/pihomeserver) :)

[![patreonLink](http://www.pihomeserver.fr/hosting/patreon/patreon_1.png)](https://www.patreon.com/pihomeserver)


To contribute, you can [open an issue](https://github.com/pihomeserver/Kupiki-Hotspot-Script/issues) and/or fork this repository.

Requirements
============

What are the requirements ?
- A Raspberry Pi 3 or 3B+
- An ethernet cable
- A power supply for the Raspberry Pi
- An internet access of course
- A 4Gb micro SD card with a raspbian-like OS installed like the official [Raspbian Stretch Lite](https://www.raspberrypi.org/downloads/raspbian/). No warranty that it will work with OSes like Official Raspbian, Ubuntu Mate Xenial, etc.

Installation
=====

You just have to download the script, edit it to update it's parameters, execute and wait ... If the wifi on the Raspberry is not already configured, don't worry, the script will do it

- Download the script with the following command
` git clone https://github.com/pihomeserver/Kupiki-Hotspot-Script.git`
- Edit the script and update the first lines to define your own configuration (take care that an ethernet link is required) **[Please read the wiki for more help about parameters](https://github.com/pihomeserver/Kupiki-Hotspot-Script/wiki)**
- Execute the script using the following command :
` sudo chmod +x pihotspot.sh && sudo ./pihotspot.sh `

A log file named `pihotspot.log` will be created in the folder `/var/log`. Open a new session on the Pi and run the following command `tail -f /var/log/pihotspot.log`

In case you want to give a try to Kupiki Hotspot in a Virtual Machine, please look at [this Wiki page](https://github.com/pihomeserver/Kupiki-Hotspot-Script/wiki/Using-Kupiki-Hotspot-in-a-virtual-machine)

Then
=====
Once installed use your favorite browser to connect to daloRadius installed on your Raspberry Pi.
` http://<mypi_ip>/daloradius ` or ` http://<my_hotspot_name>.local/daloradius ` if your system supports Bonjour.
The exact address will be displayed at the end of the script execution.

**Do not try to connect to daloRadius throught your new hotspot network**

Updates
=======

Since version 2.0.0 (no update for previous versions), you can get and apply latest updates on your system.
Go in _/etc/kupiki_ folder and run as _root_ :
```
/etc/kupiki/kupiki_updater.sh
```
Feel free to add it in a cron job to get automatic updates

Screenshots
=======

#### Connexion screen
![portalConnect](http://www.pihomeserver.fr/hosting/portalConnect.png)

#### Successful connexion
![portalConnected](http://www.pihomeserver.fr/hosting/portalConnected.png)

#### Daloradius
![daloradius](http://www.pihomeserver.fr/hosting/daloradius.png)

Additionnal application
=======

For those who want to try another interface (in english of french only) with less functionnalities and more bugs, you can try the portal currently in development [here](https://github.com/Kupiki/Kupiki-Hotspot-Admin-Install)

#### Login screen
![login](http://www.pihomeserver.fr/hosting/kupiki/login.png)

#### Dashboard
![dashboard](http://www.pihomeserver.fr/hosting/kupiki/dashboard.png)

#### Basic configuration
![simple](http://www.pihomeserver.fr/hosting/kupiki/simple.png)

#### Advanced configuration
![advanced](http://www.pihomeserver.fr/hosting/kupiki/advanced.png)

#### Hotspot management
![mgmt](http://www.pihomeserver.fr/hosting/kupiki/mgmt.png)