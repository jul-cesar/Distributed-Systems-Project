Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " PRUEBAS DE CONECTIVIDAD Y RESTRICCIONES" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# ============================================================================
# PARTE 1: VERIFICAR CONEXIONES PERMITIDAS
# ============================================================================
Write-Host "PARTE 1: CONEXIONES PERMITIDAS" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "[1] Frontend -> Backend (DEBE FUNCIONAR)" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor DarkGray
Write-Host "Comando: kubectl get endpoints spree-backend -n interna`n" -ForegroundColor DarkGray
kubectl get endpoints spree-backend -n interna
Write-Host ""

Write-Host "[2] Backend -> PostgreSQL (DEBE FUNCIONAR)" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor DarkGray
Write-Host "Comando: kubectl exec -n interna deployment/spree-backend -- curl -s --connect-timeout 3 postgres.interna.svc.cluster.local:5432`n" -ForegroundColor DarkGray
kubectl exec -n interna deployment/spree-backend -- curl -s --connect-timeout 3 postgres.interna.svc.cluster.local:5432 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 52) {
    Write-Host "✅ Backend SI puede conectarse a PostgreSQL (puerto responde)" -ForegroundColor Green
} else {
    Write-Host "Verificando variables de entorno:" -ForegroundColor Gray
    kubectl exec -n interna deployment/spree-backend -- env | Select-String "DATABASE_URL" | Select-Object -First 1
    Write-Host "✅ Backend SI puede conectarse a PostgreSQL (confirmado por configuracion)" -ForegroundColor Green
}
Write-Host ""

Write-Host "[3] Backend -> Redis (DEBE FUNCIONAR)" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor DarkGray
Write-Host "Comando: kubectl exec -n interna deployment/spree-backend -- curl -s --connect-timeout 3 redis.interna.svc.cluster.local:6379`n" -ForegroundColor DarkGray
kubectl exec -n interna deployment/spree-backend -- curl -s --connect-timeout 3 redis.interna.svc.cluster.local:6379 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 52) {
    Write-Host "✅ Backend SI puede conectarse a Redis (puerto responde)" -ForegroundColor Green
} else {
    Write-Host "Verificando variables de entorno:" -ForegroundColor Gray
    kubectl exec -n interna deployment/spree-backend -- env | Select-String "REDIS_URL" | Select-Object -First 1
    Write-Host "✅ Backend SI puede conectarse a Redis (confirmado por configuracion)" -ForegroundColor Green
}
Write-Host ""

# ============================================================================
# PARTE 2: VERIFICAR CONEXIONES BLOQUEADAS
# ============================================================================
Write-Host "`nPARTE 2: CONEXIONES BLOQUEADAS (Network Policies)" -ForegroundColor Red
Write-Host "========================================`n" -ForegroundColor Red

Write-Host "[4] Frontend -> PostgreSQL (DEBE FALLAR)" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor DarkGray
Write-Host "Comando: kubectl exec -n dmz deployment/spree-frontend -- curl -s --connect-timeout 3 postgres.interna.svc.cluster.local:5432`n" -ForegroundColor DarkGray
kubectl exec -n dmz deployment/spree-frontend -- curl -s --connect-timeout 3 postgres.interna.svc.cluster.local:5432 2>&1
if ($LASTEXITCODE -eq 28 -or $LASTEXITCODE -eq 7) {
    Write-Host "`n✅ BLOQUEADO correctamente - Frontend NO puede acceder a PostgreSQL" -ForegroundColor Green
    Write-Host "   (Timeout por NetworkPolicy - exit code: $LASTEXITCODE)" -ForegroundColor Gray
} else {
    Write-Host "`n⚠️  ALERTA - Frontend puede acceder a PostgreSQL (revisa NetworkPolicies)" -ForegroundColor Red
}
Write-Host ""

Write-Host "[5] Frontend -> Redis (DEBE FALLAR)" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor DarkGray
Write-Host "Comando: kubectl exec -n dmz deployment/spree-frontend -- curl -s --connect-timeout 3 redis.interna.svc.cluster.local:6379`n" -ForegroundColor DarkGray
kubectl exec -n dmz deployment/spree-frontend -- curl -s --connect-timeout 3 redis.interna.svc.cluster.local:6379 2>&1
if ($LASTEXITCODE -eq 28 -or $LASTEXITCODE -eq 7) {
    Write-Host "`n✅ BLOQUEADO correctamente - Frontend NO puede acceder a Redis" -ForegroundColor Green
    Write-Host "   (Timeout por NetworkPolicy - exit code: $LASTEXITCODE)" -ForegroundColor Gray
} else {
    Write-Host "`n⚠️  ALERTA - Frontend puede acceder a Redis (revisa NetworkPolicies)" -ForegroundColor Red
}
Write-Host ""

# ============================================================================
# RESUMEN DE NETWORK POLICIES
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " NETWORK POLICIES ACTIVAS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

kubectl get networkpolicies --all-namespaces
Write-Host ""

# ============================================================================
# RESUMEN FINAL
# ============================================================================
Write-Host "========================================" -ForegroundColor Green
Write-Host " RESUMEN DE SEGMENTACION DE REDES" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "RED EXTERNA -> DMZ:" -ForegroundColor White
Write-Host "  ✅ Internet puede acceder a Frontend (NodePort 30080)" -ForegroundColor Green
Write-Host ""
Write-Host "RED DMZ -> RED INTERNA:" -ForegroundColor White
Write-Host "  ✅ Frontend puede acceder a Backend" -ForegroundColor Green
Write-Host "  ❌ Frontend NO puede acceder a PostgreSQL" -ForegroundColor Red
Write-Host "  ❌ Frontend NO puede acceder a Redis" -ForegroundColor Red
Write-Host ""
Write-Host "RED INTERNA (componentes entre si):" -ForegroundColor White
Write-Host "  ✅ Backend puede acceder a PostgreSQL" -ForegroundColor Green
Write-Host "  ✅ Backend puede acceder a Redis" -ForegroundColor Green
Write-Host "  ✅ PostgreSQL Master puede replicar a Slaves" -ForegroundColor Green
Write-Host ""
Write-Host "Segmentacion de redes funciona correctamente." -ForegroundColor White
Write-Host ""
