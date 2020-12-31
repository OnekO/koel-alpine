FROM alpine

RUN apk update && apk --no-cache add \
    coreutils \
    supervisor \
    nginx \
    php7 \
    php7-fpm \
    php7-zip \
    php7-gd \
    php7-exif \
    php7-apcu \
    php7-json \
    php7-mbstring \
    php7-xmlwriter \
    php7-pdo_mysql \
    php7-pdo_sqlite \
    php7-sqlite3 \
    php7-pdo \
    php7-openssl \
    php7-opcache \
    php7-session \
    php7-ctype \
    php7-imagick \
    php7-phar \
    php7-simplexml \
    php7-dom \
    php7-tokenizer \
    php7-fileinfo \
    php7-xml \
    php7-iconv \
    php7-curl \
    imagemagick \
    tzdata \
    git \
    curl \
    yarn


RUN set -x ; \
    addgroup -g 82 -S www-data ; \
    adduser -u 82 -D -S -G www-data www-data && exit 0 ; exit 1

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/koel.conf /etc/nginx/conf.d/default.conf
ENV VIRTUAL_HOST="koel.lan"
RUN sed -i "s|server_name koel.lan;|server_name ${VIRTUAL_HOST};|g" /etc/nginx/conf.d/default.conf

ENV PHP_FPM_USER="www-data" \
    PHP_FPM_GROUP="www-data" \
    PHP_FPM_LISTEN_MODE="0660" \
    PHP_MEMORY_LIMIT="1024M" \
    PHP_MAX_UPLOAD="1000M" \
    PHP_MAX_FILE_UPLOAD="600" \
    PHP_MAX_POST="10000M" \
    PHP_MAX_EXECUTION_TIME="3600" \
    PHP_DISPLAY_ERRORS="On" \
    PHP_DISPLAY_STARTUP_ERRORS="On" \
    PHP_ERROR_REPORTING="E_COMPILE_ERROR\|E_RECOVERABLE_ERROR\|E_ERROR\|E_CORE_ERROR" \
    PHP_CGI_FIX_PATHINFO=0

RUN sed -i "s|;listen.owner\s*=\s*nobody|listen.owner = ${PHP_FPM_USER}|g" /etc/php7/php-fpm.conf && \
    sed -i "s|;listen.group\s*=\s*nobody|listen.group = ${PHP_FPM_GROUP}|g" /etc/php7/php-fpm.conf && \
    sed -i "s|;listen.mode\s*=\s*0660|listen.mode = ${PHP_FPM_LISTEN_MODE}|g" /etc/php7/php-fpm.conf && \
    sed -i "s|user\s*=\s*nobody|user = ${PHP_FPM_USER}|g" /etc/php7/php-fpm.conf && \
    sed -i "s|group\s*=\s*nobody|group = ${PHP_FPM_GROUP}|g" /etc/php7/php-fpm.conf && \
    sed -i "s|;log_level\s*=\s*notice|log_level = notice|g" /etc/php7/php-fpm.conf && \
    sed -i "s|display_errors\s*=\s*Off|display_errors = ${PHP_DISPLAY_ERRORS}|i" /etc/php7/php.ini && \
    sed -i "s|max_execution_time\s*=\s*30|max_execution_time = ${PHP_MAX_EXECUTION_TIME}|i" /etc/php7/php.ini && \
    sed -i "s|display_startup_errors\s*=\s*Off|display_startup_errors = ${PHP_DISPLAY_STARTUP_ERRORS}|i" /etc/php7/php.ini && \
    sed -i "s|error_reporting\s*=\s*E_ALL & ~E_DEPRECATED & ~E_STRICT|error_reporting = ${PHP_ERROR_REPORTING}|i" /etc/php7/php.ini && \
    sed -i "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php7/php.ini && \
    sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = ${PHP_MAX_UPLOAD}|i" /etc/php7/php.ini && \
    sed -i "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /etc/php7/php.ini && \
    sed -i "s|;*post_max_size =.*|post_max_size = ${PHP_MAX_POST}|i" /etc/php7/php.ini && \
    sed -i "s|;opcache.validate_timestamps=.*|opcache.validate_timestamps=0|i" /etc/php7/php.ini && \
    sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= ${PHP_CGI_FIX_PATHINFO}|i" /etc/php7/php.ini && \
    sed -i "s|user\s*=\s*nobody|user = ${PHP_FPM_USER}|g" /etc/php7/php-fpm.d/www.conf && \
    sed -i "s|group\s*=\s*nobody|group = ${PHP_FPM_USER}|g" /etc/php7/php-fpm.d/www.conf && \
    sed -i "s|;clear_env = no|clear_env = no|i" /etc/php7/php-fpm.d/www.conf


ENV TIMEZONE "Europe/Madrid"

RUN cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone && \
    sed -i "s|;*date.timezone =.*|date.timezone = ${TIMEZONE}|i" /etc/php7/php.ini

ADD init.sh /
RUN chmod 777 /init.sh && chmod 777 /var/www
ADD supervisord.conf /etc/supervisord.conf
RUN ln -sf /dev/stdout /var/log/nginx/koel_access.log && ln -sf /dev/stderr /var/log/nginx/koel_error.log
RUN ln -sf /dev/stderr /var/log/php7/error.log


USER www-data
WORKDIR /var/www
RUN git clone https://github.com/koel/koel.git
WORKDIR /var/www/koel
RUN git submodule update --init

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=. --filename=composer

ARG DB_CONNECTION="mysql"
ENV DB_CONNECTION=$DB_CONNECTION
ARG DB_HOST="db-host"
ENV DB_HOST=$DB_HOST
ARG DB_PORT="3306"
ENV DB_PORT=$DB_PORT
ARG DB_DATABASE="koel"
ENV DB_DATABASE=$DB_DATABASE
ARG DB_USERNAME="koel"
ENV DB_USERNAME=$DB_USERNAME
ARG DB_PASSWORD="password"
ENV DB_PASSWORD=$DB_PASSWORD
ARG APP_KEY="app-key"
ENV APP_KEY=$APP_KEY
ARG JWT_SECRET="jwt-secret"
ENV JWT_SECRET=$JWT_SECRET
ARG IGNORE_DOT_FILES="true"
ENV IGNORE_DOT_FILES=$IGNORE_DOT_FILES
ARG APP_ENV="production"
ENV APP_ENV=$APP_ENV
ARG APP_DEBUG="true"
ENV APP_DEBUG=$APP_DEBUG
ARG APP_URL="https://koel.lan"
ENV APP_URL=$APP_URL
ARG APP_MAX_SCAN_TIME="600"
ENV APP_MAX_SCAN_TIME=$APP_MAX_SCAN_TIME
ARG MEMORY_LIMIT="512"
ENV MEMORY_LIMIT=$MEMORY_LIMIT
ARG STREAMING_METHOD="php"
ENV STREAMING_METHOD=$STREAMING_METHOD
ARG LASTFM_API_KEY="lastfm-key"
ENV LASTFM_API_KEY=$LASTFM_API_KEY
ARG LASTFM_API_SECRET="lastfm-secret"
ENV LASTFM_API_SECRET=$LASTFM_API_SECRET
ARG AWS_ACCESS_KEY_ID=""
ENV AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY=""
ENV AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
ARG AWS_REGION=""
ENV AWS_REGION=$AWS_REGION
ARG YOUTUBE_API_KEY="youtube-key"
ENV YOUTUBE_API_KEY=$YOUTUBE_API_KEY
ARG CDN_URL=""
ENV CDN_URL=$CDN_URL
ARG FFMPEG_PATH="/usr/local/bin/ffmpeg"
ENV FFMPEG_PATH=$FFMPEG_PATH
ARG OUTPUT_BIT_RATE="256"
ENV OUTPUT_BIT_RATE=$OUTPUT_BIT_RATE
ARG ALLOW_DOWNLOAD="true"
ENV ALLOW_DOWNLOAD=$ALLOW_DOWNLOAD
ARG CACHE_MEDIA="true"
ENV CACHE_MEDIA=$CACHE_MEDIA
ARG PUSHER_APP_ID=""
ENV PUSHER_APP_ID=$PUSHER_APP_ID
ARG PUSHER_APP_KEY=""
ENV PUSHER_APP_KEY=$PUSHER_APP_KEY
ARG PUSHER_APP_SECRET=""
ENV PUSHER_APP_SECRET=$PUSHER_APP_SECRET
ARG PUSHER_APP_CLUSTER=""
ENV PUSHER_APP_CLUSTER=$PUSHER_APP_CLUSTER
ARG APP_LOG_LEVEL="debug"
ENV APP_LOG_LEVEL=$APP_LOG_LEVEL
ARG BROADCAST_DRIVER="log"
ENV BROADCAST_DRIVER=$BROADCAST_DRIVER
ARG CACHE_DRIVER="file"
ENV CACHE_DRIVER=$CACHE_DRIVER
ARG SESSION_DRIVER="file"
ENV SESSION_DRIVER=$SESSION_DRIVER
ARG QUEUE_DRIVER="sync"
ENV QUEUE_DRIVER=$QUEUE_DRIVER
ARG MAIL_DRIVER="smtp"
ENV MAIL_DRIVER=$MAIL_DRIVER
ARG MAIL_HOST="mailtrap.io"
ENV MAIL_HOST=$MAIL_HOST
ARG MAIL_PORT="2525"
ENV MAIL_PORT=$MAIL_PORT
ARG MAIL_USERNAME="null"
ENV MAIL_USERNAME=$MAIL_USERNAME
ARG MAIL_PASSWORD="null"
ENV MAIL_PASSWORD=$MAIL_PASSWORD
ARG MAIL_ENCRYPTION="null"
ENV MAIL_ENCRYPTION=$MAIL_ENCRYPTION
ARG ADMIN_NAME="admin"
ENV ADMIN_NAME=$ADMIN_NAME
ARG ADMIN_EMAIL="admin@admin.com"
ENV ADMIN_EMAIL=$ADMIN_EMAIL
ARG ADMIN_PASSWORD="admin-password"
ENV ADMIN_PASSWORD=$ADMIN_PASSWORD
ARG FORCE_HTTPS="true"
ENV FORCE_HTTPS=$FORCE_HTTPS

RUN /var/www/koel/composer install

USER root
RUN mkdir storage/logs && chown www-data:www-data storage -R  && chmod -R 777 storage
EXPOSE 80
ENTRYPOINT /init.sh
