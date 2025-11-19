FROM netboxcommunity/netbox:latest

# Cloudron runs as cloudron user; NetBox image already has its own structure.
# We'll just add our entrypoint script + env templating.

USER root
WORKDIR /opt/netbox

# Copy helper files
COPY start.sh /app/start.sh
COPY netbox.env.template /app/netbox.env.template

RUN chmod +x /app/start.sh

# Cloudron will inject these env vars at runtime (postgres, redis, domain, etc.)
# We do not set them here to keep the image generic.

EXPOSE 8080

CMD ["/app/start.sh"]
