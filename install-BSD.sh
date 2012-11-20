#!/usr/local/bin/bash
###################
## INFO GENERAL ##
###################
# for /etc/hosts
HOSTNAME="HOSTNAME.YOURDOMAIN.COM"

################
## INFO MYSQL ##
################
# Hote Mysql
HOSTDB="localhost"

## To create a MYSQL user for zpanel put 1. and give USERBD and PASSDB, in all case give ROOTPASSDB  
MODUSERSQL="0"
USERDB="MYSQL_ZPANEL_USER"
PASSDB="MYSQL_ZPANEL_PASSWORD"
ROOTPASSDB="MYSQL_ROOT_PASSWORD"
## Pour creer un utilisateur MYSQL different pour proftpd. sinon $USERDB sera utilise
MODUSERFTP="1"
FTPUSERDB="MYSQL_PROFTPD_USER"
FTPPASSDB="MYSQL_PROFTPD_PASSWORD"

##################
## INFO APACHE ##
##################
## TODO what difference ZPANEL_DOMAIN MYHOSTNAME MYDOMAIN
ZPANEL_DOMAIN="CONTROLPANEL.YOURDOMAIN.COM"
SERVER_IP="YOUR_PUBLIC_IP_ADDRESS"

PHPTIMEZONE='"Europe/Paris"'

##################
## INFO POSTFIX  ##
##################
MYHOSTNAME="control.yourdomain.com"
MYDOMAIN="control.yourdomain.com"

###################
## INFO PROFTPD  ##
###################
## Put 1 if you want ftp ipv6
FTPIPV6="0"

##################################################################
##################################################################
##		 NE PAS MODIFIER LA SUITE 			##
##		DO NOT MODIFY THE FOLLOWING			##
##################################################################
##################################################################
## DON'T CHANGE DBNAME* IF YOU DON'T KNOW WHAT YOU DO
## NE PAS CHANGER DBNAME* SI VOUS NE SAVEZ PAS CE QUE VOUS FAITES
DBNAME="zpanel_core"
DBNAMEPOSTFIX="zpanel_postfix"

if [ $MODUSERSQL = 0 ]; then
	PASSDB=$ROOTPASSDB ;
fi
CHEMIN=$(pwd)

#============================
# Update ports et upgrade
#============================
echo "WITHOUT_X11= yes" >> /etc/make.conf
if [ -d "/usr/ports" ]; then 
	portsnap fetch update;
else
	portsnap fetch extract;
fi

cd /usr/ports/ports-mgmt/portupgrade
make BATCH=yes install clean
portupgrade -a --batch
portupgrade -fo devel/pkgconf pkg-config-\*

#============================
#Install the base packages:-
#============================
# Proftpd
cd /usr/ports/databases/proftpd-mod_sql_mysql
make BATCH=yes install clean

# MySQL Server insatll:-
cd /usr/ports/databases/mysql55-server/
make BATCH=yes install clean
cp /usr/local/share/mysql/my-large.cnf /usr/local/etc/my.cnf

# Web
cd /usr/ports/www/apache22/
make BATCH=yes install clean

# Install PHP
cd /usr/ports/lang/php53
make WITH_APACHE=yes WITH_CLI=yes BATCH=yes install clean
cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini
echo "date.timezone = ${PHPTIMEZONE}" >> /usr/local/etc/php.ini
ln -s /usr/local/bin/php /usr/bin/php

#============================
# VERIFIER php-pear  libdb4.7 zip webalizer
#=================================
# Install PHP-extensions
cd /usr/ports/lang/php53-extensions
## TODO options install -DBATCH
make WITH_GD=yes WITH_MCRYPT=yes WITH_MBSTRING=yes WITH_MYSQL=yes WITH_PDO_MYSQL=yes WITH_XLS=yes WITH_XMLRPC=yes WITH_IMAP=yes WITH_CURL=yes WITH_ZIP=yes BATCH=yes install clean

# Install Suhosin...
cd /usr/ports/security/php-suhosin
make BATCH=yes install clean

## Install Mod_BW
cd /usr/ports/www/mod_bw
make BATCH=yes install clean

## Install Postfix28
cd /usr/ports/mail/postfix28
make WITH_DOVECOT2=yes WITH_MYSQL=yes WITH_TLS=yes WITH_SASL2=yes BATCH=YES install clean

## ADD service startup
echo 'apache22_enable="YES"' >> /etc/rc.conf
echo 'apache2ssl_enable="YES"' >> /etc/rc.conf
echo 'accf_http_ready="YES"' >> /etc/rc.conf && kldload accf_http
echo 'mysql_enable="YES"' >> /etc/rc.conf && service mysql-server start
echo 'sendmail_enable="NO"' >> /etc/rc.conf 
echo 'sendmail_submit_enable="NO"' >> /etc/rc.conf
echo 'sendmail_outbound_enable="NO"' >> /etc/rc.conf
echo 'sendmail_msp_queue_enable="NO"' >> /etc/rc.conf
echo 'postfix_enable="YES"' >> /etc/rc.conf
echo 'dovecot_enable="YES"' >> /etc/rc.conf
echo 'proftpd_enable="YES"' >> /etc/rc.conf
# Configure Suhosin in php.ini...
echo "[Suhosin]" >> /usr/local/etc/php.ini
echo "suhosin.session.encrypt = Off" >> /usr/local/etc/php.ini
echo "suhosin.cookie.encrypt = Off" >> /usr/local/etc/php.ini
echo "suhosin.memory.limit = 512M" >> /usr/local/etc/php.ini


portsclean -C
cd $CHEMIN
hash -r

#############################################################################
# ZPanel Enviroment Configuration Tool for Microsoft Windows based systems.	#
#																			#
# Written by Bobby Allen, 19/02/2012										#
# corrected by cbcercas, 13/11/2012. to work on Freebsd						#
#																			#
#############################################################################
clear
echo "ZPanel Enviroment Configuration Tool"
echo "===================================="
echo ""
echo "If you need help, please visit our forums: http://forums.zpanelcp.com/"
echo ""
echo "Creating folder structure.."
mkdir /usr/local/etc/zpanel
mkdir /usr/local/etc/zpanel/configs
mkdir /usr/local/etc/zpanel/panel
mkdir /usr/local/etc/zpanel/docs
mkdir /var/zpanel
mkdir /var/zpanel/hostdata
mkdir /var/zpanel/hostdata/zadmin
mkdir /var/zpanel/hostdata/zadmin/public_html
mkdir /var/zpanel/logs
mkdir /var/zpanel/backups
mkdir /var/zpanel/temp
echo "Complete!"
echo "Copying ZPanel files into place.."
cp -R ../../* /usr/local/etc/zpanel/panel/ 
echo "Complete!"
echo "Copying application configuration files.."
cp -R -v config_packs/freebsd/* /usr/local/etc/zpanel/configs
echo "Complete!"
echo "Setting permissions.."
## NEED more security 644?
chgrp -R www /usr/local/etc/zpanel/
chmod -R 774 /usr/local/etc/zpanel/
chmod -R 774 /var/zpanel/
chmod 640 /usr/local/etc/zpanel/panel/etc/apps/phpmyadmin/config.inc.php
chmod 655 /usr/local/etc/zpanel/configs/apache/httpd.conf
chmod 640 /usr/local/etc/zpanel/panel/cnf/db.php
echo "Complete!"
echo "Registering 'zppy' client.."
ln -s /usr/local/etc/zpanel/panel/bin/zppy /usr/local/bin/zppy
chmod +x /usr/local/bin/zppy
ln -s /usr/local/etc/zpanel/panel/bin/setso /usr/local/bin/setso
chmod +x /usr/local/bin/setso
echo "Complete!"
echo ""
echo ""
echo "The Zpanel directories have now been created in /usr/local/etc/zpanel and /var/zpanel"
echo ""

#############################################################################
#============================
#	MYSQL Database
#============================
# create mysql root password
mysqladmin -u root password ${ROOTPASSDB}

echo "sql set password ok";

#============================
#SET ZPANEL DATABASE CONFIG:
#============================
if [ ${HOSTDB} != 'localhost' ]; then
sed -i -e "s/localhost/${HOSTDB}/g" /usr/local/etc/zpanel/panel/cnf/db.php ;
fi
#if [ ${DBNAME} != 'zpanel_core' ]
#sed -i -e "s/zpanel_core/${DBNAME}/g" /usr/local/etc/zpanel/panel/cnf/db.php
#fi
if [ ${MODUSERSQL} = 1 ]; then
	## Create USERDB
	echo "GRANT USAGE ON *.* TO '${USERDB}'@'localhost' IDENTIFIED BY '${PASSDB}';" | mysql -uroot -p${ROOTPASSDB} ;
	echo "GRANT ALL PRIVILEGES ON \`zpanel\_%\`.* TO '${USERDB}'@'localhost';" | mysql -uroot -p${ROOTPASSDB} ;
	sed -i -e "s/root/${USERDB}/g" /usr/local/etc/zpanel/panel/cnf/db.php ;
fi 
sed -i -e "s/\$pass\ \=\ \"\"\;/\$pass\ =\ \"${PASSDB}\";/g" /usr/local/etc/zpanel/panel/cnf/db.php
echo "Zpanel ok";
# Import zpanel_core database
mysql -uroot -p${ROOTPASSDB} < /usr/local/etc/zpanel/configs/zpanel_core.sql
# Import zpanel_postfix database
mysql -uroot -p${ROOTPASSDB} < /usr/local/etc/zpanel/configs/postfix/zpanel_postfix.sql
# Import zpanel_roundcube database
mysql -uroot -p${ROOTPASSDB} < /usr/local/etc/zpanel/configs/roundcube/zpanel_roundcube.sql
# Import zpanel_proftpd
mysql -uroot -p${ROOTPASSDB} < /usr/local/etc/zpanel/configs/proftpd/zpanel_proftpd.sql

echo "import sql ok";

## TODO change sed commande 
sed -i -e "21 s/.*/&\$rcmail_config[\'db_dsnw\'] = \'mysql\:\/\/${USERDB}\:${PASSDB}\@localhost\/zpanel_roundcube';/" /usr/local/etc/zpanel/panel/etc/apps/webmail/config/db.inc.php


#============================
#Configure Apache 
#============================
## TODO YOUREMAIL@YOUDOMAIN.COM in httpd-vhost.conf
## TODO servername in httpd-vhost.conf
echo "127.0.0.1 $HOSTNAME" >> /etc/hosts
echo "::1 $HOSTNAME" >> /etc/hosts
ln -s /usr/local/etc/zpanel/configs/apache/httpd.conf /usr/local/etc/apache22/Includes/zpanel.conf

#*Set ZPanel Network info and compile the default vhost.conf
/usr/local/etc/zpanel/panel/bin/setso --set zpanel_domain $ZPANEL_DOMAIN
/usr/local/etc/zpanel/panel/bin/setso --set server_ip $SERVER_IP
php /usr/local/etc/zpanel/panel/bin/daemon.php

echo "Apache ok";

mkdir -p /var/zpanel/vmail
## TODO need 777 security?
chmod -R 777 /var/zpanel/vmail
chmod -R g+s /var/zpanel/vmail
pw groupadd vmail -g 5000
pw useradd vmail -u 5000 -g vmail -s /usr/sbin/nologin -d /nonexistent -c "Virtual Mail Owner"
chown -R vmail:vmail /var/zpanel/vmail


# Postfix Master.cf
echo "# Dovecot LDA" >> /usr/local/etc/postfix/master.cf
echo "dovecot   unix  -       n       n       -       -       pipe" >> /usr/local/etc/postfix/master.cf
## TODO dovecot "-f ${sender}" ?

echo '  flags=DRhu user=vmail:mail argv=/usr/lib/dovecot/deliver -d ${recipient}' >> /usr/local/etc/postfix/master.cf

	for file in /usr/local/etc/zpanel/configs/postfix/conf/dovecot-sql.conf
		do
			sed -i -e "s/localhost/${HOSTDB}/g" $file
			sed -i -e "s/zpanel_postfix/${DBNAMEPOSTFIX}/g" $file
			sed -i -e "s/zpanel/${USERDB}/g" $file
			sed -i -e "s/PASSDB/${PASSDB}/g" $file
		done

	for file in /usr/local/etc/zpanel/configs/postfix/conf/mysql*
		do
			sed -i -e "s/localhost/${HOSTDB}/g" $file
			sed -i -e "s/zpanel_postfix/${DBNAMEPOSTFIX}/g" $file
			sed -i -e "s/zpanel/${USERDB}/g" $file
			sed -i -e "s/PASSDB/${PASSDB}/g" $file
		done

mv /usr/local/etc/postfix/main.cf /usr/local/etc/postfix/main.old
ln -s /usr/local/etc/zpanel/configs/postfix/conf/main.cf /usr/local/etc/postfix/main.cf
ln -s /usr/local/etc/zpanel/configs/dovecot2/dovecot.conf /usr/local/etc/dovecot/dovecot.conf

sed -i -e "s/control.yourdomain.tld/${MYHOSTNAME}/g" /usr/local/etc/zpanel/configs/postfix/conf/main.cf
sed -i -e "s/youromain.com/${MYDOMAIN}/g" /usr/local/etc/zpanel/configs/postfix/conf/main.cf

echo "postfix ok";

## Configuration ProFTPD
#=================
## TODO changer ServerAdmin  root@localhost dans proftpd-mysql.conf
pw groupadd ftpgroup -g 2001
pw useradd ftpuser -u 2001 -s /usr/sbin/nologin -d /nonexistent -c "proftpd user" -g ftpgroup

if [ ${MODUSERFTP} = 1 ]; then
        ## Create FTPUSERDB
        echo "GRANT USAGE ON *.* TO '${FTPUSERDB}'@'localhost' IDENTIFIED BY '${FTPPASSDB}';" | mysql -uroot -p${ROOTPASSDB};
        echo "GRANT ALL PRIVILEGES ON zpanel_proftpd.* TO '${USERDB}'@'localhost';" | mysql -uroot -p${ROOTPASSDB};
        else
                FTPUSERDB=$USERDB;
                FTPPASSDB=$PASSDB;
        ##sed -i -e "s/root/${USERDB}/g" /usr/local/etc/zpanel/panel/cnf/db.php
fi
        sed -i -e "s/FTPUSERDB/${FTPUSERDB}/g" /usr/local/etc/zpanel/configs/proftpd/proftpd-mysql.conf
        sed -i -e "s/FTPPASSDB/${FTPPASSDB}/g" /usr/local/etc/zpanel/configs/proftpd/proftpd-mysql.conf

#touch /usr/local/etc/proftpd.conf
if [ ${FTPIPV6} = 0 ]; then
	echo "UseIPv6 off" >> /usr/local/etc/zpanel/conf/proftpd.conf;
fi
echo "include /etc/zpanel/configs/proftpd/proftpd-mysql.conf" >> /usr/local/etc/proftpd/proftpd.conf
touch /var/zpanel/logs/proftpd
chmod -R 644 /var/zpanel/logs/proftpd

echo "proftpd ok";

#Install BIND DNS Server:-
#=========================
mkdir /var/zpanel/logs/bind
touch /var/zpanel/logs/bind/bind.log
chmod -R 777 /var/zpanel/logs/bind/bind.log
ln /var/zpanel/logs/bind/bind.log /var/named/var/log/bind.log
echo "include \"/etc/namedb/zpanel.log.conf\";" >> /etc/namedb/named.conf
echo "include \"/etc/namedb/zpanel.named.conf\";" >> /etc/namedb/named.conf
ln /usr/local/etc/zpanel/configs/bind/etc/named.conf /var/named/etc/namedb/zpanel.named.conf
ln /usr/local/etc/zpanel/configs/bind/etc/log.conf /var/named/etc/namedb/zpanel.log.conf
ln -s /usr/sbin/named-checkconf /usr/bin/named-checkconf
ln -s /usr/sbin/named-checkzone /usr/bin/named-checkzone
ln -s /usr/sbin/named-compilezone /usr/bin/named-compilezone

echo 'named_enable="YES"' >> /etc/rc.conf

echo "named ok";
#ZPANEL ZSUDO:
#====================================
# Must be owned by root with 4777 permissions, or zsudo will not work!
cc -o /usr/local/etc/zpanel/panel/bin/zsudo /usr/local/etc/zpanel/configs/bin/zsudo.c
chown root /usr/local/etc/zpanel/panel/bin/zsudo
chmod +s /usr/local/etc/zpanel/panel/bin/zsudo
echo "zsudo ok";

#Setup the CRON job for the zdaemon:-
#====================================
#touch /etc/cron.d/zdaemon
echo "*/5 * * * * root /usr/bin/php -q /etc/zpanel/panel/bin/daemon.php >> /dev/null 2>&1" >> /etc/crontab

#Registering the zppy client:-
#=============================
ln -s /etc/zpanel/panel/bin/zppy /usr/bin/zppy

## SECURITY
rm /root/.history

echo "Server will need a reboot for postfix to be fully functional"
#REBOOT SERVER
echo "Browse to http://$HOSTNAME (Or by your server IP) http://xxx.xxx.xxx.xxx"
echo "USER: zadmin"
echo "PASS: password (Change on 1st login!)"
