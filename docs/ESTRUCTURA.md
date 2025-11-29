# 📂 Estructura del Proyecto - Distributed Systems

## 📊 Vista General

```
distributed-systems-project/
│
├── 📁 k8s/                           # Configuraciones de Kubernetes
│   └── 📁 base/                      # Configuraciones base
│       ├── 📁 frontend/              # Componente Frontend (DMZ)
│       ├── 📁 backend/               # Componente Backend (Interna)
│       ├── 📁 database/              # PostgreSQL (Interna)
│       ├── 📁 cache/                 # Redis (Interna)
│       └── 📁 network/               # NetworkPolicies (Firewall)
│
├── 📁 scripts/                       # Scripts de automatización
│   ├── deploy-all.ps1               # ⭐ Desplegar todo
│   ├── cleanup.ps1                  # 🧹 Limpiar recursos
│   └── status.ps1                   # 📊 Ver estado
│
├── 📁 spree-app/                     # Código fuente Spree Commerce
│   ├── app/                         # Aplicación Rails
│   ├── config/                      # Configuración
│   ├── Dockerfile                   # Imagen Docker
│   └── ...
│
├── 📁 docs/                          # Documentación adicional
│
└── 📄 README.md                      # Documentación principal
```

---

## 🎯 Detalle por Componente

### 📦 Frontend (DMZ Zone)

```
k8s/base/frontend/
├── frontend-deploy.yaml              # Deployment de Nginx (3 réplicas)
├── frontend-service.yaml             # Service NodePort (30080)
└── frontend-configmap.yaml           # Configuración de Nginx
```

**Propósito:**
- Proxy reverso con Nginx
- Punto de entrada público (NodePort 30080)
- Balancea tráfico hacia backend
- Zona desmilitarizada (DMZ)

---

### 🔧 Backend (Internal Zone)

```
k8s/base/backend/
├── spree-backend-deploy.yaml         # Deployment Rails (3 réplicas)
├── spree-backend-service.yaml        # Service ClusterIP (3000)
└── spree-migrate-job.yaml            # Job de migraciones DB
```

**Propósito:**
- Aplicación Rails/Spree
- Lógica de negocio
- API y admin panel
- Zona interna protegida

---

### 💾 Database (Internal Zone)

```
k8s/base/database/
├── postgres-master-statefulset.yaml  # StatefulSet master (1 réplica)
├── postgres-slave-statefulset.yaml   # StatefulSet slaves (2 réplicas)
├── postgres-services.yaml            # Services (master + slaves)
├── postgres-config.yaml              # ConfigMap de PostgreSQL
├── postgres-replication-secret.yaml  # Credenciales replicación
└── postgres-replication-netpol.yaml  # NetworkPolicy replicación
```

**Propósito:**
- PostgreSQL con replicación master-slave
- Persistencia de datos (PVC)
- Alta disponibilidad
- Streaming replication

---

### 🚀 Cache (Internal Zone)

```
k8s/base/cache/
├── redis-deploy.yaml                 # Deployment de Redis (1 réplica)
└── redis-service.yaml                # Service ClusterIP (6379)
```

**Propósito:**
- Cache de sesiones
- Job queue (Sidekiq)
- Performance optimization

---

### 🔥 Network (Firewall)

```
k8s/base/network/
├── np-interna-default-deny.yaml      # Bloquea TODO por defecto
├── np-allow-dmz-to-backend.yaml      # Permite DMZ → Backend
├── np-allow-backend-to-db-redis.yaml # Permite Backend → DB/Redis
└── (postgres-replication-netpol.yaml) # En database/ - Réplica PostgreSQL
```

**Propósito:**
- Firewall L3/L4 con NetworkPolicies
- Segmentación de red
- Zero-trust networking
- Control de tráfico entre namespaces

---

### 🛠️ Scripts de Automatización

```
scripts/
├── deploy-all.ps1                    # Despliegue completo paso a paso
├── cleanup.ps1                       # Elimina todos los recursos
└── status.ps1                        # Muestra estado del cluster
```

**Uso:**

```powershell
# Desplegar todo
cd scripts
.\deploy-all.ps1

# Ver estado
.\status.ps1

# Limpiar
.\cleanup.ps1
```

---

## 🎨 Flujo de Datos

```
Usuario (Browser)
    │
    ▼
http://localhost:30080 (NodePort)
    │
    ▼
┌─────────────────────┐
│  Namespace: DMZ     │
│  ┌────────────────┐ │
│  │ Nginx Frontend │ │ (3 réplicas)
│  └────────────────┘ │
└─────────────────────┘
    │
    │ proxy_pass (puerto 3000)
    │ NetworkPolicy: allow-dmz-to-backend
    ▼
┌─────────────────────────────────────────┐
│  Namespace: INTERNA                     │
│  ┌────────────────┐                     │
│  │ Rails Backend  │ (3 réplicas)        │
│  └────────────────┘                     │
│         │                               │
│         ├──────────────┬────────────┐   │
│         │              │            │   │
│         ▼              ▼            ▼   │
│  ┌──────────┐   ┌──────────┐   ┌─────┐│
│  │PostgreSQL│   │PostgreSQL│   │Redis││
│  │ Master   │   │ Slaves   │   │     ││
│  └──────────┘   └──────────┘   └─────┘│
│  (StatefulSet)  (StatefulSet)   (Dep) │
└─────────────────────────────────────────┘
```

---

## 📋 Recursos de Kubernetes por Tipo

### Deployments
```
✅ spree-frontend    (dmz)      - 3 réplicas
✅ spree-backend     (interna)  - 3 réplicas
✅ redis             (interna)  - 1 réplica
```

### StatefulSets
```
✅ postgres-master   (interna)  - 1 réplica
✅ postgres-slave    (interna)  - 2 réplicas
```

### Services
```
✅ spree-frontend    NodePort   30080 → 80
✅ spree-backend     ClusterIP  3000
✅ postgres          Headless   5432
✅ postgres-master   ClusterIP  5432
✅ postgres-read     ClusterIP  5432 (slaves)
✅ redis             ClusterIP  6379
```

### ConfigMaps
```
✅ spree-frontend-config  (dmz)      - Nginx config
✅ postgres-config        (interna)  - PostgreSQL config
```

### Secrets
```
✅ postgres-replication-secret (interna) - Credenciales replicación
```

### NetworkPolicies
```
✅ interna-default-deny           - Bloquea todo ingress
✅ allow-dmz-to-backend          - DMZ → Backend (puerto 3000)
✅ allow-backend-to-db-redis     - Backend → PostgreSQL/Redis
✅ postgres-replication-netpol   - Master ↔ Slaves
```

---

## 🏷️ Labels y Selectors

### Namespaces
```yaml
dmz:      # Zona pública
  - spree-frontend

interna:  # Zona privada
  - spree-backend
  - postgres-master
  - postgres-slave
  - redis
```

### Nodos
```yaml
proyectosd (control-plane):  # Control plane
proyectosd-m02:  zona=dmz    # Worker DMZ
proyectosd-m03:  zona=interna # Worker Interna
```

### Pods
```yaml
app: spree-frontend    # Frontend
app: spree-backend     # Backend
app: postgres          # PostgreSQL (todos)
role: master           # PostgreSQL master
role: slave            # PostgreSQL slaves
app: redis             # Redis
```

---

## 📈 Alta Disponibilidad

| Componente | Réplicas | Tolerancia | Tipo |
|------------|----------|------------|------|
| Frontend   | 3        | 2 fallos   | Deployment |
| Backend    | 3        | 2 fallos   | Deployment |
| PostgreSQL Master | 1 | 0 fallos*  | StatefulSet |
| PostgreSQL Slaves | 2 | 1 fallo    | StatefulSet |
| Redis      | 1        | 0 fallos   | Deployment |

\* *Master con replicación - failover manual posible*

---

## 🔒 Matriz de Acceso (NetworkPolicies)

|         | Frontend (DMZ) | Backend (Interna) | PostgreSQL | Redis |
|---------|----------------|-------------------|------------|-------|
| **Internet** | ✅ (30080)    | ❌                | ❌         | ❌    |
| **Frontend** | ✅            | ✅ (3000)         | ❌         | ❌    |
| **Backend**  | ❌            | ✅                | ✅ (5432)  | ✅ (6379) |
| **PostgreSQL** | ❌          | ❌                | ✅ (repl)  | ❌    |
| **Redis**    | ❌            | ❌                | ❌         | ✅    |

---

## 🎓 Conceptos de Kubernetes Implementados

- ✅ **Namespaces** - Segmentación lógica
- ✅ **Deployments** - Aplicaciones stateless
- ✅ **StatefulSets** - Bases de datos con identidad
- ✅ **Services** (ClusterIP, NodePort, Headless)
- ✅ **ConfigMaps** - Configuración externa
- ✅ **Secrets** - Credenciales seguras
- ✅ **PersistentVolumeClaims** - Storage persistente
- ✅ **NetworkPolicies** - Firewall L3/L4
- ✅ **NodeSelector** - Scheduling específico
- ✅ **Readiness/Liveness Probes** - Health checks
- ✅ **Jobs** - Tareas one-time (migraciones)
- ✅ **Labels & Selectors** - Organización

---

## 📚 Para Más Información

- **README.md** - Documentación general del proyecto
- **scripts/** - Automatización del despliegue
- **k8s/base/** - Todas las configuraciones YAML

---

**¿Necesitas entender algo específico?** Cada archivo YAML está documentado internamente con comentarios explicativos. 😊
