# Configuración para manejar CSRF cuando estamos detrás de un proxy/túnel
# Esto es necesario porque el puerto puede cambiar (túnel de Minikube)

Rails.application.configure do
  if Rails.env.production?
    # Desactivar la validación de origen en CSRF
    # Esto es seguro cuando tienes validación de sesión adecuada
    config.action_controller.forgery_protection_origin_check = false
    
    # Permitir mismo sitio en cookies de sesión
    config.action_dispatch.cookies_same_site_protection = :lax
    
    # Asegurar que las cookies de sesión funcionen detrás de proxy
    config.session_store :cookie_store, 
      key: '_spree_session',
      same_site: :lax,
      secure: false  # Cambia a true si usas HTTPS
  end
end
