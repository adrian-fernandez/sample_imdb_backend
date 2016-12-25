Rails.application.routes.draw do
  resources :sessions, only: [:create]
  resources :users, only: [:create]
  resources :directors, only: [:index, :show]
  resources :movies, only: [:index, :create] do
    collection do
      get :suggestions
      get :get_movie
      post :batch_create
    end
  end
end
