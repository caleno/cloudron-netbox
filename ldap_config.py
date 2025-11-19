# /etc/netbox/config/ldap/ldap_config.py
import os
import ldap
from django_auth_ldap.config import LDAPSearch

AUTH_LDAP_SERVER_URI = os.environ.get("CLOUDRON_LDAP_URL")

AUTH_LDAP_BIND_DN = os.environ.get("CLOUDRON_LDAP_BIND_DN", "")
AUTH_LDAP_BIND_PASSWORD = os.environ.get("CLOUDRON_LDAP_BIND_PASSWORD", "")

# Users live under CLOUDRON_LDAP_USERS_BASE_DN, attribute 'username'
AUTH_LDAP_USER_SEARCH = LDAPSearch(
    os.environ.get("CLOUDRON_LDAP_USERS_BASE_DN", ""),
    ldap.SCOPE_SUBTREE,
    "(username=%(user)s)",
)

AUTH_LDAP_USER_ATTR_MAP = {
    "username": "username",
    "email": "mail",
    "first_name": "givenName",
    "last_name": "sn",
}