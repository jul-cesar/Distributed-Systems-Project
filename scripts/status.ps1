#!/usr/bin/env pwsh
# Script para verificar el estado de todos los componentes

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  Estado del Cluster Kubernetes" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Verificar cluster
Write-Host "📦 Nodos del Cluster:" -ForegroundColor Yellow
kubectl get nodes -o wide
Write-Host ""

# Namespace DMZ
Write-Host "🌐 Namespace DMZ (Frontend):" -ForegroundColor Yellow
kubectl get pods,svc -n dmz
Write-Host ""

# Namespace Interna
Write-Host "🔒 Namespace Interna (Backend, DB, Cache):" -ForegroundColor Yellow
kubectl get pods,svc -n interna
Write-Host ""

# NetworkPolicies
Write-Host "🔥 NetworkPolicies (Firewall):" -ForegroundColor Yellow
Write-Host "DMZ:" -ForegroundColor Gray
kubectl get networkpolicies -n dmz
Write-Host "Interna:" -ForegroundColor Gray
kubectl get networkpolicies -n interna
Write-Host ""

# Calico
Write-Host "🛡️  Calico (CNI):" -ForegroundColor Yellow
kubectl get pods -n kube-system -l k8s-app=calico-node
Write-Host ""

# PVCs
Write-Host "💾 Persistent Volume Claims:" -ForegroundColor Yellow
kubectl get pvc -n interna
Write-Host ""

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Para acceder: http://localhost:30080" -ForegroundColor White
Write-Host "=====================================" -ForegroundColor Cyan
