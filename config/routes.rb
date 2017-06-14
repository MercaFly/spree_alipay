Spree::Core::Engine.routes.draw do
  # Add your extension routes here

  namespace :api do
    namespace :v1 do
      resources :alipay, only: [:index] do
        collection do
          post :mobile_security
          post :notify
        end
      end
    end
  end
end
