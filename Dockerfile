FROM mautic/mautic:7.1-apache

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

# Pass build args to runtime environment
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

# Create the wrapper script using a Heredoc for cleaner syntax
RUN cat << 'SCRIPT' > /railway-wrapper.sh
#!/bin/bash
set -e

# 1. Create required directories for volumes
mkdir -p /var/www/html/var/{logs,cache,sessions,imports,exports}
mkdir -p /var/www/html/media/{files,images}
chown -R www-data:www-data /var/www/html/var /var/www/html/media
mkdir -p /var/www/html/config

# 2. Inject missing parameters into local.php
# Reads MAUTIC_SITE_URL and MAUTIC_TRUSTED_PROXIES from environment
# and adds them to config/local.php if they don't exist.
if [ -f config/local.php ]; then
    php << 'PHP_INJECT'
<?php
$file = "config/local.php";
$content = file_get_contents($file);
$siteUrl = rtrim(getenv("MAUTIC_SITE_URL"), "/");
$trustedProxiesJson = getenv("MAUTIC_TRUSTED_PROXIES");

$updated = false;

// Inject site_url
if (strpos($content, "'site_url'") === false && $siteUrl) {
    $inject = "\n\t'site_url' => '$siteUrl',";
    $content = preg_replace("/;\s*$/", $inject . "\n);", $content);
    $updated = true;
}

// Inject trusted_proxies
if (strpos($content, "'trusted_proxies'") === false && $trustedProxiesJson) {
    $p = json_decode($trustedProxiesJson, true);
    if ($p) {
        $pStr = "'" . implode("', '", $p) . "'";
        $inject = "\n\t'trusted_proxies' => [$pStr],";
        // Re-read content in case site_url was just added
        $content = file_get_contents($file);
        $content = preg_replace("/;\s*$/", $inject . "\n);", $content);
        $updated = true;
    }
}

if ($updated) {
    file_put_contents($file, $content);
    echo "Successfully injected site_url and/or trusted_proxies into local.php\n";
}
?>
PHP_INJECT
    # Ensure permissions are correct after write
    chown www-data:www-data config/local.php
fi

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
