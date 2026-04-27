FROM mautic/mautic:7.1-apache

ARG MAUTIC_DB_HOST
ARG MAUTIC_DB_PORT
ARG MAUTIC_DB_USER
ARG MAUTIC_DB_PASSWORD
ARG MAUTIC_DB_DATABASE
ARG MAUTIC_TRUSTED_PROXIES
ARG MAUTIC_URL
ARG MAUTIC_ADMIN_EMAIL
ARG MAUTIC_ADMIN_PASSWORD

ENV MAUTIC_DB_HOST=$MAUTIC_DB_HOST
ENV MAUTIC_DB_PORT=$MAUTIC_DB_PORT
ENV MAUTIC_DB_USER=$MAUTIC_DB_USER
ENV MAUTIC_DB_PASSWORD=$MAUTIC_DB_PASSWORD
ENV MAUTIC_DB_DATABASE=$MAUTIC_DB_DATABASE
ENV MAUTIC_TRUSTED_PROXIES=$MAUTIC_TRUSTED_PROXIES
ENV MAUTIC_URL=$MAUTIC_URL
ENV MAUTIC_ADMIN_EMAIL=$MAUTIC_ADMIN_EMAIL
ENV MAUTIC_ADMIN_PASSWORD=$MAUTIC_ADMIN_PASSWORD
ENV PHP_INI_VALUE_DATE_TIMEZONE='Europe/Bucharest'

RUN printf '%s\n' \
  '#!/bin/bash' \
  'set -e' \
  'mkdir -p /var/www/html/var/{logs,cache,sessions,imports,exports}' \
  'mkdir -p /var/www/html/docroot/media/{files,images}' \
  'chown -R www-data:www-data /var/www/html/var /var/www/html/docroot/media' \
  'a2dismod -f mpm_event  >/dev/null 2>&1 || true' \
  'a2dismod -f mpm_worker >/dev/null 2>&1 || true' \
  'a2enmod     mpm_prefork >/dev/null 2>&1 || true' \
  'rm -f /etc/apache2/mods-enabled/mpm_event.* /etc/apache2/mods-enabled/mpm_worker.*' \
  'exec /entrypoint.sh "$@"' \
  > /railway-wrapper.sh \
 && chmod +x /railway-wrapper.sh

ENTRYPOINT ["/railway-wrapper.sh"]
CMD ["apache2-foreground"]
