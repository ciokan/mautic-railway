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
  '' \
  '# Railway gives us one volume — use it for both media and config via symlinks.' \
  'VOL=/persistent' \
  'mkdir -p "$VOL/media/files" "$VOL/media/images" "$VOL/config"' \
  '' \
  '# Seed config from image on first boot (only if volume is empty).' \
  'if [ -z "$(ls -A "$VOL/config" 2>/dev/null)" ] && [ -d /var/www/html/config ]; then' \
  '  cp -a /var/www/html/config/. "$VOL/config/" || true' \
  'fi' \
  '' \
  '# Replace in-image dirs with symlinks into the volume.' \
  'rm -rf /var/www/html/docroot/media /var/www/html/config' \
  'ln -sfn "$VOL/media"  /var/www/html/docroot/media' \
  'ln -sfn "$VOL/config" /var/www/html/config' \
  '' \
  '# Ephemeral var/ — fine to recreate every boot.' \
  'mkdir -p /var/www/html/var/logs /var/www/html/var/cache /var/www/html/var/sessions /var/www/html/var/imports /var/www/html/var/exports' \
  '' \
  'chown -R www-data:www-data "$VOL" /var/www/html/var /var/www/html/docroot/media /var/www/html/config' \
  '' \
  'exec /entrypoint.sh "$@"' \
  > /railway-wrapper.sh \
 && chmod +x /railway-wrapper.sh

ENTRYPOINT ["/railway-wrapper.sh"]
CMD ["apache2-foreground"]
