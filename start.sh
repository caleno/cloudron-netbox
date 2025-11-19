#!/bin/bash
set -eu

# 1. Configure database from env
export DB_NAME=$CLOUDRON_POSTGRESQL_DATABASE
export DB_USER=$CLOUDRON_POSTGRESQL_USERNAME
export DB_PASSWORD=$CLOUDRON_POSTGRESQL_PASSWORD
export DB_HOST=$CLOUDRON_POSTGRESQL_HOST
export DB_PORT=$CLOUDRON_POSTGRESQL_PORT

# 2. Configure Redis from env
export REDIS_HOST=$CLOUDRON_REDIS_HOST
export REDIS_PORT=$CLOUDRON_REDIS_PORT

# 3. Run Django setup
python3 manage.py migrate
python3 manage.py collectstatic --noinput

# 4. Create superuser if missing (via a small Django management command or shell script)

# 5. Start web + worker processes (example)
gunicorn netbox.wsgi:application --bind 0.0.0.0:8000 --workers 3

