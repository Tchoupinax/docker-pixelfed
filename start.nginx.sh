#!/bin/bash

PATH=/usr/local/bin:/usr/sbin:/usr/bin:$PATH
cd /var/www

# Create the storage tree if needed and fix permissions
cp -r storage.skel/* storage/
cp -r bootstrap.skel/* bootstrap/
# chown -R www-data:www-data storage/ bootstrap/

# Render nginx config in /tmp (works with read-only root filesystem)
NGINX_CONF=/tmp/nginx.conf
cp /etc/nginx/nginx.conf "${NGINX_CONF}"
sed -i "s/__PORT__/${APP_PORT}/" "${NGINX_CONF}"
sed -i "s/__SERVERNAME__/${APP_DOMAIN}/" "${NGINX_CONF}"

# Refresh the environment
php artisan storage:link
php artisan route:cache
php artisan view:cache
php artisan config:cache
php artisan migrate --force
# php artisan import:cities
php artisan instance:actor

# Finally run everything
php-fpm${PHP_VERSION} -D &
if [ "${ENABLE_HORIZON:-false}" = "true" ]; then
    php artisan horizon &
fi
nginx -c "${NGINX_CONF}" -g 'daemon off;'