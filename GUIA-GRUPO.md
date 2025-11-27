# 👥 Guía para Estudiar en Grupo

**Cómo estudiar este proyecto con compañeros de forma efectiva**

---

## 📚 Plan de Estudio Sugerido

### Sesión 1: Setup y Primera Ejecución (2-3 horas)

**Objetivo**: Tener el proyecto corriendo en todos los equipos

#### Opción A: Setup Automático (Recomendado)
```powershell
.\setup-completo.ps1
```

#### Opción B: Setup Manual
Seguir la guía: **[INICIO-RAPIDO.md](./INICIO-RAPIDO.md)**

#### Al final de la sesión, todos deben poder:
- [ ] Ver los 3 nodos del cluster
- [ ] Acceder a http://localhost:30080
- [ ] Hacer login en /admin
- [ ] Ver productos en la tienda

---

### Sesión 2: Entender la Arquitectura (2-3 horas)

**Objetivo**: Comprender cómo funcionan los componentes

#### Actividades:

1. **Leer juntos**: [GUIA-ESTUDIO.md](./GUIA-ESTUDIO.md)
   - Una persona lee en voz alta cada concepto
   - Discutan en grupo si tienen dudas

2. **Explorar el cluster**:
   ```powershell
   # Cada persona ejecuta estos comandos y comparte qué ve
   kubectl get nodes -o wide
   kubectl get pods -A -o wide
   kubectl get svc -A
   kubectl get networkpolicies -A
   ```

3. **Dibujar la arquitectura** en una pizarra/papel:
   - Nodos
   - Namespaces
   - Pods
   - Servicios
   - Network Policies

#### División de temas (uno por persona):

| Persona | Tema a Investigar | Presentar al grupo (15 min) |
|---------|-------------------|------------------------------|
| 1 | Namespaces y NodeSelector | ¿Por qué separar DMZ e interna? |
| 2 | Network Policies | ¿Cómo funciona el firewall? |
| 3 | Replicación y Alta Disponibilidad | ¿Por qué 3 réplicas? |
| 4 | PostgreSQL Replication | Master-Slave, ¿cómo funciona? |
| 5 | Sidekiq y Redis | Procesamiento asíncrono |

---

### Sesión 3: Experimentar y Romper Cosas (2-3 horas)

**Objetivo**: Aprender experimentando

#### Experimentos sugeridos:

##### Experimento 1: Eliminar un pod
```powershell
# Persona 1: Elimina un pod del frontend
kubectl delete pod -n dmz <nombre-pod> --force --grace-period=0

# Persona 2: Observa qué pasa
kubectl get pods -n dmz -w

# Persona 3: Intenta acceder a la app
# ¿Sigue funcionando?
```

**Discutir**: ¿Por qué Kubernetes recrea el pod?

---

##### Experimento 2: Escalar réplicas
```powershell
# Reducir a 1
kubectl scale deployment spree-backend -n interna --replicas=1

# Aumentar a 5
kubectl scale deployment spree-backend -n interna --replicas=5

# Ver el proceso
kubectl get pods -n interna -w
```

**Discutir**: ¿Cómo distribuye Kubernetes los pods?

---

##### Experimento 3: Romper una Network Policy
```powershell
# Eliminar la política que permite DMZ→Backend
kubectl delete networkpolicy allow-dmz-to-backend -n interna

# Intentar acceder a la app
# ¿Funciona?

# Restaurar
kubectl apply -f np-allow-dmz-to-backend.yaml
```

**Discutir**: ¿Qué mensaje de error aparece?

---

##### Experimento 4: Probar replicación de BD
```powershell
# Persona 1: Insertar dato en el master
kubectl exec -it -n interna postgres-master-0 -- psql -U postgres -d spreedb
CREATE TABLE test_grupo (id serial, mensaje text, created_at timestamp);
INSERT INTO test_grupo (mensaje, created_at) VALUES ('Hola desde master', NOW());
\q

# Persona 2: Verificar en la réplica
kubectl exec -it -n interna postgres-slave-0 -- psql -U postgres -d spreedb
SELECT * FROM test_grupo;
\q
```

**Discutir**: ¿Apareció el dato? ¿Fue instantáneo?

---

##### Experimento 5: Monitorear logs en tiempo real
```powershell
# Cada persona abre una terminal diferente:

# Terminal 1: Logs del frontend
kubectl logs -n dmz -l app=spree-frontend --tail=10 -f

# Terminal 2: Logs del backend
kubectl logs -n interna -l app=spree-backend --tail=10 -f

# Terminal 3: Logs de PostgreSQL
kubectl logs -n interna postgres-master-0 --tail=10 -f

# Terminal 4: Hacer requests a la app desde el navegador
# Observar qué logs aparecen en cada terminal
```

**Discutir**: ¿Qué componente registra cada acción?

---

### Sesión 4: Preparar la Presentación (2-3 horas)

**Objetivo**: Documentar y preparar demo

#### Tareas:

1. **Dividir comandos de demostración** entre todos:
   - Ver: [EVALUACION-FINAL.md](./EVALUACION-FINAL.md)
   - Cada persona practica su parte

2. **Crear un script de demostración**:
   ```
   Persona 1: Mostrar arquitectura (kubectl get nodes, pods)
   Persona 2: Explicar Network Policies (kubectl get/describe)
   Persona 3: Demo de alta disponibilidad (eliminar pod)
   Persona 4: Demo de replicación PostgreSQL
   Persona 5: Demo de procesamiento asíncrono (Sidekiq)
   ```

3. **Preparar capturas de pantalla**:
   - Arquitectura completa (`kubectl get pods -A -o wide`)
   - Network Policies (`kubectl get networkpolicies -A`)
   - Replicación (`pg_stat_replication`)
   - Storefront funcionando
   - Admin panel

4. **Grabar la demo** (opcional):
   - Usar OBS Studio o similar
   - 10-15 minutos mostrando todo

---

## 🎯 División de Responsabilidades

### Por Componente

| Componente | Responsable | Debe saber explicar |
|------------|-------------|---------------------|
| Frontend (Nginx) | Persona 1 | Proxy reverso, routing, load balancing |
| Backend (Rails) | Persona 2 | API, lógica de negocio, conexión a BD |
| PostgreSQL | Persona 3 | Replicación master-slave, queries |
| Redis + Sidekiq | Persona 4 | Colas de mensajes, jobs asíncronos |
| Network Policies | Persona 5 | Firewall, segmentación, seguridad |

### Por Concepto Teórico

| Concepto | Responsable | Debe preparar |
|----------|-------------|---------------|
| Sistemas Distribuidos (teoría) | Persona 1 | Definición, características, ejemplos |
| Kubernetes (orquestación) | Persona 2 | Pods, Services, Deployments |
| Alta Disponibilidad | Persona 3 | Réplicas, load balancing, failover |
| Seguridad de Red | Persona 4 | DMZ, Network Policies, zero-trust |
| Replicación de Datos | Persona 5 | Master-slave, consistencia, CAP |

---

## 📝 Template para Notas Individuales

Cada persona debe llevar su propio documento con:

```markdown
# Mis Notas - Proyecto Sistemas Distribuidos

## Componente asignado: [Nombre]

### ¿Qué hace?
- ...

### ¿Cómo funciona?
- ...

### Comandos importantes
```bash
# Listar aquí
```

### Problemas que encontré
1. ...
2. ...

### Soluciones
1. ...
2. ...

### Preguntas para el grupo
- ¿...?
- ¿...?

### Para la demo
- Mostrar: ...
- Explicar: ...
- Comandos a ejecutar: ...
```

---

## 💡 Estrategias de Estudio Efectivas

### 1. Pair Programming
- 2 personas por computadora
- Uno escribe comandos, el otro explica qué hace
- Rotar cada 15 minutos

### 2. Stand-ups Diarios
Si trabajan varios días:
- Reunión de 10 min al inicio
- Cada uno cuenta: ¿Qué entendí ayer? ¿Qué no entiendo? ¿Qué voy a estudiar hoy?

### 3. Enseñar para Aprender
- Cada persona prepara una mini-clase de 10 minutos sobre su tema
- Explica al grupo como si nadie supiera nada
- El resto hace preguntas

### 4. Debugging en Grupo
- Cuando alguien tiene un problema, TODOS intentan resolverlo
- Aprenden juntos a:
  - Leer logs
  - Interpretar errores
  - Buscar soluciones

---

## 🚨 Errores Comunes al Estudiar en Grupo

### ❌ Error 1: Solo una persona hace todo
**Solución**: Rotar quién ejecuta los comandos cada 15-20 min

### ❌ Error 2: Cada uno va a su ritmo
**Solución**: Avanzar juntos, esperar a que todos completen cada paso

### ❌ Error 3: No documentar lo que aprenden
**Solución**: Crear un Google Doc compartido con notas de cada sesión

### ❌ Error 4: No hacer preguntas
**Solución**: Regla: "No hay preguntas tontas". Si no entiendes, pregunta.

### ❌ Error 5: Copiar sin entender
**Solución**: Antes de ejecutar un comando, discutir qué hace

---

## 📊 Checklist por Sesión

### Sesión 1 Completada ✅
- [ ] Todos tienen el cluster corriendo
- [ ] Todos pueden acceder a la app
- [ ] Todos ejecutaron los comandos básicos
- [ ] Tomaron capturas de pantalla

### Sesión 2 Completada ✅
- [ ] Leyeron GUIA-ESTUDIO.md
- [ ] Dibujaron la arquitectura
- [ ] Cada uno presentó su tema
- [ ] Resolvieron dudas en grupo

### Sesión 3 Completada ✅
- [ ] Ejecutaron todos los experimentos
- [ ] Documentaron resultados
- [ ] Entendieron cómo funciona cada componente
- [ ] Identificaron áreas que necesitan repasar

### Sesión 4 Completada ✅
- [ ] Dividieron la demo
- [ ] Cada uno practicó su parte
- [ ] Tomaron todas las capturas necesarias
- [ ] Prepararon el script de presentación

---

## 🎓 Recursos Compartidos

### Crea una carpeta compartida (Google Drive / OneDrive) con:

```
ProyectoGrupo/
├── Capturas/
│   ├── arquitectura.png
│   ├── network-policies.png
│   ├── replicacion.png
│   └── ...
├── Notas/
│   ├── sesion1-notes.md
│   ├── sesion2-notes.md
│   └── ...
├── Videos/
│   ├── demo-completa.mp4
│   └── experimentos.mp4
└── Documentos/
    ├── script-presentacion.md
    └── preguntas-frecuentes.md
```

---

## 🗣️ Preguntas para Discutir en Grupo

### Arquitectura
- ¿Por qué usar Kubernetes en lugar de Docker Compose?
- ¿Cuándo usarías 1 vs 3 vs 10 réplicas?
- ¿Qué pasa si un nodo completo falla?

### Seguridad
- ¿Por qué separar DMZ e interna?
- ¿Qué pasaría si no hubiera Network Policies?
- ¿Cómo proteges secrets en producción?

### Datos
- ¿Por qué replicar la base de datos?
- ¿Qué pasa si el master de PostgreSQL falla?
- ¿Cómo garantizas consistencia en lecturas?

### Práctica
- ¿Qué comandos usas para diagnosticar un problema?
- ¿Cómo escalarías esto a 100 nodos?
- ¿Qué mejorarías en la arquitectura?

---

## 📞 Contacto y Coordinación

### Herramientas recomendadas:
- **Discord/Slack**: Chat en tiempo real
- **Google Docs**: Notas compartidas
- **Trello**: Tablero de tareas
- **Zoom/Meet**: Sesiones virtuales

### Roles sugeridos:
- **Coordinador**: Organiza sesiones, lleva agenda
- **Documentador**: Toma notas, actualiza Google Docs
- **Debugger**: Lidera solución de problemas
- **Presentador**: Coordina la demo final

---

## ✅ Checklist Final de Grupo

Antes de la entrega/presentación:

- [ ] Todos entienden la arquitectura completa
- [ ] Cada persona puede explicar su componente
- [ ] Han practicado la demo al menos 2 veces
- [ ] Tienen todas las capturas de pantalla
- [ ] Prepararon respuestas a preguntas frecuentes
- [ ] Revisaron la rúbrica ([EVALUACION-FINAL.md](./EVALUACION-FINAL.md))
- [ ] Probaron el proyecto en al menos 2 computadoras diferentes

---

**¡Éxito en su proyecto!** 🚀

Recuerden: El objetivo no es solo que funcione, sino que **ENTIENDAN cómo y por qué funciona**.
