#!/bin/bash
set -e

echo "⏳ Esperando a que Keycloak arranque en http://localhost:8080..."
until curl -s http://localhost:8080 > /dev/null; do
  sleep 2
done
echo "✅ Keycloak disponible"

# Configurar credenciales admin
/opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 \
  --realm master \
  --user ${KEYCLOAK_ADMIN} \
  --password ${KEYCLOAK_ADMIN_PASSWORD}

# Borrar realm previo si existe
if /opt/keycloak/bin/kcadm.sh get realms/alarma > /dev/null 2>&1; then
  echo "🗑  Borrando realm 'alarma' existente..."
  /opt/keycloak/bin/kcadm.sh delete realms/alarma
fi

# Importar realm desde JSON (el que ya funciona con sub + roles + session limit)
echo "📥 Importando realm 'alarma'..."
/opt/keycloak/bin/kcadm.sh create realms -f /opt/keycloak/data/import/realm-alarma.json

echo "✅ Realm 'alarma' importado correctamente"
