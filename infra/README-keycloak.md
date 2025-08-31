# 🚀 Guía rápida: Keycloak + Postgres (Sirena Station Link)

Este proyecto levanta **Keycloak**, **Postgres** y **EMQX** con datos separados.  
Incluye un **realm preconfigurado (`realm-alarma.json`)** y un **script de inicialización (`init-keycloak.sh`)**.

---

## 🔧 1. Levantar todo
```bash
docker compose up -d
```

Esto crea:
- Postgres con dos bases (`sirena_db`, `keycloak_db`)
- Keycloak (puerto `8080`)
- EMQX (MQTT puerto `1883`, dashboard en `18083`)

---

## 🔄 2. Resetear completamente (⚠️ borra datos)
```bash
docker compose down -v
docker volume rm sirena-station-link_pgdata
docker compose up -d
```

Esto recrea las DB limpias y vuelve a importar `realm-alarma.json`.

---

## 👤 3. Usuarios iniciales

Tras levantar, tendrás 4 usuarios en el **realm `alarma`**:

| Usuario  | Rol        | Password  |
|----------|-----------|-----------|
| admin1   | ADMIN     | admin123  |
| admin2   | SUPERADMIN| admin123  |
| admin3   | GUARDIA   | admin123  |
| admin4   | RESIDENTE | admin123  |

---

## 🛠 4. Script de Init Manual
El JSON (`realm-alarma.json`) debería cargar solo, pero si falla, usa el script.

Ejecutar dentro del contenedor Keycloak:

```bash
docker exec -it kc-sirena bash /opt/keycloak/init/init-keycloak.sh
```

Este script:
- Crea el **realm `alarma`** si no existe.
- Crea los **roles** (SUPERADMIN, ADMIN, GUARDIA, RESIDENTE).
- Crea los **clientes** (`frontend-spa`, `backend-api`).
- Crea los **4 usuarios** con su rol y password `admin123`.

---

## 🔑 5. Login y pruebas

- Keycloak UI → [http://localhost:8080](http://localhost:8080)  
  Usuario: `admin`  
  Password: `admin123`

- Realm: `alarma`  
- Tokens: incluirán `sub`, `roles`, `email`, etc.

---

## 📡 6. Comandos útiles

Ver logs de Keycloak:
```bash
docker logs -f kc-sirena
```

Entrar al contenedor de Keycloak:
```bash
docker exec -it kc-sirena bash
```

Ver si realm `alarma` existe:
```bash
docker exec -it kc-sirena   /opt/keycloak/bin/kcadm.sh get realms/alarma   --server http://localhost:8080   --realm master   --user admin   --password admin123
```
