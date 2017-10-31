# from https://www.drupal.org/requirements/php#drupalversions
FROM php:7.1-apache

RUN a2enmod rewrite

# install the PHP extensions we need
RUN set -ex \
	&& buildDeps=' \
		libjpeg62-turbo-dev \
		libpng12-dev \
		libpq-dev \
	' \
	&& apt-get update && apt-get install -y --no-install-recommends $buildDeps && rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd \
		--with-jpeg-dir=/usr \
		--with-png-dir=/usr \
	&& docker-php-ext-install -j "$(nproc)" gd mbstring opcache pdo pdo_mysql pdo_pgsql zip \
	&& apt-mark manual \
		libjpeg62-turbo \
		libpq5 \
	&& apt-get purge -y --auto-remove $buildDeps

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

WORKDIR /var/www/html

# https://www.drupal.org/node/3060/release
ENV DRUPAL_VERSION 8.4.0
ENV DRUPAL_MD5 074795a2f5fc0b599a7dcfb9d1fb03f5

RUN curl -fSL "https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz" -o drupal.tar.gz \
	&& echo "${DRUPAL_MD5} *drupal.tar.gz" | md5sum -c - \
	&& tar -xz --strip-components=1 -f drupal.tar.gz \
	&& rm drupal.tar.gz \
	&& chown -R www-data:www-data sites modules themes



RUN set -ex \
	&& apt-get update && apt-get install -y mysql-client \
		openssh-client \
		git \
		curl \
		wget \
		gzip \
		nano \
		tar

# Install Composer.
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer


RUN git clone git@github.com:daveferrara1/drupal-project.git drupal


RUN composer install --no-interaction
