Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " VERIFICACION COMPLETA DE ARQUITECTURA" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "[1/8] NODOS DEL CLUSTER (3 esperados)" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor DarkGray
kubectl get nodes
Write-Host ""

Write-Host ""

Write-Host "[2/8] NAMESPACES - Zonas de seguridad" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor DarkGray
kubectl get namespaces | Select-String "dmz|interna"
Write-Host ""

Write-Host "[3/8] COMPONENTES EN ZONA DMZ (publica)" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor DarkGray
kubectl get all -n dmz
Write-Host ""

Write-Host "[4/8] COMPONENTES EN ZONA INTERNA (privada)" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor DarkGray
kubectl get all -n interna
Write-Host ""

Write-Host "[5/8] NETWORK POLICIES - Reglas de firewall" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor DarkGray
kubectl get networkpolicies --all-namespaces
Write-Host ""

Write-Host "[6/8] PERSISTENT VOLUMES - Almacenamiento" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor DarkGray
kubectl get pvc -n interna
Write-Host ""

Write-Host "[7/8] UBICACION FISICA - Zona DMZ (nodo proyectosd-m02)" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor DarkGray
kubectl get pods -n dmz -o wide
Write-Host ""

Write-Host "[8/8] UBICACION FISICA - Zona INTERNA (nodo proyectosd-m03)" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor DarkGray
kubectl get pods -n interna -o wide
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host " VERIFICACION COMPLETADA" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
