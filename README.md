
**If you want something easier than a script, look at the dedicated distro that will build an up-to-date wifi hotspot. 
Look at [this repository](https://github.com/pihomeserver/Kupiki-Hotspot)**


What is Pi Hotspot
==================

This project is the latest version of [the tutorial](http://www.pihomeserver.fr/2015/08/05/raspberry-pi-coovachilli-et-freeradius-pour-un-hotspot-wifi-avec-portail-captif/) created first on my blog [Pi Home Server](http://www.pihomeserver.fr)
Created on a Raspberry Pi 2, some functionalities and tools where not available for the Raspberry Pi 3. Also the tutorial was a little bit difficult to 
implement because of too many steps. That's why i decided to create a script that will help you to build your own hotspot automatically.

Once the script is executed, you will get :
- A Wifi hotspot using the integrated wifi chipset
- A captive portal based on coovachilli
- An authenticate control based on freeRadius
- An interface for freeRadius based on daloRadius

Requirements
============

What are the requirements ?
- A Raspberry Pi 3
- An ethernet cable
- A power supply for the Raspberry Pi
- A micro SD card with a raspbian-like OS installed. For this project i used [minibian](https://minibianpi.wordpress.com/) which optimized
for this project
- An internet access of course

Usage
=====

You just have to download the script, edit it to update it's parameters, execute and wait ... If the wifi on the Raspberry is not already configured, don't worry, the script will do it

- Prepair system with these commands:
    - sudo apt-get update
    - sudo rpi-update
    - sudo reboot
    
- Install your USB wifi adapters FIRMWARE and DRIVERS
    - ie:
        - lsusb
        - Look for something like, "Ralink Technology, Corp RT2870/RT3070"
        - sudo apt-get install firmware-ralink
        - sudo reboot
        
- Download the script with the following command   
` git clone https://github.com/pihomeserver/Pi-Hotspot.git `
- Edit the script and update the first lines to define your own configuration (take care that an ethernet link is required)
- Execute the script using sudo (or as root but you already may know that it's not recommanded)
        - You must make script executable and not run with SH for it will ignore shebang and give syntax errors
        - ie: 
           - sudo chmod +x pihotspot.sh
           - sudo ./pihotspot.sh
           (Running with SH will give syntax errors)

A log file named `pihotspot.log` will be created in the folder `/var/log`

Support
=======

Please use input your requests or issues in the GIT repository 

Any contribution is welcome !
