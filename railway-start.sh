#!/bin/bash
# Railway wrapper for OpenCode Manager. Runs as root, prepares the volume and the
# auth settings, then hands over to the upstream entrypoint (which drops to `node`).
set -euo pipefail

fail() { echo "railway-start: ERROR: $*" >&2; exit 1; }

# 1. Never start without a login. Without ADMIN_EMAIL + ADMIN_PASSWORD upstream
#    lets the first visitor register, so refuse to start instead.
[ -n "${AUTH_SECRET:-}" ] || fail "AUTH_SECRET is empty. Set it to a long random string."
[ -n "${ADMIN_EMAIL:-}" ] || fail "ADMIN_EMAIL is empty. Set the admin login email."
pw="${ADMIN_PASSWORD:-}"; [ "${#pw}" -ge 8 ] || fail "ADMIN_PASSWORD must be at least 8 characters."

# 2. Public URL settings, derived from Railway's domain unless set explicitly.
if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  export AUTH_TRUSTED_ORIGINS="${AUTH_TRUSTED_ORIGINS:-https://${RAILWAY_PUBLIC_DOMAIN}}"
  export PASSKEY_RP_ID="${PASSKEY_RP_ID:-${RAILWAY_PUBLIC_DOMAIN}}"
  export PASSKEY_ORIGIN="${PASSKEY_ORIGIN:-https://${RAILWAY_PUBLIC_DOMAIN}}"
else
  echo "railway-start: no RAILWAY_PUBLIC_DOMAIN; using localhost origins (add a domain or set AUTH_TRUSTED_ORIGINS)"
  export AUTH_TRUSTED_ORIGINS="${AUTH_TRUSTED_ORIGINS:-http://localhost:${PORT:-5003}}"
  export AUTH_SECURE_COOKIES="${AUTH_SECURE_COOKIES_OVERRIDE:-false}"
fi

# 3. Optional provider keys: drop empty ones so OpenCode doesn't see a blank key.
for v in OPENAI_API_KEY ANTHROPIC_API_KEY OPENROUTER_API_KEY GEMINI_API_KEY GOOGLE_GENERATIVE_AI_API_KEY GROQ_API_KEY DEEPSEEK_API_KEY; do
  if [ -z "${!v:-}" ]; then unset "$v"; fi
done
# Never forward a password reset flag that is set to anything but "true".
[ "${ADMIN_PASSWORD_RESET:-false}" = "true" ] || export ADMIN_PASSWORD_RESET=false

# 4. Cap thread pools to the service's CPUs, not the host's (Railway shows 32+).
cpus=1
if [ -r /sys/fs/cgroup/cpu.max ]; then
  read -r quota period < /sys/fs/cgroup/cpu.max || true
  if [ "${quota:-max}" != "max" ] && [ -n "${period:-}" ] && [ "$period" -gt 0 ]; then
    cpus=$(( (quota + period - 1) / period ))
  else
    cpus=$(nproc 2>/dev/null || echo 2)
  fi
fi
[ "$cpus" -ge 1 ] || cpus=1
[ "$cpus" -le 4 ] || cpus=4
export UV_THREADPOOL_SIZE="${UV_THREADPOOL_SIZE:-$cpus}"
export BUN_JSC_numberOfGCMarkers="${BUN_JSC_numberOfGCMarkers:-$cpus}"
export RAYON_NUM_THREADS="${RAYON_NUM_THREADS:-$cpus}"

# 5. One volume at /data holds the workspace and the database.
data_root="$(dirname "$WORKSPACE_PATH")"
mkdir -p "$WORKSPACE_PATH" "$(dirname "$DATABASE_PATH")"
if [ "$(stat -c %U "$data_root")" != "node" ] || [ "$(stat -c %U "$WORKSPACE_PATH")" != "node" ]; then
  echo "railway-start: first boot on this volume, giving it to the node user"
  chown -R node:node "$data_root"
fi
chown node:node "$data_root" "$WORKSPACE_PATH" "$(dirname "$DATABASE_PATH")"
# OpenCode upgrades made from the app's settings land in ~/.opencode/bin: keep them on the volume.
mkdir -p "$data_root/opencode-bin"; chown node:node "$data_root/opencode-bin"
if [ ! -L /home/node/.opencode/bin ]; then rm -r /home/node/.opencode/bin 2>/dev/null || true; ln -s "$data_root/opencode-bin" /home/node/.opencode/bin; fi

echo "railway-start: OpenCode Manager on port ${PORT}, origin ${AUTH_TRUSTED_ORIGINS}, data in ${data_root}, ${cpus} CPU(s)"

# 6. Upstream entrypoint: installs nothing new (OpenCode is bundled), aligns the
#    user and execs the backend as `node`. Any non-zero exit makes Railway restart it.
stopping=0
on_stop() { stopping=1; [ -n "${child:-}" ] && kill -TERM "$child" 2>/dev/null; }
trap on_stop TERM INT
set +e
/docker-entrypoint.sh "$@" &
child=$!
wait "$child"; code=$?
# wait returns early when a trapped signal arrives: wait for the real exit.
while kill -0 "$child" 2>/dev/null; do wait "$child"; code=$?; done
if [ "$stopping" -eq 1 ]; then exit "$code"; fi
if [ "$code" -eq 0 ]; then
  # A clean exit nobody asked for still counts as a failure, so ON_FAILURE restarts it.
  echo "railway-start: backend exited 0 without a stop signal; exiting 1 so Railway restarts it" >&2
  exit 1
fi
echo "railway-start: backend exited with code $code" >&2
exit "$code"
