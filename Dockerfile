FROM mautic/mautic:7.1-apache

ARG MAUTIC_DB_HOST
ARG MAUTIC_DB_PORT
ARG MAUTIC_DB_USER
ARG MAUTIC_DB_PASSWORD
ARG MAUTIC_DB_DATABASE
ARG MAUTIC_TRUSTED_PROXIES
ARG MAUTIC_URL
ARG MAUTIC_SITE_URL
ARG MAUTIC_MAILER_DSN
ARG MAUTIC_ADMIN_EMAIL
ARG MAUTIC_ADMIN_PASSWORD

ENV MAUTIC_DB_HOST=$MAUTIC_DB_HOST
ENV MAUTIC_DB_PORT=$MAUTIC_DB_PORT
ENV MAUTIC_DB_USER=$MAUTIC_DB_USER
ENV MAUTIC_DB_PASSWORD=$MAUTIC_DB_PASSWORD
ENV MAUTIC_DB_DATABASE=$MAUTIC_DB_DATABASE
ENV MAUTIC_TRUSTED_PROXIES=$MAUTIC_TRUSTED_PROXIES
ENV MAUTIC_URL=$MAUTIC_URL
ENV MAUTIC_SITE_URL=$MAUTIC_SITE_URL
ENV MAUTIC_MAILER_DSN=${MAUTIC_MAILER_DSN:-smtp://localhost:25}
ENV MAUTIC_ADMIN_EMAIL=$MAUTIC_ADMIN_EMAIL
ENV MAUTIC_ADMIN_PASSWORD=$MAUTIC_ADMIN_PASSWORD
ENV PHP_INI_VALUE_DATE_TIMEZONE='Europe/Bucharest'

# Create the wrapper script
RUN cat << 'SCRIPT' > /railway-wrapper.sh
#!/bin/bash
set -e

# 1. Create required directories for volumes
mkdir -p /var/www/html/var/{logs,cache,sessions,imports,exports}
mkdir -p /var/www/html/media/{files,images}
chown -R www-data:www-data /var/www/html/var /var/www/html/media

# 2. Generate config/local.php entirely from ENV vars
php -r "
\$proxy = getenv('MAUTIC_TRUSTED_PROXIES');
if (\$proxy) {
    \$arr = json_decode(\$proxy, true);
    if (is_array(\$arr)) \$proxy = implode(\"', '\", \$arr);
}
\$content = \"<?php
\\\$parameters = [
    'db_driver' => 'pdo_mysql',
    'db_host' => '\\\$_ENV[\"MAUTIC_DB_HOST\"]',
    'db_port' => '\\\$_ENV[\"MAUTIC_DB_PORT\"]',
    'db_name' => '\\\$_ENV[\"MAUTIC_DB_DATABASE\"]',
    'db_user' => '\\\$_ENV[\"MAUTIC_DB_USER\"]',
    'db_password' => '\\\$_ENV[\"MAUTIC_DB_PASSWORD\"]',
    'db_table_prefix' => null,
    'db_backup_tables' => 1,
    'db_backup_prefix' => 'bak_',
    'mailer_dsn' => '\\\$_ENV[\"MAUTIC_MAILER_DSN\"]',
    'site_url' => '\\\$_ENV[\"MAUTIC_SITE_URL\"];',
\";
if (\$proxy) {
    \$content .= \"    'trusted_proxies' => ['\\\${proxy}'],\n\";
}
\$content .= \"];\\n\";
mkdir('config', 0755, true);
file_put_contents('config/local.php', \$content);
echo 'Generated config/local.php from environment\n';
"

# 3. Fix Apache MPM (Switch from event to prefork for PHP)
a2dismod -f mpm_event  >/dev/null 2>&1 || true
a2dismod -f mpm_worker >/dev/null 2>&1 || true
a2enmod     mpm_prefork >/dev/null 2>&1 || true
rm -f /etc/apache2/mods-enabled/mpm_event.* /etc/apache2/mods-enabled/mpm_worker.*

# 4. Execute the official Mautic entrypoint
exec /entrypoint.sh "$@"
SCRIPT

RUN chmod +x /railway-wrapper.sh

ENTRYPOINT ["/railway-wrapper.sh"]
CMD ["apache2-foreground"]
