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

# Bake the MPM fix into the image so the symlinks are sane before any wrapper runs.
# Railway sometimes ends up with mpm_event AND mpm_prefork both enabled on
# php:*-apache base images, which makes Apache refuse to start.
RUN a2dismod -f mpm_event mpm_worker >/dev/null 2>&1 || true \
 && rm -f /etc/apache2/mods-enabled/mpm_event.* \
          /etc/apache2/mods-enabled/mpm_worker.* \
 && a2enmod mpm_prefork >/dev/null

RUN printf '%s\n' \
  '#!/bin/bash' \
  'set -e' \
  '' \
  '# Belt-and-braces: fix MPM at runtime too, in case the platform re-enables anything.' \
  'a2dismod -f mpm_event mpm_worker >/dev/null 2>&1 || true' \
  'rm -f /etc/apache2/mods-enabled/mpm_event.* /etc/apache2/mods-enabled/mpm_worker.*' \
  'a2enmod mpm_prefork >/dev/null 2>&1 || true' \
  '' \
  'VOL=/persistent' \
  'mkdir -p "$VOL/media/files" "$VOL/media/images" "$VOL/config"' \
  '' \
  'if [ -z "$(ls -A "$VOL/config" 2>/dev/null)" ] && [ -d /var/www/html/config ]; then' \
  '  cp -a /var/www/html/config/. "$VOL/config/" || true' \
  'fi' \
  '' \
  'rm -rf /var/www/html/docroot/media /var/www/html/config' \
  'ln -sfn "$VOL/media"  /var/www/html/docroot/media' \
  'ln -sfn "$VOL/config" /var/www/html/config' \
  '' \
  'mkdir -p /var/www/html/var/logs /var/www/html/var/cache /var/www/html/var/sessions /var/www/html/var/imports /var/www/html/var/exports' \
  '' \
  'chown -R www-data:www-data "$VOL" /var/www/html/var /var/www/html/docroot/media /var/www/html/config' \
  '' \
  '# Sanity-check apache config before handing off — fail loud, not after migrations.' \
  'apache2ctl -t' \
  '' \
  'exec /entrypoint.sh "$@"' \
  > /railway-wrapper.sh \
 && chmod +x /railway-wrapper.sh

ENTRYPOINT ["/railway-wrapper.sh"]
CMD ["apache2-foreground"]
