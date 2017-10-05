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
- An interface for freeRadius management
    - daloRadius is installed by default, served by Nginx web server
    - A full management of the hotspot, with batch for user creation, vouchers, NAS, etc.

Requirements
============

What are the requirements ? 
- A Raspberry Pi 3
- An ethernet cable
- A power supply for the Raspberry Pi
- An internet access of course
- A micro SD card with a raspbian-like OS installed like the official [Raspbian Stretch Lite](https://www.raspberrypi.org/downloads/raspbian/) ). No warranty that it will work with OSes like Official Raspbian, Ubuntu Mate Xenial, etc.

Usage
=====

You just have to download the script, edit it to update it's parameters, execute and wait ... If the wifi on the Raspberry is not already configured, don't worry, the script will do it

- Download the script with the following command   
` git clone https://github.com/pihomeserver/Kupiki-Hotspot-Script.git`
- Edit the script and update the first lines to define your own configuration (take care that an ethernet link is required)
- Execute the script using the following command :
` sudo chmod +x pihotspot.sh && sudo ./pihotspot.sh `

A log file named `pihotspot.log` will be created in the folder `/var/log`. Open a new session on the Pi and run the following command `tail -f /var/log/pihotspot.log`

Full distro
====

**Warning**
**Warning**
**Warning**

The image is using the script v1.1 on Debian Jessie (not the last Stretch release). So you should have some bugs in it. It's recommanded to use the script instead this image.

If you don't want to install the script yourself, you can download a ready-to-use image with this [link](https://drive.google.com/file/d/0B5CzDtjmXSaySVNPZ1A1VkYtVFk/view?usp=sharing)

Credentials to connect to the pi using **SSH** (not in the hotspot) are user : pi / password : raspbian

One more time : this is not the latest release so you will find bugs that have been already solved
For hotspot users creation, manage them with daloradius

Then
=====
Once installed use your favorite browser to connect to daloRadius installed on your Raspberry Pi. 
` http://<mypi_ip>/daloradius ` or ` http://<my_hotspot_name>.local/daloradius ` if your system supports Bonjour.
The exact address will be displayed at the end of the script execution.

**Do not try to connect to daloRadius throught your new hotspot network**

Screenshots
=======

<h4 align="center">Connexion screen</h4>
<img src="http://www.pihomeserver.fr/hosting/portalConnect.png">
<h4 align="center">Successful connexion</h4>
<img src="http://www.pihomeserver.fr/hosting/portalConnected.png">
<h4 align="center">Daloradius</h4>
<img src="http://www.pihomeserver.fr/hosting/daloradius.png">


Support
=======

Please use input your requests or issues in the GIT repository 

Any contribution is welcome !
