Rails.application.routes.draw do
  resources :stamps
  resources :deputies

  root 'deputies#index'
  health_check_routes
end
