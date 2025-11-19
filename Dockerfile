FROM netboxcommunity/netbox:latest

# Cloudron runs everything as cloudron user
RUN adduser --system --group --home /app netbox
WORKDIR /app

# Copy Cloudron-specific bits
COPY start.sh /app/start.sh
COPY netbox_configuration.py /etc/netbox/configuration.py

RUN chmod +x /app/start.sh

# Cloudron will inject env vars for Postgres/Redis/etc.
ENV SUPERUSER_NAME=admin \
    SUPERUSER_EMAIL=admin@example.com

CMD ["/app/start.sh"]

