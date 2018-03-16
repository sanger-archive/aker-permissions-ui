Rails.application.routes.draw do
  resources :stamps
  resources :deputies

  root 'deputies#index'
end
