#!/usr/bin/env bash
# Ping ringan ke Supabase REST API agar project free tier tidak di-pause
# karena tidak ada aktivitas.
#
# Pemakaian:
#   SUPABASE_URL=https://xxxx.supabase.co \
#   SUPABASE_KEY=sb_publishable_... \
#   ./scripts/supabase_keepalive.sh
#
# Jika variabel tidak di-set, skrip mencoba membaca env.json di root project
# (format --dart-define-from-file). env.json tidak boleh di-commit.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/env.json}"

json_value() {
  sed -n 's/^[[:space:]]*"'"$1"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    "$2" | head -n 1
}

if [[ -z "${SUPABASE_URL:-}" && -f "$ENV_FILE" ]]; then
  SUPABASE_URL="$(json_value SUPABASE_URL "$ENV_FILE")"
fi

if [[ -z "${SUPABASE_KEY:-}" && -f "$ENV_FILE" ]]; then
  SUPABASE_KEY="$(json_value SUPABASE_PUBLISHABLE_KEY "$ENV_FILE")"
  if [[ -z "$SUPABASE_KEY" ]]; then
    SUPABASE_KEY="$(json_value SUPABASE_ANON_KEY "$ENV_FILE")"
  fi
fi

SUPABASE_URL="${SUPABASE_URL:-}"
SUPABASE_KEY="${SUPABASE_KEY:-}"

if [[ -z "$SUPABASE_URL" || -z "$SUPABASE_KEY" ]]; then
  echo "Gagal: SUPABASE_URL dan SUPABASE_KEY wajib diisi." >&2
  exit 1
fi

if [[ "$SUPABASE_URL" == *"PROJECT_REF"* || "$SUPABASE_KEY" == *"ISI_DENGAN"* ]]; then
  echo "Gagal: env.json masih berisi nilai placeholder." >&2
  exit 1
fi

ENDPOINT="${SUPABASE_URL%/}/rest/v1/branches?select=id&limit=1"
BODY_FILE="$(mktemp)"
trap 'rm -f "$BODY_FILE"' EXIT

# Request kecil yang tetap melewati PostgREST + RLS, sehingga tercatat sebagai
# aktivitas project. Respons 200 dengan array kosong tetap dianggap sukses.
HTTP_CODE="$(
  curl -sS --max-time 30 \
    -o "$BODY_FILE" \
    -w '%{http_code}' \
    -H "apikey: $SUPABASE_KEY" \
    -H "Authorization: Bearer $SUPABASE_KEY" \
    "$ENDPOINT"
)" || {
  echo "Gagal: tidak dapat menghubungi $ENDPOINT" >&2
  exit 1
}

case "$HTTP_CODE" in
  200|206)
    echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] Supabase keepalive OK (HTTP $HTTP_CODE)"
    ;;
  401|403)
    echo "Gagal: kunci ditolak (HTTP $HTTP_CODE). Gunakan publishable/anon key." >&2
    cat "$BODY_FILE" >&2
    exit 1
    ;;
  *)
    echo "Gagal: Supabase membalas HTTP $HTTP_CODE." >&2
    cat "$BODY_FILE" >&2
    exit 1
    ;;
esac
