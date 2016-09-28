FROM php:latest

ENV PHP_VERSION 7.0.11
ENV PHP_FILENAME php-7.0.11.tar.xz
ENV PHP_SHA256 2ee6968b5875f2f38700c58a189aad859a6a0b85fc337aa102ec2dc3652c3b7b

# To have libzmq 4.1
RUN echo "deb http://httpredir.debian.org/debian/ testing main contrib non-free" >> /etc/apt/sources.list && \
	echo "deb-src http://httpredir.debian.org/debian/ testing main contrib non-free" >> /etc/apt/sources.list

RUN set -xe \
	&& buildDeps=" \
    locales \
		libcurl4-openssl-dev \
		libedit-dev \
		libsqlite3-dev \
		libssl-dev \
		libxml2-dev \
		xz-utils \
    vim \
    pkg-config \
    net-tools \
    libzmq3-dev \
    libmcrypt-dev \
		libevent-dev \
    libicu-dev \
		librdkafka-dev \
		unzip \
	" \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends && rm -rf /var/lib/apt/lists/*

RUN curl -fSL "http://php.net/get/$PHP_FILENAME/from/this/mirror" -o "$PHP_FILENAME" \
	&& mkdir -p /usr/src/php \
	&& tar -xf "$PHP_FILENAME" -C /usr/src/php --strip-components=1 \
	&& rm "$PHP_FILENAME" \
	&& cd /usr/src/php \
	&& ./configure \
    --enable-maintainer-zts \
		--with-config-file-path="$PHP_INI_DIR" \
		--with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
		--enable-fd-setsize=51200 \
		--disable-cgi \
		--enable-mbstring \
    --enable-sockets \
    --with-libedit \
		--with-curl \
		--with-json \
    --with-iconv \
    --with-libedit \
		--with-openssl \
		--with-zlib \
	&& make -j"$(nproc)" \
	&& make install \
	&& { find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true; } \
	&& make clean \
	&& apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $buildDeps

# Add other needed extensions
RUN docker-php-ext-install intl mcrypt pcntl

# Allow beta packages
RUN pear config-set preferred_state beta
# ZMQ for sockets
RUN printf "\n" | pecl install zmq && \
  echo "extension=zmq.so" | tee /usr/local/etc/php/conf.d/zmq.ini
# Message pack for messaging
RUN printf "\n" | pecl install msgpack && \
  echo "extension=msgpack.so" | tee /usr/local/etc/php/conf.d/msgpack.ini
# MongoDB
RUN printf "\n" | pecl install mongodb && \
  echo "extension=mongodb.so" | tee /usr/local/etc/php/conf.d/mongodb.ini
# Pthreads
#RUN printf "\n" | pecl install pthreads && \
#  echo "extension=pthreads.so" | tee /usr/local/etc/php/conf.d/pthreads.ini
# lib ev for react
RUN printf "\n" | pecl install ev && \
  echo "extension=ev.so" | tee /usr/local/etc/php/conf.d/ev.ini

# Redis client
#RUN curl https://codeload.github.com/phpredis/phpredis/zip/php7 > redis.zip &&\
#	unzip redis.zip &&\
#	cd phpredis-php7 &&\
#	phpize &&\
#	./configure &&\
#	make &&\
#	make install &&\
#  echo "extension=redis.so" | tee /usr/local/etc/php/conf.d/redis.ini
# Kafka client
#RUN curl https://codeload.github.com/arnaud-lb/php-rdkafka/zip/php7 > rdkafka.zip &&\
#	unzip rdkafka.zip &&\
#	cd php-rdkafka-php7 &&\
#	phpize &&\
#	./configure &&\
#	make &&\
#	make install &&\
#  echo "extension=rdkafka.so" | tee /usr/local/etc/php/conf.d/rdkafka.ini

# timezone for php is now paris
RUN echo "date.timezone = Europe/Paris" | tee /usr/local/etc/php/conf.d/timezone.ini
# Set french as default language
ADD locale.gen /etc/locale.gen
RUN locale-gen en_US en_US.UTF-8 fr_FR.UTF-8 && update-locale LANG=fr_FR.UTF-8

RUN mkdir /code && chown -R 1000:1000 /code
# Source code will be here
WORKDIR /code
VOLUME /code

CMD ["php", "-a"]
