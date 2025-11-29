#!/usr/bin/env pwsh
# Script para eliminar toda la aplicación de Kubernetes

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  Eliminando Spree Commerce de K8s" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Advertencia
Write-Host "⚠️  ADVERTENCIA: Esto eliminará todos los recursos del cluster" -ForegroundColor Red
$confirm = Read-Host "¿Continuar? (s/n)"
if ($confirm -ne "s") {
    Write-Host "Operación cancelada" -ForegroundColor Yellow
    exit 0
}

# 1. Eliminar Frontend
Write-Host "[1/5] Eliminando Frontend..." -ForegroundColor Yellow
kubectl delete -f ../k8s/base/frontend/ --ignore-not-found=true
Write-Host "✅ Frontend eliminado" -ForegroundColor Green

# 2. Eliminar Backend
Write-Host "[2/5] Eliminando Backend..." -ForegroundColor Yellow
kubectl delete -f ../k8s/base/backend/ --ignore-not-found=true
Write-Host "✅ Backend eliminado" -ForegroundColor Green

# 3. Eliminar Cache
Write-Host "[3/5] Eliminando Redis..." -ForegroundColor Yellow
kubectl delete -f ../k8s/base/cache/ --ignore-not-found=true
Write-Host "✅ Redis eliminado" -ForegroundColor Green

# 4. Eliminar Base de Datos
Write-Host "[4/5] Eliminando PostgreSQL..." -ForegroundColor Yellow
kubectl delete -f ../k8s/base/database/ --ignore-not-found=true
Write-Host "✅ PostgreSQL eliminado" -ForegroundColor Green

# 5. Eliminar NetworkPolicies
Write-Host "[5/5] Eliminando NetworkPolicies..." -ForegroundColor Yellow
kubectl delete -f ../k8s/base/network/ --ignore-not-found=true
Write-Host "✅ NetworkPolicies eliminadas" -ForegroundColor Green

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  ✅ Limpieza Completada" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
