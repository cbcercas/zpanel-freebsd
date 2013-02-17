#!/usr/local/bin/bash

## check if script run as root
#if [ "$(id -u)" != "0" ]; then
#  echo "This script must be run as root" 1>&2
#  exit 1
#fi

DIALOG=dialog
tempfile1=`ZpanelX 2>/dev/null` || tempfile1=/tmp/ZpanelX_1_$$
tempfile2=`ZpanelX 2>/dev/null` || tempfile2=/tmp/ZpanelX_2_$$
tempfile3=`ZpanelX 2>/dev/null` || tempfile3=/tmp/ZpanelX_3_$$
tempfile4=`ZpanelX 2>/dev/null` || tempfile4=/tmp/ZpanelX_4_$$
touch $tempfile1 $tempfile2 $tempfile3 $tempfile4
chmod 700 $tempfile1 $tempfile2 $tempfile3 $tempfile4
IP=`fetch -q -o - http://checkip.dyndns.org | sed -e 's/[^:]*: //' -e 's/<.*$//'`

trap "rm -f $tempfile1 $tempfile2 $tempfile3 $tempfile4" 0 1 2 5 15

	echo "HOSTNAME MYNAME" > $tempfile1
	echo "MY_DOMAIN MYDOMAIN" >> $tempfile1
	echo "MYSQL_HOST LOCALHOST" >> $tempfile1
	echo "MYSQL_ROOT_PASSWORD RPASSWORD" >> $tempfile1
	echo "MYSQL_ZPANEL_USER zpanelx" >> $tempfile1
	echo "MYSQL_ZPANEL_PASSWORD ZPASSWORD" >> $tempfile1
	echo "MOD_PROFTPD_MYSQL_USER 0" >> $tempfile1
	echo "MYSQL_PROFTPD_USER proftpduser" >> $tempfile1
	echo "MYSQL_PROFTPD_PASSWORD proftpdpassword" >> $tempfile1
	echo "ZPANEL_VHOST zvhost" >> $tempfile1
	echo "SERVER_IP SERVERIP" >> $tempfile1
	echo "PHPTIMEZONE PHPTZONE" >> $tempfile1
	echo "POSTFIX_HOSTNAME postfixname" >> $tempfile1
	echo "POSTFIX_DOMAIN postfixdomain" >> $tempfile1
	echo "FTP_IPV6 0" >> $tempfile1
	cp ${tempfile1} ${tempfile3};

_view () {
        $DIALOG --backtitle "ZpanelX-Freebsd Installer by cbcercas" \
        		--title "ZpanelX Configuration" --clear \
        		--exit-label OK \
        		--textbox $1 0 0
}

_defaultyn () {
        $DIALOG --backtitle "ZpanelX-Freebsd Installer by cbcercas" \
                --title "ZpanelX Configuration" --clear \
                --yesno "Are you sure you want to use this configuration?" 0 0
		retval=$?
		case $retval in
			0) _install $tempfile1;;
			1) _main;;
#_menuperso;;
			255) _escape _defaultyn;;
		esac
}

_hostname () {
	$DIALOG --backtitle "ZpanelX-Freebsd Installer by cbcercas" \
			--title "Hostname" --clear \
			--form "Enter the Host info:" 0 0 0 \
				"Hostname (without domain) :" 1 1 "`echo $HOSTNAME |awk -F. '{ print $1 }'`" 1 30 25 30  \
				"Domain                    :" 2 1 "`echo $HOSTNAME |awk -F. '{$1="";OFS="." ; print $0}' | sed 's/^.//' `" 2 30 25 30  2> $tempfile2
	retval=$?
	case $retval in
	  0)  a=( `cat ${tempfile2}` ); HOST=${a[0]}.${a[1]}; DOMAIN=${a[1]};
			sed -i "" "1,1s/MYNAME/$HOST/g" $tempfile3 ;
			sed -i "" "2,2s/MYDOMAIN/$DOMAIN/g" $tempfile3 ;;
	  1) _menuperso;;
	  255) _escape _hostname;;
	esac
}

_hostdb () {
	$DIALOG --backtitle "ZpanelX-Freebsd Installer by cbcercas" \
			--title "Mysql Host" --clear \
			--inputbox "Please, enter Mysql hote (ip or fqdn):  " 8 45 "localhost" 2> $tempfile2
	
	retval=$?
	param=(`cat $tempfile2`)
	case $retval in
	  0) sed -i "" "3,3s/LOCALHOST/$param/g" $tempfile3 ;;
	  1) _menuperso;;
	  255) _escape _hostdb;;
	esac
}

_rootmysql () {
	$DIALOG --backtitle "ZpanelX-Freebsd Installer by cbcercas" \
			--title "Mysql Root password" --clear \
			--insecure \
			--passwordbox "Please, enter Mysql root password:  " 8 40 "" 2> $tempfile2
	retval=$?
	param=( `cat $tempfile2` )
	echo "" > $tempfile2		
	case $retval in
	  0) if [[ -z ${param} ]]; then
				$DIALOG --colors --msgbox "\Z1\ZuPassword can't be null ! " 5 29 
				_rootmysql;
		fi;
		sed -i "" "4,4s/RPASSWORD/$param/g" $tempfile3 ;;

	  1) _menuperso;;
	  255) _escape _rootmysql;;
	esac
}

_zpanelmysql () {
	if [[ -z "$1" ]]; then
		zmu=zpanelx
	else
		zmu=$1
	fi
	$DIALOG --backtitle "ZpanelX-Freebsd Installer by cbcercas" \
			--title " ZpanelX Mysql User " --clear \
			--insecure \
			--mixedform "Enter the Mysql ZpanelX user info:" 25 60 16 \
				"Username        :" 1 1 "$zmu" 1 25 25 30 0 \
				"Password        :" 2 1 "" 2 25 25 30 1 \
				"Retype Password :" 3 1 "" 3 25 25 30 1  2> $tempfile2
	retval=$?
	a=( `cat ${tempfile2}` );
	echo "" > $tempfile2
	case $retval in
		0) 	if [[ -z "${a[2]}" ]]; then
				$DIALOG --colors --msgbox "\Z1\ZuPassword can't be null ! " 5 29 
	        	_zpanelmysql ${a[0]} ; 
			else 
				if [[ "${a[1]}" != "${a[2]}" ]]; then
					$DIALOG --colors --msgbox "\Z1\ZuPassword don't match ! " 5 26 
							_zpanelmysql ${a[0]} ;
				fi
				sed -i "" "5,5s/zpanelx/${a[0]}/g" $tempfile3 
				sed -i "" "6,6s/ZPASSWORD/${a[1]}/g" $tempfile3 
			fi;;
		1) _menuperso;;
		255) _escape _zpanelmysql;;
	esac

}

_modproftpdmysql () {
	$DIALOG --backtitle "ZpanelX-Freebsd Installer by cbcercas" \
	        --title " Mod Proftpd Mysql User " --clear \
	        --yesno "Do you want to create a mysql user for Proftpd ?" 8 52
	retval=$?
	case $retval in
	  0) sed -i "" "7,7s/0/1/g" $tempfile3;
		_proftpdmysql;;
	  1) tmp=(`cat $tempfile3 | grep MYSQL_ZPANEL_USER`)
			sed -i "" "8,8s/proftpduser/${tmp[1]}/g" $tempfile3 ;
		 tmp=(`cat $tempfile3 | grep MYSQL_ZPANEL_PASSWORD`)
		 	sed -i "" "9,9s/proftpdpassword/${tmp[1]}/g" $tempfile3 ;;
	  255) _escape _modproftpdmysql;;
	esac
}

_proftpdmysql () {
	if [[ -z "$1" ]]; then
		pmu=proftpd
	else
		pmu=$1
	fi
	$DIALOG --backtitle "ZpanelX-Freebsd Installer by cbcercas" \
			--title " Proftpd Mysql User " --clear \
			--insecure \
			--mixedform "Enter the Mysql Proftpd user info:" 25 60 16 \
				"Username        :" 1 1 "$pmu" 1 25 25 30 0 \
				"Password        :" 2 1 "" 2 25 25 30 1 \
				"Retype Password :" 3 1 "" 3 25 25 30 1  2> $tempfile2
	retval=$?
	a=( `cat ${tempfile2}` );
	echo "" > $tempfile2
	case $retval in
		0) if [[ -z "${a[2]}" ]]; then
				$DIALOG --colors --msgbox "\Z1\ZuPassword can't be null ! " 5 29 
	        	_proftpdmysql ${a[0]} ; 
			else 
				if [[ "${a[1]}" != "${a[2]}" ]]; then
					$DIALOG --colors --msgbox "\Z1\ZuPassword don't match ! " 5 26 
							_proftpdmysql ${a[0]} ;
				fi
				sed -i "" "8,8s/proftpduser/${a[0]}/g" $tempfile3 ;
				sed -i "" "9,9s/proftpdpassword/${a[1]}/g" $tempfile3 ;
						fi;;
		1) _menuperso;;
		255) _escape _proftpdmysql;;
	esac
}

_apache () {
	$DIALOG --backtitle "ZpanelX-Freebsd Installer by cbcercas" \
			--title " Apache configuration " --clear \
			--form "Enter the apache info:" 0 0 0 \
				"ZpanelX Vhost (without domain) :" 1 1 "panel" 1 30 25 30  \
				"Server IP                      :" 2 1 "$IP" 2 30 25 30  2> $tempfile2
	retval=$?
	case $retval in
	  0) a=( `cat ${tempfile2}` );
			sed -i "" "10,10s/zvhost/${a[0]}.${DOMAIN}/g" $tempfile3 ;
			sed -i "" "11,11s/SERVERIP/${a[1]}/g" $tempfile3 ;;
	  1) _menuperso;;
	  255) _escape _apache;;
	esac
}

_phptimezone () {
	$DIALOG --backtitle "ZpanelX-Freebsd Installer by cbcercas" \
			--title " PHPTIMEZONE " --clear \
			--menu "Select Timezone:" 0 0 0 \
					Etc/GMT-12 "Eniwetok, Kwajalein" \
					Etc/GMT-11 "Midway Island, Samoa" \
					Etc/GMT-10 "Hawaii" \
					Etc/GMT-9  "Alaska" \
					Etc/GMT-8  "Pacific Time (US; Canada)" \
					Etc/GMT-7  "Mountain Time (US; Canada)" \
					Etc/GMT-6  "Central Time (US; Canada), Mexico City" \
					Etc/GMT-5  "Eastern Time (US; Canada), Bogota, Lima" \
					Etc/GMT-4  "Atlantic Time (Canada), Caracas, La Paz" \
					Etc/GMT-3  "Brazil, Buenos Aires, Georgetown" \
					Etc/GMT-2  "Mid-Atlantic" \
					Etc/GMT-1  "Azores, Cape Verde Islands" \
					Etc/GMT    "Western Europe Time, London, Lisbon, Casablanca" \
					Etc/GMT+1  "Brussels, Copenhagen, Madrid, Paris" \
					Etc/GMT+2  "Kaliningrad, South Africa" \
					Etc/GMT+3  "Baghdad, Riyadh, Moscow, St. Petersburg" \
					Etc/GMT+4  "Abu Dhabi, Muscat, Baku, Tbilisi" \
					Etc/GMT+5  "Ekaterinburg, Islamabad, Karachi, Tashkent" \
					Etc/GMT+6  "Almaty, Dhaka, Colombo" \
					Etc/GMT+7  "Bangkok, Hanoi, Jakarta" \
					Etc/GMT+8  "Beijing, Perth, Singapore, Hong Kong" \
					Etc/GMT+9  "Tokyo, Seoul, Osaka, Sapporo, Yakutsk" \
					Etc/GMT+10 "Eastern Australia, Guam, Vladivostok" \
					Etc/GMT+11 "Magadan, Solomon Islands, New Caledonia" \
					Etc/GMT+12 "Auckland, Wellington, Fiji, Kamchatka" \
					Other  "" 2> $tempfile2
	retval=$?
	param=$(cat $tempfile2)
	case $retval in
		0) if [[ $param = Other ]]; then
	  		$DIALOG --backtitle "ZpanelX-Freebsd Installer by cbcercas" \
			--title "PHPTIMEZONE" --clear \
			--inputbox "Enter your timezone (Continent/City):  " 0 0 "" 2> $tempfile2
			case $? in
				0) param=$(cat $tempfile2) ;;
				1) _menuperso;;
				255) _escape;;
			esac
		fi;
	sed -i "" "s/\// /g" $tempfile2
	a=( `cat ${tempfile2}` )
	sed -i "" "12,12s/PHPTZONE/${a[0]}\/${a[1]}/g" $1 ;;
		1) _menuperso;;
	  	255) _escape _phptimezone;;
	esac
}

_postfix () {
	$DIALOG --backtitle "ZpanelX-Freebsd Installer by cbcercas" \
			--title "Postfix" --clear \
			--form "Enter the Postfix info:" 0 0 0 \
				"My Hostname  :" 1 1 "$HOSTNAME" 1 25 25 30  \
				"My Domain    :" 2 1 "`echo $HOSTNAME |awk -F. '{$1="";OFS="." ; print $0}' | sed 's/^.//' `" 2 25 25 30  2> $tempfile2
	retval=$?
	case $retval in
		0) a=( `cat ${tempfile2}` );
			sed -i "" "13,13s/postfixname/${a[0]}/g" $tempfile3 ;
			sed -i "" "14,14s/postfixdomain/${a[1]}/g" $tempfile3 ;;
		1) _menuperso;;
		255) _escape _postfix;;
	esac
}

_ftpv6 () {
	$DIALOG --backtitle "ZpanelX-Freebsd Installer by cbcercas" \
	        --title " Proftpd IpV6 support " --clear \
	        --yesno "Do you want support Ipv6 in Proftpd ?" 5 41
	retval=$?
	case $retval in
	  0) sed -i "" "15,15s/0/1/g" $tempfile3 ;;
	  1) ;;
	  255) _escape _ftpv6;;
	esac
}

_escape () {
	$DIALOG --backtitle "ZpanelX-Freebsd Installer by cbcercas" \
			--title "Exit" --clear \
			--yesno "Are you sure you want to exit?" 5 34
		retval=$?
		case $retval in
			0) exit;;
			1) $1;;
			255) exit;;
		esac
}

_menuperso () {
	items=$(awk -F\: '{print $1,$2}' $tempfile3)
	$DIALOG --backtitle "ZpanelX-Freebsd Installer by cbcercas" \
			--title "Menu Perso" \
			--menu "What you want to change :" 0 0 0 $items 2> $tempfile2

		retval=$?
		parameter=$(cat $tempfile2)
	case $retval in
		1) _main;;
		255) _escape _menuperso;;
	esac
	[ $retval -eq 0 ] && tochange=$parameter || return 1
	val=$(awk -F\: -v x=$tochange '$1==x {print $2}' $tempfile3)
	
	$DIALOG --backtitle "ZpanelX-Freebsd Installer by cbcercas" \
			--clear --title "Inputbox" \
			--inputbox "Enter new value for: \n \n    $tochange " 0 0 $val 2> $tempfile4
	retval=$?
	case $retval in
		1) _menuperso;;
		255) _escape _menuperso;;
	esac
	$DIALOG --backtitle "ZpanelX-Freebsd Installer by cbcercas" \
			--title "Confirmation"  --yesno "Commit ?" 0 0
	retval=$?
	case $retval in
	    0) newval=$(cat $tempfile4)
	       awk -v x=$tochange -v n=$newval '
	            BEGIN {FS=OFS=" "}$1==x {$2=n} {print}
	            ' $tempfile3 > $tempfile3.tmp
	       mv $tempfile3.tmp $tempfile3 ; 
	       _menuperso;;
	    1)	_menuperso;;
		255) dialog --infobox "No Changes done" 0 0
	           sleep 2;
	           _escape _menuperso;;
	esac
}

_installdefault () {
	#_menuperso;
	RMDP=`tr -d -c "a-zA-Z0-9" < /dev/urandom | head -c 10`
	ZMDP=`tr -d -c "a-zA-Z0-9" < /dev/urandom | head -c 10`
	DOMAIN=`echo $HOSTNAME |awk -F. '{$1="";OFS="." ; print $0}' | sed 's/^.//' `
	sed -i "" "1,1s/MYNAME/${HOSTNAME}/g" $tempfile1 ;
	sed -i "" "2,2s/MYDOMAIN/${DOMAIN}/g" $tempfile1 ;
	sed -i "" "4,4s/RPASSWORD/${RMDP}/g" $tempfile1 ;
	sed -i "" "6,6s/ZPASSWORD/${ZMDP}/g" $tempfile1 ;
	sed -i "" "8,8s/proftpduser/zpanelx/g" $tempfile1 ;
	sed -i "" "9,9s/proftpdpassword/${ZMDP}/g" $tempfile1 ;
	sed -i "" "10,10s/zvhost/admin.${DOMAIN}/g" $tempfile1 ;
	sed -i "" "11,11s/SERVERIP/${IP}/g" $tempfile1 ;
	sed -i "" "13,13s/postfixname/${HOSTNAME}/g" $tempfile1 ;
	sed -i "" "14,14s/postfixdomain/${DOMAIN}/g" $tempfile1 ;
	_phptimezone $tempfile1 ;
	_view $tempfile1 ;
	_defaultyn;
}

_installperso () {
	_hostname;
	_hostdb;
	_rootmysql;
	_zpanelmysql;
	_modproftpdmysql;
	_apache;
	_postfix;
	_ftpv6;
	_phptimezone $tempfile3;
	_view $tempfile3;
#TODO add confirmation and redirect menuperso if !=
	_install $tempfile3;
}

_install() {
	## Export des variables
		while read line ;do
			a=( $line );
			if [[ "${a[O]]}" = "PHPTIMEZONE" ]]; then
				export ${a[O]]}='"'${a[1]]}'"';
			else 
				export ${a[O]]}=${a[1]]};
		done < $1
#
		##!/usr/local/bin/bash
#
		##if [ $MOD_ZPANEL_MYSQL_USER = 0 ]; then
		##	MYSQL_ZPANEL_USER=$MYSQL_ROOT_PASSWORD ;
		##fi
		CHEMIN=$(pwd)
#
		##============================
		## Update ports et upgrade
		##============================
		echo "WITHOUT_X11=yes" >> /etc/make.conf
		if [ -d "/usr/ports" ]; then 
			portsnap fetch update;
		else
			portsnap fetch extract;
		fi
#
		cd /usr/ports/ports-mgmt/portupgrade
		make BATCH=yes install clean
		hash -r
		portupgrade -a --batch
		portupgrade -fo devel/pkgconf pkg-config-\*
#
		##============================
		##Install the base packages:-
		##============================
		## Proftpd
		cd /usr/ports/databases/proftpd-mod_sql_mysql
		make BATCH=yes install clean
#
		# MySQL Server insatll:-
		cd /usr/ports/databases/mysql55-server/
		make BATCH=yes install clean
		cp /usr/local/share/mysql/my-large.cnf /usr/local/etc/my.cnf
#
		# Web
		cd /usr/ports/www/apache22/
		make BATCH=yes install clean
#		# Install PHP
		cd /usr/ports/lang/php53
		make WITH_APACHE=yes WITH_CLI=yes BATCH=yes install clean
		cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini
		echo "date.timezone = ${PHPTIMEZONE}" >> /usr/local/etc/php.ini
		ln -s /usr/local/bin/php /usr/bin/php
#
		##============================
		## VERIFIER php-pear  libdb4.7 zip webalizer
		##=================================
		## Install PHP-extensions
		cd /usr/ports/lang/php53-extensions
		## TODO options install -DBATCH
		make WITH_GD=yes WITH_MCRYPT=yes WITH_MBSTRING=yes WITH_MYSQL=yes WITH_PDO_MYSQL=yes WITH_XLS=yes WITH_XMLRPC=yes WITH_IMAP=yes WITH_CURL=yes WITH_ZIP=yes BATCH=yes install clean
#
		## Install Suhosin...
		cd /usr/ports/security/php-suhosin
		make BATCH=yes install clean
#
		### Install Mod_BW
		cd /usr/ports/www/mod_bw
		make BATCH=yes install clean
#
		### Install Postfix28
		cd /usr/ports/mail/postfix28
		make WITH_DOVECOT2=yes WITH_MYSQL=yes WITH_TLS=yes WITH_SASL2=yes BATCH=YES install clean
#
		### ADD service startup
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
		## Configure Suhosin in php.ini...
		echo "[Suhosin]" >> /usr/local/etc/php.ini
		echo "suhosin.session.encrypt = Off" >> /usr/local/etc/php.ini
		echo "suhosin.cookie.encrypt = Off" >> /usr/local/etc/php.ini
		echo "suhosin.memory.limit = 512M" >> /usr/local/etc/php.ini
#
#
		portsclean -C
		cd $CHEMIN
		hash -r
#
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
		echo ${MYSQL_ROOT_PASSWORD}
		mysqladmin -u root password ${MYSQL_ROOT_PASSWORD}

		echo "sql set password ok";

		#============================
		# ZPANEL DATABASE CONFIGURATION :
		#============================		
		
		if [ ${MYSQL_HOST} != 'localhost' ]; then
		sed -i "" "s/localhost/${MYSQL_HOST}/g" /usr/local/etc/zpanel/panel/cnf/db.php ;
		fi
		## Create USERDB
		echo "GRANT USAGE ON *.* TO '${MYSQL_ZPANEL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_ZPANEL_PASSWORD}';" | mysql -uroot -p${MYSQL_ROOT_PASSWORD} ;
		echo "GRANT ALL PRIVILEGES ON \`zpanel\_%\`.* TO '${MYSQL_ZPANEL_USER}'@'localhost';" | mysql -uroot -p${MYSQL_ROOT_PASSWORD} ;
		
		sed -i "" "s/root/${MYSQL_ZPANEL_USER}/g" /usr/local/etc/zpanel/panel/cnf/db.php ;
		sed -i "" "s/YOUR_ROOT_MYSQL_PASSWORD/${MYSQL_ZPANEL_PASSWORD}/g" /usr/local/etc/zpanel/panel/cnf/db.php;
		echo "Zpanel DB ok";

		# Import zpanel_core database
		mysql -uroot -p${MYSQL_ROOT_PASSWORD} < /usr/local/etc/zpanel/configs/zpanel_core.sql
		# Import zpanel_postfix database
		mysql -uroot -p${MYSQL_ROOT_PASSWORD} < /usr/local/etc/zpanel/configs/postfix/zpanel_postfix.sql
		# Import zpanel_roundcube database
		mysql -uroot -p${MYSQL_ROOT_PASSWORD} < /usr/local/etc/zpanel/configs/roundcube/zpanel_roundcube.sql
		# Import zpanel_proftpd
		mysql -uroot -p${MYSQL_ROOT_PASSWORD} < /usr/local/etc/zpanel/configs/proftpd/zpanel_proftpd.sql

		echo "import sql ok";

		cp /usr/local/etc/zpanel/panel/etc/apps/webmail/config/db.inc.php.dist /usr/local/etc/zpanel/panel/etc/apps/webmail/config/db.inc.php
		sed -i "" "25 s/.*/&\$rcmail_config[\'db_dsnw\'] = \'mysql\:\/\/${MYSQL_ZPANEL_USER}\:${MYSQL_ZPANEL_PASSWORD}\@localhost\/zpanel_roundcube';/" /usr/local/etc/zpanel/panel/etc/apps/webmail/config/db.inc.php


		#============================
		#Configuration Apache 
		#============================
		## TODO YOUREMAIL@YOUDOMAIN.COM in httpd-vhost.conf
		echo "127.0.0.1 $HOSTNAME" >> /etc/hosts
		echo "::1 $HOSTNAME" >> /etc/hosts
		ln -s /usr/local/etc/zpanel/configs/apache/httpd.conf /usr/local/etc/apache22/Includes/zpanel.conf
		sed -i "" "s/HOSTNAME/${ZPANEL_VHOST}/g" /usr/local/etc/zpanel/configs/apache/httpd-vhosts.conf ;

		#*Set ZPanel Network info and compile the default vhost.conf
		/usr/local/etc/zpanel/panel/bin/setso --set zpanel_domain $ZPANEL_VHOST
		/usr/local/etc/zpanel/panel/bin/setso --set server_ip $SERVER_IP
		php /usr/local/etc/zpanel/panel/bin/daemon.php > log.log

		echo "Apache ok";

		#============================
		#Configuration Postfix 
		#============================


		mkdir -p /var/zpanel/vmail
		## TODO need 777 ? security?
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
					sed -i -e "s/localhost/${MYSQL_HOST}/g" $file
					sed -i -e "s/zpanel_postfix/${DBNAMEPOSTFIX}/g" $file
					sed -i -e "s/zpanel/${MYSQL_ZPANEL_USER}/g" $file
					sed -i -e "s/PASSDB/${MYSQL_ZPANEL_PASSWORD}/g" $file
				done

			for file in /usr/local/etc/zpanel/configs/postfix/conf/mysql*
				do
					sed -i -e "s/localhost/${MYSQL_HOST}/g" $file
					sed -i -e "s/zpanel_postfix/${DBNAMEPOSTFIX}/g" $file
					sed -i -e "s/zpanel/${MYSQL_ZPANEL_USER}/g" $file
					sed -i -e "s/PASSDB/${MYSQL_ZPANEL_PASSWORD}/g" $file
				done

		mv /usr/local/etc/postfix/main.cf /usr/local/etc/postfix/main.old
		ln -s /usr/local/etc/zpanel/configs/postfix/conf/main.cf /usr/local/etc/postfix/main.cf
		ln -s /usr/local/etc/zpanel/configs/dovecot2/dovecot.conf /usr/local/etc/dovecot/dovecot.conf

		sed -i -e "s/control.yourdomain.com/${POSTFIX_HOSTNAME}/g" /usr/local/etc/zpanel/configs/postfix/conf/main.cf
		sed -i -e "s/yourdomain.com/${POSTFIX_DOMAIN}/g" /usr/local/etc/zpanel/configs/postfix/conf/main.cf

		echo "postfix ok";

		#=======================
		# Configuration ProFTPD
		#=======================

		## TODO changer ServerAdmin  root@localhost dans proftpd-mysql.conf
		pw groupadd ftpgroup -g 2001
		pw useradd ftpuser -u 2001 -s /usr/sbin/nologin -d /nonexistent -c "proftpd user" -g ftpgroup

		if [ ${MOD_PROFTPD_MYSQL_USER} = 1 ]; then
		        ## Create FTPUSERDB
		        echo "GRANT USAGE ON *.* TO '${MYSQL_PROFTPD_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PROFTPD_PASSWORD}';" | mysql -uroot -p${MYSQL_ROOT_PASSWORD};
		        echo "GRANT ALL PRIVILEGES ON zpanel_proftpd.* TO '${MYSQL_PROFTPD_USER}'@'localhost';" | mysql -uroot -p${MYSQL_ROOT_PASSWORD};
		        else
		                MYSQL_PROFTPD_USER=$MYSQL_ZPANEL_USER;
		                MYSQL_PROFTPD_PASSWORD=$MYSQL_ZPANEL_PASSWORD;
		        ##sed -i -e "s/root/${USERDB}/g" /usr/local/etc/zpanel/panel/cnf/db.php
		fi
		        sed -i -e "s/FTPUSERDB/${MYSQL_PROFTPD_USER}/g" /usr/local/etc/zpanel/configs/proftpd/proftpd-mysql.conf
		        sed -i -e "s/FTPPASSDB/${MYSQL_PROFTPD_PASSWORD}/g" /usr/local/etc/zpanel/configs/proftpd/proftpd-mysql.conf

		#touch /usr/local/etc/proftpd.conf
		if [ ${FTP_IPV6} = 0 ]; then
			echo "UseIPv6 off" >> /usr/local/etc/zpanel/configs/proftpd/proftpd-mysql.conf;
		fi
		echo "include /usr/local/etc/zpanel/configs/proftpd/proftpd-mysql.conf" >> /usr/local/etc/proftpd/proftpd.conf
		touch /var/zpanel/logs/proftpd
		chmod -R 644 /var/zpanel/logs/proftpd

		echo "proftpd ok";

		#=========================
		#Install Namedb DNS Server:
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
		echo "*/5 * * * * root /usr/bin/php -q /usr/local/etc/zpanel/panel/bin/daemon.php >> /dev/null 2>&1" >> /etc/crontab

		#Registering the zppy client:-
		#=============================
		ln -s /etc/zpanel/panel/bin/zppy /usr/bin/zppy

		## SECURITY
		rm /root/.history

		echo "Server will need a reboot for postfix to be fully functional"
		#REBOOT SERVER
		echo "Browse to http://$HOSTNAME (Or by your server IP) http://`ifconfig  | grep -E 'inet.[0-9]' | grep -v '127.0.0.1' | awk '{ print $2}'`"
		echo "Login Username: zadmin"
		echo "Password: password (Change on 1st login!)"

}

_main () {
	$DIALOG --backtitle "ZpanelX-Freebsd Installer by cbcercas" \
                --title "ZpanelX Configuration" --clear \
                --yesno "Do you want to use the default configuration?" 0 0
	retval=$?
	case $retval in
		0) _installdefault;;
		1) _installperso;;
		255) exit;;
	esac
}

_quit () {
	exit;
}

_main
