FROM composer:2 as vendor

COPY database/ database/

COPY composer.json composer.json
COPY composer.lock composer.lock

RUN composer install \
  --ignore-platform-reqs \
  --no-interaction \
  --no-plugins \
  --no-scripts \
  --prefer-dist

FROM node:14 as frontend

WORKDIR /app

COPY artisan package.json webpack.mix.js package-lock.json ./

RUN npm install

COPY resources/ /app/resources/

RUN npm run production

FROM php:7.4-fpm-alpine

RUN apk update && apk add --no-cache libzip-dev icu-dev freetype libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev \
  && docker-php-ext-configure gd --with-freetype --with-jpeg \
  && docker-php-ext-install gd zip intl pdo_mysql bcmath \
  && apk del --no-cache freetype-dev libpng-dev libjpeg-turbo-dev

COPY . /var/www/html
COPY --from=vendor /app/vendor/ /var/www/html/vendor/
COPY --from=frontend /app/public/js/ /var/www/html/public/js/
COPY --from=frontend /app/public/css/ /var/www/html/public/css/
COPY --from=frontend /app/public/fonts/ /var/www/html/public/fonts/
COPY --from=frontend /app/public/mix-manifest.json /var/www/html/public/mix-manifest.json

WORKDIR /var/www/html

RUN chgrp -R www-data /var/www/html/storage /var/www/html/bootstrap/cache && chmod -R ug+rwx /var/www/html/storage /var/www/html/bootstrap/cache

RUN php artisan config:cache
RUN php artisan route:cache
