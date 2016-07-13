FROM ubuntu:14.04


RUN echo 'deb http://download.videolan.org/pub/debian/stable/ /' >> /etc/apt/sources.list
RUN echo 'deb-src http://download.videolan.org/pub/debian/stable/ /' >> /etc/apt/sources.list
RUN echo 'deb http://archive.ubuntu.com/ubuntu trusty main multiverse' >> /etc/apt/sources.list

RUN apt-get update
RUN apt-get -y upgrade
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install wget inotify-tools
RUN wget -O - https://download.videolan.org/pub/debian/videolan-apt.asc|sudo apt-key add -
RUN apt-get update

# Need this environment variable otherwise mysql will prompt for passwords
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install mysql-server apache2 wget php5 php5-json php5-curl php5-mysqlnd pwgen lame libvorbis-dev vorbis-tools flac libmp3lame-dev libavcodec-extra* libfaac-dev libtheora-dev libvpx-dev libav-tools git libgd3 libpng-dev libjpeg-dev libfreetype6-dev
    
# Install other needed extensions
#RUN docker-php-ext-configure gd --enable-gd-native-ttf --with-jpeg-dir=/usr/lib/x86_64-linux-gnu --with-png-dir=/usr/lib/x86_64-linux-gnu --with-freetype-dir=/usr/lib/x86_64-linux-gnu \
#	&& docker-php-ext-install gd

# Install and Test PHP
RUN apt-get install --no-install-recommends -y \
		curl ca-certificates \
		php5-cli \
		php5-dev \
		php5-xdebug php5-xhprof \
		php5-apcu \
		php5-json \
		php5-memcached php5-memcache \
		php5-mysql php5-pgsql \
		php5-mongo \
		php5-sqlite php5-sybase php5-interbase php5-adodb php5-odbc \
		php5-gearman \
		php5-mcrypt  \
		php5-ldap \
		php5-gmp  \
		php5-intl \
		php5-geoip \
		php5-imagick php5-gd php5-exactimage \
		php5-imap \
		php5-curl \
		php5-gdcm php5-vtkgdcm \
		php5-gnupg \
		php5-librdf \
		php5-mapscript \
		php5-midgard2 \
		php5-msgpack \
		php5-oauth \
		php5-pinba \
		php5-radius \
		php5-redis \
		php5-remctl \
		php5-sasl \
		php5-stomp \
		php5-svn \
		php5-tokyo-tyrant \
		php5-rrd \
		php5-ps \
		php5-ming \
		php5-lasso \
		php5-enchant \
		php5-xsl \
		php5-xmlrpc \
		php5-tidy \
		php5-recode \
		php5-readline \
		php5-pspell \
		php-pear && \
		php --version && \
		php -m
		
# Tidy up
RUN apt-get -y autoremove && apt-get clean && apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#RUN apt-get install -y libfreetype6-dev
#RUN apt-get install -y libgd-dev
#RUN docker-php-ext-configure gd --with-freetype-dir=/usr
# exif pour gregwar/image ?
#RUN docker-php-ext-install gd exif

# Install composer for dependency management
RUN php -r "readfile('https://getcomposer.org/installer');" | php && \
    mv composer.phar /usr/local/bin/composer

# For local testing / faster builds
# COPY master.tar.gz /opt/master.tar.gz
ADD https://github.com/ampache/ampache/archive/develop.tar.gz /opt/develop.tar.gz

# extraction / installation
RUN rm -rf /var/www/* && \
    tar -C /var/www -xf /opt/develop.tar.gz ampache-develop --strip=1 && \
    cd /var/www && composer install --prefer-source --no-interaction && \
    chown -R www-data /var/www

# setup mysql like this project does it: https://github.com/tutumcloud/tutum-docker-mysql
# Remove pre-installed database

RUN rm -rf /var/lib/mysql/*
ADD create_mysql_admin_user.sh /create_mysql_admin_user.sh
ADD run.sh /run.sh
RUN chmod 755 /*.sh
ENV MYSQL_PASS **Random**
# Add VOLUMEs to allow backup of config and databases
VOLUME  ["/etc/mysql", "/var/lib/mysql"]

# setup apache with default ampache vhost
ADD 001-ampache.conf /etc/apache2/sites-available/
RUN rm -rf /etc/apache2/sites-enabled/*
RUN ln -s /etc/apache2/sites-available/001-ampache.conf /etc/apache2/sites-enabled/
RUN a2enmod rewrite

# Add job to cron to clean the library every night
RUN echo '30 7    * * *   www-data php /var/www/bin/catalog_update.inc' >> /etc/crontab

VOLUME ["/media"]
VOLUME ["/var/www/config"]
VOLUME ["/var/www/themes"]
EXPOSE 80

CMD ["/run.sh"]
