#!/bin/bash

## This is a modifed version from Netbox git repository
## Last found here: https://github.com/netbox-community/netbox-docker/tree/release/docker
## Here you can also se the entrypoint script

## To be able to store socket and pid file we need to use wriable folder in Cloudron
# Base dir for Unit runtime stuff (socket, pid, state, tmp, config)
UNIT_DIR="${UNIT_DIR-/app/data/opt/unit}"

# Config file (we'll seed it from /etc/unit in start.sh on first run)
UNIT_CONFIG="${UNIT_CONFIG-${UNIT_DIR}/nginx-unit.json}"

# Also used in "nginx-unit.json"
UNIT_SOCKET="${UNIT_SOCKET-${UNIT_DIR}/unit.sock}"

load_configuration() {
  MAX_WAIT=10
  WAIT_COUNT=0

  while [ ! -S "$UNIT_SOCKET" ]; do
    if [ "$WAIT_COUNT" -ge "$MAX_WAIT" ]; then
      echo "⚠️ No control socket found; configuration will not be loaded."
      return 1
    fi

    WAIT_COUNT=$((WAIT_COUNT + 1))
    echo "⏳ Waiting for control socket to be created... (${WAIT_COUNT}/${MAX_WAIT})"
    sleep 1
  done

  # even when the control socket exists, it does not mean unit has finished initialisation
  # this curl call will get a reply once unit is fully launched
  curl --silent --output /dev/null --request GET \
       --unix-socket "$UNIT_SOCKET" http://localhost/ || true

  echo "⚙️ Applying configuration from $UNIT_CONFIG"

  RESP_CODE=$(
    curl \
      --silent \
      --output /dev/null \
      --write-out '%{http_code}' \
      --request PUT \
      --data-binary "@${UNIT_CONFIG}" \
      --unix-socket "$UNIT_SOCKET" \
      http://localhost/config
  )

  if [ "$RESP_CODE" != "200" ]; then
    echo "⚠️ Could not load Unit configuration"
    kill "$(cat "${UNIT_DIR}/unit.pid")"
    return 1
  fi

  echo "✅ Unit configuration loaded successfully"
}

load_configuration &

exec unitd \
  --no-daemon \
  --control "unix:${UNIT_SOCKET}" \
  --pid "${UNIT_DIR}/unit.pid" \
  --log /dev/stdout \
  --statedir "${UNIT_DIR}/state" \
  --tmpdir "${UNIT_DIR}/tmp" \
  --user unit \
  --group root