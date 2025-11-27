# 🚀 LEEME PRIMERO - Empezar desde Cero

**¡Bienvenido al proyecto! Este archivo es tu punto de partida.**

---

## 📚 ¿Qué es este proyecto?

Este es un **sistema distribuido completo** que implementa una tienda e-commerce corriendo en **Kubernetes con 3 nodos**.

Es perfecto para aprender:
- Arquitectura distribuida
- Kubernetes
- Network segmentation (DMZ + zona interna)
- Alta disponibilidad
- Replicación de base de datos

---

## 🎯 ¿Por dónde empiezo?

### Si quieres **instalarlo rápido** (30 minutos):

1. Ejecuta el script automático:
   ```powershell
   .\setup-completo.ps1
   ```

2. Cuando termine, abre el navegador en: http://localhost:30080

3. ¡Listo! Ahora salta a la sección "Para entenderlo".

---

### Si quieres **entender cada paso** (2-3 horas):

1. Lee: **[INICIO-RAPIDO.md](./INICIO-RAPIDO.md)**
   - Guía completa paso a paso
   - Explicación de cada comando
   - Troubleshooting incluido

2. Ejecuta los comandos manualmente
   - Aprenderás más haciéndolo manual

3. Usa **[VERIFICACION.md](./VERIFICACION.md)** para comprobar que todo funciona

---

### Para **entenderlo a fondo** (4-6 horas):

1. Primero instala (ver arriba)

2. Lee: **[GUIA-ESTUDIO.md](./GUIA-ESTUDIO.md)**
   - Conceptos teóricos explicados
   - Por qué funciona cada cosa
   - Analogías y ejemplos
   - Ejercicios prácticos

3. Experimenta:
   - Elimina pods
   - Escala réplicas
   - Rompe Network Policies
   - Mira qué pasa

---

### Si **estudian en grupo** (Plan completo):

Lee: **[GUIA-GRUPO.md](./GUIA-GRUPO.md)**
- Plan de estudio de 4 sesiones
- División de tareas
- Experimentos sugeridos
- Preparación de demo

---

## 📁 ¿Qué archivos hay aquí?

### 📘 Documentación (¡Empieza por aquí!)
- **`LEEME-PRIMERO.md`** ← Estás aquí
- **`README.md`** - Descripción general del proyecto
- **`INICIO-RAPIDO.md`** - Setup paso a paso
- **`GUIA-ESTUDIO.md`** - Conceptos teóricos
- **`GUIA-GRUPO.md`** - Guía para estudiar en equipo
- **`VERIFICACION.md`** - Checklist de verificación
- **`EVALUACION-FINAL.md`** - Rúbrica y puntaje

### 🤖 Scripts
- **`setup-completo.ps1`** - Script que instala TODO automáticamente

### 📦 Manifiestos de Kubernetes

#### Frontend (Nginx - Namespace DMZ)
- `frontend-deploy.yaml` - Deployment del frontend
- `frontend-service.yaml` - Service NodePort (puerto 30080)
- `frontend-configmap.yaml` - Configuración de Nginx

#### Backend (Rails/Spree - Namespace interna)
- `spree-backend-deploy.yaml` - Deployment del backend
- `spree-backend-service.yaml` - Service del backend
- `spree-migrate-job.yaml` - Job de migraciones

#### Base de Datos (PostgreSQL - Namespace interna)
- `postgres-config.yaml` - ConfigMap de configuración
- `postgres-replication-secret.yaml` - Secretos de replicación
- `postgres-master-statefulset.yaml` - Master (escritura)
- `postgres-slave-statefulset.yaml` - Réplicas (lectura)
- `postgres-services.yaml` - Services (master/read/headless)

#### Cache y Jobs (Redis - Namespace interna)
- `redis-deploy.yaml` - Deployment de Redis
- `redis-service.yaml` - Service de Redis

#### Network Policies (Firewall)
- `np-interna-default-deny.yaml` - Bloquear todo por defecto
- `np-allow-dmz-to-backend.yaml` - Permitir DMZ → Backend
- `np-allow-backend-to-db-redis.yaml` - Permitir Backend → DB/Redis
- `postgres-replication-netpol.yaml` - Permitir replicación PostgreSQL

### 💻 Código de la Aplicación
- **`spree-app/`** - Aplicación Rails completa (NO tocar)

---

## ⚡ Quick Start (3 comandos)

```powershell
# 1. Instalar todo
.\setup-completo.ps1

# 2. Esperar a que termine (5-10 minutos)

# 3. En otra terminal, exponer el servicio:
kubectl port-forward --address 0.0.0.0 service/spree-frontend 30080:80 -n dmz

# 4. Abrir navegador: http://localhost:30080
```

**Credenciales de admin:**
- Email: `admin@example.com`
- Password: `admin123456`

---

## 🔍 ¿Qué voy a aprender?

### Conceptos de Sistemas Distribuidos
- ✅ Arquitectura multinodo
- ✅ Separación de concerns (frontend/backend/datos)
- ✅ Service discovery
- ✅ Load balancing
- ✅ Fault tolerance

### Conceptos de Kubernetes
- ✅ Pods, Services, Deployments
- ✅ Namespaces
- ✅ ConfigMaps y Secrets
- ✅ StatefulSets (para bases de datos)
- ✅ Network Policies
- ✅ Node affinity

### Conceptos de Seguridad
- ✅ DMZ vs zona interna
- ✅ Network segmentation
- ✅ Zero-trust networking
- ✅ Firewall entre pods

### Conceptos de Datos
- ✅ Replicación master-slave
- ✅ Read/write splitting
- ✅ Consistencia eventual

### Conceptos de DevOps
- ✅ Infrastructure as Code
- ✅ Container orchestration
- ✅ Health checks
- ✅ Procesamiento asíncrono (Sidekiq)

---

## 🎓 Plan de Estudio Sugerido

### Día 1: Setup (2-3 horas)
- [ ] Ejecutar `setup-completo.ps1`
- [ ] Verificar que todo funciona
- [ ] Acceder a la aplicación
- [ ] Tomar capturas de pantalla

### Día 2: Arquitectura (2-3 horas)
- [ ] Leer GUIA-ESTUDIO.md
- [ ] Dibujar la arquitectura
- [ ] Ejecutar comandos de exploración
- [ ] Entender cada componente

### Día 3: Experimentar (2-3 horas)
- [ ] Hacer los ejercicios prácticos
- [ ] Eliminar pods y ver qué pasa
- [ ] Escalar réplicas
- [ ] Probar Network Policies

### Día 4: Demostración (2-3 horas)
- [ ] Leer EVALUACION-FINAL.md
- [ ] Practicar comandos de demo
- [ ] Preparar capturas
- [ ] Ensayar presentación

---

## 🆘 ¿Problemas?

### 1. Si algo no funciona durante la instalación:
- Lee los mensajes de error
- Revisa: [INICIO-RAPIDO.md - Sección Troubleshooting](./INICIO-RAPIDO.md#-problemas-comunes)
- Ejecuta: `kubectl get pods -A` para ver el estado

### 2. Si no entiendes algo:
- Busca el concepto en [GUIA-ESTUDIO.md](./GUIA-ESTUDIO.md)
- Busca en la sección de Preguntas y Respuestas
- Experimenta con los comandos

### 3. Si estudian en grupo:
- Sigue: [GUIA-GRUPO.md](./GUIA-GRUPO.md)
- Dividan responsabilidades
- Enseñen unos a otros

---

## 📊 Estado del Proyecto

### ✅ Implementado y funcionando:
- 3 nodos de Kubernetes
- Namespaces separados (dmz + interna)
- Frontend (Nginx) - 3 réplicas
- Backend (Rails/Spree) - 3 réplicas
- PostgreSQL con replicación (1 master + 2 réplicas)
- Redis para cache y jobs
- Sidekiq para procesamiento asíncrono
- Network Policies completas
- Acceso desde VM externa

### 📈 Puntaje estimado: 90%
Ver detalles en: [EVALUACION-FINAL.md](./EVALUACION-FINAL.md)

---

## 🎯 Objetivos de Aprendizaje

Al finalizar este proyecto, deberías poder:

- [ ] Explicar qué es un sistema distribuido
- [ ] Desplegar una aplicación en Kubernetes
- [ ] Configurar Network Policies
- [ ] Entender replicación master-slave
- [ ] Diagnosticar problemas con `kubectl`
- [ ] Escalar aplicaciones horizontalmente
- [ ] Implementar alta disponibilidad
- [ ] Configurar procesamiento asíncrono
- [ ] Demostrar el proyecto ante otros

---

## 📞 Próximos Pasos

### Ahora mismo:

1. **Si quieres instalarlo YA**:
   ```powershell
   .\setup-completo.ps1
   ```

2. **Si quieres entenderlo primero**:
   - Lee: [INICIO-RAPIDO.md](./INICIO-RAPIDO.md)

3. **Si estudian en grupo**:
   - Lean: [GUIA-GRUPO.md](./GUIA-GRUPO.md)
   - Organicen su primera sesión

---

### Después de instalarlo:

1. Lee: [GUIA-ESTUDIO.md](./GUIA-ESTUDIO.md)
2. Experimenta con los comandos
3. Prepara tu demo: [EVALUACION-FINAL.md](./EVALUACION-FINAL.md)

---

## 💡 Consejo Final

> **No te apures.** Este proyecto tiene muchas partes, pero están bien documentadas.
> 
> Tómate el tiempo para entender cada concepto. Si algo no tiene sentido, experimenta con los comandos hasta que lo entiendas.
> 
> ¡Recuerda: La mejor manera de aprender es haciendo (y rompiendo cosas)! 🚀

---

## 📚 Orden de Lectura Recomendado

1. **LEEME-PRIMERO.md** ← Estás aquí ✅
2. **INICIO-RAPIDO.md** o `setup-completo.ps1` (instalar)
3. **VERIFICACION.md** (comprobar que funciona)
4. **GUIA-ESTUDIO.md** (entender conceptos)
5. **GUIA-GRUPO.md** (si aplica)
6. **EVALUACION-FINAL.md** (preparar demo)

---

**¡Mucha suerte con tu estudio!** 🎓

Si tienes dudas, revisa los documentos enlazados. TODO está explicado.
