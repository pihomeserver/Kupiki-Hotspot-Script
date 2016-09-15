What is Pi Hotspot
==================

This project is the latest version of [the tutorial](http://www.pihomeserver.fr/2015/08/05/raspberry-pi-coovachilli-et-freeradius-pour-un-hotspot-wifi-avec-portail-captif/) created first on the blog [Pi Home Server](http://www.pihomeserver.fr)
Created on a Raspberry Pi 2, some functionalities and tools where not available for the Raspberry Pi 3. Also the tutorial was a little bit difficult to 
implement beacause of the too many steps. That's why i decide to create a script that will help you to build easily your own hotspot.

Once the script executed,you will get :
- A Wifi hotspot using the integrated wifi chipset
- A captive portal based on coovachilli
- A user management based on freeRadius
- An interface for freeRadius based on daloRadius

I hope that it will help you to get your Pi hotspot

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

- Download the script with the following command   
` git clone https://github.com/pihomeserver/Pi-Hotspot.git `
- Edit the script and update the first lines to define your own configuration
- Execute the script using sudo (or as root but you already may know that it's not recommanded)

A log file named `pihotspot.log` will be created in the folder `/var/log`

Support
=======

Please use input your requests or issues in the GIT repository 

Any contribution is welcome !