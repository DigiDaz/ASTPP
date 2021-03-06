#!/bin/bash
###########################################################################
# ASTPP - Open Source VoIP Billing Solution
# Copyright (C) 2016, iNextrix Technologies Pvt. Ltd. (http://www.inextrix.com)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details..
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>
#
############################################################################

#################################
##########  variables ###########
#################################
TEMP_USER_ANSWER="no"
INSTALL_ASTPP="no"
CURRENT_DIR="${PWD}"
DOWNLOAD_DIR="/usr/src"
#ASTPP_SOURCE_DIR="/usr/src/trunk"
ASTPP_SOURCE_DIR=/usr/src/latest
ASTPP_HOST_DOMAIN_NAME="host.domain.tld"

#ASTPP Configuration
ASTPPDIR=/var/lib/astpp/
ASTPPEXECDIR=/usr/local/astpp/
ASTPPLOGDIR=/var/log/astpp/
LOCALE_DIR=/usr/local/share/locale

#Freeswich Configuration
FS_DIR=/usr/local/freeswitch
FS_SOUNDSDIR=${FS_DIR}/sounds/en/us/callie
FS_SCRIPTS=${FS_DIR}/scripts
WWWDIR=/var/www/html

ASTPP_USING_FREESWITCH="no"
ASTPP_USING_ASTERISK="no"
INSTALL_ASTPP_WEB_INTERFACE="no"

ASTPP_DATABASE_NAME="astpp"

ASTPP_DB_USER="astppuser"

MYSQL_ROOT_PASSWORD=""
ASTPPUSER_MYSQL_PASSWORD=""


#################################
####  general functions #########
#################################

# task of function: ask to user yes or no
# usage: ask_to_user_yes_or_no "your question"
# return TEMP_USER_ANSWER variable filled with "yes" or "no"
ask_to_user_yes_or_no () 
{
		# default answer = no
		TEMP_USER_ANSWER="no"
		clear
		echo ""
		echo -e ${1}
		read -n 1 -p "(y/n)? :"
		if [ "${REPLY}" = "y" ]; then
			TEMP_USER_ANSWER="yes"
		else
			TEMP_USER_ANSWER="no"
		fi
}

# Determine the OS architecture
get_os_architecture () 
{
		if [ ${HOSTTYPE} == "x86_64" ]; then
			ARCH=x64
		else
			ARCH=x32
		fi
}
get_os_architecture

# Linux Distribution CentOS or Debian
get_linux_distribution ()
{ 
	V1=`cat /etc/*release | head -n1 | tail -n1 | cut -c 14- | cut -c1-18`
	V2=`cat /etc/*release | head -n7 | tail -n1 | cut -c 14- | cut -c1-14`
	if [ "$V1" = "Debian GNU/Linux 8" ]; then
		DIST="DEBIAN"
		else if [ "$V2" = "CentOS Linux 7" ]; then
			DIST="CENTOS"
		else
			DIST="OTHER"
			echo 'OOoops!!!! Quick Installation does not support your distribution'
			exit 1
		fi
	fi
}														
get_linux_distribution


install_epel () 
{
		yum install epel-release
}

remove_epel () 
{
		# only on CentOS
		yum remove epel-release
}

# Generate random password (for MySQL)
genpasswd() 
{
		length=$1
		[ "$length" == "" ] && length=16
		tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${length} | xargs
}

MYSQL_ROOT_PASSWORD=$(genpasswd)
ASTPPUSER_MYSQL_PASSWORD=$(genpasswd)

#################################
########  ASK SCRIPTS ###########
#################################

# Ask to install astpp
ask_to_install_astpp () 
{

		# License acceptance
		yum -y install wget
		
		clear		
		echo "********************"
		echo "License acceptance"
		echo "********************"		
		if [ -f LICENSE ]; then
			more LICENSE
		else
			wget --no-check-certificate -q -O GNU-AGPLv3.0.txt https://raw.githubusercontent.com/iNextrix/ASTPP/master/LICENSE
			more GNU-AGPLv3.0.txt	
		fi
		echo "***"
		echo "*** I agree to be bound by the terms of the license - [YES/NO]"
		echo "*** " 
		read ACCEPT
		while [ "$ACCEPT" != "yes" ] && [ "$ACCEPT" != "Yes" ] && [ "$ACCEPT" != "YES" ] && [ "$ACCEPT" != "no" ] && [ "$ACCEPT" != "No" ] && [ "$ACCEPT" != "NO" ]; do
			echo "I agree to be bound by the terms of the license - [YES/NO]"
			read ACCEPT
		done
		if [ "$ACCEPT" != "yes" ] && [ "$ACCEPT" != "Yes" ] && [ "$ACCEPT" != "YES" ]; then
			echo "License rejected!"
			exit 0
		else
			echo "Licence accepted!"
			echo "============checking your working directory=================="			
			git clone https://github.com/iNextrix/ASTPP
			cp -rf ASTPP latest			
			if [ ${CURRENT_DIR} == ${DOWNLOAD_DIR} ]; then
				echo "dir is '$CURRENT_DIR' and it's matched!!!"			
			else			
				echo "dir is '$CURRENT_DIR' and not matched!!!"
				mv -f ${CURRENT_DIR}/latest ${DOWNLOAD_DIR}/.			
				clear
				echo "====================Starting installation again======================"
				sleep 10
				#cd ${ASTPP_SOURCE_DIR} && chmod +x install.sh && ./install.sh			
				clear
			fi
		fi
		ask_to_user_yes_or_no "Do you want to install ASTPP?"
		if [ "${TEMP_USER_ANSWER}" = "yes" ]; then
			INSTALL_ASTPP="yes"
			echo ""
			read -p "Enter FQDN example (i.e ${ASTPP_HOST_DOMAIN_NAME}): "
			ASTPP_HOST_DOMAIN_NAME=${REPLY}
			echo "Your entered FQDN is : ${ASTPP_HOST_DOMAIN_NAME} "
			echo ""
			read -p "Enter your email address: ${EMAIL}"
			EMAIL=${REPLY}
			read -n 1 -p "Press any key to continue ... "
			ask_to_user_yes_or_no "Do you want use FreeSwitch on ASTPP?"
			if 	[ ${TEMP_USER_ANSWER} = "yes" ]; then
				ASTPP_USING_FREESWITCH="yes"			  
			fi					  
			ask_to_user_yes_or_no "Do you want to install ASTPP web interface?"
			if [ ${TEMP_USER_ANSWER} = "yes" ]; then
				INSTALL_ASTPP_WEB_INTERFACE="yes"
			fi	 
		fi
		echo "Installation Done"
}
ask_to_install_astpp


#################################
####  INSTALL SCRIPTS ###########
#################################

clear
echo -e "Are you ready?"
read -n 1 -p "Press any key to continue ... "
clear

# install freeswitch for astpp
install_freeswitch_for_astpp () 
{  
		if [ ${DIST} = "DEBIAN" ]; then
			apt-get -o Acquire::Check-Valid-Until=false update && apt-get install -y curl
			curl https://files.freeswitch.org/repo/deb/debian/freeswitch_archive_g0.pub | apt-key add -
			echo "deb http://files.freeswitch.org/repo/deb/freeswitch-1.6/ jessie main" > /etc/apt/sources.list.d/freeswitch.list
			apt-get -o Acquire::Check-Valid-Until=false update && apt-get install -y --force-yes freeswitch-video-deps-most
			# Install Freeswitch pre-requisite packages using apt-get
			apt-get install -y autoconf automake devscripts gawk chkconfig ntpdate ntp g++ git-core curl libjpeg62-turbo-dev libncurses5-dev make python-dev pkg-config libgdbm-dev libyuv-dev libdb-dev libvpx2-dev gettext sudo lua5.1 php5 php5-dev php5-common php5-cli php5-gd php-pear php5-cli php-apc php5-curl libxml2 libxml2-dev openssl libcurl4-openssl-dev gettext gcc libldns-dev libpcre3-dev build-essential libssl-dev libspeex-dev libspeexdsp-dev libsqlite3-dev libedit-dev libldns-dev libpq-dev bc
			
			#-------------------MySQL setup in for freeswitch Start ------------------------
			clear
			echo "======================Mysql installation start======================="
			sleep 20
			echo "MySQL root password is set to : ${MYSQL_ROOT_PASSWORD}" 
			echo "astppuser password is set to : ${ASTPPUSER_MYSQL_PASSWORD}"
			echo mysql-server mysql-server/root_password password ${MYSQL_ROOT_PASSWORD} | debconf-set-selections
			echo mysql-server mysql-server/root_password_again password ${MYSQL_ROOT_PASSWORD} | debconf-set-selections
			apt-get install -y mysql-server php5-mysql
			echo "======================Mysql installation end======================="
			sleep 20
			#-------------------MySQL setup in for freeswitch End ------------------------
			
	    elif  [ ${DIST} = "CENTOS" ]; then
			#yum install -y git
			# Install Freeswitch pre-requisite packages using yum
			yum groupinstall "Development tools" -y
			install_epel
			rpm -Uvh http://files.freeswitch.org/freeswitch-release-1-6.noarch.rpm
			yum install epel-release
			yum install -y wget git autoconf automake expat-devel yasm nasm gnutls-devel libtiff-devel libX11-devel unixODBC-devel python-devel zlib-devel alsa-lib-devel libogg-devel libvorbis-devel uuid-devel @development-tools gdbm-devel db4-devel libjpeg libjpeg-devel compat-libtermcap ncurses ncurses-devel ntp screen sendmail sendmail-cf gcc-c++ @development-tools bison bzip2 curl curl-devel dmidecode git make mysql-connector-odbc openssl-devel unixODBC zlib pcre-devel speex-devel sqlite-devel ldns-devel libedit-devel bc e2fsprogs-devel libcurl-devel libxml2-devel libyuv-devel opus-devel libvpx-devel libvpx2* libdb4* libidn-devel unbound-devel libuuid-devel lua-devel libsndfile-devel
		fi  
		curl --data "email=$EMAIL" --data "type=script" http://demo.astppbilling.org/lib/
		echo "Lets first make sure that time is correct before we continue ... "
    
		# set right time
		set_right_time () 
		{
			echo "Setting up correct time ..."
			ntpdate pool.ntp.org
			if [ ${DIST} = "DEBIAN" ]; then
				systemctl restart ntp
				chkconfig ntp on
			else [ -f /etc/redhat-release ]
				systemctl restart ntpd
				chkconfig ntpd on
			fi
		}
		set_right_time
		
		#-----------------Freeswitch Installation Start------------------------------
		# Download latest freeswitch version
		cd /usr/local/src		
		git config --global pull.rebase true
		git clone -b v1.6.8 https://freeswitch.org/stash/scm/fs/freeswitch.git
		cd freeswitch
		./bootstrap.sh -j
		# Edit modules.conf
		#echo "Enabling mod_xml_curl, mod_json_cdr, mod_db"
		sed -i "s#\#xml_int/mod_xml_curl#xml_int/mod_xml_curl#g" /usr/local/src/freeswitch/modules.conf
		sed -i "s#\#mod_db#mod_db#g" /usr/local/src/freeswitch/modules.conf
		sed -i "s#\#event_handlers/mod_json_cdr#event_handlers/mod_json_cdr#g" /usr/local/src/freeswitch/modules.conf
		
		# Compile the Source
		./configure -C
		# Install Freeswitch with sound files		
		make all install cd-sounds-install cd-moh-install
		make && make install
		# Create symbolic links for Freeswitch executables
		ln -s /usr/local/freeswitch/bin/freeswitch /usr/local/bin/freeswitch
		ln -s /usr/local/freeswitch/bin/fs_cli /usr/local/bin/fs_cli		
		#-----------------Freeswitch Installation End------------------------------
		systemctl stop apache2
		systemctl disable apache2
}

#SUB Configure astpp Freeswitch Startup Script
astpp_freeswitch_startup_script ()
{
		if [ ! -d ${ASTPP_SOURCE_DIR} ]; then
			echo "ASTPP source doesn't exists, downloading it..."
			cd /usr/src/			
			git clone https://github.com/iNextrix/ASTPP
			cp -rf ASTPP latest			
		fi 		
		if [ ${DIST} = "DEBIAN" ]; then
			adduser --disabled-password  --quiet --system --home ${FS_DIR} --gecos "FreeSWITCH Voice Platform" --ingroup daemon freeswitch
			chown -R freeswitch:daemon ${FS_DIR}/
			chmod -R o-rwx ${FS_DIR}/
			chmod -R u=rwx,g=rx ${FS_DIR}/bin/*
			cp ${ASTPP_SOURCE_DIR}/freeswitch/init/freeswitch.debian.init /etc/init.d/freeswitch
		elif  [ ${DIST} = "CENTOS" ]; then
			cp ${ASTPP_SOURCE_DIR}/freeswitch/init/freeswitch.centos.init /etc/init.d/freeswitch
		fi
	  	chmod 755 /etc/init.d/freeswitch
	  	chmod +x /etc/init.d/freeswitch
		update-rc.d freeswitch defaults
		chkconfig --add freeswitch
		chkconfig --level 345 freeswitch on
		mkdir /var/run/freeswitch
		chown -R freeswitch:daemon  /var/run/freeswitch
}

startup_services() 
{
	# Startup Services
    if [ ${DIST} = "DEBIAN" ]; then
		chkconfig --add nginx
		chkconfig --level 345 nginx on
		chkconfig --add mysql
		chkconfig --level 345 mysql on			
		systemctl restart mysql
		systemctl restart nginx
		systemctl restart freeswitch
	elif  [ ${DIST} = "CENTOS" ]; then
		chkconfig --add nginx
		chkconfig --levels 35 nginx on
		chkconfig --add mysqld
		chkconfig --levels 35 mysqld on
		systemctl restart mariadb
		systemctl restart nginx
		systemctl restart freeswitch		
	fi
}

# Setup MySQL For ASTPP
mySQL_for_astpp () 
{
		# Start MySQL server
		if [ ${DIST} = "DEBIAN" ]; then
			systemctl restart mysql
		else [ -f /etc/redhat-release ]
		#	/etc/init.d/mysqld restart
			systemctl restart mariadb
		fi
		# Configure MySQL server
		sleep 5
		#MYSQL_ROOT_PASSWORD=$(genpasswd)
		#ASTPPUSER_MYSQL_PASSWORD=$(genpasswd)
		mysql -uroot -e "UPDATE mysql.user SET password=PASSWORD('${MYSQL_ROOT_PASSWORD}') WHERE user='root'; FLUSH PRIVILEGES;"
		# Save MySQL root password to a text file in /root
		echo ""
		echo "MySQL password set to '${MYSQL_ROOT_PASSWORD}'. Remember to delete ~/.mysql_passwd" | tee ~/.mysql_passwd
		echo "" >>  ~/.mysql_passwd
		echo "MySQL astppuser password:  ${ASTPPUSER_MYSQL_PASSWORD} " >>  ~/.mysql_passwd
		chmod 400 ~/.mysql_passwd
		read -n 1 -p "*** Press any key to continue ..."
		
		# Create astpp database
		mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "create database ${ASTPP_DATABASE_NAME};"
		mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "CREATE USER 'astppuser'@'localhost' IDENTIFIED BY '${ASTPPUSER_MYSQL_PASSWORD}';"
		mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON \`${ASTPP_DATABASE_NAME}\` . * TO 'astppuser'@'localhost' WITH GRANT OPTION;FLUSH PRIVILEGES;"		
		mysql -uroot -p${MYSQL_ROOT_PASSWORD} astpp < ${ASTPP_SOURCE_DIR}/database/astpp-3.0.sql
		mysql -uroot -p${MYSQL_ROOT_PASSWORD} astpp < ${ASTPP_SOURCE_DIR}/database/astpp_rates.sql
		if [ ${DIST} = "DEBIAN" ]; then
			apt-get install libmyodbc unixodbc-bin
			cp ${ASTPP_SOURCE_DIR}/misc/odbc/deb_odbc.ini /etc/odbc.ini
			cp ${ASTPP_SOURCE_DIR}/misc/odbc/deb_odbcinst.ini /etc/odbcinst.ini
		fi
		if  [ ${DIST} = "CENTOS" ]; then
			yum install unixODBC mysql-connector-odbc
			cp ${ASTPP_SOURCE_DIR}/misc/odbc/cent_odbc.ini /etc/odbc.ini
			cp ${ASTPP_SOURCE_DIR}/misc/odbc/cent_odbcinst.ini /etc/odbcinst.ini
		fi
		sed -i "s#PASSWORD = <PASSWORD>#PASSWORD = ${MYSQL_ROOT_PASSWORD}#g" /etc/odbc.ini
}

install_astpp () 
{
		# Download ASTPP
		if [ ! -d ${ASTPP_SOURCE_DIR} ]; then
			echo "ASTPP source doesn't exists, downloading it..."
			cd /usr/src/			
			wget http://www.astppbilling.org/download/latest.tar.gz
			tar -xzf latest.tar.gz
    	fi
    	if [ ${DIST} = "DEBIAN" ]; then
			# Install ASTPP pre-requisite packages using apt-get
			systemctl stop apache2
			systemctl disable apache2
			apt-get -o Acquire::Check-Valid-Until=false update
			apt-get install -y curl libyuv-dev libvpx2-dev nginx php5-fpm php5 php5-mcrypt libmyodbc unixodbc-bin php5-dev php5-common php5-cli php5-gd php-pear php5-cli php-apc php5-curl libxml2 libxml2-dev openssl libcurl4-openssl-dev gettext gcc g++
		elif  [ ${DIST} = "CENTOS" ]; then
			# Install ASTPP pre-requisite packages using YUM
			yum install -y autoconf automake bzip2 cpio curl nginx php-fpm php-mcrypt* unixODBC mysql-connector-odbc curl-devel php php-devel php-common php-cli php-gd php-pear php-mysql php-pdo php-pecl-json mysql mariadb-server mysql-devel libxml2 libxml2-devel openssl openssl-devel gettext-devel fileutils gcc-c++ httpd httpd-devel
		fi	
		#	cd ${ASTPP_SOURCE_DIR}	
		if [ ${DIST} = "DEBIAN" ]; then
			echo "Normalize ASTPP for Debian"			
			touch /var/log/nginx/astpp_access_log
			touch /var/log/nginx/astpp_error_log
			touch /var/log/nginx/fs_access_log
			touch /var/log/nginx/fs_error_log			
			php5enmod mcrypt
			systemctl restart php5-fpm
			service nginx reload
		fi
		if [ ${DIST} = "CENTOS" ]; then
			systemctl stop apache2
			systemctl disable apache2
			systemctl start php-fpm			
		fi
		if [ ${ASTPP_USING_FREESWITCH} = "yes" ]; then
			#Folder creation and permission
			mkdir -p ${ASTPPDIR}		
			mkdir -p ${ASTPPLOGDIR}		
			mkdir -p ${ASTPPEXECDIR}
			if [ ${DIST} = "DEBIAN" ]; then
				chown -Rf root.root ${ASTPPDIR}
				chown -Rf root.root ${ASTPPLOGDIR}
				chown -Rf root.root ${ASTPPEXECDIR}				
			elif [ ${DIST} = "CENTOS" ]; then
				chown -Rf root.root ${ASTPPDIR}
				chown -Rf root.root ${ASTPPLOGDIR}
				chown -Rf root.root ${ASTPPEXECDIR}				
			fi
			
			#Setup FS-Scripts
			/bin/cp -rf ${ASTPP_SOURCE_DIR}/freeswitch/scripts/* ${FS_SCRIPTS}/
			/bin/cp -rf ${ASTPP_SOURCE_DIR}/freeswitch/fs /var/www/html/
						
			/bin/cp -rf ${ASTPP_SOURCE_DIR}/freeswitch/sounds/*.wav ${FS_SOUNDSDIR}/
			chmod -Rf 777 ${FS_SOUNDSDIR}
		fi
		if [ ${INSTALL_ASTPP_WEB_INTERFACE} = "yes" ]; then
			echo "Installing ASTPP web interface"
			mkdir -p ${ASTPPDIR}		
			#Copy configuration file
			cp ${ASTPP_SOURCE_DIR}/config/astpp-config.conf ${ASTPPDIR}astpp-config.conf
			cp ${ASTPP_SOURCE_DIR}/config/astpp.lua ${ASTPPDIR}astpp.lua			
			#Install GUI of ATSPP
			mkdir -p ${WWWDIR}/astpp
			echo "Directory created ${WWWDIR}/astpp"
			cp -rf ${ASTPP_SOURCE_DIR}/web_interface/astpp/* ${WWWDIR}/astpp/			
			if [ ${DIST} = "DEBIAN" ]; then
				chown -Rf root.root ${WWWDIR}/astpp
				cp ${ASTPP_SOURCE_DIR}/web_interface/nginx/deb_astpp.conf /etc/nginx/sites-enabled/astpp.conf
				cp ${ASTPP_SOURCE_DIR}/web_interface/nginx/deb_fs.conf /etc/nginx/sites-enabled/fs.conf				
				systemctl restart nginx
			elif  [ ${DIST} = "CENTOS" ]; then
				chown -Rf root.root ${WWWDIR}/astpp
				cp ${ASTPP_SOURCE_DIR}/web_interface/nginx/cent_astpp.conf /etc/nginx/conf.d/astpp.conf
				cp ${ASTPP_SOURCE_DIR}/web_interface/nginx/cent_fs.conf /etc/nginx/conf.d/fs.conf
				sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/sysconfig/selinux
				sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config
				/etc/init.d/iptables stop
				chkconfig iptables off
				setenforce 0
			fi
			chmod -Rf 777 ${WWWDIR}/astpp
		fi	
		touch /var/log/astpp/astpp.log
}

finalize_astpp_installation () 
{
		# /etc/php.ini short_open_tag = On
		# short_open_tag = Off   to short_open_tag = On        
		echo "Make sure Short Open Tag is switched On"    
		if [ ${DIST} = "DEBIAN" ]; then
			sed -i "s#short_open_tag = Off#short_open_tag = On#g" /etc/php5/fpm/php.ini
			sed -i "s#;cgi.fix_pathinfo=1#cgi.fix_pathinfo=1#g" /etc/php5/fpm/php.ini
			systemctl restart php5-fpm
			systemctl restart nginx
		elif [ ${DIST} = "CENTOS" ]; then
			sed -i "s#short_open_tag = Off#short_open_tag = On#g" /etc/php.ini
			sed -i "s#;cgi.fix_pathinfo=1#cgi.fix_pathinfo=1#g" /etc/php.ini
			
			#######   Some more steps for CentOS 7  #########
			yum update					
			sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/sysconfig/selinux
			sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config
			setenforce 0			
			systemctl disable httpd
			systemctl enable nginx
			systemctl enable php-fpm			
			systemctl start mariadb
			systemctl start freeswitch
			systemctl stop firewalld			
			chkconfig --levels 345 mariadb on
			chkconfig --levels 345 freeswitch on
			chkconfig --levels 123456 firewalld off
		fi		
		/bin/cp -rf ${ASTPP_SOURCE_DIR}/freeswitch/conf/autoload_configs/* /usr/local/freeswitch/conf/autoload_configs/
		#sed -i "s/localhost\/fs/localhost:8735/g" /usr/local/freeswitch/conf/autoload_configs/xml_curl.conf.xml
		#sed -i "s/localhost\/fs/localhost:8735/g" /usr/local/freeswitch/conf/autoload_configs/json_cdr.conf.xml		
		# edit ASTPP Database Connection Information
		# /var/lib/astpp/astpp-config.conf
		sed -i "s#dbpass = <PASSSWORD>#dbpass = ${MYSQL_ROOT_PASSWORD}#g" ${ASTPPDIR}astpp-config.conf
		sed -i "s#DB_PASSWD=\"<PASSSWORD>\"#DB_PASSWD = \"${MYSQL_ROOT_PASSWORD}\"#g" ${ASTPPDIR}astpp.lua
		sed -i "s#base_url=http://localhost:8081/#base_url=http://${ASTPP_HOST_DOMAIN_NAME}:8089/#g" ${ASTPPDIR}/astpp-config.conf
}

setup_cron()
{
		if [ ${DIST} = "DEBIAN" ]; then
			CRONPATH='/var/spool/cron/crontabs/astpp'
		elif [ ${DIST} = "CENTOS" ]; then
			CRONPATH='/var/spool/cron/astpp'
		fi
		echo "# Generate Invoice   
		0 1 * * * cd /var/www/html/astpp/cron/ && php cron.php GenerateInvoice
		# Low balance notification
		0 1 * * * cd /var/www/html/astpp/cron/ && php cron.php UpdateBalance
		# Low balance notification
		0 0 * * * cd /var/www/html/astpp/cron/ && php cron.php LowBalance		
		# Update currency rate
		0 0 * * * cd /var/www/html/astpp/cron/ && php cron.php CurrencyUpdate
		" > $CRONPATH
		chmod 600 $CRONPATH
		crontab $CRONPATH
}

install_fail2ban()
{
		read -n 1 -p "Do you want to install and configure Fail2ban ? (y/n) "
		if [ "$REPLY"   = "y" ]; then
			if [ -f /etc/debian_version ] ; then
				DIST="DEBIAN"
				apt-get -y install fail2ban
			elif [ -f /etc/redhat-release ] ; then
				DIST="CENTOS"
				echo ""
				echo "Downloading sources"
				cd /usr/src
				service iptables stop
				wget -T 10 -t 1 http://sourceforge.net/projects/fail2ban/files/fail2ban-stable/fail2ban-0.8.4/fail2ban-0.8.4.tar.bz2
				echo "/!\IF FILE COULD BE DOWNLOADED, MAKE SURE TO UPLOAD SOURCE ARCHIVE [fail2ban-0.8.4.tar.bz2] MANUALLY IN [/usr/src/] DIRECTORY/!\"
				echo "/!\PRESS [CTRL-C] TO ABORT OR [ENTER] WHEN SOURCE ARCHIVE IS UPLOADED OR DOWNLOADED/!\"
				read -e OK
				if [ ! -f /usr/src/fail2ban-0.8.4.tar.bz2 ] ; #File that you are looking for isn't there
				then
					echo "/!\ STOP /!\ FILE fail2ban-0.8.4.tar.bz2 NOT AVAILABLE IN /USR/SRC/"
					echo "Aborting Installation"
				exit
				fi
				echo "################################################################"
				echo "File OK, unarchiving in progress"
				tar -jxf fail2ban-0.8.4.tar.bz2
				cd fail2ban-0.8.4
				echo "################################################################"
				echo "Fail2Ban installation in progress"
				python setup.py install
				cp /usr/src/fail2ban-0.8.4/files/redhat-initd /etc/init.d/fail2ban
				chmod 755 /etc/init.d/fail2ban
				echo "Installation done"
				echo "################################################################"
				echo "################################################################"
				echo "Auto Configuration in progress"
				echo "-- Writing /etc/fail2ban/filter.d/freeswitch.conf file"
				touch /etc/fail2ban/filter.d/freeswitch.conf
				cp /etc/fail2ban/filter.d/freeswitch.conf /etc/fail2ban/filter.d/freeswitch.bak
			else
				echo "***"
				echo "*** This Installer should be run only on CentOS 6.x or Debian based system"
				echo "***"
				exit 1
			fi
			echo "# Fail2Ban configuration file
			[Definition]
			# Option: failregex
			# Notes.: regex to match the password failures messages in the logfile. The
			# host must be matched by a group named "host". The tag '<HOST>' can
			# be used for standard IP/hostname matching and is only an alias for
			# (?:::f{4,6}:)?(?P<host>[\w\-.^_]+)
			# Values: TEXT
			#
			failregex = \[WARNING\] sofia_reg.c:\d+ SIP auth challenge \(REGISTER\) on sofia profile \'[^']+\' for \[.*\] from ip <HOST>
			\[WARNING\] sofia_reg.c:\d+ SIP auth failure \(INVITE\) on sofia profile \'[^']+\' for \[.*\] from ip <HOST>
			# Option: ignoreregex
			# Notes.: regex to ignore. If this regex matches, the line is ignored.
			# Values: TEXT
			#
			ignoreregex =" > /etc/fail2ban/filter.d/freeswitch.conf
					echo "# Fail2Ban configuration file
			[Definition]
			# Option:  failregex
			# Notes.:  regex to match the password failures messages in the logfile. The
			#          host must be matched by a group named "host". The tag '<HOST>' can
			#          be used for standard IP/hostname matching and is only an alias for
			#          (?:::f{4,6}:)?(?P<host>[\w\-.^_]+)
			# Values:  TEXT
			#
			failregex = \[WARNING\] sofia_reg.c:\d+ SIP auth challenge \(REGISTER\) on sofia profile \'[^']+\' for \[.*\] from ip <HOST>
			# Option:  ignoreregex
			# Notes.:  regex to ignore. If this regex matches, the line is ignored.
			# Values:  TEXT
			#
			ignoreregex =" > /etc/fail2ban/filter.d/freeswitch-dos.conf
			################################# FREESWITCH.CONF FILE READY ##################
			echo "-- Modifying /etc/fail2ban/jail.conf file"
			################################# JAIL.CONF FILE WRITING ####################
			cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.bak
			echo "
			[freeswitch]
			enabled = true
			port = 5060,5061,5080,5081
			filter = freeswitch
			logpath = /usr/local/freeswitch/log/freeswitch.log
			maxretry = 10
			bantime = 10000000
			findtime = 480
			action = iptables-allports[name=freeswitch, protocol=all]
			sendmail-whois[name=FreeSwitch, dest=$EMAIL, sender=fail2ban@${ASTPP_HOST_DOMAIN_NAME}]
			" >> /etc/fail2ban/jail.local
					echo "
			[freeswitch-dos]
			enabled = true
			port = 5060,5061,5080,5081
			filter = freeswitch-dos
			logpath = /usr/local/freeswitch/log/freeswitch.log
			action = iptables-allports[name=freeswitch-dos, protocol=all]
			maxretry = 50
			findtime = 30
			bantime = 6000
			" >> /etc/fail2ban/jail.local
			################################# JAIL.CONF FILE READY ######################
			echo "################################################################"
			echo "Auto Configuration Completed"
			if [ -f /etc/redhat-release ] ; then
				echo "Restarting IPtables"
				/etc/init.d/iptables start
			fi
			echo "Starting Fail2Ban Integration"
			/etc/init.d/fail2ban start
			if [ -f /etc/redhat-release ] ; then
				echo "Restarting IPtables"
				/etc/init.d/iptables restart
			fi
			/etc/init.d/fail2ban restart
			if [ -f /etc/redhat-release ] ; then
				chkconfig iptables on
			fi
			chkconfig fail2ban on
			echo "################################################################"
			echo "Fail2Ban for FreeSwitch & IPtables Integration completed"
			else
			echo ""
			echo "Fail2ban installation is aborted !"
		fi   
}

astpp_install () 
{
		if [ ${ASTPP_USING_FREESWITCH} = "yes" ]; then
			install_freeswitch_for_astpp
			astpp_freeswitch_startup_script
			echo ""
			echo "FreeSWITCH is Installed"
		fi
		install_astpp
		mySQL_for_astpp
		finalize_astpp_installation		
		setup_cron
		startup_services	
		clear
		echo "---------------------"
		echo "| Login information |"
		echo "---------------------"
		echo "http://${ASTPP_HOST_DOMAIN_NAME}:8089 "
		echo "Username= admin "
		echo "Password= admin "
		echo ""
		sleep 5
		echo ""	
		install_fail2ban
		init 6
}

# Install astpp
start_install_astpp () 
{
		if [ ${DIST} = "CENTOS" ]; then
			astpp_install
		elif [ ${DIST} = "DEBIAN" ]; then
			astpp_install
		else
			echo "Can't install with this script on your OS"
		fi
}
if [ ${INSTALL_ASTPP} = "yes" ]; then
		start_install_astpp
fi
