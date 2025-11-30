# 📋 Plan de Pruebas - Proyecto Sistemas Distribuidos

## 🎯 Objetivo

Validar que la arquitectura distribuida en Kubernetes cumple con todos los requisitos del proyecto:
- Multinodo con segmentación de red
- Alta disponibilidad
- NetworkPolicies como firewall
- Replicación de base de datos
- Funcionamiento correcto de la aplicación

---

## 📊 Sección 1: Ambientación del Cluster

### 🎯 Objetivo
Demostrar la arquitectura multinodo con zonas DMZ e Interna.

### ✅ Prueba 1.1: Verificar Nodos del Cluster

**Comando:**
```powershell
kubectl get nodes -o wide --show-labels
```

**Resultado Esperado:**
- 3 nodos en estado `Ready`
- `proyectosd` (control-plane)
- `proyectosd-m02` con label `zona=dmz`
- `proyectosd-m03` con label `zona=interna`

**Puntos a Validar:**
- ✅ Todos los nodos STATUS = Ready
- ✅ Labels correctos en cada nodo
- ✅ Versión de Kubernetes visible

**Evidencia:** Screenshot de la salida del comando

---

### ✅ Prueba 1.2: Verificar Namespaces

**Comando:**
```powershell
kubectl get namespaces
kubectl get all -n dmz
kubectl get all -n interna
```

**Resultado Esperado:**
- Namespace `dmz` creado con frontend
- Namespace `interna` creado con backend, DB, cache

**Puntos a Validar:**
- ✅ Namespaces dmz e interna existen
- ✅ Pods distribuidos correctamente por namespace
- ✅ Frontend solo en dmz
- ✅ Backend, PostgreSQL, Redis solo en interna

**Evidencia:** Screenshot mostrando ambos namespaces

---

### ✅ Prueba 1.3: Verificar Distribución de Pods en Nodos

**Comando:**
```powershell
kubectl get pods -A -o wide | Select-String "dmz|interna"
```

**Resultado Esperado:**
- Pods de dmz corriendo en nodo proyectosd-m02
- Pods de interna corriendo en nodo proyectosd-m03

**Puntos a Validar:**
- ✅ NodeSelector funcionando (zona=dmz, zona=interna)
- ✅ Segregación física de pods
- ✅ No hay pods de interna en dmz y viceversa

**Evidencia:** Screenshot con columna NODE visible

---

## 🔒 Sección 2: NetworkPolicies (Firewall)

### 🎯 Objetivo
Demostrar que NetworkPolicies actúan como firewall bloqueando/permitiendo tráfico.

### ✅ Prueba 2.1: Verificar NetworkPolicies Aplicadas

**Comando:**
```powershell
kubectl get networkpolicies -n interna
kubectl get networkpolicies -n dmz
kubectl describe networkpolicy interna-default-deny -n interna
```

**Resultado Esperado:**
- NetworkPolicy `interna-default-deny` (bloquea todo por defecto)
- NetworkPolicy `allow-dmz-to-backend` (permite DMZ → Backend)
- NetworkPolicy `allow-backend-to-db-redis` (permite Backend → DB/Redis)

**Puntos a Validar:**
- ✅ Todas las NetworkPolicies creadas
- ✅ PolicyTypes incluye Ingress y Egress donde aplique
- ✅ Selectors correctos (matchLabels)

**Evidencia:** Screenshot de `kubectl get networkpolicies -A`

---

### ✅ Prueba 2.2: Test - Tráfico Permitido (DMZ → Backend)

**Comando:**
```powershell
# Crear pod de prueba en DMZ
kubectl run test-dmz --image=curlimages/curl --rm -i -n dmz -- `
  curl -s -o /dev/null -w "%{http_code}" http://spree-backend.interna.svc.cluster.local:3000/up
```

**Resultado Esperado:**
- Código HTTP: `200` (OK)
- Conexión exitosa desde DMZ hacia Backend

**Puntos a Validar:**
- ✅ HTTP 200 recibido
- ✅ NetworkPolicy `allow-dmz-to-backend` permite el tráfico
- ✅ DNS resolution funciona (spree-backend.interna.svc.cluster.local)

**Evidencia:** Screenshot mostrando HTTP 200

---

### ✅ Prueba 2.3: Test - Tráfico Bloqueado (Default Deny)

**Comando:**
```powershell
# Crear pod de prueba en namespace default (sin permisos)
kubectl run test-denied --image=curlimages/curl --rm -i --timeout=10s -- `
  curl --max-time 5 http://spree-backend.interna.svc.cluster.local:3000/up
```

**Resultado Esperado:**
- Timeout o "Connection timed out"
- Tráfico bloqueado por default-deny policy

**Puntos a Validar:**
- ✅ Conexión rechazada/timeout
- ✅ Default deny funciona
- ✅ Solo tráfico explícitamente permitido puede entrar

**Evidencia:** Screenshot mostrando timeout/error

---

### ✅ Prueba 2.4: Test - Backend → PostgreSQL (Permitido)

**Comando:**
```powershell
kubectl exec -n interna deployment/spree-backend -- nc -zv postgres.interna.svc.cluster.local 5432
```

**Resultado Esperado:**
- Salida: `postgres.interna.svc.cluster.local (10.x.x.x:5432) open`
- Conexión exitosa

**Puntos a Validar:**
- ✅ Backend puede conectar a PostgreSQL
- ✅ Puerto 5432 accesible
- ✅ NetworkPolicy permite tráfico

**Evidencia:** Screenshot mostrando "open" o "succeeded"

---

### ✅ Prueba 2.5: Test - Backend → Redis (Permitido)

**Comando:**
```powershell
kubectl exec -n interna deployment/spree-backend -- nc -zv redis.interna.svc.cluster.local 6379
```

**Resultado Esperado:**
- Salida: `redis.interna.svc.cluster.local (10.x.x.x:6379) open`
- Conexión exitosa

**Puntos a Validar:**
- ✅ Backend puede conectar a Redis
- ✅ Puerto 6379 accesible

**Evidencia:** Screenshot mostrando conexión exitosa

---

## 🔄 Sección 3: Alta Disponibilidad

### 🎯 Objetivo
Demostrar que el sistema tolera fallos de pods gracias a las réplicas.

### ✅ Prueba 3.1: Verificar Réplicas

**Comando:**
```powershell
kubectl get deployments -n dmz
kubectl get deployments -n interna
```

**Resultado Esperado:**
- Frontend: `3/3` réplicas READY
- Backend: `3/3` réplicas READY
- Redis: `1/1` réplicas READY

**Puntos a Validar:**
- ✅ Múltiples réplicas configuradas
- ✅ Todas las réplicas en estado READY
- ✅ AVAILABLE = DESIRED

**Evidencia:** Screenshot mostrando READY/AVAILABLE

---

### ✅ Prueba 3.2: Test de Failover - Eliminar Pod Backend

**Comando:**
```powershell
# Ver pods actuales
kubectl get pods -n interna -l app=spree-backend

# Eliminar un pod
kubectl delete pod -n interna -l app=spree-backend --field-selector=status.phase=Running | Select-Object -First 1

# Esperar 5 segundos
Start-Sleep -Seconds 5

# Verificar que se recreó
kubectl get pods -n interna -l app=spree-backend
```

**Resultado Esperado:**
- Pod eliminado se recrea automáticamente
- Siempre hay 3/3 pods READY
- Servicio sigue funcionando

**Puntos a Validar:**
- ✅ Pod eliminado no aparece en la lista
- ✅ Nuevo pod creado (AGE reciente)
- ✅ Total sigue siendo 3 pods
- ✅ App accesible durante el proceso

**Evidencia:** Screenshots antes/después mostrando recreación

---

### ✅ Prueba 3.3: Verificar Readiness/Liveness Probes

**Comando:**
```powershell
kubectl describe deployment spree-backend -n interna | Select-String -Pattern "Liveness|Readiness" -Context 2
```

**Resultado Esperado:**
- Liveness probe configurado (GET /up)
- Readiness probe configurado (GET /up)
- initialDelaySeconds, periodSeconds definidos

**Puntos a Validar:**
- ✅ Ambas probes configuradas
- ✅ HTTP GET a /up endpoint
- ✅ Configuración de delays y thresholds

**Evidencia:** Screenshot mostrando configuración de probes

---

## 💾 Sección 4: Persistencia y Replicación de Datos

### 🎯 Objetivo
Demostrar replicación de PostgreSQL y persistencia con PVCs.

### ✅ Prueba 4.1: Verificar StatefulSets PostgreSQL

**Comando:**
```powershell
kubectl get statefulsets -n interna
kubectl get pods -n interna -l app=postgres
```

**Resultado Esperado:**
- StatefulSet `postgres-master`: 1/1 READY
- StatefulSet `postgres-slave`: 2/2 READY
- Pods con nombres estables (postgres-master-0, postgres-slave-0, postgres-slave-1)

**Puntos a Validar:**
- ✅ StatefulSets funcionando
- ✅ Identidad estable de pods
- ✅ Total 3 pods PostgreSQL (1 master + 2 slaves)

**Evidencia:** Screenshot mostrando StatefulSets y pods

---

### ✅ Prueba 4.2: Verificar Persistent Volume Claims

**Comando:**
```powershell
kubectl get pvc -n interna
kubectl get pv
```

**Resultado Esperado:**
- 3 PVCs (uno por cada pod PostgreSQL)
- Todos en estado `Bound`
- Storage class: `standard`

**Puntos a Validar:**
- ✅ PVCs creados automáticamente por StatefulSet
- ✅ Cada PVC vinculado a un PV
- ✅ Status = Bound
- ✅ Capacidad configurada (ej: 5Gi)

**Evidencia:** Screenshot mostrando PVCs y PVs

---

### ✅ Prueba 4.3: Test de Replicación PostgreSQL

**Comando:**
```powershell
# Verificar replicación activa en el master
kubectl exec -it postgres-master-0 -n interna -- psql -U postgres -d spreedb -c "SELECT * FROM pg_stat_replication;"
```

**Resultado Esperado:**
- 2 conexiones de replicación (una por slave)
- Estado `streaming`
- `sync_state` puede ser `async` o `sync`

**Puntos a Validar:**
- ✅ 2 filas en pg_stat_replication
- ✅ state = streaming
- ✅ client_addr de los slaves visible

**Evidencia:** Screenshot mostrando salida de pg_stat_replication

---

### ✅ Prueba 4.4: Test de Persistencia - Reiniciar Pod

**Comando:**
```powershell
# Crear dato de prueba
kubectl exec -it postgres-master-0 -n interna -- psql -U postgres -d spreedb -c "CREATE TABLE IF NOT EXISTS test_persistence (id INT, data TEXT); INSERT INTO test_persistence VALUES (1, 'test-data');"

# Eliminar pod
kubectl delete pod postgres-master-0 -n interna

# Esperar recreación
Start-Sleep -Seconds 30

# Verificar dato persiste
kubectl exec -it postgres-master-0 -n interna -- psql -U postgres -d spreedb -c "SELECT * FROM test_persistence;"
```

**Resultado Esperado:**
- Datos persisten después del reinicio
- PVC mantiene la data intacta

**Puntos a Validar:**
- ✅ Tabla test_persistence existe después del reinicio
- ✅ Datos intactos
- ✅ PVC funciona correctamente

**Evidencia:** Screenshots antes/después del reinicio

---

## 🌐 Sección 5: Funcionalidad de la Aplicación

### 🎯 Objetivo
Verificar que la aplicación Spree funciona correctamente end-to-end.

### ✅ Prueba 5.1: Acceso al Frontend

**Comando:**
```powershell
minikube service spree-frontend -n dmz -p proyectosd
```

**Resultado Esperado:**
- Navegador abre en http://localhost:30080
- Página de Spree carga correctamente
- No hay errores 502/503

**Puntos a Validar:**
- ✅ Frontend accesible
- ✅ HTTP 200 OK
- ✅ Assets cargando (CSS, JS, imágenes)

**Evidencia:** Screenshot del storefront funcionando

---

### ✅ Prueba 5.2: Acceso al Admin Panel

**Comando:**
```powershell
Start-Process "http://localhost:30080/admin"
```

**Resultado Esperado:**
- Página de login del admin carga
- No hay errores "Blocked host"

**Puntos a Validar:**
- ✅ /admin accesible
- ✅ Form de login visible
- ✅ Backend responde

**Evidencia:** Screenshot del login admin

---

### ✅ Prueba 5.3: Test de Conectividad Frontend → Backend

**Comando:**
```powershell
kubectl logs -n dmz deployment/spree-frontend --tail=50 | Select-String "backend|upstream|proxy_pass"
```

**Resultado Esperado:**
- Logs muestran requests siendo enviados al backend
- No hay errores de conexión

**Puntos a Validar:**
- ✅ Nginx hace proxy_pass correcto
- ✅ Backend responde
- ✅ No hay timeouts

**Evidencia:** Screenshot de logs

---

### ✅ Prueba 5.4: Test de Conectividad Backend → DB

**Comando:**
```powershell
kubectl logs -n interna deployment/spree-backend --tail=50 | Select-String "database|postgres|ActiveRecord"
```

**Resultado Esperado:**
- Backend conectado a PostgreSQL
- Queries ejecutándose correctamente
- No hay errores de conexión

**Puntos a Validar:**
- ✅ ActiveRecord connected
- ✅ No hay "connection refused"
- ✅ Queries exitosos

**Evidencia:** Screenshot de logs

---

## 📈 Sección 6: Monitoreo y Observabilidad

### ✅ Prueba 6.1: Health Checks

**Comando:**
```powershell
kubectl exec -n dmz deployment/spree-frontend -- curl -s http://spree-backend.interna.svc.cluster.local:3000/up
```

**Resultado Esperado:**
- Respuesta: "OK" o status 200
- Health endpoint funcionando

**Puntos a Validar:**
- ✅ /up endpoint responde
- ✅ Backend healthy
- ✅ Probes funcionando

**Evidencia:** Screenshot mostrando respuesta

---

### ✅ Prueba 6.2: DNS Resolution

**Comando:**
```powershell
kubectl exec -n interna deployment/spree-backend -- nslookup postgres.interna.svc.cluster.local
kubectl exec -n interna deployment/spree-backend -- nslookup redis.interna.svc.cluster.local
kubectl exec -n dmz deployment/spree-frontend -- nslookup spree-backend.interna.svc.cluster.local
```

**Resultado Esperado:**
- Todos los servicios resuelven correctamente
- IPs ClusterIP visibles

**Puntos a Validar:**
- ✅ DNS funciona
- ✅ Service discovery operativo
- ✅ Namespaces aislados pero alcanzables

**Evidencia:** Screenshot mostrando resolución DNS

---

## 📊 Resumen de Validación

### Checklist Final

- [ ] **Ambientación:** 3 nodos, 2 namespaces, distribución correcta
- [ ] **NetworkPolicies:** Firewall funcionando, tráfico controlado
- [ ] **Alta Disponibilidad:** Réplicas, failover automático, probes
- [ ] **Persistencia:** PVCs, StatefulSets, replicación PostgreSQL
- [ ] **Funcionalidad:** App accesible, frontend/backend/DB conectados
- [ ] **Monitoreo:** Health checks, DNS, logs limpios

---

## 🎯 Criterios de Éxito

| Componente | Criterio | Estado |
|------------|----------|--------|
| Cluster | 3 nodos Ready | ⬜ |
| Namespaces | dmz + interna segregados | ⬜ |
| NetworkPolicies | Firewall activo, tráfico controlado | ⬜ |
| Alta Disponibilidad | Múltiples réplicas, failover funciona | ⬜ |
| PostgreSQL | Master + 2 slaves replicando | ⬜ |
| PVCs | Data persiste tras reinicio | ⬜ |
| Frontend | Accesible en puerto 30080 | ⬜ |
| Backend | Conectado a DB y Redis | ⬜ |
| Logs | Sin errores críticos | ⬜ |

---

## 📝 Notas Importantes

1. **Ejecutar pruebas en orden** - Algunas dependen de recursos creados previamente
2. **Capturar evidencias** - Screenshots de cada prueba exitosa
3. **Logs limpios** - Verificar que no haya errores antes de la demo
4. **Tiempos** - Algunas pruebas requieren esperar (recreación de pods, replicación)
5. **Cleanup** - Limpiar pods de prueba después (`kubectl delete pod test-xxx`)

---

¿Quieres que ejecutemos alguna prueba específica ahora? 😊
