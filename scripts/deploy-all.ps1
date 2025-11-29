#!/usr/bin/env pwsh
# Script para desplegar toda la aplicación en Kubernetes

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  Desplegando Spree Commerce en K8s" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# 1. Verificar que el cluster está corriendo
Write-Host "[1/6] Verificando cluster Minikube..." -ForegroundColor Yellow
$status = minikube status -p proyectosd 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error: Cluster no está corriendo. Ejecuta: minikube start -p proyectosd" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Cluster corriendo" -ForegroundColor Green
Write-Host ""

# 2. Crear namespaces
Write-Host "[2/6] Creando namespaces..." -ForegroundColor Yellow
kubectl create namespace dmz --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace interna --dry-run=client -o yaml | kubectl apply -f -
Write-Host "✅ Namespaces creados" -ForegroundColor Green
Write-Host ""

# 3. Desplegar Base de Datos
Write-Host "[3/6] Desplegando PostgreSQL..." -ForegroundColor Yellow
kubectl apply -f ../k8s/base/database/
Write-Host "✅ PostgreSQL desplegado" -ForegroundColor Green
Write-Host ""

# 4. Desplegar Cache
Write-Host "[4/6] Desplegando Redis..." -ForegroundColor Yellow
kubectl apply -f ../k8s/base/cache/
Write-Host "✅ Redis desplegado" -ForegroundColor Green
Write-Host ""

# 5. Desplegar Backend
Write-Host "[5/6] Desplegando Backend..." -ForegroundColor Yellow
Start-Sleep -Seconds 10  # Esperar a que DB esté lista
kubectl apply -f ../k8s/base/backend/
Write-Host "✅ Backend desplegado" -ForegroundColor Green
Write-Host ""

# 6. Desplegar Frontend
Write-Host "[6/6] Desplegando Frontend..." -ForegroundColor Yellow
kubectl apply -f ../k8s/base/frontend/
Write-Host "✅ Frontend desplegado" -ForegroundColor Green
Write-Host ""

# 7. Aplicar NetworkPolicies
Write-Host "[7/7] Aplicando NetworkPolicies (Firewall)..." -ForegroundColor Yellow
kubectl apply -f ../k8s/base/network/
Write-Host "✅ NetworkPolicies aplicadas" -ForegroundColor Green
Write-Host ""

# Resumen
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  ✅ Despliegue Completado" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para ver el estado de los pods:" -ForegroundColor White
Write-Host "  kubectl get pods -n dmz" -ForegroundColor Gray
Write-Host "  kubectl get pods -n interna" -ForegroundColor Gray
Write-Host ""
Write-Host "Para acceder a la aplicación:" -ForegroundColor White
Write-Host "  http://localhost:30080" -ForegroundColor Gray
Write-Host ""
