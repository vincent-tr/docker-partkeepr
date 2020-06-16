FROM php:7.0-apache

ARG PARTKEEPR_VERSION='1.4.0'
ARG PARTKEEPR_UID=33
ARG PARTKEEPR_GID=33
ARG TZ='Europe/Paris'

# Override image files
COPY 000-default.conf /etc/apache2/sites-available
COPY docker-php-entrypoint /usr/local/bin

# Apache user and group
RUN usermod -u ${PARTKEEPR_UID} www-data && \
    groupmod -g ${PARTKEEPR_GID} www-data

# PHP extensions and settings
RUN apt update -y && \
    apt install -y bsdtar pwgen libfreetype6-dev libjpeg62-turbo-dev libpng-dev zlib1g-dev libldap2-dev libpqxx-dev libicu-dev cron && \
    # APCU
    pecl update-channels && \
    pecl install apcu apcu_bc && \
    pecl clear-cache && \
    # Required extensions
    docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu && \
    docker-php-ext-install -j$(nproc) gd ldap pdo_pgsql intl opcache && \
    docker-php-ext-enable --ini-name 01-apcu.ini apcu && \
    docker-php-ext-enable --ini-name 02-apcu_bc.ini apc && \
    # Phing
    curl -sL https://www.phing.info/get/phing-latest.phar -o /usr/local/bin/phing && chmod +x /usr/local/bin/phing && \
    # Apache mod_rewrite
    a2enmod rewrite && \
    # PHP settings
    mv /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini && \
    echo "date.timezone=${TZ}"       > /usr/local/etc/php/conf.d/partkeepr.ini && \
    echo "max_execution_time = 120" >> /usr/local/etc/php/conf.d/partkeepr.ini

# PartKeepr installation
RUN cd /var/www/html && \
    curl -sL https://downloads.partkeepr.org/partkeepr-${PARTKEEPR_VERSION}.tbz2 | bsdtar --strip-components=1 -xvf- && \
    chown -R www-data: /var/www/html

# PartKeepr crontab
COPY crontab /etc/cron.d/partkeepr
