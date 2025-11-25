FROM netboxcommunity/netbox:latest

USER root

## Isntall LDAP support using django-auth-ldap
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libldap2-dev libsasl2-dev libssl-dev

COPY ldap_config.py /etc/netbox/config/ldap/ldap_config.py

COPY nginx-unit.json /etc/unit/nginx-unit.json

# Our small wrapper that maps Cloudron env vars -> NetBox vars
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh 

COPY launch-netbox.sh /app/launch-netbox.sh
RUN chmod +x /app/launch-netbox.sh

WORKDIR /opt/netbox/netbox

EXPOSE 8080

# IMPORTANT:
# - Keep upstream ENTRYPOINT (tini)
# - Only override CMD to call our wrapper, which then calls docker-entrypoint.sh
CMD ["/app/start.sh", "/app/launch-netbox.sh"]
