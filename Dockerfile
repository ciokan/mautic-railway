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

# 2. Generate config — single php -r, no nested heredoc
php -r '
$proxiesArr = ["0.0.0.0/0", "::/0"];

$config = [
    "db_driver"        => "pdo_mysql",
    "db_host"          => getenv("MAUTIC_DB_HOST"),
    "db_port"          => getenv("MAUTIC_DB_PORT") ?: "3306",
    "db_user"          => getenv("MAUTIC_DB_USER"),
    "db_password"      => getenv("MAUTIC_DB_PASSWORD"),
    "db_name"          => getenv("MAUTIC_DB_DATABASE"),
    "db_table_prefix"  => null,
    "db_backup_tables" => 1,
    "db_backup_prefix" => "bak_",
    "mailer_dsn"       => getenv("MAUTIC_MAILER_DSN") ?: "smtp://localhost:25",
    "site_url"         => rtrim((string)getenv("MAUTIC_SITE_URL"), "/"),
    "trusted_proxies"  => $proxiesArr,
];

$content = "<?php\n\n\$parameters = " . var_export($config, true) . ";\n";
file_put_contents("/var/www/html/config/local.php", $content);
echo "Config written.\n";
'
chown www-data:www-data /var/www/html/config/local.php

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
