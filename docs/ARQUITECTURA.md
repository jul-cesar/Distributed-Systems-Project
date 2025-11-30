# 🏗️ Arquitectura del Proyecto - Sistemas Distribuidos

## 📊 Vista General

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         INTERNET / USUARIO                                  │
│                                  │                                           │
│                                  ▼                                           │
│                         http://localhost:30080                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                   │
                                   │ NodePort 30080
                                   ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           NODO: proyectosd-m02                              │
│                          ZONA: DMZ (Pública)                                │
│                          IP: 192.168.49.3                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────┐          │
│  │  NAMESPACE: dmz                                              │          │
│  │  ┌────────────────────────────────────────────────────────┐  │          │
│  │  │  Frontend: Nginx (Reverse Proxy)                       │  │          │
│  │  │  ├─ Pod: spree-frontend-xxx                            │  │          │
│  │  │  ├─ IP: 10.244.231.142                                 │  │          │
│  │  │  ├─ Puerto: 80                                         │  │          │
│  │  │  └─ Función: Proxy reverso hacia backend              │  │          │
│  │  └────────────────────────────────────────────────────────┘  │          │
│  │                            │                                  │          │
│  │                            │ proxy_pass (puerto 3000)         │          │
│  │                            │ NetworkPolicy: allow-dmz-to-backend         │
│  └────────────────────────────┼───────────────────────────────────          │
└────────────────────────────────┼───────────────────────────────────────────┘
                                 │
                                 │ HTTP Request
                                 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           NODO: proyectosd-m03                              │
│                         ZONA: INTERNA (Privada)                             │
│                          IP: 192.168.49.4                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────┐          │
│  │  NAMESPACE: interna                                          │          │
│  │                                                              │          │
│  │  ┌────────────────────────────────────────────────────────┐  │          │
│  │  │  Backend: Spree Commerce (Rails)                       │  │          │
│  │  │  ├─ Pods: spree-backend-xxx (3 réplicas)               │  │          │
│  │  │  ├─ IPs: 10.244.204.201, .204, .205                   │  │          │
│  │  │  ├─ Puerto: 3000                                       │  │          │
│  │  │  ├─ Service: spree-backend (ClusterIP 10.101.151.58)  │  │          │
│  │  │  └─ Función: Lógica de negocio, API, Admin           │  │          │
│  │  └────────────────────────────────────────────────────────┘  │          │
│  │              │                              │                 │          │
│  │              │                              │                 │          │
│  │              ▼                              ▼                 │          │
│  │  ┌────────────────────────┐   ┌─────────────────────────┐   │          │
│  │  │  PostgreSQL (DB)       │   │  Redis (Cache)          │   │          │
│  │  │  StatefulSets:         │   │  ├─ Pod: redis-xxx      │   │          │
│  │  │  ├─ Master (1 pod)     │   │  ├─ IP: 10.244.204.206  │   │          │
│  │  │  │  └─ postgres-master-0│  │  ├─ Puerto: 6379        │   │          │
│  │  │  │     IP: 10.244.204.202│ │  └─ Service: ClusterIP  │   │          │
│  │  │  │                      │   │     10.101.21.51        │   │          │
│  │  │  ├─ Slaves (2 pods)    │   │  Función: Cache,        │   │          │
│  │  │  │  ├─ postgres-slave-0│   │           Session Store │   │          │
│  │  │  │  │  IP: 10.244.204.200│ └─────────────────────────┘   │          │
│  │  │  │  └─ postgres-slave-1│                               │          │
│  │  │  │     IP: 10.244.204.203│                              │          │
│  │  │  ├─ Puerto: 5432       │                               │          │
│  │  │  ├─ Replicación: Streaming│                            │          │
│  │  │  └─ PVCs: 3x 5Gi       │                               │          │
│  │  │  Función: Persistencia │                               │          │
│  │  └────────────────────────┘                               │          │
│  └──────────────────────────────────────────────────────────────          │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔢 Resumen de Componentes

### **Nodos Físicos: 3**

| Nodo | Rol | IP | Zona | Función |
|------|-----|-------|------|---------|
| proyectosd | Control Plane | 192.168.49.2 | - | Gestión del cluster |
| proyectosd-m02 | Worker | 192.168.49.3 | **dmz** | Frontend público |
| proyectosd-m03 | Worker | 192.168.49.4 | **interna** | Backend privado |

### **Componentes de Aplicación: 7**

#### 1️⃣ **Frontend (Nginx)**

- **Namespace:** dmz
- **Tipo:** Deployment
- **Réplicas:** 1
- **Puerto:** 80
- **NodePort:** 30080
- **Función:** Proxy reverso que recibe requests externos y los envía al backend
- **Nodo:** proyectosd-m02 (zona=dmz)

#### 2️⃣ **Backend (Spree/Rails)**

- **Namespace:** interna
- **Tipo:** Deployment
- **Réplicas:** 3
- **Puerto:** 3000
- **Service:** ClusterIP (10.101.151.58)
- **Función:** Lógica de negocio, API REST, Admin panel
- **Nodo:** proyectosd-m03 (zona=interna)

#### 3️⃣ **PostgreSQL Master**

- **Namespace:** interna
- **Tipo:** StatefulSet
- **Réplicas:** 1
- **Puerto:** 5432
- **PVC:** postgres-data-postgres-master-0 (5Gi)
- **Función:** Base de datos principal (escritura)
- **Nodo:** proyectosd-m03

#### 4️⃣ **PostgreSQL Slaves**

- **Namespace:** interna
- **Tipo:** StatefulSet
- **Réplicas:** 2
- **Puerto:** 5432
- **PVCs:** 2x 5Gi (uno por slave)
- **Función:** Réplicas de lectura (streaming replication)
- **Nodo:** proyectosd-m03

#### 5️⃣ **Redis**

- **Namespace:** interna
- **Tipo:** Deployment
- **Réplicas:** 1
- **Puerto:** 6379
- **Función:** Cache de sesiones, Job queue (Sidekiq)
- **Nodo:** proyectosd-m03

#### 6️⃣ **Spree Migrate Job**

- **Namespace:** interna
- **Tipo:** Job
- **Estado:** Completed
- **Función:** Ejecutar migraciones de base de datos al inicio

#### 7️⃣ **Services (DNS Interno)**

- `spree-frontend.dmz.svc.cluster.local` (NodePort)
- `spree-backend.interna.svc.cluster.local` (ClusterIP)
- `postgres.interna.svc.cluster.local` (ClusterIP)
- `redis.interna.svc.cluster.local` (ClusterIP)

---

## 🔌 Conectividad Entre Componentes

```
Frontend (dmz)
    │
    └─→ spree-backend.interna:3000 ✅ (NetworkPolicy permite)
            │
            ├─→ postgres.interna:5432 ✅ (NetworkPolicy permite)
            │
            └─→ redis.interna:6379 ✅ (NetworkPolicy permite)

Internet → Frontend ✅ (NodePort 30080)
Internet → Backend ❌ (No accesible directamente)
Internet → PostgreSQL ❌ (No accesible directamente)
Internet → Redis ❌ (No accesible directamente)
```

---

## 🛡️ NetworkPolicies (Firewall)

| Policy | Namespace | Efecto |
|--------|-----------|--------|
| `interna-default-deny` | interna | Bloquea TODO ingress por defecto |
| `allow-dmz-to-backend` | interna | Permite DMZ → Backend (puerto 3000) |
| `allow-backend-to-postgres` | interna | Permite Backend → PostgreSQL (5432) |
| `allow-backend-to-redis` | interna | Permite Backend → Redis (6379) |
| `allow-postgres-replication` | interna | Permite Master ↔ Slaves (5432) |

---

## 📈 Alta Disponibilidad

| Componente | Réplicas | Tolerancia a Fallos |
|------------|----------|---------------------|
| Frontend | 1 | ⚠️ 0 fallos |
| Backend | 3 | ✅ 2 fallos |
| PostgreSQL Master | 1 | ⚠️ 0 fallos* |
| PostgreSQL Slaves | 2 | ✅ 1 fallo |
| Redis | 1 | ⚠️ 0 fallos |

\* *Master con replicación - failover manual posible promocionando un slave*

---

## 💾 Almacenamiento

| PVC | Tamaño | Bound To | Función |
|-----|--------|----------|---------|
| postgres-data-postgres-master-0 | 5Gi | postgres-master-0 | Data del master |
| postgres-data-postgres-slave-0 | 5Gi | postgres-slave-0 | Data del slave 0 |
| postgres-data-postgres-slave-1 | 5Gi | postgres-slave-1 | Data del slave 1 |

**Total Storage:** 15Gi

---

## 🌐 URLs de Acceso

| URL | Componente | Descripción |
|-----|------------|-------------|
| <http://localhost:30080> | Frontend | Storefront público |
| <http://localhost:30080/admin> | Backend | Panel administrativo |
| <http://localhost:30080/api> | Backend | API REST |
| (interno) spree-backend.interna:3000 | Backend | Servicio interno |
| (interno) postgres.interna:5432 | PostgreSQL | Base de datos |
| (interno) redis.interna:6379 | Redis | Cache |

---

## 🔍 Verificación Rápida

```powershell
# Ver todos los componentes
kubectl get all -n dmz
kubectl get all -n interna

# Ver distribución en nodos
kubectl get pods -A -o wide | Select-String "dmz|interna"

# Ver NetworkPolicies
kubectl get networkpolicies -A

# Ver PVCs
kubectl get pvc -n interna
```

---

**Última actualización:** 29 de Noviembre, 2025
