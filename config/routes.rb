Rails.application.routes.draw do
  resources :stamps
  resources :deputies

  root 'stamps#index'
end
