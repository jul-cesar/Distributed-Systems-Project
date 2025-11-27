# ✅ Checklist de Verificación Rápida

**Para verificar que todo esté funcionando correctamente**

---

## 🔍 Verificación Paso a Paso

### 1. Cluster y Nodos

```powershell
# Ver nodos del cluster
kubectl get nodes -o wide
```

✅ **Resultado esperado**: 3 nodos en estado `Ready`
```
NAME               STATUS   ROLES
proyectosd         Ready    control-plane
proyectosd-m02     Ready    <none>
proyectosd-m03     Ready    <none>
```

---

### 2. Namespaces

```powershell
kubectl get namespaces
```

✅ **Resultado esperado**: Ver `dmz` e `interna`

---

### 3. Pods en ejecución

```powershell
# Todos los pods
kubectl get pods -A -o wide

# Solo DMZ
kubectl get pods -n dmz

# Solo interna
kubectl get pods -n interna
```

✅ **Resultado esperado**:

**DMZ**:
- `spree-frontend-xxx` → 3 pods en `Running`

**Interna**:
- `spree-backend-xxx` → 3 pods en `Running`
- `postgres-master-0` → 1 pod en `Running`
- `postgres-slave-0` → 1 pod en `Running`
- `postgres-slave-1` → 1 pod en `Running`
- `redis-xxx` → 1 pod en `Running`

---

### 4. Servicios

```powershell
kubectl get svc -A
```

✅ **Resultado esperado**: Ver servicios de frontend, backend, postgres, redis

---

### 5. Network Policies

```powershell
kubectl get networkpolicies -A
```

✅ **Resultado esperado**: Ver al menos 3-4 políticas

---

### 6. Conectividad: DMZ → Backend

```powershell
kubectl run test --image=curlimages/curl --rm -i -n dmz -- `
  curl -s http://spree-backend.interna.svc.cluster.local:3000/up
```

✅ **Resultado esperado**: Status 200 o mensaje de health check

---

### 7. Conectividad: Backend → PostgreSQL

```powershell
kubectl exec -n interna deployment/spree-backend -- `
  nc -zv postgres-master.interna.svc.cluster.local 5432
```

✅ **Resultado esperado**: `Connection succeeded`

---

### 8. Conectividad: Backend → Redis

```powershell
kubectl exec -n interna deployment/spree-backend -- `
  nc -zv redis.interna.svc.cluster.local 6379
```

✅ **Resultado esperado**: `Connection succeeded`

---

### 9. Sidekiq y Redis

```powershell
kubectl exec -n interna deployment/spree-backend -- `
  bin/rails runner "puts 'Sidekiq: ' + (defined?(Sidekiq) ? 'OK' : 'NO'); puts 'Redis: ' + Sidekiq.redis { |r| r.ping }"
```

✅ **Resultado esperado**:
```
Sidekiq: OK
Redis: PONG
```

---

### 10. Replicación de PostgreSQL

```powershell
kubectl exec -it -n interna postgres-master-0 -- `
  psql -U postgres -d spreedb -c "SELECT client_addr, state, sync_state FROM pg_stat_replication;"
```

✅ **Resultado esperado**: Ver 2 filas (las 2 réplicas conectadas)

Si está vacío, revisar logs:
```powershell
kubectl logs -n interna postgres-slave-0 --tail=50
```

---

### 11. Base de datos con datos

```powershell
kubectl exec -it -n interna postgres-master-0 -- `
  psql -U postgres -d spreedb -c "SELECT COUNT(*) FROM spree_products;"
```

✅ **Resultado esperado**: Número > 0 (hay productos)

---

### 12. Usuario admin existe

```powershell
kubectl exec -n interna deployment/spree-backend -- `
  bin/rails runner "puts Spree::User.find_by(email: 'admin@example.com') ? 'Admin existe' : 'Admin NO existe'"
```

✅ **Resultado esperado**: `Admin existe`

Si no existe, crearlo:
```powershell
kubectl exec -it -n interna deployment/spree-backend -- bin/rails console
# En la consola:
user = Spree::User.create!(email: 'admin@example.com', password: 'admin123456', password_confirmation: 'admin123456')
role = Spree::Role.find_or_create_by(name: 'admin')
user.spree_roles << role
user.save!
exit
```

---

### 13. Productos activados

```powershell
kubectl exec -n interna deployment/spree-backend -- `
  bin/rails runner "puts 'Activos: ' + Spree::Product.active.count.to_s + ' / Total: ' + Spree::Product.count.to_s"
```

✅ **Resultado esperado**: `Activos: X / Total: X` (ambos números iguales)

Si no están activos:
```powershell
kubectl exec -n interna deployment/spree-backend -- `
  bin/rails runner "Spree::Product.update_all(status: 'active', available_on: Time.current)"
```

---

### 14. Acceso web

```powershell
# En una terminal separada:
kubectl port-forward --address 0.0.0.0 service/spree-frontend 30080:80 -n dmz
```

Luego abre en el navegador:
- http://localhost:30080 → ✅ Debe cargar la tienda
- http://localhost:30080/admin → ✅ Debe mostrar login
- http://localhost:30080/sidekiq → ✅ Debe mostrar dashboard de Sidekiq

---

### 15. Login en admin

1. Ve a: http://localhost:30080/admin
2. Email: `admin@example.com`
3. Password: `admin123456`

✅ **Resultado esperado**: Acceso al panel de administración

---

## 🚨 Problemas Comunes

### ❌ Pods en `ImagePullBackOff`

**Causa**: No se encuentra la imagen `spree-custom:latest`

**Solución**:
```powershell
& minikube -p proyectosd docker-env --shell powershell | Invoke-Expression
cd spree-app
docker build -t spree-custom:latest .
cd ..
kubectl rollout restart deployment spree-backend -n interna
kubectl rollout restart deployment spree-frontend -n dmz
```

---

### ❌ Pods en `CrashLoopBackOff`

**Causa**: Error en la aplicación

**Solución**: Ver logs
```powershell
kubectl logs -n interna -l app=spree-backend --tail=100
```

Buscar errores de:
- Conexión a BD
- Variables de entorno faltantes
- Configuración incorrecta

---

### ❌ "No se ven productos"

**Causa**: Productos en estado `draft`

**Solución**:
```powershell
kubectl exec -n interna deployment/spree-backend -- `
  bin/rails runner "Spree::Product.update_all(status: 'active', available_on: Time.current)"
```

---

### ❌ Error 502 Bad Gateway

**Causa**: Backend no responde

**Solución**:
```powershell
# Verificar estado de backend
kubectl get pods -n interna -l app=spree-backend

# Ver logs
kubectl logs -n interna -l app=spree-backend --tail=50

# Reiniciar si es necesario
kubectl rollout restart deployment spree-backend -n interna
```

---

### ❌ pg_stat_replication vacío

**Causa**: Réplicas no conectadas al master

**Solución**:
```powershell
# Ver logs de las réplicas
kubectl logs -n interna postgres-slave-0 --tail=100
kubectl logs -n interna postgres-slave-1 --tail=100

# Reiniciar réplicas
kubectl delete pod postgres-slave-0 -n interna
kubectl delete pod postgres-slave-1 -n interna
```

---

## 📊 Script de Verificación Completa

```powershell
Write-Host "=== VERIFICACIÓN COMPLETA ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Nodos:" -ForegroundColor Yellow
kubectl get nodes
Write-Host ""

Write-Host "2. Pods en DMZ:" -ForegroundColor Yellow
kubectl get pods -n dmz
Write-Host ""

Write-Host "3. Pods en interna:" -ForegroundColor Yellow
kubectl get pods -n interna
Write-Host ""

Write-Host "4. Servicios:" -ForegroundColor Yellow
kubectl get svc -A
Write-Host ""

Write-Host "5. Network Policies:" -ForegroundColor Yellow
kubectl get networkpolicies -A
Write-Host ""

Write-Host "6. Test conectividad DMZ->Backend:" -ForegroundColor Yellow
kubectl run test --image=curlimages/curl --rm -i -n dmz -- curl -s http://spree-backend.interna.svc.cluster.local:3000/up
Write-Host ""

Write-Host "7. Sidekiq y Redis:" -ForegroundColor Yellow
kubectl exec -n interna deployment/spree-backend -- bin/rails runner "puts 'Sidekiq: ' + (defined?(Sidekiq) ? 'OK' : 'NO'); puts 'Redis: ' + Sidekiq.redis { |r| r.ping }"
Write-Host ""

Write-Host "8. Replicación PostgreSQL:" -ForegroundColor Yellow
kubectl exec -it -n interna postgres-master-0 -- psql -U postgres -d spreedb -c "SELECT client_addr, state, sync_state FROM pg_stat_replication;"
Write-Host ""

Write-Host "=== VERIFICACIÓN COMPLETADA ===" -ForegroundColor Green
```

---

## ✅ Checklist Final

Marca cuando cada ítem esté funcionando:

- [ ] 3 nodos en estado `Ready`
- [ ] Namespaces `dmz` e `interna` creados
- [ ] 3 pods de frontend en `Running`
- [ ] 3 pods de backend en `Running`
- [ ] PostgreSQL master + 2 réplicas en `Running`
- [ ] Redis en `Running`
- [ ] Network Policies aplicadas
- [ ] DMZ puede conectar con backend
- [ ] Backend puede conectar con PostgreSQL
- [ ] Backend puede conectar con Redis
- [ ] Sidekiq y Redis funcionando (PONG)
- [ ] Replicación PostgreSQL activa (2 filas en pg_stat_replication)
- [ ] Base de datos con productos
- [ ] Usuario admin existe
- [ ] Productos están activos
- [ ] Puedo acceder a http://localhost:30080
- [ ] Puedo hacer login en /admin
- [ ] Sidekiq dashboard accesible en /sidekiq

---

**¡Si todos los ítems están marcados, el proyecto está funcionando correctamente!** ✅

Para más detalles, ver:
- `INICIO-RAPIDO.md` - Guía de setup
- `GUIA-ESTUDIO.md` - Conceptos teóricos
- `EVALUACION-FINAL.md` - Rúbrica y evidencias
