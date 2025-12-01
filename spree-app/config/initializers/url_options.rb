# Configuración de URLs para Kubernetes con NodePort
Rails.application.configure do
  # Configurar el host y puerto para generación de URLs
  config.after_initialize do
    # Obtener configuración desde variables de entorno
    host = ENV.fetch('RAILS_HOST', 'localhost')
    port = ENV.fetch('RAILS_PORT', '30080')
    protocol = ENV.fetch('RAILS_PROTOCOL', 'http')
    
    # Configurar default_url_options para Rails
    Rails.application.routes.default_url_options = {
      host: host,
      port: port,
      protocol: protocol
    }
    
    # Configurar para ActionMailer también
    Rails.application.config.action_mailer.default_url_options = {
      host: host,
      port: port,
      protocol: protocol
    }
    
    # Configurar asset_host si es necesario
    if ENV['ASSET_HOST'].present?
      Rails.application.config.asset_host = ENV['ASSET_HOST']
    else
      Rails.application.config.asset_host = "#{protocol}://#{host}:#{port}"
    end
    
    Rails.logger.info "=== URL Configuration ==="
    Rails.logger.info "Host: #{host}"
    Rails.logger.info "Port: #{port}"
    Rails.logger.info "Protocol: #{protocol}"
    Rails.logger.info "Asset Host: #{Rails.application.config.asset_host}"
    Rails.logger.info "========================="
  end
end
