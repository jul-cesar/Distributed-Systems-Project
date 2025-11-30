Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " VERIFICACION DE LAS 3 REDES" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "[1/3] RED EXTERNA - Acceso desde Internet" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor DarkGray

Write-Host "Service expuesto:" -ForegroundColor Cyan
kubectl get svc spree-frontend -n dmz
Write-Host ""

Write-Host "Detalles del NodePort:" -ForegroundColor Cyan
kubectl describe svc spree-frontend -n dmz | Select-String "Type:|NodePort:|Endpoints:"
Write-Host ""

Write-Host "[2/3] RED DMZ - Comunicacion entre zonas" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor DarkGray

Write-Host "Service Backend (destino):" -ForegroundColor Cyan
kubectl get svc spree-backend -n interna
Write-Host ""

Write-Host "NetworkPolicies de comunicacion:" -ForegroundColor Cyan
kubectl get networkpolicy allow-dmz-to-backend -n interna
kubectl get networkpolicy allow-dmz-egress-to-interna -n dmz
Write-Host ""

Write-Host "[3/3] RED INTERNA - Comunicacion privada" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor DarkGray

Write-Host "Services internos disponibles:" -ForegroundColor Cyan
kubectl get svc -n interna
Write-Host ""

Write-Host "NetworkPolicies de control de acceso:" -ForegroundColor Cyan
kubectl get networkpolicies -n interna
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host " RESUMEN DE REDES" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "RED 1 (Externa): NodePort 30080 -> Frontend" -ForegroundColor White
Write-Host "RED 2 (DMZ): Frontend -> Backend (cross-namespace)" -ForegroundColor White
Write-Host "RED 3 (Interna): Backend -> PostgreSQL/Redis (same namespace)" -ForegroundColor White
Write-Host ""
Write-Host "Total NetworkPolicies activas:" -ForegroundColor Cyan
kubectl get networkpolicies --all-namespaces --no-headers | Measure-Object | Select-Object -ExpandProperty Count | ForEach-Object { Write-Host "  $_  politicas configuradas" -ForegroundColor White }
Write-Host ""
