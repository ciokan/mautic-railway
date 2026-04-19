ARG MAUTIC_DB_HOST
ARG MAUTIC_DB_PORT
ARG MAUTIC_DB_USER
ARG MAUTIC_DB_PASSWORD
ARG MAUTIC_DB_NAME
ARG MAUTIC_TRUSTED_PROXIES
ARG MAUTIC_URL
ARG MAUTIC_ADMIN_EMAIL
ARG MAUTIC_ADMIN_PASSWORD

ENV MAUTIC_DB_HOST=$MAUTIC_DB_HOST \
    MAUTIC_DB_PORT=$MAUTIC_DB_PORT \
    MAUTIC_DB_USER=$MAUTIC_DB_USER \
    MAUTIC_DB_PASSWORD=$MAUTIC_DB_PASSWORD \
    MAUTIC_DB_NAME=$MAUTIC_DB_NAME \
    MAUTIC_TRUSTED_PROXIES=$MAUTIC_TRUSTED_PROXIES \
    MAUTIC_URL=$MAUTIC_URL \
    MAUTIC_ADMIN_EMAIL=$MAUTIC_ADMIN_EMAIL \
    MAUTIC_ADMIN_PASSWORD=$MAUTIC_ADMIN_PASSWORD \
    PHP_INI_DATE_TIMEZONE='Europe/Bucharest'

# 1. Forcefully remove conflicting MPM load files
# 2. Enable prefork (required for mod_php)
# 3. Ensure permissions are set
RUN rm -f /etc/apache2/mods-enabled/mpm_event.load /etc/apache2/mods-enabled/mpm_worker.load && \
    a2enmod mpm_prefork && \
    mkdir -p /var/www/html/var/logs && \
    chown -R www-data:www-data /var/www/html/var/logs

# Use the default entrypoint provided by the Mautic image
ENTRYPOINT ["docker-mautic-entrypoint"]
CMD ["apache2-foreground"]
