Zpanel-freebsd
===============
Version 0.23

This script install and configure all you need for ZpanelX


Requirement:
==============
*shell/bash  

 INSTALL
=========
with root account or sudo  
mkdir -p /usr/local/src/ && cd /usr/local/src/  
fetch https://github.com/cbcercas/zpanel-freebsd/archive/test.zip && unzip test.zip  
fetch https://github.com/bobsta63/zpanelx/archive/master.zip && unzip master.zip  
mv zpanelx-master zpanelx-10.0.2  
cp -R zpanel-freebsd-test/* zpanelx-10.0.2/etc/build/  
rm -R zpanel-freebsd-test test.zip master.zip  
cd zpanelx-10.0.2/etc/build/  
./new-install-BSD.sh  

and configure as you need    

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
but it doesn't install (for the moment) any security (like fail2ban, postscreen, amavisd, clamav ...).   


	
If you have any suggestion send me a mail

If you like this script, please give me a beer
@paypal cbcercas@gmail.com
