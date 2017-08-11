Rails.application.routes.draw do
  resources :stamps

  root 'stamps#index'
end
