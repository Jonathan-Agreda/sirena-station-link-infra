#!/bin/sh
set -e

API="http://emqx:18083/api/v5"

DASH_USER="${EMQX_DASHBOARD_USER:-admin}"
DASH_PASS="${EMQX_DASHBOARD_PASS:-admin123}"

echo "[SEED-SIRENS] Login dashboard..."
TOKEN="$(
  curl -fsS -X POST "${API}/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"${DASH_USER}\",\"password\":\"${DASH_PASS}\"}" \
  | sed -E 's/.*"token":"?([^"]+)".*/\1/'
)"
AUTH1="Authorization: Bearer ${TOKEN}"
AUTH2="Content-Type: application/json"

# Asegurar authorization source built_in_database
echo "[SEED-SIRENS] Ensure authorization source..."
curl -fsS -X POST "${API}/authorization/sources" \
  -H "$AUTH1" -H "$AUTH2" \
  -d '{"type":"built_in_database","enable":true,"max_rules":200}' \
  || echo "(authorization source ya existía)"

create_user_and_acls() {
  ID="$1"; PW="$2"

  echo "[SEED-SIRENS] User ${ID}..."
  curl -fsS -X POST "${API}/authentication/password_based:built_in_database/users" \
    -H "$AUTH1" -H "$AUTH2" \
    -d "{\"user_id\":\"${ID}\",\"password\":\"${PW}\"}" \
    || echo "(usuario ${ID} ya existía)"

  RULES_USER='[
    {"action":"publish","permission":"allow","topic":"status/${username}/#"},
    {"action":"publish","permission":"allow","topic":"tele/${username}/#"},
    {"action":"publish","permission":"allow","topic":"cmd/${username}/ack"},
    {"action":"subscribe","permission":"allow","topic":"cmd/${username}/#"}
  ]'
  curl -fsS -X PUT "${API}/authorization/sources/built_in_database/rules/users/${ID}" \
    -H "$AUTH1" -H "$AUTH2" \
    -d "{\"username\":\"${ID}\",\"rules\":${RULES_USER}}"

  RULES_CLIENT='[
    {"action":"publish","permission":"allow","topic":"status/${clientid}/#"},
    {"action":"publish","permission":"allow","topic":"tele/${clientid}/#"},
    {"action":"publish","permission":"allow","topic":"cmd/${clientid}/ack"},
    {"action":"subscribe","permission":"allow","topic":"cmd/${clientid}/#"}
  ]'
  curl -fsS -X PUT "${API}/authorization/sources/built_in_database/rules/clients/${ID}" \
    -H "$AUTH1" -H "$AUTH2" \
    -d "{\"clientid\":\"${ID}\",\"rules\":${RULES_CLIENT}}"
}

# SRN-001..SRN-010 con clave srn-00x-api-key
i=1
while [ $i -le 10 ]; do
  num=$(printf "%03d" $i)
  create_user_and_acls "SRN-${num}" "srn-api-key-${num}"
  i=$((i+1))
done

echo "[SEED-SIRENS] OK."
