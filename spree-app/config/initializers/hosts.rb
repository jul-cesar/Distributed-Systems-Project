# Configuración de hosts permitidos para producción en Kubernetes
# Esto previene el error "Blocked host" cuando se accede a través del proxy

Rails.application.configure do
  # En producción, configurar los hosts permitidos
  if Rails.env.production?
    # Permitir acceso desde el frontend/proxy
    config.hosts << "www.proyectosd.com"
    config.hosts << "spree-backend.interna.svc.cluster.local"
    config.hosts << "spree-frontend.dmz.svc.cluster.local"
    config.hosts << "localhost"
    
    # También puedes usar esto para permitir todos (menos seguro pero útil para debug)
    # config.hosts.clear
    
    # O usar ENV variable
    if ENV['TRUSTED_HOSTS'].present?
      ENV['TRUSTED_HOSTS'].split(',').each do |host|
        config.hosts << host.strip
      end
    end
  end
end
