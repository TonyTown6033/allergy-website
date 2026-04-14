#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
LINES="${LINES:-400}"
BUNDLE_ROOT="${BUNDLE_ROOT:-$ROOT_DIR/output/support-bundles}"
WORK_DIR="$BUNDLE_ROOT/allergy-support-$TIMESTAMP"
ARCHIVE_PATH="$BUNDLE_ROOT/allergy-support-$TIMESTAMP.tar.gz"

mkdir -p "$WORK_DIR"

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD=(docker-compose)
else
  echo "Neither 'docker compose' nor 'docker-compose' is available." >&2
  exit 1
fi

run_capture() {
  local output_file="$1"
  shift
  {
    echo "\$ $*"
    echo
    "$@"
  } >"$output_file" 2>&1 || true
}

redact_stream_file() {
  local file_path="$1"
  if [[ ! -f "$file_path" ]]; then
    return 0
  fi

  perl -0pi -e '
    s/^(\s*(?:SESSION_SECRET|CRYPTO_SECRET|SUBMODULES_TOKEN|.*TOKEN|.*SECRET|.*PASSWORD|.*PASSWD|.*COOKIE|.*KEY)\s*[:=]\s*).*$/${1}***REDACTED***/gmi
  ' "$file_path"
}

redact_env_file() {
  local src="$1"
  local dst="$2"
  if [[ ! -f "$src" ]]; then
    return 0
  fi

  awk '
    /^[[:space:]]*#/ || /^[[:space:]]*$/ { print; next }
    /^[A-Za-z_][A-Za-z0-9_]*=/ {
      split($0, parts, "=")
      key = parts[1]
      value = substr($0, length(key) + 2)
      upper = toupper(key)
      if (upper ~ /(SECRET|TOKEN|KEY|PASSWORD|PASSWD|COOKIE)/) {
        print key "=***REDACTED***"
      } else {
        print key "=" value
      }
      next
    }
    { print }
  ' "$src" >"$dst"
}

read_env_value() {
  local key="$1"
  local default_value="$2"
  local value
  value="$(awk -F= -v target="$key" '
    $0 ~ "^[[:space:]]*" target "=" {
      sub(/^[[:space:]]*[^=]+=/, "", $0)
      print $0
      exit
    }
  ' .env 2>/dev/null || true)"
  if [[ -n "$value" ]]; then
    printf '%s\n' "$value"
  else
    printf '%s\n' "$default_value"
  fi
}

collect_curl() {
  local url="$1"
  local output_file="$2"
  {
    echo "\$ curl -I -L -sS $url"
    echo
    curl -I -L -sS --max-time 15 "$url"
  } >"$output_file" 2>&1 || true
}

collect_body() {
  local url="$1"
  local output_file="$2"
  {
    echo "\$ curl -sS $url"
    echo
    curl -sS --max-time 15 "$url"
  } >"$output_file" 2>&1 || true
}

BACKEND_PORT="24300"
FRONTEND_PORT="24880"
if [[ -f ".env" ]]; then
  BACKEND_PORT="$(read_env_value BACKEND_PORT "$BACKEND_PORT")"
  FRONTEND_PORT="$(read_env_value FRONTEND_PORT "$FRONTEND_PORT")"
fi

printf 'timestamp=%s\nroot_dir=%s\nlines=%s\ncompose_cmd=%s\n' \
  "$TIMESTAMP" "$ROOT_DIR" "$LINES" "${COMPOSE_CMD[*]}" >"$WORK_DIR/summary.txt"

run_capture "$WORK_DIR/uname.txt" uname -a
run_capture "$WORK_DIR/date.txt" date
run_capture "$WORK_DIR/docker-version.txt" docker --version
run_capture "$WORK_DIR/docker-compose-version.txt" "${COMPOSE_CMD[@]}" version
run_capture "$WORK_DIR/docker-ps.txt" docker ps -a
run_capture "$WORK_DIR/docker-images.txt" docker images
run_capture "$WORK_DIR/compose-ps.txt" "${COMPOSE_CMD[@]}" ps
run_capture "$WORK_DIR/compose-config.txt" "${COMPOSE_CMD[@]}" config
redact_stream_file "$WORK_DIR/compose-config.txt"
run_capture "$WORK_DIR/allergy-api.log" "${COMPOSE_CMD[@]}" logs --tail "$LINES" allergy-api
run_capture "$WORK_DIR/allergy-web.log" "${COMPOSE_CMD[@]}" logs --tail "$LINES" allergy-web

collect_body "http://127.0.0.1:${BACKEND_PORT}/api/status" "$WORK_DIR/backend-status.json"
collect_curl "http://127.0.0.1:${BACKEND_PORT}/api/status" "$WORK_DIR/backend-status-head.txt"
collect_curl "http://127.0.0.1:${FRONTEND_PORT}/" "$WORK_DIR/frontend-home-head.txt"
collect_body "http://127.0.0.1:${FRONTEND_PORT}/healthz" "$WORK_DIR/frontend-health.txt"

cp docker-compose.yml "$WORK_DIR/docker-compose.yml"
redact_env_file ".env" "$WORK_DIR/env.redacted"

if [[ -d "docker-data/new-api" ]]; then
  {
    echo "\$ find docker-data/new-api -maxdepth 3 -type f | sort"
    echo
    find docker-data/new-api -maxdepth 3 -type f | sort
  } >"$WORK_DIR/data-tree.txt" 2>&1 || true
fi

tar -czf "$ARCHIVE_PATH" -C "$BUNDLE_ROOT" "$(basename "$WORK_DIR")"

cat <<EOF
Support bundle created:
$ARCHIVE_PATH

You can send back:
1. The archive itself
2. Or the key files inside:
   - $(basename "$WORK_DIR")/compose-ps.txt
   - $(basename "$WORK_DIR")/allergy-api.log
   - $(basename "$WORK_DIR")/allergy-web.log
   - $(basename "$WORK_DIR")/backend-status-head.txt
   - $(basename "$WORK_DIR")/frontend-home-head.txt
EOF
