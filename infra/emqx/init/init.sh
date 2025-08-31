#!/bin/sh
set -e

API="http://emqx:18083/api/v5"
DASH_USER="${EMQX_DASHBOARD_USER:-admin}"
DASH_PASS="${EMQX_DASHBOARD_PASS:-admin123}"
BACK_USER="${MQTT_BACKEND_USER:-srv-backend}"
BACK_PASS="${MQTT_BACKEND_PASS:-srv-backend-secret}"

echo "[INIT] Esperando API..."
until curl -fsS "${API}/status" >/dev/null 2>&1; do sleep 2; done

TOKEN="$(curl -fsS -X POST "${API}/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"${DASH_USER}\",\"password\":\"${DASH_PASS}\"}" \
  | sed -E 's/.*"token":"?([^"]+)".*/\1/')"

AUTH1="Authorization: Bearer ${TOKEN}"
AUTH2="Content-Type: application/json"

# Authorization source
curl -fsS -X POST "${API}/authorization/sources" \
  -H "$AUTH1" -H "$AUTH2" \
  -d '{"type":"built_in_database","enable":true,"max_rules":200}' \
  || echo "(authorization source ya existía)"

# Backend user
curl -fsS -X POST "${API}/authentication/password_based:built_in_database/users" \
  -H "$AUTH1" -H "$AUTH2" \
  -d "{\"user_id\":\"${BACK_USER}\",\"password\":\"${BACK_PASS}\"}" \
  || echo "(backend ya existía)"

BACK_RULES='[
  {"action":"subscribe","permission":"allow","topic":"status/+/#"},
  {"action":"subscribe","permission":"allow","topic":"tele/+/#"},
  {"action":"subscribe","permission":"allow","topic":"cmd/+/#"},
  {"action":"publish","permission":"allow","topic":"cmd/+/#"}
]'
curl -fsS -X PUT "${API}/authorization/sources/built_in_database/rules/users/${BACK_USER}" \
  -H "$AUTH1" -H "$AUTH2" \
  -d "{\"username\":\"${BACK_USER}\",\"rules\":${BACK_RULES}}"

# Crear sirenas SRN-001..SRN-010
i=1
while [ $i -le 10 ]; do
  num=$(printf "%03d" $i)
  ID="SRN-${num}"
  PW="srn-api-key-${num}"

  curl -fsS -X POST "${API}/authentication/password_based:built_in_database/users" \
    -H "$AUTH1" -H "$AUTH2" \
    -d "{\"user_id\":\"${ID}\",\"password\":\"${PW}\"}" \
    || echo "(sirena ${ID} ya existía)"

  RULES='[
    {"action":"publish","permission":"allow","topic":"status/${username}/#"},
    {"action":"publish","permission":"allow","topic":"tele/${username}/#"},
    {"action":"publish","permission":"allow","topic":"cmd/${username}/ack"},
    {"action":"subscribe","permission":"allow","topic":"cmd/${username}/#"}
  ]'
  curl -fsS -X PUT "${API}/authorization/sources/built_in_database/rules/users/${ID}" \
    -H "$AUTH1" -H "$AUTH2" \
    -d "{\"username\":\"${ID}\",\"rules\":${RULES}}"

  i=$((i+1))
done

echo "[INIT] Todo listo."
