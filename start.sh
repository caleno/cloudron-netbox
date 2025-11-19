#!/bin/bash
set -eu

# --- 1. Map Cloudron Postgres addon to NetBox DB vars ---

export DB_HOST="${CLOUDRON_POSTGRESQL_HOST}"
export DB_NAME="${CLOUDRON_POSTGRESQL_DATABASE}"
export DB_USER="${CLOUDRON_POSTGRESQL_USERNAME}"
export DB_PASSWORD="${CLOUDRON_POSTGRESQL_PASSWORD}"

# --- 2. Map Cloudron Redis addon to NetBox Redis vars ---

export REDIS_HOST="${CLOUDRON_REDIS_HOST}"
export REDIS_PORT="${CLOUDRON_REDIS_PORT}"
export REDIS_PASSWORD="${CLOUDRON_REDIS_PASSWORD:-}"

# --- 3. Secret key & allowed hosts ---

# Use a stable SECRET_KEY across restarts – Cloudron will typically keep env vars
# constant; as a fallback we derive one from the app id.
if [ -z "${SECRET_KEY:-}" ]; then
  export SECRET_KEY="$(echo "${CLOUDRON_APP_ORIGIN:-netbox}" | sha256sum | cut -c1-50)"
fi

# ALLOWED_HOSTS is set via env in the official image; Cloudron provides app domain.
export ALLOWED_HOSTS="${CLOUDRON_APP_DOMAIN:-*}"

# --- 4. Render netbox.env from template ---

envsubst < /app/netbox.env.template > /opt/netbox/netbox.env

# Make sure media dir exists and is in localstorage (Cloudron mounts /run/local).
mkdir -p /run/local/media
chown -R 101:101 /run/local/media || true  # 101 is often the netbox user in image
export MEDIA_ROOT=/run/local/media

# Also export MEDIA_ROOT to env file for NetBox
echo "MEDIA_ROOT=${MEDIA_ROOT}" >> /opt/netbox/netbox.env

# --- 5. Prepare database & static files ---

# The official image has manage.py & venv in /opt/netbox
. /opt/netbox/venv/bin/activate

# Migrate & collectstatic
/opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py migrate --noinput
/opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py collectstatic --noinput

# --- 6. Create initial superuser if missing ---

ADMIN_USER="${NETBOX_ADMIN_USER:-admin}"
ADMIN_EMAIL="${NETBOX_ADMIN_EMAIL:-[email protected]}"
ADMIN_PASSWORD="${NETBOX_ADMIN_PASSWORD:-changeme}"

cat << 'PYCODE' | /opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py shell
from django.contrib.auth import get_user_model
import os

User = get_user_model()
username = os.environ.get("ADMIN_USER", "admin")
email = os.environ.get("ADMIN_EMAIL", "[email protected]")
password = os.environ.get("ADMIN_PASSWORD", "changeme")

if not User.objects.filter(username=username).exists():
    print(f"Creating NetBox superuser '{username}'")
    User.objects.create_superuser(username=username, email=email, password=password)
else:
    print(f"NetBox superuser '{username}' already exists")
PYCODE

# --- 7. Start NetBox (gunicorn via official entrypoint) ---

# The official image normally uses /opt/netbox/docker-entrypoint.sh.
# We just call the same command it would run by default: gunicorn on 0.0.0.0:8080.
exec /opt/netbox/venv/bin/gunicorn \
  --bind 0.0.0.0:8080 \
  --workers 3 \
  netbox.wsgi

