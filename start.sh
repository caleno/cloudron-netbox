#!/bin/bash
set -eu

# --------------------------------------------
# Unit runtime + config in /app/data
# --------------------------------------------
UNIT_DIR="/app/data/opt/unit"
mkdir -p "${UNIT_DIR}" "${UNIT_DIR}/state" "${UNIT_DIR}/tmp"

# On first run, seed the Unit config from the original read-only one
if [ ! -f "${UNIT_DIR}/nginx-unit.json" ]; then
  cp /etc/unit/nginx-unit.json "${UNIT_DIR}/nginx-unit.json"
fi

# Make sure Unit can write here
chown -R unit:root "${UNIT_DIR}" || true

# Export for launch-netbox.sh
export UNIT_DIR
export UNIT_CONFIG="${UNIT_DIR}/nginx-unit.json"
export UNIT_SOCKET="${UNIT_DIR}/unit.sock"

# --- 1. Map Cloudron Postgres addon -> NetBox DB vars ---

export DB_HOST="${CLOUDRON_POSTGRESQL_HOST}"
export DB_NAME="${CLOUDRON_POSTGRESQL_DATABASE}"
export DB_USER="${CLOUDRON_POSTGRESQL_USERNAME}"
export DB_PASSWORD="${CLOUDRON_POSTGRESQL_PASSWORD}"

# --- 2. Map Cloudron Redis addon -> NetBox Redis vars ---

export REDIS_HOST="${CLOUDRON_REDIS_HOST}"
export REDIS_PORT="${CLOUDRON_REDIS_PORT}"
export REDIS_PASSWORD="${CLOUDRON_REDIS_PASSWORD:-}"

# Use same Redis instance for cache but different DB index
export REDIS_DATABASE="${REDIS_DATABASE:-0}"
export REDIS_CACHE_HOST="${REDIS_HOST}"
export REDIS_CACHE_PORT="${REDIS_PORT}"
export REDIS_CACHE_PASSWORD="${REDIS_PASSWORD}"
export REDIS_CACHE_DATABASE="${REDIS_CACHE_DATABASE:-1}"

# --- 3. Secret key & allowed hosts ---

if [ -z "${SECRET_KEY:-}" ]; then
  # Derive a stable-ish secret key from the Cloudron app origin/domain
  SECRET_SOURCE="${CLOUDRON_APP_ORIGIN:-${CLOUDRON_APP_DOMAIN:-netbox}}"
  export SECRET_KEY="$(printf '%s' "$SECRET_SOURCE" | sha256sum | cut -c1-50)"
fi

# Cloudron gives us the app’s domain
export ALLOWED_HOSTS="${CLOUDRON_APP_DOMAIN:-*}"

# --- 4. Persistent files under /app/data ---

export MEDIA_ROOT="/app/data/media"
mkdir -p "$MEDIA_ROOT"

# Ensure persistent dirs
mkdir -p /app/data/media /app/data/scripts /app/data/reports /app/data/logs
chown -R 101:101 /app/data   # 101 is the netbox user in the official image

# Tell NetBox to use those
export MEDIA_ROOT=/app/data/media
export SCRIPTS_ROOT=/app/data/scripts
export REPORTS_ROOT=/app/data/reports


# Make sure Unit/NetBox user can write here (unit user in image is usually uid 101)
chown -R 101:101 /app/data || true

# --- 5. Enable LDAP only if Cloudron LDAP is actually wired
if [ -n "${CLOUDRON_LDAP_URL:-}" ]; then
    export REMOTE_AUTH_BACKEND=netbox.authentication.LDAPBackend
    # Optional flag for your own logic
    export CLOUDRON_LDAP_ENABLED=true
fi


# --- 6. Hand off to upstream entrypoint (migrations, superuser, then unitd) ---

exec /opt/netbox/docker-entrypoint.sh "$@"
