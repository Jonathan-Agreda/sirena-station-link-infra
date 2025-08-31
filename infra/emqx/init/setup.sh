#!/bin/sh 
set -e

API="http://emqx:18083/api/v5"

# Variables del .env (raíz)
DASH_USER="${EMQX_DASHBOARD_USER:-admin}"
DASH_PASS="${EMQX_DASHBOARD_PASS:-admin123}"

BACK_USER="${MQTT_BACKEND_USER:-srv-backend}"
BACK_PASS="${MQTT_BACKEND_PASS:-srv-backend-secret}"

DEVICE_ID="${SEED_DEVICE_ID:-SRN-001}"
DEVICE_PW="${SEED_DEVICE_APIKEY:-srn-001-api-key}"

echo "[EMQX-INIT] Esperando API..."
until curl -fsS "${API}/status" >/dev/null 2>&1; do
  sleep 2
done
echo "[EMQX-INIT] API OK"

echo "[EMQX-INIT] Login dashboard..."
TOKEN="$(
  curl -fsS -X POST "${API}/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"${DASH_USER}\",\"password\":\"${DASH_PASS}\"}" \
  | sed -E 's/.*"token":"?([^"]+)".*/\1/'
)"
AUTH1="Authorization: Bearer ${TOKEN}"
AUTH2="Content-Type: application/json"

# --- Authorization source: built_in_database ---
echo "[EMQX-INIT] Habilitar authorization built_in_database (idempotente)..."
curl -fsS -X POST "${API}/authorization/sources" \
  -H "$AUTH1" -H "$AUTH2" \
  -d '{"type":"built_in_database","enable":true,"max_rules":200}' \
  || echo "(authorization source ya existía)"

# --- Usuario AUTHENTICATION (dispositivo semilla) ---
echo "[EMQX-INIT] Crear usuario AUTHENTICATION (seed device) si no existe..."
curl -fsS -X POST "${API}/authentication/password_based:built_in_database/users" \
  -H "$AUTH1" -H "$AUTH2" \
  -d "{\"user_id\":\"${DEVICE_ID}\",\"password\":\"${DEVICE_PW}\"}" \
  || echo "(seed device ya existía)"

# --- ACL del dispositivo ---
# Reglas por USERNAME (funciona aunque el clientId sea aleatorio)
RULES_USER='[
  {"action":"publish","permission":"allow","topic":"status/${username}/#"},
  {"action":"publish","permission":"allow","topic":"tele/${username}/#"},
  {"action":"publish","permission":"allow","topic":"cmd/${username}/ack"},
  {"action":"subscribe","permission":"allow","topic":"cmd/${username}/#"}
]'
echo "[EMQX-INIT] Set rules por USERNAME (${DEVICE_ID})..."
curl -fsS -X PUT "${API}/authorization/sources/built_in_database/rules/users/${DEVICE_ID}" \
  -H "$AUTH1" -H "$AUTH2" \
  -d "{\"username\":\"${DEVICE_ID}\",\"rules\":${RULES_USER}}"

# Reglas por CLIENTID (ideal si clientId=deviceId en firmware)
RULES_CLIENT='[
  {"action":"publish","permission":"allow","topic":"status/${clientid}/#"},
  {"action":"publish","permission":"allow","topic":"tele/${clientid}/#"},
  {"action":"publish","permission":"allow","topic":"cmd/${clientid}/ack"},
  {"action":"subscribe","permission":"allow","topic":"cmd/${clientid}/#"}
]'
echo "[EMQX-INIT] Set rules por CLIENTID (${DEVICE_ID})..."
curl -fsS -X PUT "${API}/authorization/sources/built_in_database/rules/clients/${DEVICE_ID}" \
  -H "$AUTH1" -H "$AUTH2" \
  -d "{\"clientid\":\"${DEVICE_ID}\",\"rules\":${RULES_CLIENT}}"

# --- Backend service account ---
echo "[EMQX-INIT] Crear usuario AUTHENTICATION (backend) si no existe..."
curl -fsS -X POST "${API}/authentication/password_based:built_in_database/users" \
  -H "$AUTH1" -H "$AUTH2" \
  -d "{\"user_id\":\"${BACK_USER}\",\"password\":\"${BACK_PASS}\"}" \
  || echo "(backend user ya existía)"

BACK_RULES='[
  {"action":"subscribe","permission":"allow","topic":"status/+/#"},
  {"action":"subscribe","permission":"allow","topic":"tele/+/#"},
  {"action":"subscribe","permission":"allow","topic":"cmd/+/#"},
  {"action":"publish","permission":"allow","topic":"cmd/+/#"}
]'
echo "[EMQX-INIT] Reglas backend por USERNAME (${BACK_USER})..."
curl -fsS -X PUT "${API}/authorization/sources/built_in_database/rules/users/${BACK_USER}" \
  -H "$AUTH1" -H "$AUTH2" \
  -d "{\"username\":\"${BACK_USER}\",\"rules\":${BACK_RULES}}"

echo "[EMQX-INIT] Listo."
