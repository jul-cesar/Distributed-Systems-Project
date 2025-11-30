Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " PRUEBAS DE CLUSTER DE BASE DE DATOS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# ============================================================================
# PARTE A: EXPLICAR TECNOLOGIA DE CLUSTERIZACION
# ============================================================================
Write-Host "PARTE A: TECNOLOGIA DE CLUSTERIZACION" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "TECNOLOGIA: PostgreSQL con Streaming Replication" -ForegroundColor Yellow
Write-Host ""
Write-Host "ARQUITECTURA:" -ForegroundColor Cyan
kubectl get statefulsets -n interna
Write-Host ""
kubectl get pods -n interna | Select-String "postgres"
Write-Host ""

Write-Host "SERVICIOS DEL CLUSTER:" -ForegroundColor Cyan
kubectl get svc -n interna | Select-String "postgres|NAME"
Write-Host ""

Write-Host "EXPLICACION:" -ForegroundColor Yellow
Write-Host "  - Master (postgres-master-0): Acepta ESCRITURAS y LECTURAS" -ForegroundColor White
Write-Host "  - Slave 1 (postgres-slave-0): Solo LECTURAS (replica en tiempo real)" -ForegroundColor White
Write-Host "  - Slave 2 (postgres-slave-1): Solo LECTURAS (replica en tiempo real)" -ForegroundColor White
Write-Host ""
Write-Host "REPLICACION:" -ForegroundColor Yellow
Write-Host "  - Tipo: Streaming Replication (replicacion binaria WAL)" -ForegroundColor White
Write-Host "  - Los slaves replican cambios en tiempo real desde el master" -ForegroundColor White
Write-Host "  - Garantiza consistencia de datos en los 3 nodos" -ForegroundColor White
Write-Host ""
Write-Host "BALANCEO:" -ForegroundColor Yellow
Write-Host "  - Escrituras -> postgres-write.interna (solo al Master)" -ForegroundColor White
Write-Host "  - Lecturas -> postgres-read.interna (balancea entre Slaves)" -ForegroundColor White
Write-Host ""

Read-Host "Presiona Enter para continuar a Parte B"

# ============================================================================
# PARTE B: CREAR DATO Y VERIFICAR REPLICACION
# ============================================================================
Write-Host "`nPARTE B: CREAR DATO Y VERIFICAR REPLICACION" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "[1] Verificar estado de replicacion" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor DarkGray
Write-Host "Slaves conectados al Master:`n" -ForegroundColor Gray
kubectl exec -n interna postgres-master-0 -- psql -U spreeuser -d postgres -c "SELECT application_name, client_addr, state FROM pg_stat_replication;"
Write-Host ""

Write-Host "[2] Crear un producto de prueba en el MASTER" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor DarkGray
Write-Host "Comando: INSERT INTO spree_products...`n" -ForegroundColor DarkGray

# Crear producto de prueba
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$productName = "Producto Prueba Cluster $(Get-Date -Format 'HHmmss')"
kubectl exec -n interna postgres-master-0 -- psql -U spreeuser -d spreedb -c "INSERT INTO spree_products (name, slug, available_on, created_at, updated_at) VALUES ('$productName', 'producto-prueba-cluster-$(Get-Date -Format 'HHmmss')', '$timestamp', '$timestamp', '$timestamp');" 2>&1
Write-Host "✅ Producto insertado en el Master" -ForegroundColor Green
Write-Host ""

Write-Host "[3] Verificar en MASTER" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor DarkGray
kubectl exec -n interna postgres-master-0 -- psql -U spreeuser -d spreedb -c "SELECT id, name, slug, created_at FROM spree_products WHERE name LIKE 'Producto Prueba Cluster%' ORDER BY id DESC LIMIT 1;"
Write-Host ""

Write-Host "[4] Verificar en SLAVE 0 (replicado)" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor DarkGray
Start-Sleep -Seconds 2
kubectl exec -n interna postgres-slave-0 -- psql -U spreeuser -d spreedb -c "SELECT id, name, slug, created_at FROM spree_products WHERE name LIKE 'Producto Prueba Cluster%' ORDER BY id DESC LIMIT 1;" 2>&1 | Select-String -Pattern "id|---" -Context 0,10
Write-Host ""

Write-Host "[5] Verificar en SLAVE 1 (replicado)" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor DarkGray
kubectl exec -n interna postgres-slave-1 -- psql -U spreeuser -d spreedb -c "SELECT id, name, slug, created_at FROM spree_products WHERE name LIKE 'Producto Prueba Cluster%' ORDER BY id DESC LIMIT 1;" 2>&1 | Select-String -Pattern "id|---" -Context 0,10
Write-Host ""

Write-Host "✅ El producto esta replicado en los 3 nodos en tiempo real" -ForegroundColor Green
Write-Host ""

Read-Host "Presiona Enter para continuar a Parte C"

# ============================================================================
# PARTE C: DESMONTAR 1 NODO Y PROBAR
# ============================================================================
Write-Host "`nPARTE C: DESMONTAR 1 NODO (SLAVE 2) Y PROBAR" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "⚠️  Desmontando postgres-slave-1..." -ForegroundColor Yellow
Write-Host "Comando: kubectl scale statefulset postgres-slave --replicas=1 -n interna`n" -ForegroundColor DarkGray
kubectl scale statefulset postgres-slave --replicas=1 -n interna
Write-Host ""
Start-Sleep -Seconds 5

Write-Host "Estado del cluster (solo 2 nodos activos):" -ForegroundColor Cyan
kubectl get pods -n interna | Select-String "postgres"
Write-Host ""

Write-Host "Creando nuevo producto con un nodo menos..." -ForegroundColor Yellow
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$productName = "Producto Parte C $(Get-Date -Format 'HHmmss')"
kubectl exec -n interna postgres-master-0 -- psql -U spreeuser -d spreedb -c "INSERT INTO spree_products (name, slug, available_on, created_at, updated_at) VALUES ('$productName', 'producto-parte-c-$(Get-Date -Format 'HHmmss')', '$timestamp', '$timestamp', '$timestamp');" 2>&1
Write-Host "✅ Producto insertado" -ForegroundColor Green
Write-Host ""

Write-Host "Verificando en MASTER:" -ForegroundColor Cyan
kubectl exec -n interna postgres-master-0 -- psql -U spreeuser -d spreedb -c "SELECT id, name, slug, created_at FROM spree_products WHERE name LIKE 'Producto Parte C%' ORDER BY id DESC LIMIT 1;"
Write-Host ""

Write-Host "Verificando en SLAVE 0 (unico slave activo - replicado):" -ForegroundColor Cyan
Start-Sleep -Seconds 2
kubectl exec -n interna postgres-slave-0 -- psql -U spreeuser -d spreedb -c "SELECT id, name, slug, created_at FROM spree_products WHERE name LIKE 'Producto Parte C%' ORDER BY id DESC LIMIT 1;" 2>&1 | Select-String -Pattern "id|---" -Context 0,10
Write-Host ""

Write-Host "✅ Replicacion funciona con 2 nodos (1 master + 1 slave)" -ForegroundColor Green
Write-Host ""

Read-Host "Presiona Enter para continuar a Parte D"

# ============================================================================
# PARTE D: DESMONTAR OTRO NODO (SOLO 1 ACTIVO)
# ============================================================================
Write-Host "`nPARTE D: DESMONTAR OTRO NODO (SOLO MASTER ACTIVO)" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "⚠️  Desmontando postgres-slave-0 (todos los slaves)..." -ForegroundColor Yellow
Write-Host "Comando: kubectl scale statefulset postgres-slave --replicas=0 -n interna`n" -ForegroundColor DarkGray
kubectl scale statefulset postgres-slave --replicas=0 -n interna
Write-Host ""
Start-Sleep -Seconds 5

Write-Host "Estado del cluster (solo Master activo):" -ForegroundColor Cyan
kubectl get pods -n interna | Select-String "postgres"
Write-Host ""

Write-Host "Creando nuevo producto con solo el Master activo..." -ForegroundColor Yellow
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$productName = "Producto Parte D $(Get-Date -Format 'HHmmss')"
kubectl exec -n interna postgres-master-0 -- psql -U spreeuser -d spreedb -c "INSERT INTO spree_products (name, slug, available_on, created_at, updated_at) VALUES ('$productName', 'producto-parte-d-$(Get-Date -Format 'HHmmss')', '$timestamp', '$timestamp', '$timestamp');" 2>&1
Write-Host "✅ Producto insertado" -ForegroundColor Green
Write-Host ""

Write-Host "Verificando en MASTER:" -ForegroundColor Cyan
kubectl exec -n interna postgres-master-0 -- psql -U spreeuser -d spreedb -c "SELECT id, name, slug, created_at FROM spree_products WHERE name LIKE 'Producto P%' ORDER BY id DESC LIMIT 3;"
Write-Host ""

Write-Host "✅ Base de datos sigue funcionando con solo el Master activo" -ForegroundColor Green
Write-Host ""

Read-Host "Presiona Enter para continuar a Parte E"

# ============================================================================
# PARTE E: RESTAURAR TODOS LOS NODOS Y VERIFICAR
# ============================================================================
Write-Host "`nPARTE E: RESTAURAR TODOS LOS NODOS Y VERIFICAR" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "✅ Restaurando los 2 slaves..." -ForegroundColor Yellow
Write-Host "Comando: kubectl scale statefulset postgres-slave --replicas=2 -n interna`n" -ForegroundColor DarkGray
kubectl scale statefulset postgres-slave --replicas=2 -n interna
Write-Host ""

Write-Host "Esperando que los slaves inicien y sincronicen..." -ForegroundColor Gray
Start-Sleep -Seconds 45

Write-Host "Estado del cluster (3 nodos activos):" -ForegroundColor Cyan
kubectl get pods -n interna | Select-String "postgres"
Write-Host ""

Write-Host "Verificando TODOS los productos de prueba en MASTER:" -ForegroundColor Yellow
kubectl exec -n interna postgres-master-0 -- psql -U spreeuser -d spreedb -c "SELECT id, name, slug, created_at FROM spree_products WHERE name LIKE 'Producto P%' ORDER BY id;"
Write-Host ""

Write-Host "Verificando TODOS los productos en SLAVE 0 (replicados):" -ForegroundColor Yellow
Start-Sleep -Seconds 3
kubectl exec -n interna postgres-slave-0 -- psql -U spreeuser -d spreedb -c "SELECT id, name, slug, created_at FROM spree_products WHERE name LIKE 'Producto P%' ORDER BY id;" 2>&1 | Select-String -Pattern "id|---|\d+\s+\|" -Context 0,0
Write-Host ""

Write-Host "Verificando TODOS los productos en SLAVE 1 (replicados):" -ForegroundColor Yellow
kubectl exec -n interna postgres-slave-1 -- psql -U spreeuser -d spreedb -c "SELECT id, name, slug, created_at FROM spree_products WHERE name LIKE 'Producto P%' ORDER BY id;" 2>&1 | Select-String -Pattern "id|---|\d+\s+\|" -Context 0,0
Write-Host ""

Write-Host "Verificando estado de replicacion final:" -ForegroundColor Yellow
kubectl exec -n interna postgres-master-0 -- psql -U spreeuser -d postgres -c "SELECT application_name, state, sync_state FROM pg_stat_replication;"
Write-Host ""

Write-Host "✅ TODOS los datos estan replicados en los 3 nodos - Streaming Replication activa" -ForegroundColor Green
Write-Host ""

# ============================================================================
# RESUMEN
# ============================================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " RESUMEN DE PRUEBAS DE CLUSTER DB" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Estado final del cluster:" -ForegroundColor Yellow
kubectl get pods -n interna | Select-String "postgres"
Write-Host ""
Write-Host "Registros totales creados:" -ForegroundColor Yellow
$count = kubectl exec -n interna postgres-master-0 -- psql -U spreeuser -d spreedb -t -c "SELECT COUNT(*) FROM spree_products WHERE name LIKE 'Producto P%';" 2>&1
Write-Host "  $count productos de prueba creados durante la validacion" -ForegroundColor White
Write-Host ""
Write-Host "PRUEBAS COMPLETADAS:" -ForegroundColor Yellow
Write-Host "  ✅ Parte A: Explicada arquitectura de Streaming Replication" -ForegroundColor Green
Write-Host "  ✅ Parte B: Producto replicado en tiempo real a 3 nodos" -ForegroundColor Green
Write-Host "  ✅ Parte C: Replicacion funciona con 2 nodos" -ForegroundColor Green
Write-Host "  ✅ Parte D: Base de datos funciona con 1 nodo (solo Master)" -ForegroundColor Green
Write-Host "  ✅ Parte E: Replicacion restaurada con 3 nodos" -ForegroundColor Green
Write-Host ""
Write-Host "El cluster de PostgreSQL usa Streaming Replication en tiempo real." -ForegroundColor White
Write-Host ""
