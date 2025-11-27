# Script de Setup Automático - Proyecto Sistemas Distribuidos
# Ejecutar con: .\setup-completo.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SETUP AUTOMÁTICO - PROYECTO SD" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Función para verificar comando
function Test-Command {
    param($Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

# Función para esperar pods
function Wait-PodsReady {
    param(
        [string]$Namespace,
        [string]$Label,
        [int]$ExpectedCount,
        [int]$TimeoutSeconds = 300
    )
    
    Write-Host "⏳ Esperando $ExpectedCount pods con label '$Label' en namespace '$Namespace'..." -ForegroundColor Yellow
    
    $elapsed = 0
    while ($elapsed -lt $TimeoutSeconds) {
        $readyPods = (kubectl get pods -n $Namespace -l $Label --no-headers 2>$null | Where-Object { $_ -match "Running" }).Count
        
        if ($readyPods -ge $ExpectedCount) {
            Write-Host "✅ $readyPods/$ExpectedCount pods listos" -ForegroundColor Green
            return $true
        }
        
        Write-Host "   $readyPods/$ExpectedCount pods listos... esperando" -ForegroundColor Gray
        Start-Sleep -Seconds 5
        $elapsed += 5
    }
    
    Write-Host "❌ Timeout esperando pods" -ForegroundColor Red
    return $false
}

# ============================================
# PASO 1: Verificar requisitos
# ============================================

Write-Host "PASO 1: Verificando requisitos..." -ForegroundColor Cyan
Write-Host ""

$requirements = @{
    "minikube" = "Minikube"
    "kubectl" = "Kubectl"
    "docker" = "Docker"
}

$allGood = $true
foreach ($cmd in $requirements.Keys) {
    if (Test-Command $cmd) {
        Write-Host "✅ $($requirements[$cmd]) instalado" -ForegroundColor Green
    } else {
        Write-Host "❌ $($requirements[$cmd]) NO encontrado" -ForegroundColor Red
        $allGood = $false
    }
}

if (-not $allGood) {
    Write-Host ""
    Write-Host "Por favor instala las herramientas faltantes antes de continuar." -ForegroundColor Red
    Write-Host "Ver: https://minikube.sigs.k8s.io/docs/start/" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# ============================================
# PASO 2: Levantar cluster Minikube
# ============================================

Write-Host "PASO 2: Levantando cluster Minikube (3 nodos)..." -ForegroundColor Cyan
Write-Host "⏳ Esto puede tardar 3-5 minutos..." -ForegroundColor Yellow
Write-Host ""

# Verificar si ya existe
$existing = minikube status -p proyectosd 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "⚠️  Cluster 'proyectosd' ya existe" -ForegroundColor Yellow
    $response = Read-Host "¿Quieres eliminarlo y recrearlo? (s/N)"
    if ($response -eq 's' -or $response -eq 'S') {
        Write-Host "🗑️  Eliminando cluster existente..." -ForegroundColor Yellow
        minikube delete -p proyectosd
    } else {
        Write-Host "✅ Usando cluster existente" -ForegroundColor Green
    }
}

# Iniciar cluster
if ($LASTEXITCODE -ne 0) {
    minikube start -p proyectosd --nodes 3 --cpus 2 --memory 4096 --driver=docker
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error al iniciar Minikube" -ForegroundColor Red
        exit 1
    }
}

Write-Host "✅ Cluster iniciado" -ForegroundColor Green
Write-Host ""

# Verificar nodos
Write-Host "Nodos del cluster:" -ForegroundColor Cyan
kubectl get nodes
Write-Host ""

# ============================================
# PASO 3: Etiquetar nodos
# ============================================

Write-Host "PASO 3: Etiquetando nodos..." -ForegroundColor Cyan
Write-Host ""

kubectl label node proyectosd-m02 zona=dmz --overwrite
kubectl label node proyectosd-m03 zona=interna --overwrite

Write-Host "✅ Nodos etiquetados" -ForegroundColor Green
Write-Host ""

# ============================================
# PASO 4: Crear namespaces
# ============================================

Write-Host "PASO 4: Creando namespaces..." -ForegroundColor Cyan
Write-Host ""

kubectl create namespace dmz --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace interna --dry-run=client -o yaml | kubectl apply -f -

Write-Host "✅ Namespaces creados" -ForegroundColor Green
Write-Host ""

# ============================================
# PASO 5: Construir imagen Docker
# ============================================

Write-Host "PASO 5: Construyendo imagen Docker..." -ForegroundColor Cyan
Write-Host "⏳ Esto puede tardar 5-10 minutos..." -ForegroundColor Yellow
Write-Host ""

# Configurar Docker para usar Minikube
& minikube -p proyectosd docker-env --shell powershell | Invoke-Expression

# Construir imagen
Push-Location spree-app
docker build -t spree-custom:latest .
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error al construir imagen" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

Write-Host "✅ Imagen construida" -ForegroundColor Green
Write-Host ""

# ============================================
# PASO 6: Desplegar PostgreSQL
# ============================================

Write-Host "PASO 6: Desplegando PostgreSQL (master + réplicas)..." -ForegroundColor Cyan
Write-Host ""

kubectl apply -f postgres-config.yaml
kubectl apply -f postgres-replication-secret.yaml
kubectl apply -f postgres-master-statefulset.yaml

Write-Host "⏳ Esperando a que el master esté listo..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod/postgres-master-0 -n interna --timeout=300s

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error esperando PostgreSQL master" -ForegroundColor Red
    exit 1
}

kubectl apply -f postgres-slave-statefulset.yaml
kubectl apply -f postgres-services.yaml
kubectl apply -f postgres-replication-netpol.yaml

Write-Host "✅ PostgreSQL desplegado" -ForegroundColor Green
Write-Host ""

# ============================================
# PASO 7: Migrar base de datos
# ============================================

Write-Host "PASO 7: Ejecutando migraciones de BD..." -ForegroundColor Cyan
Write-Host ""

kubectl apply -f spree-migrate-job.yaml

Write-Host "⏳ Esperando a que las migraciones completen..." -ForegroundColor Yellow
kubectl wait --for=condition=complete job/spree-migrate -n interna --timeout=300s

if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Migraciones fallaron o tardaron mucho" -ForegroundColor Yellow
    Write-Host "Ver logs con: kubectl logs -n interna job/spree-migrate" -ForegroundColor Gray
} else {
    Write-Host "✅ Migraciones completadas" -ForegroundColor Green
}
Write-Host ""

# ============================================
# PASO 8: Desplegar Redis
# ============================================

Write-Host "PASO 8: Desplegando Redis..." -ForegroundColor Cyan
Write-Host ""

kubectl apply -f redis-deploy.yaml
kubectl apply -f redis-service.yaml

if (Wait-PodsReady -Namespace "interna" -Label "app=redis" -ExpectedCount 1 -TimeoutSeconds 120) {
    Write-Host "✅ Redis desplegado" -ForegroundColor Green
} else {
    Write-Host "⚠️  Redis no está listo aún" -ForegroundColor Yellow
}
Write-Host ""

# ============================================
# PASO 9: Desplegar Backend
# ============================================

Write-Host "PASO 9: Desplegando Backend (Rails/Spree)..." -ForegroundColor Cyan
Write-Host ""

kubectl apply -f spree-backend-deploy.yaml
kubectl apply -f spree-backend-service.yaml

if (Wait-PodsReady -Namespace "interna" -Label "app=spree-backend" -ExpectedCount 3 -TimeoutSeconds 300) {
    Write-Host "✅ Backend desplegado" -ForegroundColor Green
} else {
    Write-Host "⚠️  Backend no está listo aún" -ForegroundColor Yellow
}
Write-Host ""

# ============================================
# PASO 10: Desplegar Frontend
# ============================================

Write-Host "PASO 10: Desplegando Frontend (Nginx)..." -ForegroundColor Cyan
Write-Host ""

kubectl apply -f frontend-configmap.yaml
kubectl apply -f frontend-deploy.yaml
kubectl apply -f frontend-service.yaml

if (Wait-PodsReady -Namespace "dmz" -Label "app=spree-frontend" -ExpectedCount 3 -TimeoutSeconds 300) {
    Write-Host "✅ Frontend desplegado" -ForegroundColor Green
} else {
    Write-Host "⚠️  Frontend no está listo aún" -ForegroundColor Yellow
}
Write-Host ""

# ============================================
# PASO 11: Aplicar Network Policies
# ============================================

Write-Host "PASO 11: Aplicando Network Policies..." -ForegroundColor Cyan
Write-Host ""

kubectl apply -f np-interna-default-deny.yaml
kubectl apply -f np-allow-backend-to-db-redis.yaml
kubectl apply -f np-allow-dmz-to-backend.yaml

Write-Host "✅ Network Policies aplicadas" -ForegroundColor Green
Write-Host ""

# ============================================
# PASO 12: Crear usuario admin
# ============================================

Write-Host "PASO 12: Creando usuario admin..." -ForegroundColor Cyan
Write-Host ""

$createAdminScript = @"
user = Spree::User.find_or_create_by(email: 'admin@example.com') do |u|
  u.password = 'admin123456'
  u.password_confirmation = 'admin123456'
end
role = Spree::Role.find_or_create_by(name: 'admin')
user.spree_roles << role unless user.spree_roles.include?(role)
user.save!
puts 'Admin creado: ' + user.email
"@

$backendPod = (kubectl get pods -n interna -l app=spree-backend -o jsonpath='{.items[0].metadata.name}' 2>$null)

if ($backendPod) {
    kubectl exec -n interna $backendPod -- bin/rails runner $createAdminScript 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Admin creado: admin@example.com / admin123456" -ForegroundColor Green
    } else {
        Write-Host "⚠️  No se pudo crear admin automáticamente" -ForegroundColor Yellow
        Write-Host "   Crea manualmente con: kubectl exec -it -n interna deployment/spree-backend -- bin/rails console" -ForegroundColor Gray
    }
} else {
    Write-Host "⚠️  No se encontró pod del backend" -ForegroundColor Yellow
}
Write-Host ""

# ============================================
# PASO 13: Activar productos
# ============================================

Write-Host "PASO 13: Activando productos..." -ForegroundColor Cyan
Write-Host ""

if ($backendPod) {
    $activateScript = "Spree::Product.update_all(status: 'active', available_on: Time.current); puts 'Productos activados: ' + Spree::Product.active.count.to_s"
    kubectl exec -n interna $backendPod -- bin/rails runner $activateScript 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Productos activados" -ForegroundColor Green
    } else {
        Write-Host "⚠️  No hay productos aún (normal en primera instalación)" -ForegroundColor Yellow
    }
}
Write-Host ""

# ============================================
# RESUMEN FINAL
# ============================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  ✅ SETUP COMPLETADO CON ÉXITO" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "📊 Estado del cluster:" -ForegroundColor Cyan
Write-Host ""
kubectl get pods -A -o wide
Write-Host ""

Write-Host "🌐 Para acceder a la aplicación:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. En una nueva terminal, ejecuta:" -ForegroundColor Yellow
Write-Host "   kubectl port-forward --address 0.0.0.0 service/spree-frontend 30080:80 -n dmz" -ForegroundColor White
Write-Host ""
Write-Host "2. Abre tu navegador en:" -ForegroundColor Yellow
Write-Host "   🏪 Tienda:  http://localhost:30080" -ForegroundColor White
Write-Host "   👤 Admin:   http://localhost:30080/admin" -ForegroundColor White
Write-Host "   📊 Sidekiq: http://localhost:30080/sidekiq" -ForegroundColor White
Write-Host ""
Write-Host "3. Credenciales de admin:" -ForegroundColor Yellow
Write-Host "   Email:    admin@example.com" -ForegroundColor White
Write-Host "   Password: admin123456" -ForegroundColor White
Write-Host ""

Write-Host "📚 Siguiente paso:" -ForegroundColor Cyan
Write-Host "   Lee INICIO-RAPIDO.md y GUIA-ESTUDIO.md para entender el proyecto" -ForegroundColor White
Write-Host ""

Write-Host "🔧 Comandos útiles:" -ForegroundColor Cyan
Write-Host "   Ver pods:        kubectl get pods -A" -ForegroundColor Gray
Write-Host "   Ver logs:        kubectl logs -n interna -l app=spree-backend --tail=50 -f" -ForegroundColor Gray
Write-Host "   Ver servicios:   kubectl get svc -A" -ForegroundColor Gray
Write-Host "   Reiniciar:       kubectl rollout restart deployment spree-backend -n interna" -ForegroundColor Gray
Write-Host ""

Write-Host "¡Buena suerte con tu estudio! 🚀" -ForegroundColor Green
Write-Host ""
