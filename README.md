Zpanel-freebsd
===============
Version 0.23

This script install and configure all you need for ZpanelX


Requirement:
==============
*shell/bash  

 INSTALL
=========
mkdir -p /usr/local/src/zpanelx && cd /usr/local/src/  
fetch http://sourceforge.net/projects/zpanelcp/files/releases/10.0.0/zpanelx-1_0_0.zip  
fetch https://github.com/cbcercas/zpanel-freebsd/archive/master.zip  
unzip -d zpanelx zpanelx-1_0_0.zip && unzip master.zip  
cp -R zpanel-freebsd-master/* zpanelx/etc/build/  
rm -R zpanel-freebsd-master master.zip zpanelx-1_0_0.zip  
cd zpanelx/etc/build/  
vi install-BSD.sh  
and configure all variable as you need, then with root account  
./install-BSD.sh  

 What it does?
===============
1- Update port tree  
2- Install portupgrade  
2- Upgrade all installed port  
3- install all requirement for ZpanelX (apache, php, mysql, ...)  
4- Install ZpanelX and configure all to work.  

 Advertissement:
=================
This script install the minimum to have a working ZpanelX,  
but it doesn't install any security (like fail2ban, postscreen, amavisd, clamav ...).   



If you have any suggestion send me a mail

If you like this script, please give me a beer
@paypal cbcercas@gmail.com
