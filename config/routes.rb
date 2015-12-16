SharedLists::Application.routes.draw do
  match 'log_in' => 'sessions#new', :as => :log_in
  match 'log_out' => 'sessions#destroy', :as => :log_out
  resources :sessions, :only => [:new, :create, :destroy]

  match '/' => 'suppliers#index', :as => :root

  resources :suppliers do
    collection do
      get :ofn, action: 'index_ofn'
      get :new_from_ofn
      get :map
    end
    resources :articles do # name_prefix => nil
      collection do
        delete :destroy_all
        get :upload
        post :parse
        post :sync
      end
    end
  end

  match '/:controller(/:action(/:id))'
end
