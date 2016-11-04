	FROM library/debian:jessie
	MAINTAINER Ricardo Belo <email@ricardobelo.com.br>

	# update and upgrade
	RUN apt-get update -y && apt-get upgrade -y 

	# Set the env variable DEBIAN_FRONTEND to noninteractive
	ENV DEBIAN_FRONTEND noninteractive

	# Utils
	RUN apt-get install -y --fix-missing build-essential apt-utils debconf-utils wget curl vim

	# MariaDB
		RUN echo mariadb-server mysql-server/root_password password root | debconf-set-selections
		RUN echo mariadb-server mysql-server/root_password_again password root | debconf-set-selections
		RUN apt-get install -y --fix-missing mariadb-server

		# Create a runit entry for mysql
			RUN mkdir -p /etc/service/mysql
			ADD mariadb.sh /etc/service/mysql/run
			RUN chown root /etc/service/mysql/run
			RUN chmod +x /etc/service/mysql/run

	# Nginx / fcgiwrap spawn-fcgi / aspell
		RUN apt-get install -y --fix-missing  nginx fcgiwrap spawn-fcgi aspell-pt-br 

		# Create a runit entry for fcgiwrap
			RUN mkdir -p /etc/service/fcgiwrap
			ADD fcgiwrap.sh /etc/service/fcgiwrap/run
			RUN chown root /etc/service/fcgiwrap/run
			RUN chmod +x /etc/service/fcgiwrap/run

	# NGINX
		RUN echo 'fastcgi_param  SCRIPT_FILENAME $request_filename;' >> /etc/nginx/fastcgi_params
		ADD nginx.conf /etc/nginx/sites-available/otrs
		RUN mkdir -p /etc/nginx/sites-enabled
		RUN cd /etc/nginx/sites-enabled && rm -f *
		RUN cd /etc/nginx/sites-enabled && ln -s ../sites-available/otrs


 # service fcgiwrap start && service nginx start

	# OTRS - https://packages.debian.org/stretch/otrs
	# debconf-set-selections for OTRS
	
	# Backports - https://wiki.debian.org/Backports
		RUN echo "deb http://httpredir.debian.org/debian jessie-backports main contrib non-free" >> /etc/apt/sources.list
		
		#CMD mkdir /etc/dbconfig-common
		#ADD dbconfig_config /etc/dbconfig-common/config
		#ADD dbconfig_otrs2.conf /etc/dbconfig-common/otrs2.conf
		
		# apt-get purge otrs2
		RUN apt-get update -y && apt-get -t jessie-backports install -y otrs --fix-missing
		RUN sed -i -e 's#deb http://httpredir.debian.org/debian jessie-backports main contrib non-free##g' /etc/apt/sources.list

	#apt-get install -y net-tools --fix-missing
	# Clean up APT when done
		RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

	#OTRS
		# RUN useradd -d /opt/otrs/ -c 'OTRS user' otrs
		# RUN usermod -a -G nogroup otrs
		# RUN usermod -a -G www-data otrs
		# RUN /usr/share/otrs/bin/otrs.SetPermissions.pl --otrs-user=otrs --web-user=www-data --otrs-group=nogroup --web-group=www-data /usr/share/otrs

		# After install
			# su -c "/usr/share/otrs/bin/otrs.Console.pl Admin::Package::Install http://ftp.otrs.org/pub/otrs/packages/:FAQ-5.0.6.opm" -s /bin/bash otrs
			RUN sed -i "s/.*max_allowed_packet.*/max_allowed_packet = 20M/" /etc/mysql/my.cnf
			RUN apt-get install -y --fix-missing ca-certificates libclass-inspector-perl libmodule-refresh-perl libsoap-lite-perl libmozilla-ldap-perl
			RUN chown -R otrs:www-data /usr/share/otrs/ && chown -R otrs:www-data /var/lib/otrs/
			RUN su -c "/usr/share/otrs/bin/otrs.Console.pl Admin::Package::Install http://ftp.otrs.org/pub/otrs/packages/:FAQ-5.0.6.opm \
&& /usr/share/otrs/bin/otrs.Console.pl Admin::Package::Install http://ftp.otrs.org/pub/otrs/packages/:Survey-5.0.2.opm \
&& /usr/share/otrs/bin/otrs.Console.pl Admin::Package::Install http://ftp.otrs.org/pub/otrs/packages/:SystemMonitoring-5.0.1.opm \
&& /usr/share/otrs/bin/otrs.Console.pl Admin::Package::Install http://ftp.otrs.org/pub/otrs/packages/:TimeAccounting-5.0.4.opm \
&& /usr/share/otrs/bin/otrs.Console.pl Admin::Package::Install http://ftp.otrs.org/pub/otrs/packages/:OTRSMasterSlave-5.0.3.opm  \
&& /usr/share/otrs/bin/otrs.Console.pl Admin::Package::Install http://ftp.otrs.org/pub/otrs/itsm/packages5/:GeneralCatalog-5.0.13.opm \
&& /usr/share/otrs/bin/otrs.Console.pl Admin::Package::Install http://ftp.otrs.org/pub/otrs/itsm/packages5/:ImportExport-5.0.13.opm \
&& /usr/share/otrs/bin/otrs.Console.pl Admin::Package::Install http://ftp.otrs.org/pub/otrs/itsm/packages5/:ITSMCore-5.0.13.opm \
&& /usr/share/otrs/bin/otrs.Console.pl Admin::Package::Install http://ftp.otrs.org/pub/otrs/itsm/packages5/:ITSMChangeManagement-5.0.13.opm \
&& /usr/share/otrs/bin/otrs.Console.pl Admin::Package::Install http://ftp.otrs.org/pub/otrs/itsm/packages5/:ITSMConfigurationManagement-5.0.13.opm \
&& /usr/share/otrs/bin/otrs.Console.pl Admin::Package::Install http://ftp.otrs.org/pub/otrs/itsm/packages5/:ITSMIncidentProblemManagement-5.0.13.opm \
&& /usr/share/otrs/bin/otrs.Console.pl Admin::Package::Install http://ftp.otrs.org/pub/otrs/itsm/packages5/:ITSMServiceLevelManagement-5.0.13.opm" -s /bin/bash otrs

		# sudo perl -MCPAN -e shell
		# install YAML
		# install Encode::HanExtra
		# install JSON::XS
		# install Net::LDAP

		# RUN /usr/share/otrs/bin/otrs.SetPermissions.pl --otrs-user=otrs --web-user=www-data --otrs-group=nogroup --web-group=www-data /usr/share/otrs 

EXPOSE 22 80
ENTRYPOINT service mysql start && service fcgiwrap start && service nginx start && bash