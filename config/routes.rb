SharedLists::Application.routes.draw do
  match 'log_in' => 'sessions#new', :as => :log_in
  match 'log_out' => 'sessions#destroy', :as => :log_out
  resources :sessions, :only => [:new, :create, :destroy]

  match '/' => redirect('/suppliers?with_articles=1'), :as => :root

  resources :suppliers do
    get :map, :on => :collection
    resources :articles do # name_prefix => nil
      collection do
        delete :destroy_all
        get :upload
        post :parse
      end
    end
  end

  match '/:controller(/:action(/:id))'
end
