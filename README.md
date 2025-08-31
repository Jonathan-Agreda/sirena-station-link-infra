# Sirena Station Link - Stack de Infraestructura

Este repo contiene la **infraestructura base en Docker** para levantar los servicios necesarios del sistema:

- **PostgreSQL 16** (Base de datos principal)
- **Keycloak 26.3.2** (Autenticación OIDC/roles)
- **EMQX 5.8.6** (Broker MQTT para sirenas)
- **Init de EMQX** (job de inicialización de usuarios/dispositivos)

---

## 🚀 Levantar servicios

1. Clonar este repo o entrar en la carpeta `stack/`.
2. Copiar el archivo de entorno:

```bash
cp .env.example .env
```

3. Levantar servicios:

```bash
docker compose up -d
```

---

## 📋 Comandos útiles

- Ver estado de contenedores:
```bash
docker ps
```

- Ver logs de un servicio:
```bash
docker compose logs -f keycloak
docker compose logs -f emqx
```

- Apagar todo (los volúmenes **no se borran**):
```bash
docker compose down
```

- Apagar y borrar volúmenes (⚠️ elimina data de DB/Keycloak/EMQX):
```bash
docker compose down -v
```

---

## 💾 Backup de la base de datos

Para exportar un backup de PostgreSQL:

```bash
docker exec -t pg-sirena pg_dump -U $POSTGRES_SUPERUSER > backups/db_$(date +%Y%m%d).sql
```

Para restaurar:

```bash
cat backups/db_20250101.sql | docker exec -i pg-sirena psql -U $POSTGRES_SUPERUSER
```

---

## 🔐 Notas de seguridad

- Los usuarios/contraseñas se configuran en `.env`.  
- No subas `.env` al repo (ya está en `.gitignore`).  
- En producción, se recomienda cerrar los puertos externos de Postgres y Keycloak, dejando acceso solo desde el backend.  

---

## 🌐 Redes

Todos los servicios se comunican en la red interna `sirena-net`.  
El backend podrá acceder usando estos **hostnames**:

- PostgreSQL → `postgres:5432`
- Keycloak → `kc-sirena:8080`
- EMQX → `emqx-sirena:1883`

---
