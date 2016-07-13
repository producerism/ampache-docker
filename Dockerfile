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
