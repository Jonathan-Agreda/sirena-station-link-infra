
#!/usr/bin/env bash

set -Eeuo pipefail

# ============================================================
# SIRENA STATION LINK
# PostgreSQL database initialization
# ============================================================

echo "[PostgreSQL] Starting database initialization..."

# ============================================================
# VALIDATE REQUIRED ENVIRONMENT VARIABLES
# ============================================================

: "${POSTGRES_USER:?POSTGRES_USER is required}"

: "${APP_DB_NAME:?APP_DB_NAME is required}"
: "${APP_DB_USER:?APP_DB_USER is required}"
: "${APP_DB_PASSWORD:?APP_DB_PASSWORD is required}"

: "${KC_DB_NAME:?KC_DB_NAME is required}"
: "${KC_DB_USER:?KC_DB_USER is required}"
: "${KC_DB_PASSWORD:?KC_DB_PASSWORD is required}"

# ============================================================
# CREATE DATABASES AND USERS
# ============================================================

psql \
  --username "$POSTGRES_USER" \
  --dbname postgres \
  --set ON_ERROR_STOP=1 <<'EOSQL'

\getenv app_db_name APP_DB_NAME
\getenv app_db_user APP_DB_USER
\getenv app_db_password APP_DB_PASSWORD

\getenv kc_db_name KC_DB_NAME
\getenv kc_db_user KC_DB_USER
\getenv kc_db_password KC_DB_PASSWORD

-- Backend role

CREATE ROLE :"app_db_user"
  WITH LOGIN PASSWORD :'app_db_password';

-- Backend database

CREATE DATABASE :"app_db_name"
  OWNER :"app_db_user";

GRANT ALL PRIVILEGES
  ON DATABASE :"app_db_name"
  TO :"app_db_user";

-- Keycloak role

CREATE ROLE :"kc_db_user"
  WITH LOGIN PASSWORD :'kc_db_password';

-- Keycloak database

CREATE DATABASE :"kc_db_name"
  OWNER :"kc_db_user";

GRANT ALL PRIVILEGES
  ON DATABASE :"kc_db_name"
  TO :"kc_db_user";

EOSQL

echo "[PostgreSQL] Database initialization completed."
