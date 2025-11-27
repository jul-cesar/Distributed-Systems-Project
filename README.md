# 🚀 Proyecto Sistemas Distribuidos - Spree Commerce en K8s

Plataforma e-commerce completa desplegada en Kubernetes multinodo con arquitectura distribuida y segmentación de red.

---

## ⚡ ¿PRIMERA VEZ? → Lee: **[LEEME-PRIMERO.md](./LEEME-PRIMERO.md)**

**Si tú y tus compañeros van a estudiar este proyecto desde cero**, ese documento es tu punto de partida. Todo lo demás está enlazado desde ahí.

---

## 🎯 ¿Primera vez? ¡Empieza aquí!

Si tú y tus compañeros van a estudiar este proyecto desde cero, sigan este orden:

### 📘 Para Setup Rápido

1. **📚 [INICIO-RAPIDO.md](./INICIO-RAPIDO.md)** ← **EMPIEZA AQUÍ**
   - Guía paso a paso para levantar todo el proyecto
   - Setup completo en ~30 minutos
   - Comandos detallados y verificación

2. **🤖 Script automático**: `.\setup-completo.ps1`
   - Automatiza TODOS los pasos del setup
   - Perfecto si quieres ir directo al grano
   - Ejecutar: `.\setup-completo.ps1`

3. **✅ [VERIFICACION.md](./VERIFICACION.md)**
   - Checklist para verificar que todo funcione
   - Comandos de diagnóstico
   - Troubleshooting común

### 📖 Para Entender el Proyecto

4. **📖 [GUIA-ESTUDIO.md](./GUIA-ESTUDIO.md)** ← **Leer después del setup**
   - Explicación de conceptos teóricos
   - Por qué funciona cada cosa
   - Ejercicios prácticos
   - Preguntas y respuestas

5. **👥 [GUIA-GRUPO.md](./GUIA-GRUPO.md)** ← **Si estudian en equipo**
   - Plan de estudio para grupos
   - División de responsabilidades
   - Experimentos sugeridos
   - Preparación de demo

### 📋 Para Evaluación

6. **📋 [EVALUACION-FINAL.md](./EVALUACION-FINAL.md)**
   - Rúbrica y puntaje del proyecto
   - Comandos de demostración
   - Evidencias necesarias
   - Capturas recomendadas

---

## 📋 Descripción del Proyecto

Sistema distribuido que implementa:
- ✅ **Kubernetes multinodo** (3 nodos)
- ✅ **2 Namespaces**: `dmz` (público) e `interna` (privado)
- ✅ **Network Policies** para seguridad entre namespaces
- ✅ **Spree Commerce** como backend (Rails)
- ✅ **Nginx** como frontend/proxy reverso
- ✅ **PostgreSQL** para persistencia
- ✅ **Redis** para cache y jobs
- ✅ **Node Labels** para placement específico

## 🏗️ Arquitectura

```
Internet → NodePort (30080)
    ↓
[Namespace DMZ]
    Nginx (Frontend) → proxy_pass
         ↓
[Namespace INTERNA]
    Rails Backend (Spree)
         ↓
    PostgreSQL + Redis
```

Para diagrama completo ver: **[ARQUITECTURA.md](./ARQUITECTURA.md)**

## 🔧 Solución al Problema de Conectividad

**PROBLEMA**: Frontend abre pero no permite acceder al admin ni se ven productos.

**CAUSA**: 
1. Nginx sin headers correctos para Rails
2. Network Policy sin egress desde dmz
3. Rails bloqueando hosts no confiables
4. Sesiones no persistentes

**SOLUCIÓN APLICADA**:
- ✅ ConfigMap de Nginx actualizado con headers necesarios
- ✅ Network Policy para permitir egress desde dmz
- ✅ Variables de entorno en backend para trusted hosts
- ✅ Configuración de preservación de cookies

Ver guía completa: **[SOLUCION-TROUBLESHOOTING.md](./SOLUCION-TROUBLESHOOTING.md)**

## ⚡ Quick Start

### 1. Aplicar Correcciones
```powershell
.\aplicar-correcciones.ps1
```

Este script:
- Reconstruye la imagen Docker
- Aplica ConfigMaps actualizados
- Actualiza Network Policies
- Reinicia los pods
- Muestra el estado final

### 2. Configurar Admin y Productos ⭐ IMPORTANTE
```powershell
.\admin-setup.ps1
```

Menú interactivo para:
- Crear usuario admin
- Listar productos
- **Hacer productos visibles** (activa status: 'active') ← **NECESARIO**
- Crear productos de prueba
- Ver estadísticas de BD

> 💡 **NOTA**: Los productos creados manualmente quedan en estado "draft" y no son visibles.  
> **Debes ejecutar la opción 3** del script para activarlos.  
> Ver: **[PRODUCTOS-NO-VISIBLES-FIX.md](./PRODUCTOS-NO-VISIBLES-FIX.md)**
- Crear usuario admin
- Listar productos
- Hacer productos visibles
- Crear productos de prueba
- Ver estadísticas de BD

### 3. Diagnóstico (si hay problemas)
```powershell
.\diagnostico.ps1
```

Muestra:
- Estado de todos los recursos
- Logs recientes
- Tests de conectividad
- Resolución DNS

## 🌐 Acceso a la Aplicación

Una vez aplicadas las correcciones:

| URL | Descripción |
|-----|-------------|
| http://localhost:30080 | 🏪 Storefront |
| http://localhost:30080/admin | 👤 Panel Admin |
| http://localhost:30080/api/v2 | 🔌 API |
| http://localhost:30080/sidekiq | 📊 Monitor Jobs |

### 🔌 Acceso desde una VM (cliente externo)

Si vas a usar una máquina cliente separada (por ejemplo una VM en VirtualBox), puedes acceder al frontend de dos maneras:

- Usando la IP del host que corre el cluster (modo puente/bridged) y el NodePort publicado (30080):

  http://<IP_DEL_HOST>:30080

  Asegúrate de:
  - Que la VM tenga conectividad a la IP del host (bridged networking o reglas de NAT apropiadas).
  - Que el port-forward/NodePort esté escuchando en 0.0.0.0 (por ejemplo `kubectl port-forward --address 0.0.0.0 service/spree-frontend 30080:80 -n dmz`).
  - Que el firewall de Windows permita conexiones entrantes al puerto 30080 (si aplica).

- Alternativa (temporal): usar el túnel local que genera `kubectl port-forward` o herramientas de túnel mientras dure la demo.

### 🔁 Replicación de PostgreSQL (master + réplicas)

Se desplegó una configuración de PostgreSQL con StatefulSets: un master al que se restauró el dump original y dos réplicas de solo lectura (standby). Esto busca demostrar replicación y alta disponibilidad de la capa de datos.

Comandos útiles para verificar el estado:

```powershell
# Ver pods del cluster de Postgres
kubectl get pods -n interna -l app=postgres

# Entrar al master y revisar clientes de replicación
kubectl exec -it -n interna sts/postgres-master -- pg_isready
kubectl exec -it -n interna sts/postgres-master -- psql -U postgres -d spreedb -c "SELECT * FROM pg_stat_replication;"

# Revisar logs de una réplica (ej: postgres-slave-0)
kubectl logs -n interna statefulset/postgres-slave -f
```

Notas y estado actual:
- ✅ Se restauró el dump inicial en el master y los datos (productos, usuarios) están presentes.
- ⚠️ Las réplicas arrancaron y los pods están en estado Running. En algunas ejecuciones el master todavía no mostraba filas en `pg_stat_replication` — esto puede requerir pequeños ajustes en el init container o en la configuración de recuperación (`recovery.conf` / `standby.signal`) dependiendo de la imagen/base utilizada.

Si `pg_stat_replication` está vacío:
- Verifica que los archivos de recuperación (`standby.signal` / `recovery.conf`) se hayan creado en la réplica.
- Revisa que el `primary_conninfo` en la réplica apunte correctamente al servicio `postgres-master.interna.svc.cluster.local` y use las credenciales del usuario de replicación.
- Revisa los logs de la réplica para errores de `pg_basebackup` o de conexión.

Pequeñas acciones de reparación (ejemplos):

```powershell
# Forzar re-sincronización desde la réplica (si procede):
kubectl delete pod -n interna statefulset/postgres-slave-0 --grace-period=0 --force
# El init container debería volver a ejecutar el basebackup y crear el standby signal
```

Para entrega y demo: mostrar la restauración de datos en el master (consulta a `spree_products`) y luego, si la réplica aparece en `pg_stat_replication`, mostrar failover/read-scaling básico apuntando consultas de lectura a la service de lectura.

## 📁 Estructura del Proyecto

```
distributed-systems-project/
├── spree-app/                    # Aplicación Rails (Spree)
│   ├── app/                      # Controllers, models, views
│   ├── config/                   # Configuración Rails
│   │   └── initializers/
│   │       └── hosts.rb         # ⭐ Nuevo: Trusted hosts
│   ├── Dockerfile               # Build de la imagen
│   └── ...
│
├── Deployments K8s
│   ├── db-deploy.yaml           # PostgreSQL deployment
│   ├── db-service.yaml          # PostgreSQL service
│   ├── redis-deploy.yaml        # Redis deployment
│   ├── redis-service.yaml       # Redis service
│   ├── spree-backend-deploy.yaml   # ⭐ Backend Rails (actualizado)
│   ├── spree-backend-service.yaml  # Backend service
│   ├── frontend-deploy.yaml     # Nginx deployment
│   ├── frontend-service.yaml    # Frontend NodePort
│   ├── frontend-configmap.yaml  # ⭐ Nginx config (actualizado)
│   └── spree-migrate-job.yaml   # Job de migraciones
│
├── Network Policies
│   ├── np-interna-default-deny.yaml           # Deny all ingress
│   ├── np-allow-backend-to-db-redis.yaml      # Backend → DB/Redis
│   └── np-allow-dmz-to-backend.yaml          # ⭐ DMZ ↔ Backend (actualizado)
│
├── Scripts PowerShell
│   ├── aplicar-correcciones.ps1   # ⭐ Script principal
│   ├── admin-setup.ps1            # ⭐ Setup admin/productos
│   └── diagnostico.ps1            # ⭐ Diagnóstico completo
│
└── Documentación
    ├── README.md                   # Este archivo
    ├── SOLUCION-TROUBLESHOOTING.md # ⭐ Guía de solución
    └── ARQUITECTURA.md             # ⭐ Documentación técnica
```

## 🔐 Credenciales por Defecto

### Base de Datos
- **Host**: `postgres.interna.svc.cluster.local:5432`
- **Database**: `spreedb`
- **Usuario**: `spreeuser`
- **Password**: `spreepass`

### Admin de Spree (crear con admin-setup.ps1)
- **Email**: `admin@example.com`
- **Password**: `password123`

⚠️ **IMPORTANTE**: Cambiar en producción real.

## 📊 Comandos Útiles

### Ver estado general
```powershell
kubectl get all -n dmz
kubectl get all -n interna
```

### Ver logs
```powershell
# Frontend
kubectl logs -n dmz -l app=spree-frontend --tail=50 -f

# Backend
kubectl logs -n interna -l app=spree-backend --tail=50 -f
```

### Consola Rails
```powershell
kubectl exec -it -n interna deployment/spree-backend -- bin/rails console
```

### Reiniciar servicios
```powershell
kubectl rollout restart deployment spree-backend -n interna
kubectl rollout restart deployment spree-frontend -n dmz
```

### Verificar Network Policies
```powershell
kubectl get networkpolicies -n interna
kubectl describe networkpolicy allow-dmz-to-backend -n interna
```

## 🧪 Testing de Conectividad

### Test DMZ → Backend
```powershell
kubectl run test --image=curlimages/curl --rm -i -n dmz -- `
  curl -v http://spree-backend.interna.svc.cluster.local:3000/up
```

### Test Backend → PostgreSQL
```powershell
kubectl exec -n interna deployment/spree-backend -- `
  nc -zv postgres.interna.svc.cluster.local 5432
```

### Test Backend → Redis
```powershell
kubectl exec -n interna deployment/spree-backend -- `
  nc -zv redis.interna.svc.cluster.local 6379
```

## 🎯 Conceptos Clave Implementados

### Sistemas Distribuidos
- [x] Arquitectura multinodo
- [x] Separación de concerns (frontend/backend)
- [x] Service discovery (DNS de K8s)
- [x] Load balancing (Service ClusterIP)
- [x] Health checks (readiness/liveness probes)
- [x] Fault tolerance (múltiples réplicas)

### Seguridad
- [x] Network segmentation (namespaces)
- [x] Network policies (firewall de pods)
- [x] Secrets management
- [x] Trusted hosts validation
- [x] Zero-trust networking

### DevOps
- [x] Infrastructure as Code (YAML)
- [x] Configuration management (ConfigMaps)
- [x] Container orchestration (K8s)
- [x] Service mesh básico (proxy reverso)

## 🚨 Troubleshooting

### Problema: 502 Bad Gateway
**Solución**: Verificar que backend esté corriendo
```powershell
kubectl get pods -n interna
kubectl logs -n interna -l app=spree-backend --tail=50
```

### Problema: "Blocked host" en logs
**Solución**: Reconstruir imagen con nuevo `hosts.rb`
```powershell
cd spree-app
docker build -t spree-custom:latest .
kubectl rollout restart deployment spree-backend -n interna
```

### Problema: Sesiones no persisten
**Solución**: Aplicar nuevo ConfigMap de Nginx
```powershell
kubectl apply -f frontend-configmap.yaml
kubectl rollout restart deployment spree-frontend -n dmz
```

### ⚠️ Problema: No se ven productos (MUY COMÚN)
**Causa**: Los productos están en estado "draft" en lugar de "active"

**Solución Rápida**:
```powershell
.\admin-setup.ps1
# Seleccionar opción 3: "Hacer productos visibles (available)"
```

**Ver guía completa**: **[PRODUCTOS-NO-VISIBLES-FIX.md](./PRODUCTOS-NO-VISIBLES-FIX.md)**

### Para más detalles
📖 Ver: **[SOLUCION-TROUBLESHOOTING.md](./SOLUCION-TROUBLESHOOTING.md)**

## 📚 Recursos Adicionales

- **Spree Guides**: https://docs.spreecommerce.org/
- **Kubernetes Docs**: https://kubernetes.io/docs/
- **Network Policies**: https://kubernetes.io/docs/concepts/services-networking/network-policies/
- **Rails Production**: https://guides.rubyonrails.org/configuring.html

## 👨‍💻 Desarrollo

### Reconstruir imagen
```powershell
cd spree-app
docker build -t spree-custom:latest .
```

### Aplicar cambios en K8s
```powershell
kubectl apply -f <archivo>.yaml
```

### Hot-reload de ConfigMaps
```powershell
# Editar ConfigMap
kubectl edit configmap spree-frontend-config -n dmz

# Reiniciar para aplicar
kubectl rollout restart deployment spree-frontend -n dmz
```

## 🎓 Entrega del Proyecto

### Checklist para Entrega
- [ ] Cluster K8s multinodo funcionando
- [ ] 2 namespaces (dmz, interna) con labels
- [ ] Network Policies aplicadas y documentadas
- [ ] Backend accesible desde frontend
- [ ] Admin panel funcional
- [ ] Productos visibles en storefront
- [ ] Logs sin errores críticos
- [ ] Documentación completa (este README + ARQUITECTURA.md)
- [ ] Scripts de automatización funcionando
- [ ] Diagrama de arquitectura incluido

### Evidencias a Mostrar
1. **Arquitectura**: Diagrama y explicación de componentes
2. **Namespaces**: `kubectl get namespaces` con labels
3. **Network Policies**: `kubectl get networkpolicies -A`
4. **Pods distribuidos**: `kubectl get pods -A -o wide` mostrando nodos
5. **Acceso funcional**: Screenshots de storefront y admin
6. **Logs limpios**: Sin errores de conectividad
7. **Comandos de verificación**: Mostrar tests de conectividad

### Puntos Destacables
- ✅ Implementación de DMZ real con segmentación de red
- ✅ Network Policies de tipo ingress Y egress
- ✅ Arquitectura de 3 capas (frontend, backend, data)
- ✅ Node affinity con labels personalizados
- ✅ Configuración de producción de Rails
- ✅ Health checks configurados correctamente
- ✅ Automatización con scripts PowerShell

## 📝 Notas Finales

Este proyecto demuestra:
1. **Arquitectura distribuida** real con separación de concerns
2. **Seguridad de red** con políticas estrictas
3. **Alta disponibilidad** con múltiples réplicas
4. **Buenas prácticas** de K8s (ConfigMaps, Secrets, Probes)
5. **Documentación completa** y scripts de automatización

¡Ideal para curso de Sistemas Distribuidos! 🎯

---

## 🆘 Soporte

Si encuentras problemas:
1. Ejecuta `.\diagnostico.ps1` para recopilar información
2. Revisa logs con los comandos de arriba
3. Consulta [SOLUCION-TROUBLESHOOTING.md](./SOLUCION-TROUBLESHOOTING.md)
4. Verifica Network Policies con `kubectl describe`

---

**Desarrollado para**: Curso de Sistemas Distribuidos  
**Tecnologías**: Kubernetes, Spree Commerce, Rails, PostgreSQL, Redis, Nginx  
**Fecha**: 2024

🚀 **¡Buena suerte con tu entrega!**
