# 📚 Guía de Estudio - Conceptos de Sistemas Distribuidos

**Entendiendo el "por qué" detrás del proyecto** 🧠

Esta guía explica los conceptos teóricos de sistemas distribuidos que se implementan en este proyecto.

---

## 📖 Índice

1. [¿Qué es un sistema distribuido?](#qué-es-un-sistema-distribuido)
2. [Arquitectura del proyecto](#arquitectura-del-proyecto)
3. [Conceptos clave implementados](#conceptos-clave)
4. [Preguntas y respuestas](#preguntas-y-respuestas)
5. [Ejercicios prácticos](#ejercicios-prácticos)

---

## 🌐 ¿Qué es un Sistema Distribuido?

### Definición

> Un sistema distribuido es una colección de computadoras **independientes** que aparecen ante los usuarios como **un único sistema coherente**.

### Características principales

1. **Transparencia**: El usuario no percibe que hay múltiples máquinas
2. **Escalabilidad**: Podemos agregar más recursos fácilmente
3. **Tolerancia a fallos**: Si una parte falla, el sistema sigue funcionando
4. **Concurrencia**: Múltiples procesos ejecutándose simultáneamente

### Ejemplo del mundo real

- **Netflix**: Miles de servidores trabajando juntos
- **Google**: Millones de servidores coordinados
- **WhatsApp**: Mensajes distribuidos en muchos data centers

### En este proyecto

Tenemos **3 nodos de Kubernetes** trabajando como un solo cluster:
- Cada nodo es una computadora independiente
- Kubernetes los coordina como un solo sistema
- Los usuarios acceden a UNA aplicación (aunque corre en múltiples pods)

---

## 🏗️ Arquitectura del Proyecto

### Vista de alto nivel

```
┌─────────────────────────────────────────────────────┐
│              KUBERNETES CLUSTER                     │
│                  (3 nodos)                          │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌───────────────────────────────────────────┐    │
│  │  NAMESPACE: dmz (Zona Desmilitarizada)    │    │
│  │  ────────────────────────────────────      │    │
│  │  Componente: Frontend (Nginx)              │    │
│  │  Réplicas: 3                               │    │
│  │  Nodo: proyectosd-m02                      │    │
│  │  Puerto expuesto: 30080 (NodePort)         │    │
│  │                                            │    │
│  │  Función:                                  │    │
│  │  - Proxy reverso                           │    │
│  │  - Routing de peticiones                   │    │
│  │  - Balanceo de carga hacia backend         │    │
│  └───────────────────────────────────────────┘    │
│            ↓ (HTTP sobre red interna)              │
│       ┌────────────────────────┐                   │
│       │   Network Policy       │                   │
│       │   (Firewall de K8s)    │                   │
│       └────────────────────────┘                   │
│            ↓                                        │
│  ┌───────────────────────────────────────────┐    │
│  │  NAMESPACE: interna (Zona privada)        │    │
│  │  ───────────────────────────────────       │    │
│  │  Componente: Backend (Rails/Spree)        │    │
│  │  Réplicas: 3                               │    │
│  │  Nodo: proyectosd-m03                      │    │
│  │                                            │    │
│  │  Función:                                  │    │
│  │  - Lógica de negocio                       │    │
│  │  - API REST                                │    │
│  │  - Procesamiento de pedidos                │    │
│  │                                            │    │
│  │  ┌──────────────────────────────────┐     │    │
│  │  │  PostgreSQL (Master + Réplicas)  │     │    │
│  │  │  - Master: lectura/escritura     │     │    │
│  │  │  - Réplicas: solo lectura        │     │    │
│  │  └──────────────────────────────────┘     │    │
│  │                                            │    │
│  │  ┌──────────────────────────────────┐     │    │
│  │  │  Redis                           │     │    │
│  │  │  - Sesiones                      │     │    │
│  │  │  - Cola de jobs (Sidekiq)        │     │    │
│  │  └──────────────────────────────────┘     │    │
│  └───────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
```

---

## 🔑 Conceptos Clave Implementados

### 1️⃣ **Namespaces** (Segmentación lógica)

#### ¿Qué son?

Los namespaces son como "contenedores virtuales" dentro del cluster. Permiten **aislar** grupos de recursos.

#### ¿Por qué usarlos?

- **Seguridad**: Separar componentes públicos de privados
- **Organización**: Facilita encontrar recursos
- **Políticas**: Aplicar reglas diferentes a cada namespace

#### En este proyecto:

| Namespace | Propósito | Componentes |
|-----------|-----------|-------------|
| `dmz` | Zona pública (accesible desde internet) | Frontend (Nginx) |
| `interna` | Zona privada (solo acceso interno) | Backend, PostgreSQL, Redis |

#### Comando para explorar:

```powershell
# Ver todos los namespaces
kubectl get namespaces

# Ver recursos en un namespace específico
kubectl get all -n dmz
kubectl get all -n interna
```

#### Analogía:

Piensa en un edificio:
- **DMZ** = Recepción (cualquiera puede entrar)
- **Interna** = Oficinas privadas (solo personal autorizado)

---

### 2️⃣ **Network Policies** (Firewall de Kubernetes)

#### ¿Qué son?

Las Network Policies son **reglas de firewall** que controlan qué pods pueden comunicarse entre sí.

#### ¿Por qué son importantes?

- **Seguridad**: Principio de "zero trust" - denegar todo por defecto
- **Control**: Solo permitir tráfico necesario
- **Segmentación**: DMZ no debe acceder directamente a la BD

#### Políticas implementadas:

##### 1. **`interna-default-deny`** (namespace: interna)
```yaml
# Bloquea TODO el tráfico de entrada por defecto
# Cualquier acceso debe ser explícitamente permitido
```

**Por qué**: Seguridad máxima - empezar negando todo

##### 2. **`allow-dmz-to-backend`** (namespace: interna)
```yaml
# Permite: DMZ → Backend (puerto 3000)
# Bloquea: DMZ → PostgreSQL, Redis
```

**Por qué**: El frontend necesita hablar con el backend, pero NO con la BD

##### 3. **`allow-backend-to-db-redis`** (namespace: interna)
```yaml
# Permite:
#   - Backend → PostgreSQL (puerto 5432)
#   - Backend → Redis (puerto 6379)
```

**Por qué**: El backend necesita acceso a datos y cache

#### Comandos para explorar:

```powershell
# Ver todas las políticas
kubectl get networkpolicies -A

# Describir una política específica
kubectl describe networkpolicy interna-default-deny -n interna

# Experimentar: eliminar una política y ver qué pasa
kubectl delete networkpolicy allow-dmz-to-backend -n interna
# Intenta acceder a la app - fallar
# Restaurar:
kubectl apply -f np-allow-dmz-to-backend.yaml
```

#### Analogía:

Las Network Policies son como **guardias de seguridad**:
- Por defecto, nadie pasa
- Solo personas con credenciales específicas pueden entrar
- Diferentes áreas tienen diferentes niveles de acceso

---

### 3️⃣ **Alta Disponibilidad** (Réplicas)

#### ¿Qué es?

Alta disponibilidad significa que el sistema **sigue funcionando** aunque fallen componentes individuales.

#### ¿Cómo se logra?

Mediante **réplicas** - múltiples copias del mismo servicio corriendo simultáneamente.

#### En este proyecto:

| Componente | Réplicas | ¿Por qué? |
|------------|----------|-----------|
| Frontend (Nginx) | 3 | Si uno falla, los otros 2 siguen sirviendo |
| Backend (Rails) | 3 | Distribuir carga y tolerar fallos |
| PostgreSQL | 1 master + 2 réplicas | Master para escritura, réplicas para lectura |
| Redis | 1 | En producción real tendría réplicas también |

#### ¿Cómo funciona el balanceo?

```
Usuario hace request a: http://localhost:30080
           ↓
    Kubernetes Service (ClusterIP)
           ↓
    Distribuye entre las 3 réplicas
           ↓
    ┌─────────┬─────────┬─────────┐
    │ Pod 1   │ Pod 2   │ Pod 3   │
    └─────────┴─────────┴─────────┘
```

#### Experimento:

```powershell
# Ver las réplicas actuales
kubectl get pods -n dmz -l app=spree-frontend -o wide

# Eliminar un pod
kubectl delete pod -n dmz <nombre-del-pod>

# Observar cómo Kubernetes crea uno nuevo automáticamente
kubectl get pods -n dmz -w
```

**Resultado**: El sistema sigue funcionando mientras Kubernetes recrea el pod eliminado.

#### Analogía:

Es como tener **3 cajeros** en un banco:
- Si uno se va a almorzar, los otros 2 atienden
- Los clientes no notan la diferencia
- Todos tienen acceso a la misma información (BD compartida)

---

### 4️⃣ **Replicación de Base de Datos**

#### ¿Qué es?

La replicación significa tener **múltiples copias** de la base de datos sincronizadas.

#### Arquitectura implementada: Master-Slave

```
┌─────────────────────┐
│  PostgreSQL Master  │ ← Escrituras (INSERT, UPDATE, DELETE)
│  (Lectura/Escritura)│
└──────────┬──────────┘
           │ Replica (streaming)
           ├─────────────────────────┐
           ↓                         ↓
┌────────────────┐          ┌────────────────┐
│ Replica 1      │          │ Replica 2      │
│ (Solo lectura) │          │ (Solo lectura) │
└────────────────┘          └────────────────┘
```

#### ¿Por qué replicar?

1. **Escalabilidad de lectura**: Distribuir queries SELECT entre réplicas
2. **Alta disponibilidad**: Si el master falla, una réplica puede ser promovida
3. **Backups**: Las réplicas son copias en tiempo real
4. **Disaster recovery**: Réplicas en diferentes ubicaciones

#### Tipos de lectura/escritura:

| Operación | Destino | Motivo |
|-----------|---------|--------|
| `INSERT`, `UPDATE`, `DELETE` | Master | Solo el master acepta cambios |
| `SELECT` (consultas pesadas) | Réplicas | Descargar trabajo del master |
| `SELECT` (admin, críticas) | Master | Datos más frescos (sin lag) |

#### Verificar replicación:

```powershell
# Ver clientes de replicación conectados
kubectl exec -it -n interna postgres-master-0 -- `
  psql -U postgres -d spreedb -c "SELECT client_addr, state, sync_state FROM pg_stat_replication;"
```

**Resultado esperado:**
```
client_addr     | state     | sync_state
-------------------------------------------------
10.244.2.15     | streaming | async
10.244.2.16     | streaming | async
```

#### Analogía:

Es como tener **una biblioteca central** (master) y **sucursales** (réplicas):
- Solo en la central puedes comprar libros nuevos (escritura)
- En las sucursales puedes leer cualquier libro (lectura)
- Los libros se copian de la central a las sucursales cada noche (replicación)

---

### 5️⃣ **Procesamiento Asíncrono** (Sidekiq + Redis)

#### ¿Qué es?

El procesamiento asíncrono significa ejecutar tareas **en segundo plano**, sin hacer esperar al usuario.

#### ¿Por qué es importante?

Tareas lentas no deben bloquear el flujo principal:
- Enviar emails
- Generar reportes
- Procesar imágenes
- Actualizar caché

#### Arquitectura:

```
Usuario hace pedido
      ↓
Backend responde inmediatamente: "Pedido recibido"
      ↓
Backend encola job en Redis
      ↓
Sidekiq (worker) procesa el job en background
      ↓
Envía email de confirmación (sin bloquear al usuario)
```

#### En este proyecto:

| Componente | Rol |
|------------|-----|
| Redis | Cola de mensajes (broker) |
| Sidekiq | Procesador de jobs (worker) |
| Backend | Encola jobs cuando es necesario |

#### Verificar que funciona:

```powershell
# Comprobar conexión Sidekiq-Redis
kubectl exec -n interna deployment/spree-backend -- `
  bin/rails runner "puts 'Sidekiq: ' + (defined?(Sidekiq) ? 'OK' : 'NO'); puts 'Redis: ' + Sidekiq.redis { |r| r.ping }"
```

**Resultado esperado:**
```
Sidekiq: OK
Redis: PONG
```

#### Ver jobs en ejecución:

Accede a: http://localhost:30080/sidekiq

#### Analogía:

Es como en un **restaurante**:
- **Backend (Mesero)**: Toma el pedido y lo envía a la cocina inmediatamente
- **Redis (Ventana de cocina)**: Lista de pedidos pendientes
- **Sidekiq (Cocinero)**: Procesa los pedidos uno por uno
- **Usuario**: No tiene que esperar en la mesa a que cocinen - puede seguir conversando

---

### 6️⃣ **Service Discovery** (DNS de Kubernetes)

#### ¿Qué es?

Service Discovery es la capacidad de los servicios de **encontrarse entre sí** automáticamente, sin IPs fijas.

#### ¿Cómo funciona en Kubernetes?

Kubernetes crea automáticamente entradas DNS para cada Service:

```
<nombre-servicio>.<namespace>.svc.cluster.local
```

#### Ejemplos en este proyecto:

| Service | DNS interno | Usado por |
|---------|-------------|-----------|
| Backend | `spree-backend.interna.svc.cluster.local:3000` | Frontend |
| PostgreSQL | `postgres-master.interna.svc.cluster.local:5432` | Backend |
| Redis | `redis.interna.svc.cluster.local:6379` | Backend |

#### Ventaja:

No importa en qué nodo o IP esté el pod - el nombre DNS **siempre funciona**.

#### Probar:

```powershell
# Desde un pod en DMZ, resolver el DNS del backend
kubectl run test --image=curlimages/curl --rm -i -n dmz -- `
  nslookup spree-backend.interna.svc.cluster.local
```

#### Analogía:

Es como llamar a alguien por **nombre** en lugar de por **número de teléfono**:
- Si cambia de número, el nombre sigue siendo el mismo
- No necesitas memorizar números - solo nombres

---

### 7️⃣ **Node Affinity** (Placement de pods)

#### ¿Qué es?

Node Affinity permite **forzar** que ciertos pods corran en nodos específicos.

#### ¿Por qué usarlo?

- **Segmentación física**: Nodos separados para DMZ vs interna
- **Hardware especializado**: Nodos con GPU, SSD, etc.
- **Compliance**: Separar workloads sensibles

#### En este proyecto:

| Label | Asignado a | Pods que corren ahí |
|-------|------------|---------------------|
| `zona=dmz` | proyectosd-m02 | Frontend (Nginx) |
| `zona=interna` | proyectosd-m03 | Backend, PostgreSQL, Redis |

#### Configuración (ejemplo del frontend):

```yaml
spec:
  nodeSelector:
    zona: dmz  # Solo corre en nodos con esta etiqueta
```

#### Verificar:

```powershell
# Ver qué pods corren en cada nodo
kubectl get pods -A -o wide

# Ver labels de los nodos
kubectl get nodes --show-labels
```

#### Analogía:

Es como asignar **empleados a edificios**:
- Vendedores en el edificio de ventas
- Ingenieros en el edificio de desarrollo
- Cada uno tiene las herramientas que necesita

---

## 🤔 Preguntas y Respuestas

### P1: ¿Por qué no poner todo en un solo namespace?

**R**: Seguridad y organización.
- Si un atacante compromete el frontend, no puede acceder directamente a la BD
- Las Network Policies solo funcionan entre namespaces
- Facilita aplicar políticas diferentes (ej: cuotas de recursos)

### P2: ¿Qué pasa si elimino una Network Policy?

**R**: El tráfico se permite por defecto (si no hay otras políticas que lo bloqueen).
- `interna-default-deny` bloquea TODO
- Las otras políticas PERMITEN selectivamente

### P3: ¿Por qué 3 réplicas y no 5 o 10?

**R**: Balance entre disponibilidad y recursos.
- 1 réplica: No tolera fallos
- 3 réplicas: Puede perder 1-2 y seguir funcionando
- 10+ réplicas: Desperdicio de recursos si la carga no lo justifica

**Regla de oro**: Número impar (evita split-brain en consensus)

### P4: ¿Qué pasa si el master de PostgreSQL falla?

**R**: En este proyecto: downtime hasta que se recupere.
- En producción real: Failover automático - una réplica es promovida a master
- Requiere: Herramientas como Patroni, Stolon, o Postgres Operator

### P5: ¿Por qué Rails en lugar de microservicios separados?

**R**: Balance entre complejidad y realismo.
- Rails = Aplicación monolítica (más simple de entender)
- En producción real: Podrías dividir en servicios separados (productos, usuarios, pagos, etc.)

### P6: ¿Cómo se comunica el frontend con el backend?

**R**: A través de HTTP interno:
1. Usuario → http://localhost:30080 (NodePort)
2. NodePort → Service `spree-frontend`
3. Frontend (Nginx) → `http://spree-backend.interna.svc.cluster.local:3000`
4. Service `spree-backend` → Pods de backend

---

## 🧪 Ejercicios Prácticos

### Ejercicio 1: Experimentar con réplicas

```powershell
# Reducir réplicas a 1
kubectl scale deployment spree-backend -n interna --replicas=1
kubectl get pods -n interna -w

# Aumentar a 5
kubectl scale deployment spree-backend -n interna --replicas=5
kubectl get pods -n interna -w

# Restaurar a 3
kubectl scale deployment spree-backend -n interna --replicas=3
```

**Pregunta**: ¿Cuánto tarda en crear los nuevos pods?

### Ejercicio 2: Simular fallo de pod

```powershell
# Eliminar un pod del backend
kubectl delete pod -n interna <nombre-pod> --force --grace-period=0

# Observar cómo Kubernetes lo recrea
kubectl get pods -n interna -w
```

**Pregunta**: ¿La aplicación siguió funcionando mientras tanto?

### Ejercicio 3: Test de Network Policy

```powershell
# Intentar conectar desde DMZ a PostgreSQL (debe fallar)
kubectl run test --image=postgres:15 --rm -i -n dmz -- `
  psql -h postgres-master.interna.svc.cluster.local -U postgres -d spreedb

# Intentar conectar desde interna a PostgreSQL (debe funcionar)
kubectl run test --image=postgres:15 --rm -i -n interna -- `
  psql -h postgres-master.interna.svc.cluster.local -U postgres -d spreedb
```

**Pregunta**: ¿Por qué uno funciona y el otro no?

### Ejercicio 4: Explorar Service Discovery

```powershell
# Entrar a un pod del backend
kubectl exec -it -n interna deployment/spree-backend -- bash

# Dentro del pod:
nslookup postgres-master.interna.svc.cluster.local
nslookup redis.interna.svc.cluster.local
nslookup spree-backend.interna.svc.cluster.local

# Salir
exit
```

**Pregunta**: ¿Cuál es la IP del servicio? ¿Es la misma cada vez?

### Ejercicio 5: Monitorear replicación

```powershell
# Terminal 1: Insertar dato en el master
kubectl exec -it -n interna postgres-master-0 -- psql -U postgres -d spreedb
# En psql:
CREATE TABLE test (id serial, data text);
INSERT INTO test (data) VALUES ('Hola desde master');
\q

# Terminal 2: Verificar que la réplica tiene el dato
kubectl exec -it -n interna postgres-slave-0 -- psql -U postgres -d spreedb
# En psql:
SELECT * FROM test;
\q
```

**Pregunta**: ¿El dato apareció en la réplica? ¿Instantáneamente o con delay?

---

## 🎓 Temas Avanzados (Opcional)

### CAP Theorem

En sistemas distribuidos, solo puedes tener 2 de 3:
- **C**onsistency (Consistencia)
- **A**vailability (Disponibilidad)
- **P**artition tolerance (Tolerancia a particiones)

**Este proyecto**: Prioriza **CP** (Consistencia + Particiones)
- PostgreSQL con replicación asíncrona
- Si hay split-brain, priorizamos consistencia

### Teorema de los Dos Generales

Problema: En redes no confiables, es imposible garantizar que dos partes estén 100% sincronizadas.

**Aplicación**: Las Network Policies pueden fallar si hay problemas de red.

### Idempotencia

Las operaciones deben poder ejecutarse múltiples veces sin cambiar el resultado.

**Ejemplo en Rails**:
```ruby
# Idempotente
user = User.find_or_create_by(email: 'admin@example.com')

# NO idempotente
user = User.create(email: 'admin@example.com')  # Falla si ya existe
```

---

## 📚 Lecturas Recomendadas

1. **"Designing Data-Intensive Applications"** - Martin Kleppmann
2. **"Kubernetes in Action"** - Marko Lukša
3. **"Site Reliability Engineering"** - Google
4. **Kubernetes Docs**: https://kubernetes.io/docs/

---

## ✅ Checklist de Comprensión

Marca cuando entiendas cada concepto:

- [ ] ¿Qué es un sistema distribuido?
- [ ] ¿Para qué sirven los namespaces?
- [ ] ¿Cómo funcionan las Network Policies?
- [ ] ¿Qué es alta disponibilidad?
- [ ] ¿Cómo funciona la replicación master-slave?
- [ ] ¿Qué es procesamiento asíncrono?
- [ ] ¿Cómo funciona Service Discovery?
- [ ] ¿Para qué sirve Node Affinity?
- [ ] ¿Qué es CAP Theorem?
- [ ] ¿Puedo explicar la arquitectura completa del proyecto?

---

**¡Sigue estudiando!** 🚀

Si tienes dudas, experimenta con los comandos y observa qué pasa.
