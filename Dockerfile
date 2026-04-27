FROM mautic/mautic:7.1-apache

# Build args
ARG MAUTIC_DB_HOST
ARG MAUTIC_DB_PORT
ARG MAUTIC_DB_USER
ARG MAUTIC_DB_PASSWORD
ARG MAUTIC_DB_DATABASE
ARG MAUTIC_TRUSTED_PROXIES
ARG MAUTIC_URL
ARG MAUTIC_SITE_URL
ARG MAUTIC_ADMIN_EMAIL
ARG MAUTIC_ADMIN_PASSWORD

# Runtime ENV
ENV MAUTIC_DB_HOST=$MAUTIC_DB_HOST
ENV MAUTIC_DB_PORT=$MAUTIC_DB_PORT
ENV MAUTIC_DB_USER=$MAUTIC_DB_USER
ENV MAUTIC_DB_PASSWORD=$MAUTIC_DB_PASSWORD
ENV MAUTIC_DB_DATABASE=$MAUTIC_DB_DATABASE
ENV MAUTIC_TRUSTED_PROXIES=$MAUTIC_TRUSTED_PROXIES
ENV MAUTIC_URL=$MAUTIC_URL
ENV MAUTIC_SITE_URL=$MAUTIC_SITE_URL
ENV MAUTIC_ADMIN_EMAIL=$MAUTIC_ADMIN_EMAIL
ENV MAUTIC_ADMIN_PASSWORD=$MAUTIC_ADMIN_PASSWORD
ENV PHP_INI_VALUE_DATE_TIMEZONE='Europe/Bucharest'

# Wrapper script creation
RUN cat << 'BASH_SCRIPT' > /railway-wrapper.sh
#!/bin/bash
set -e

# 1. Create required directories (fixes startup checks)
mkdir -p /var/www/html/var/{logs,cache,sessions,imports,exports}
mkdir -p /var/www/html/media/{files,images}
mkdir -p /var/www/html/config
chown -R www-data:www-data /var/www/html/var /var/www/html/media

# 2. Write the config generator script
cat > /tmp/gen_config.php << 'PHP_SCRIPT'
<?php
$config = [
    'db_driver' => 'pdo_mysql',
    'db_host' => getenv('MAUTIC_DB_HOST'),
    'db_port' => getenv('MAUTIC_DB_PORT') ?: '3306',
    'db_table_prefix' => null,
    'db_backup_tables' => 1,
    'db_backup_prefix' => 'bak_',
    'mailer_dsn' => getenv('MAUTIC_MAILER_DSN') ?: 'smtp://localhost:25',
    'site_url' => rtrim(getenv('MAUTIC_SITE_URL'), '/'),
];

// Handle trusted proxies JSON
$proxies = getenv('MAUTIC_TRUSTED_PROXIES');
if ($proxies) {
    $p = json_decode($proxies, true);
    if (is_array($p)) {
        $config['trusted_proxies'] = $p;
    }
}

// Generate PHP code
$content = "<?php\n\n\$parameters = " . var_export($config, true) . ";\n";

mkdir('config', 0755, true);
file_put_contents('../config/local.php', $content);
echo "Config generated successfully.\n";
PHP_SCRIPT

php /tmp/gen_config.php
chown www-data:www-data ../config/local.php

# 3. Fix Apache MPM
a2dismod -f mpm_event >/dev/null 2>&1 || true
a2dismod -f mpm_worker >/dev/null 2>&1 || true
a2enmod     mpm_prefork >/dev/null 2>&1 || true
rm -f /etc/apache2/mods-enabled/mpm_event.* /etc/apache2/mods-enabled/mpm_worker.*

# 4. Start Mautic
exec /entrypoint.sh "$@"
BASH_SCRIPT

RUN chmod +x /railway-wrapper.sh

ENTRYPOINT ["/railway-wrapper.sh"]
CMD ["apache2-foreground"]
