FROM php:7.2-apache
LABEL maintainer="Guillaume Astier <guillaume.astier.work@gmail.com>"

ENV TZ=Europe/Paris
ENV PHP_VER 7.2 

ARG USER_ID
ARG GROUP_ID
ARG IP_ADDRESS

RUN set -ex; \
    apt-get update &&\
    apt-get install --no-install-recommends --no-install-suggests -y \
    freetds-bin \
	freetds-dev \
	freetds-common \
	libsybdb5 \
	tdsodbc \
	libmemcached11 \
	libmemcachedutil2 \
	build-essential \
	libmemcached-dev \
	libz-dev \
	mysql-client \
	libpq-dev \
	libc-client-dev \
	libkrb5-dev \
	curl \
	libcurl4-gnutls-dev \
	libpng-dev \
	libjpeg-dev \
	libfreetype6-dev \
	libjpeg62-turbo-dev \
	libmcrypt-dev \
	git \
	unzip \
	libxslt1-dev \
	libicu-dev \
	libldap2-dev \
	vim \
	subversion \
	ssmtp &&\
	apt-get -y --purge autoremove &&\
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/{man,doc}

RUN ln -s /usr/lib/x86_64-linux-gnu/libsybdb.so /usr/lib/
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN docker-php-ext-install -j$(nproc) iconv &&\
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ &&\
    docker-php-ext-configure imap --with-kerberos --with-imap-ssl &&\
    docker-php-ext-install xml xsl gettext soap opcache bcmath pdo_mysql intl mysqli pdo_pgsql pdo_dblib gd curl zip sockets pcntl exif

RUN a2enmod vhost_alias macro headers rewrite proxy proxy_http

RUN curl -L -o /tmp/memcached.tar.gz "https://github.com/php-memcached-dev/php-memcached/archive/php7.tar.gz" &&\
    mkdir -p /usr/src/php/ext/memcached &&\
    tar -C /usr/src/php/ext/memcached -zxvf /tmp/memcached.tar.gz --strip 1 &&\
    docker-php-ext-configure memcached &&\
    docker-php-ext-install memcached &&\
    rm /tmp/memcached.tar.gz

RUN pecl install xdebug-2.6.1 &&\
    docker-php-ext-enable xdebug &&\
    echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini &&\
    echo "xdebug.default_enable=1" >> /usr/local/etc/php/conf.d/xdebug.ini &&\
    echo "xdebug.remote_enable=1" >> /usr/local/etc/php/conf.d/xdebug.ini &&\
    echo "xdebug.remote_autostart=1" >> /usr/local/etc/php/conf.d/xdebug.ini &&\
    echo "xdebug.remote_handler=dbgp" >> /usr/local/etc/php/conf.d/xdebug.ini &&\
    echo "xdebug.remote_mode=req" >> /usr/local/etc/php/conf.d/xdebug.ini &&\
    echo "xdebug.remote_port=9001" >> /usr/local/etc/php/conf.d/xdebug.ini &&\
    echo "xdebug.remote_connect_back=0" >> /usr/local/etc/php/conf.d/xdebug.ini &&\
    echo "xdebug.remote_log =/tmp/xdebug_remote.log" >> /usr/local/etc/php/conf.d/xdebug.ini &&\
    echo "xdebug.remote_host=$IP_ADDRESS" >> /usr/local/etc/php/conf.d/xdebug.ini

COPY apache/sites/vhosts.conf /etc/apache2/sites-available/virtual.conf
COPY apache/conf/macro.vdocroot.conf /etc/apache2/conf-available/macro.vdocroot.conf
COPY apache/conf/php-custom.ini /usr/local/etc/php/conf.d/80-php-custom.ini
COPY apache/conf/opcache-custom.ini /usr/local/etc/php/conf.d/90-opcache-custom.ini

RUN a2enconf macro.vdocroot &&\
    a2ensite virtual

RUN install -d -m 0755 -o www-data -g www-data /.composer &&\
	curl -sS https://getcomposer.org/installer | \
        php -- --install-dir=/usr/local/bin \
               --filename=composer &&\
	chown -R www-data:www-data /.composer

RUN if [ ${USER_ID:-0} -ne 0 ] && [ ${GROUP_ID:-0} -ne 0 ]; then \
	groupadd -g ${GROUP_ID} user &&\
	useradd -l -s /bin/bash -u ${USER_ID} -g user user &&\
	install -d -m 0755 -o user -g user /home/user &&\
	chown --changes --silent --no-dereference --recursive \
		--from=33:33 ${USER_ID}:${GROUP_ID} \
		/home/user \
		/.composer \
;fi

EXPOSE 80
