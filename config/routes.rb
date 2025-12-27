Rails.application.routes.draw do
  resources :tasks , defaults: {format: 'json'} do
    collection do
      get :stats, defaults: {format: 'json'}
    end
    member do
      post :status, to: "tasks#update_status", defaults: {format: 'json'}
      post :duplicate, defaults: {format: 'json'}
    end
  end
  resources :genres
end
