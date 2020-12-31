#!/bin/sh
STARTED="/var/www/koel/.STARTED"
if [ ! -e $STARTED ]; then
    touch $STARTED
    php artisan koel:init
fi

/usr/bin/supervisord -c /etc/supervisord.conf
