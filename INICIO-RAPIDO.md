# 🚀 Guía de Inicio Rápido - Proyecto Sistemas Distribuidos

**Para estudiantes que comienzan desde cero** 📚

Esta guía te llevará paso a paso desde cero hasta tener el proyecto funcionando completamente.

---

## 📖 Índice

1. [¿Qué es este proyecto?](#qué-es-este-proyecto)
2. [Requisitos previos](#requisitos-previos)
3. [Paso 1: Levantar el cluster](#paso-1-levantar-el-cluster)
4. [Paso 2: Desplegar la aplicación](#paso-2-desplegar-la-aplicación)
5. [Paso 3: Verificar que todo funciona](#paso-3-verificar-que-todo-funciona)
6. [Paso 4: Acceder a la aplicación](#paso-4-acceder-a-la-aplicación)
7. [Paso 5: Explorar y entender](#paso-5-explorar-y-entender)
8. [Problemas comunes](#problemas-comunes)
9. [Siguiente paso: Estudiar arquitectura](#siguiente-paso)

---

## 🤔 ¿Qué es este proyecto?

Este es un **sistema distribuido completo** que implementa una tienda e-commerce (Spree Commerce) corriendo en **Kubernetes con 3 nodos**.

### ¿Qué vas a aprender?

- ✅ Kubernetes multinodo
- ✅ Segmentación de red (DMZ + zona interna)
- ✅ Network Policies (firewall entre pods)
- ✅ Alta disponibilidad (múltiples réplicas)
- ✅ Replicación de base de datos
- ✅ Procesamiento asíncrono (Sidekiq + Redis)
- ✅ Arquitectura de microservicios

### Componentes principales

```
┌─────────────────────────────────────┐
│     NAMESPACE: dmz (público)        │
│                                     │
│   Frontend (Nginx) - 3 réplicas    │
│          ↓                          │
└──────────┼──────────────────────────┘
           │ Network Policy
┌──────────┼──────────────────────────┐
│     NAMESPACE: interna (privado)    │
│          ↓                          │
│   Backend (Rails) - 3 réplicas      │
│          ↓                          │
│   PostgreSQL (master + réplicas)    │
│   Redis                             │
└─────────────────────────────────────┘
```

---

## 💻 Requisitos Previos

### Software necesario

1. **Minikube** (o cualquier cluster K8s)

   ```powershell
   # Verificar instalación
   minikube version
   ```

2. **kubectl**

   ```powershell
   # Verificar instalación
   kubectl version --client
   ```

3. **Docker Desktop** (para Minikube)

   ```powershell
   # Verificar
   docker version
   ```

### Recursos recomendados

- **CPU**: 4+ cores
- **RAM**: 8+ GB
- **Disco**: 20+ GB libres

---

## 🚀 Paso 1: Levantar el Cluster

### 1.1 Iniciar Minikube con 3 nodos

```powershell
# Iniciar el cluster (esto puede tardar unos minutos)
minikube start -p proyectosd --nodes 3 --cpus 2 --memory 4096

# Verificar que los nodos estén corriendo
kubectl get nodes
```

**Resultado esperado:**

```
NAME               STATUS   ROLES           AGE
proyectosd         Ready    control-plane   1m
proyectosd-m02     Ready    <none>          1m
proyectosd-m03     Ready    <none>          1m
```

### 1.2 Etiquetar los nodos

Los nodos necesitan etiquetas para saber dónde desplegar cada componente:

```powershell
# Etiquetar nodo 1 (control plane) - no usaremos para apps
# Etiquetar nodo 2 como DMZ (frontend)
kubectl label node proyectosd-m02 zona=dmz

# Etiquetar nodo 3 como interna (backend + DB)
kubectl label node proyectosd-m03 zona=interna

# Verificar etiquetas
kubectl get nodes --show-labels
```

### 1.3 Crear los namespaces

```powershell
# Crear namespace DMZ (zona pública)
kubectl create namespace dmz

# Crear namespace interna (zona privada)
kubectl create namespace interna

# Verificar
kubectl get namespaces
```

---

## 📦 Paso 2: Desplegar la Aplicación

### 2.1 Construir la imagen de la aplicación

```powershell
# Navegar a la carpeta de la app
cd spree-app

# Configurar Docker para usar el daemon de Minikube
& minikube -p proyectosd docker-env --shell powershell | Invoke-Expression

# Construir la imagen
docker build -t spree-custom:latest .

# Volver al directorio raíz
cd ..
```

> ⏱️ **Nota**: Este paso puede tardar 5-10 minutos la primera vez.

### 2.2 Desplegar PostgreSQL (master + réplicas)

```powershell
# Aplicar configuración y secretos
kubectl apply -f postgres-config.yaml
kubectl apply -f postgres-replication-secret.yaml

# Desplegar el master
kubectl apply -f postgres-master-statefulset.yaml

# Esperar a que el master esté listo
kubectl wait --for=condition=ready pod/postgres-master-0 -n interna --timeout=300s

# Desplegar las réplicas
kubectl apply -f postgres-slave-statefulset.yaml

# Desplegar los servicios
kubectl apply -f postgres-services.yaml

# Desplegar network policies
kubectl apply -f postgres-replication-netpol.yaml
```

### 2.3 Inicializar la base de datos

```powershell
# Aplicar el job de migraciones
kubectl apply -f spree-migrate-job.yaml

# Ver el progreso del job
kubectl logs -n interna job/spree-migrate -f

# Esperar a que complete
kubectl wait --for=condition=complete job/spree-migrate -n interna --timeout=300s
```

### 2.4 Desplegar Redis

```powershell
kubectl apply -f redis-deploy.yaml
kubectl apply -f redis-service.yaml

# Verificar que esté corriendo
kubectl get pods -n interna -l app=redis
```

### 2.5 Desplegar el Backend (Rails/Spree)

```powershell
kubectl apply -f spree-backend-deploy.yaml
kubectl apply -f spree-backend-service.yaml

# Esperar a que estén listos
kubectl wait --for=condition=ready pod -l app=spree-backend -n interna --timeout=300s
```

### 2.6 Desplegar el Frontend (Nginx)

```powershell
kubectl apply -f frontend-configmap.yaml
kubectl apply -f frontend-deploy.yaml
kubectl apply -f frontend-service.yaml

# Esperar a que estén listos
kubectl wait --for=condition=ready pod -l app=spree-frontend -n dmz --timeout=300s
```

### 2.7 Aplicar Network Policies (Seguridad)

```powershell
# Aplicar políticas de red
kubectl apply -f np-interna-default-deny.yaml
kubectl apply -f np-allow-backend-to-db-redis.yaml
kubectl apply -f np-allow-dmz-to-backend.yaml

# Verificar
kubectl get networkpolicies -A
```

---

## ✅ Paso 3: Verificar que Todo Funciona

### 3.1 Ver todos los pods

```powershell
# Pods en namespace DMZ
kubectl get pods -n dmz -o wide

# Pods en namespace interna
kubectl get pods -n interna -o wide
```

**Resultado esperado:**

```
NAMESPACE   NAME                              READY   STATUS
dmz         spree-frontend-xxx                1/1     Running
dmz         spree-frontend-xxx                1/1     Running
dmz         spree-frontend-xxx                1/1     Running
interna     spree-backend-xxx                 1/1     Running
interna     spree-backend-xxx                 1/1     Running
interna     spree-backend-xxx                 1/1     Running
interna     postgres-master-0                 1/1     Running
interna     postgres-slave-0                  1/1     Running
interna     postgres-slave-1                  1/1     Running
interna     redis-xxx                         1/1     Running
```

### 3.2 Verificar servicios

```powershell
kubectl get svc -A
```

### 3.3 Probar conectividad

#### Test 1: DMZ → Backend

```powershell
kubectl run test --image=curlimages/curl --rm -i -n dmz -- `
  curl -s http://spree-backend.interna.svc.cluster.local:3000/up
```

**Resultado esperado:** `200 OK` o mensaje de health check

#### Test 2: Backend → PostgreSQL

```powershell
kubectl exec -n interna deployment/spree-backend -- `
  nc -zv postgres-master.interna.svc.cluster.local 5432
```

**Resultado esperado:** `Connection succeeded`

#### Test 3: Backend → Redis

```powershell
kubectl exec -n interna deployment/spree-backend -- `
  nc -zv redis.interna.svc.cluster.local 6379
```

**Resultado esperado:** `Connection succeeded`

---

## 🌐 Paso 4: Acceder a la Aplicación

### 4.1 Exponer el servicio

```powershell
# Opción 1: Port-forward (más fácil)
kubectl port-forward --address 0.0.0.0 service/spree-frontend 30080:80 -n dmz
```

> 💡 **Deja esta ventana abierta** - el port-forward se mantiene corriendo

### 4.2 Abrir en el navegador

Abre tu navegador y visita:

- **🏪 Tienda**: <http://localhost:30080>
- **👤 Admin**: <http://localhost:30080/admin>
- **📊 Sidekiq**: <http://localhost:30080/sidekiq>

### 4.3 Crear usuario admin

En una **nueva ventana de PowerShell**:

```powershell
# Entrar al backend
kubectl exec -it -n interna deployment/spree-backend -- bin/rails console

# En la consola de Rails, ejecutar:
user = Spree::User.create!(
  email: 'admin@example.com',
  password: 'admin123456',
  password_confirmation: 'admin123456'
)
role = Spree::Role.find_or_create_by(name: 'admin')
user.spree_roles << role
user.save!
puts "Admin creado: #{user.email}"
exit
```

### 4.4 Login en el admin

1. Ve a: <http://localhost:30080/admin>
2. Email: `admin@example.com`
3. Password: `admin123456`

---

## 🔍 Paso 5: Explorar y Entender

### 5.1 Ver logs en tiempo real

```powershell
# Logs del frontend
kubectl logs -n dmz -l app=spree-frontend --tail=50 -f

# Logs del backend
kubectl logs -n interna -l app=spree-backend --tail=50 -f

# Logs de PostgreSQL master
kubectl logs -n interna postgres-master-0 -f
```

> **Tip**: Presiona `Ctrl+C` para salir de los logs

### 5.2 Explorar la base de datos

```powershell
# Entrar al master de PostgreSQL
kubectl exec -it -n interna postgres-master-0 -- psql -U postgres -d spreedb

# Dentro de psql, puedes ejecutar:
\dt                          # Ver tablas
SELECT * FROM spree_users;   # Ver usuarios
SELECT * FROM spree_products LIMIT 5;  # Ver productos
\q                           # Salir
```

### 5.3 Verificar replicación de PostgreSQL

```powershell
# Ver clientes de replicación conectados al master
kubectl exec -it -n interna postgres-master-0 -- psql -U postgres -d spreedb -c "SELECT client_addr, state, sync_state FROM pg_stat_replication;"
```

### 5.4 Verificar Sidekiq (procesamiento asíncrono)

```powershell
kubectl exec -n interna deployment/spree-backend -- `
  bin/rails runner "puts 'Sidekiq: ' + (defined?(Sidekiq) ? 'OK' : 'NO'); puts 'Redis: ' + Sidekiq.redis { |r| r.ping }"
```

**Resultado esperado:**

```
Sidekiq: OK
Redis: PONG
```

---

## 🆘 Problemas Comunes

### ❌ Pods en estado `ImagePullBackOff`

**Problema**: No encuentra la imagen `spree-custom:latest`

**Solución**:

```powershell
# Asegúrate de construir la imagen dentro del contexto de Minikube
& minikube -p proyectosd docker-env --shell powershell | Invoke-Expression
cd spree-app
docker build -t spree-custom:latest .
cd ..

# Reiniciar los pods
kubectl rollout restart deployment spree-backend -n interna
kubectl rollout restart deployment spree-frontend -n dmz
```

### ❌ "No se ven productos en la tienda"

**Problema**: Los productos están en estado "draft"

**Solución**:

```powershell
# Activar todos los productos
kubectl exec -it -n interna deployment/spree-backend -- `
  bin/rails runner "Spree::Product.update_all(status: 'active', available_on: Time.current); puts 'Productos activados: ' + Spree::Product.active.count.to_s"
```

### ❌ Error 502 Bad Gateway

**Problema**: El backend no está listo o hay problemas de red

**Solución**:

```powershell
# Ver estado de los pods
kubectl get pods -n interna -l app=spree-backend

# Ver logs para identificar el problema
kubectl logs -n interna -l app=spree-backend --tail=100

# Si los pods están crasheando, reiniciarlos
kubectl rollout restart deployment spree-backend -n interna
```

### ❌ Network Policy bloquea conexión

**Problema**: DMZ no puede conectar con backend

**Solución**:

```powershell
# Verificar que las políticas estén aplicadas
kubectl get networkpolicies -A

# Si falta alguna, aplicarla de nuevo
kubectl apply -f np-allow-dmz-to-backend.yaml
```

### ❌ Minikube se queda sin recursos

**Problema**: Pods en estado `Pending` o `CrashLoopBackOff`

**Solución**:

```powershell
# Detener Minikube
minikube stop -p proyectosd

# Eliminar y recrear con más recursos
minikube delete -p proyectosd
minikube start -p proyectosd --nodes 3 --cpus 4 --memory 8192
```

---

## 🎓 Siguiente Paso: Estudiar la Arquitectura

Una vez que tengas todo corriendo, es hora de **entender QUÉ está pasando y POR QUÉ**:

### Documentos para estudiar (en orden)

1. **`README.md`** - Descripción general del proyecto
2. **`GUIA-ESTUDIO.md`** - Conceptos teóricos explicados ⭐ NUEVO
3. **`EVALUACION-FINAL.md`** - Rúbrica y evidencias

### Preguntas para reflexionar

1. ¿Por qué separamos frontend y backend en namespaces distintos?
2. ¿Qué pasa si elimino una Network Policy?
3. ¿Cómo funciona el load balancing entre las 3 réplicas del frontend?
4. ¿Para qué sirve la replicación de PostgreSQL?
5. ¿Qué tipo de jobs procesa Sidekiq?

### Experimentos sugeridos

```powershell
# Experimento 1: Eliminar un pod y ver cómo Kubernetes lo recrea
kubectl delete pod -n dmz -l app=spree-frontend --force --grace-period=0
kubectl get pods -n dmz -w

# Experimento 2: Escalar réplicas
kubectl scale deployment spree-backend -n interna --replicas=5
kubectl get pods -n interna -w

# Experimento 3: Ver el efecto de una Network Policy
kubectl delete networkpolicy allow-dmz-to-backend -n interna
# Intenta acceder a la app - ¿qué pasa?
# Restaurar:
kubectl apply -f np-allow-dmz-to-backend.yaml
```

---

## 📚 Recursos Adicionales

- **Kubernetes Docs**: <https://kubernetes.io/docs/>
- **Spree Guides**: <https://docs.spreecommerce.org/>
- **Network Policies**: <https://kubernetes.io/docs/concepts/services-networking/network-policies/>
- **StatefulSets**: <https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/>

---

## ✅ Checklist de Progreso

Marca lo que ya has logrado:

- [ ] Cluster Minikube levantado con 3 nodos
- [ ] Nodos etiquetados (dmz, interna)
- [ ] Namespaces creados
- [ ] Imagen Docker construida
- [ ] PostgreSQL desplegado (master + réplicas)
- [ ] Redis desplegado
- [ ] Backend desplegado (3 réplicas)
- [ ] Frontend desplegado (3 réplicas)
- [ ] Network Policies aplicadas
- [ ] Puedo acceder a <http://localhost:30080>
- [ ] Admin creado y puedo hacer login
- [ ] Entiendo la arquitectura general
- [ ] He leído GUIA-ESTUDIO.md
- [ ] He probado los comandos de verificación
- [ ] He revisado EVALUACION-FINAL.md

---

## 💡 Consejos Finales

1. **No te apures** - Tómate tiempo para entender cada paso
2. **Lee los logs** - Son tu mejor amigo para debuggear
3. **Experimenta** - Rompe cosas y repáralas, así se aprende
4. **Documenta** - Anota qué comandos funcionan y cuáles no
5. **Pregunta** - Si algo no tiene sentido, investiga o pregunta

---

**¡Buena suerte con tu estudio!** 🚀

Si tienes dudas, revisa `GUIA-ESTUDIO.md` para explicaciones teóricas más detalladas.
