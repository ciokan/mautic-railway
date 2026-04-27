FROM mautic/mautic:7.1-apache

ENV PHP_INI_VALUE_DATE_TIMEZONE='Europe/Bucharest'

RUN cat > /railway-wrapper.sh << 'BASH_SCRIPT'
#!/bin/bash
set -e

# 1. Directories
mkdir -p /var/www/html/var/{logs,cache,sessions,imports,exports}
mkdir -p /var/www/html/media/{files,images}
mkdir -p /var/www/html/config
chown -R www-data:www-data /var/www/html/var /var/www/html/media /var/www/html/config

# 3. Apache MPM
a2dismod -f mpm_event   >/dev/null 2>&1 || true
a2dismod -f mpm_worker  >/dev/null 2>&1 || true
a2enmod     mpm_prefork >/dev/null 2>&1 || true
rm -f /etc/apache2/mods-enabled/mpm_event.* /etc/apache2/mods-enabled/mpm_worker.*

# 4. Hand off to Mautic
exec /entrypoint.sh "$@"
BASH_SCRIPT

RUN chmod +x /railway-wrapper.sh

ENTRYPOINT ["/railway-wrapper.sh"]
CMD ["apache2-foreground"]
