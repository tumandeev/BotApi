FROM php:8.0-fpm

RUN apt-get update \
    && apt-get install -y \
        default-mysql-client \
        zip \
        unzip \
        zlib1g-dev \
        libgmp-dev \
        libxml2-dev \
        curl \
        libcurl4 \
        libcurl4-gnutls-dev \
        libpng-dev \
        libjpeg-dev \
        libzip4 \
        libzip-dev \
        git \
        libldap2-dev \
        imagemagick \
        rsync \
        libmagickwand-dev \
        libldb-dev \
        libldap2-dev \
        --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-configure ldap \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install pdo_mysql zip bcmath gd gmp pcntl xml curl exif zip xml sockets ldap intl \
    && pecl install imagick \
    && docker-php-ext-enable imagick

RUN sed -i '/policy domain="coder" rights="none" pattern="PDF"/d' /etc/ImageMagick-6/policy.xml

RUN pecl install -o -f redis \
   &&  rm -rf /tmp/pear \
   &&  echo "extension=redis.so" > /usr/local/etc/php/conf.d/redis.ini

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=0'; \
} > $PHP_INI_DIR/conf.d/opcache-recommended.ini

RUN { \
    echo 'upload_max_filesize=200M'; \
    echo 'post_max_size=200M'; \
    echo 'memory_limit = 1G'; \
    echo 'max_execution_time=360'; \
    echo 'default_socket_timeout = 360'; \
    echo 'max_file_uploads = 100'; \
} > $PHP_INI_DIR/conf.d/post_size.ini

RUN { \
    echo 'date.timezone = Europe/Moscow'; \
} > $PHP_INI_DIR/conf.d/custom-settings.ini

RUN { \
    echo '[www]'; \
    echo 'listen = 9000'; \
    echo 'pm.max_children = 32'; \
    echo 'pm.start_servers = 8'; \
    echo 'pm.min_spare_servers = 8'; \
    echo 'pm.max_spare_servers = 16'; \
    #echo 'slowlog = /proc/self/fd/2'; \
    #echo 'request_slowlog_timeout = 7s'; \
} | tee /usr/local/etc/php-fpm.d/zz-www.conf

RUN php -r "readfile('http://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer


ARG MODE

RUN apt-get update && apt-get install -y cron ssh && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /srv/app
COPY . /srv/app

#RUN composer install $MODE
RUN chmod +x wait-for-it.sh cron-entrypoint.sh

#RUN php artisan storage:link
